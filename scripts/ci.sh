#!/usr/bin/env bash
set -euo pipefail

# CI management script for SwiftQuiz using GitHub CLI
# Usage:
#   ./scripts/ci.sh status                    # Show status of recent runs
#   ./scripts/ci.sh list [--limit N]          # List recent workflow runs
#   ./scripts/ci.sh watch [run_id]            # Watch a specific run (or latest)
#   ./scripts/ci.sh logs [run_id]             # View logs for a run (or latest)
#   ./scripts/ci.sh errors [run_id]           # View only error logs for a run
#   ./scripts/ci.sh cancel [run_id]           # Cancel a running workflow
#   ./scripts/ci.sh rerun [run_id]            # Rerun a workflow

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

show_help() {
  echo "CI Management Script using GitHub CLI"
  echo ""
  echo "USAGE:"
  echo "  $0 status                    Show status of recent workflow runs"
  echo "  $0 list [OPTIONS]            List recent workflow runs"
  echo "  $0 watch [run_id]            Watch a specific run or latest run"
  echo "  $0 logs [run_id]             View logs for a run or latest run"
  echo "  $0 errors [run_id]           View only error logs for a run"
  echo "  $0 cancel [run_id]           Cancel a running workflow"
  echo "  $0 rerun [run_id]            Rerun a workflow"
  echo ""
  echo "LIST OPTIONS:"
  echo "  --limit N                    Number of runs to show (default: 10)"
  echo "  --status <status>            Filter by status: queued, in_progress, completed"
  echo "  --branch <branch>            Filter by branch name"
  echo ""
  echo "EXAMPLES:"
  echo "  $0 status"
  echo "  $0 list --limit 5 --status in_progress"
  echo "  $0 watch"
  echo "  $0 logs 12345678"
  echo "  $0 errors"
}

# Get the latest run ID if not provided
get_latest_run_id() {
  gh run list --limit 1 --json databaseId --jq '.[0].databaseId'
}

# Check if gh CLI is authenticated
check_auth() {
  if ! gh auth status >/dev/null 2>&1; then
    echo "L GitHub CLI not authenticated. Please run: gh auth login"
    exit 1
  fi
}

status_command() {
  echo "==> Recent CI Status"
  echo ""
  gh run list --limit 10 --json status,conclusion,displayTitle,headBranch,createdAt \
    --template '{{range .}}{{.status | printf "%-12s"}} {{.conclusion | printf "%-10s"}} {{.displayTitle | printf "%-50s"}} {{.headBranch}} ({{timeago .createdAt}})
{{end}}'
}

list_command() {
  local limit=10
  local status_filter=""
  local branch_filter=""

  # Parse list options
  while [[ $# -gt 0 ]]; do
    case $1 in
      --limit)
        limit="$2"
        shift 2
        ;;
      --status)
        status_filter="$2"
        shift 2
        ;;
      --branch)
        branch_filter="$2"
        shift 2
        ;;
      *)
        echo "Unknown option: $1" >&2
        exit 1
        ;;
    esac
  done

  local gh_cmd=(gh run list --limit "$limit")

  if [[ -n "$status_filter" ]]; then
    gh_cmd+=(--status "$status_filter")
  fi

  if [[ -n "$branch_filter" ]]; then
    gh_cmd+=(--branch "$branch_filter")
  fi

  echo "==> Workflow Runs (limit: $limit)"
  if [[ -n "$status_filter" ]]; then
    echo "    Status filter: $status_filter"
  fi
  if [[ -n "$branch_filter" ]]; then
    echo "    Branch filter: $branch_filter"
  fi
  echo ""

  "${gh_cmd[@]}"
}

watch_command() {
  local run_id="${1:-}"

  if [[ -z "$run_id" ]]; then
    echo "==> Getting latest run..."
    run_id=$(get_latest_run_id)
    if [[ -z "$run_id" ]]; then
      echo "L No workflow runs found"
      exit 1
    fi
    echo "    Watching run: $run_id"
  fi

  echo "==> Watching workflow run $run_id..."
  echo "    Press Ctrl+C to stop watching"
  echo ""

  gh run watch "$run_id"
}

logs_command() {
  local run_id="${1:-}"

  if [[ -z "$run_id" ]]; then
    echo "==> Getting latest run..."
    run_id=$(get_latest_run_id)
    if [[ -z "$run_id" ]]; then
      echo "L No workflow runs found"
      exit 1
    fi
    echo "    Viewing logs for run: $run_id"
  fi

  echo "==> Viewing logs for workflow run $run_id..."
  echo ""

  gh run view "$run_id" --log
}

errors_command() {
  local run_id="${1:-}"

  if [[ -z "$run_id" ]]; then
    echo "==> Getting latest run..."
    run_id=$(get_latest_run_id)
    if [[ -z "$run_id" ]]; then
      echo "L No workflow runs found"
      exit 1
    fi
    echo "    Viewing errors for run: $run_id"
  fi

  echo "==> Viewing error logs for workflow run $run_id..."
  echo ""

  # Get logs and filter for errors/failures
  gh run view "$run_id" --log | grep -i -E "(error|fail|L|)" || {
    echo "No errors found in logs for run $run_id"
    echo ""
    echo "Run summary:"
    gh run view "$run_id"
  }
}

cancel_command() {
  local run_id="${1:-}"

  if [[ -z "$run_id" ]]; then
    echo "==> Getting latest run..."
    run_id=$(get_latest_run_id)
    if [[ -z "$run_id" ]]; then
      echo "L No workflow runs found"
      exit 1
    fi
    echo "    Canceling run: $run_id"
  fi

  echo "==> Canceling workflow run $run_id..."

  # Check if run is still in progress
  local status
  status=$(gh run view "$run_id" --json status --jq '.status')

  if [[ "$status" != "in_progress" && "$status" != "queued" ]]; then
    echo "L Run $run_id is not in progress (status: $status)"
    exit 1
  fi

  gh run cancel "$run_id"
  echo " Run $run_id canceled"
}

rerun_command() {
  local run_id="${1:-}"

  if [[ -z "$run_id" ]]; then
    echo "==> Getting latest run..."
    run_id=$(get_latest_run_id)
    if [[ -z "$run_id" ]]; then
      echo "L No workflow runs found"
      exit 1
    fi
    echo "    Rerunning run: $run_id"
  fi

  echo "==> Rerunning workflow run $run_id..."

  gh run rerun "$run_id"
  echo " Run $run_id queued for rerun"
}

# Check authentication first
check_auth

# Main command parsing
if [[ $# -eq 0 ]]; then
  show_help
  exit 0
fi

case "$1" in
  status)
    status_command
    ;;
  list)
    shift
    list_command "$@"
    ;;
  watch)
    watch_command "${2:-}"
    ;;
  logs)
    logs_command "${2:-}"
    ;;
  errors)
    errors_command "${2:-}"
    ;;
  cancel)
    cancel_command "${2:-}"
    ;;
  rerun)
    rerun_command "${2:-}"
    ;;
  help|--help|-h)
    show_help
    ;;
  *)
    echo "Unknown command: $1" >&2
    echo "Use '$0 help' for usage information" >&2
    exit 1
    ;;
esac