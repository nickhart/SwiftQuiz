#!/usr/bin/env bash
set -euo pipefail

# Simulator management script for SwiftQuiz
# Usage:
#   ./scripts/simulator.sh list                              # List all simulators
#   ./scripts/simulator.sh list --family iPhone             # Filter by device family
#   ./scripts/simulator.sh list --device "iPhone 15 Pro"    # Filter by specific device
#   ./scripts/simulator.sh list --os 18.1                   # Filter by OS version
#   ./scripts/simulator.sh create --device "iPhone 15 Pro" --os 18.1 --name "My Test Device"
#   ./scripts/simulator.sh boot <udid_or_name>              # Boot a simulator
#   ./scripts/simulator.sh shutdown <udid_or_name>          # Shutdown a simulator
#   ./scripts/simulator.sh erase <udid_or_name>             # Erase simulator data
#   ./scripts/simulator.sh delete <udid_or_name>            # Delete simulator
#   ./scripts/simulator.sh install <udid_or_name> <app_path> # Install app to simulator

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

# Source helper functions
source "$(dirname "${BASH_SOURCE[0]}")/_helpers.sh"

show_help() {
  echo "Simulator Management Script"
  echo ""
  echo "USAGE:"
  echo "  $0 list [OPTIONS]                    List available simulators"
  echo "  $0 create [OPTIONS]                  Create a new simulator"
  echo "  $0 boot <udid_or_name>               Boot a simulator"
  echo "  $0 shutdown <udid_or_name>           Shutdown a simulator"
  echo "  $0 erase <udid_or_name>              Erase simulator data"
  echo "  $0 delete <udid_or_name>             Delete a simulator"
  echo "  $0 install <udid_or_name> <app_path> Install app to simulator"
  echo ""
  echo "LIST OPTIONS:"
  echo "  --family <iPhone|iPad|Apple Watch>  Filter by device family"
  echo "  --device <device_name>               Filter by specific device name"
  echo "  --os <version>                       Filter by OS version (e.g., 18.1, 17.5)"
  echo "  --available-only                     Show only booted/shutdown devices"
  echo "  --json                               Output raw JSON"
  echo ""
  echo "CREATE OPTIONS:"
  echo "  --device <device_name>               Device type (required)"
  echo "  --os <version>                       OS version (required)"
  echo "  --name <simulator_name>              Custom name for simulator (required)"
  echo ""
  echo "EXAMPLES:"
  echo "  $0 list --family iPhone --os 18.1"
  echo "  $0 create --device \"iPhone 15 Pro\" --os 18.1 --name \"Test Device\""
  echo "  $0 boot \"iPhone 15 Pro\""
}

# Parse device types and runtimes from simctl list
get_device_types() {
  xcrun simctl list devicetypes --json | jq -r '.devicetypes[] | select(.productFamily == "'"$1"'") | .name'
}

get_runtimes() {
  xcrun simctl list runtimes --json | jq -r '.runtimes[] | select(.name | startswith("iOS")) | .version'
}

list_simulators() {
  local family_filter=""
  local device_filter=""
  local os_filter=""
  local available_only=false
  local json_output=false

  # Parse list options
  while [[ $# -gt 0 ]]; do
    case $1 in
      --family)
        family_filter="$2"
        shift 2
        ;;
      --device)
        device_filter="$2"
        shift 2
        ;;
      --os)
        os_filter="$2"
        shift 2
        ;;
      --available-only)
        available_only=true
        shift
        ;;
      --json)
        json_output=true
        shift
        ;;
      *)
        echo "Unknown option: $1" >&2
        exit 1
        ;;
    esac
  done

  if $json_output; then
    xcrun simctl list devices --json
    return
  fi

  local jq_filter='.devices | to_entries[] | .key as $runtime | .value[] | select(.isAvailable == true'

  if [[ -n "$family_filter" ]]; then
    jq_filter="$jq_filter and (.deviceTypeIdentifier | contains(\"$family_filter\"))"
  fi

  if [[ -n "$device_filter" ]]; then
    jq_filter="$jq_filter and (.name | contains(\"$device_filter\"))"
  fi

  if [[ -n "$os_filter" ]]; then
    jq_filter="$jq_filter and (\$runtime | contains(\"$os_filter\"))"
  fi

  if $available_only; then
    jq_filter="$jq_filter and (.state == \"Booted\" or .state == \"Shutdown\")"
  fi

  jq_filter="$jq_filter) | \"\(.name) (\(.udid)) [\(.state)] - \" + \$runtime"

  echo "Available Simulators:"
  echo "===================="
  xcrun simctl list devices --json | jq -r "$jq_filter" | sort
}

create_simulator() {
  local device_type=""
  local os_version=""
  local sim_name=""

  # Parse create options
  while [[ $# -gt 0 ]]; do
    case $1 in
      --device)
        device_type="$2"
        shift 2
        ;;
      --os)
        os_version="$2"
        shift 2
        ;;
      --name)
        sim_name="$2"
        shift 2
        ;;
      *)
        echo "Unknown option: $1" >&2
        exit 1
        ;;
    esac
  done

  if [[ -z "$device_type" || -z "$os_version" || -z "$sim_name" ]]; then
    echo "Error: --device, --os, and --name are required for create command" >&2
    echo "Example: $0 create --device \"iPhone 15 Pro\" --os 18.1 --name \"My Test Device\""
    exit 1
  fi

  # Find matching device type identifier
  local device_id
  device_id=$(xcrun simctl list devicetypes --json | jq -r ".devicetypes[] | select(.name == \"$device_type\") | .identifier")

  if [[ -z "$device_id" ]]; then
    echo "Error: Device type '$device_type' not found" >&2
    echo "Available device types:"
    xcrun simctl list devicetypes --json | jq -r '.devicetypes[].name' | sort
    exit 1
  fi

  # Find matching runtime identifier
  local runtime_id
  runtime_id=$(xcrun simctl list runtimes --json | jq -r ".runtimes[] | select(.version == \"$os_version\" and .name | startswith(\"iOS\")) | .identifier")

  if [[ -z "$runtime_id" ]]; then
    echo "Error: iOS runtime version '$os_version' not found" >&2
    echo "Available iOS runtimes:"
    xcrun simctl list runtimes --json | jq -r '.runtimes[] | select(.name | startswith("iOS")) | .version' | sort
    exit 1
  fi

  echo "Creating simulator '$sim_name' with $device_type running iOS $os_version..."
  local udid
  udid=$(xcrun simctl create "$sim_name" "$device_id" "$runtime_id")
  echo "Created simulator with UDID: $udid"
}

find_simulator() {
  local identifier="$1"

  # First try to find by UDID
  if xcrun simctl list devices --json | jq -e ".devices[][] | select(.udid == \"$identifier\")" >/dev/null; then
    echo "$identifier"
    return
  fi

  # Then try to find by name
  local udid
  udid=$(xcrun simctl list devices --json | jq -r ".devices[][] | select(.name == \"$identifier\") | .udid" | head -n1)

  if [[ -n "$udid" ]]; then
    echo "$udid"
    return
  fi

  echo "Error: Simulator '$identifier' not found" >&2
  exit 1
}

boot_simulator() {
  local identifier="$1"
  local udid
  udid=$(find_simulator "$identifier")

  echo "Booting simulator $identifier ($udid)..."
  xcrun simctl boot "$udid"
  echo "Simulator booted successfully"
}

shutdown_simulator() {
  local identifier="$1"
  local udid
  udid=$(find_simulator "$identifier")

  echo "Shutting down simulator $identifier ($udid)..."
  xcrun simctl shutdown "$udid"
  echo "Simulator shut down successfully"
}

erase_simulator() {
  local identifier="$1"
  local udid
  udid=$(find_simulator "$identifier")

  echo "Erasing simulator $identifier ($udid)..."
  xcrun simctl erase "$udid"
  echo "Simulator erased successfully"
}

delete_simulator() {
  local identifier="$1"
  local udid
  udid=$(find_simulator "$identifier")

  echo "Deleting simulator $identifier ($udid)..."
  xcrun simctl delete "$udid"
  echo "Simulator deleted successfully"
}

install_app() {
  local identifier="$1"
  local app_path="$2"
  local udid
  udid=$(find_simulator "$identifier")

  if [[ ! -e "$app_path" ]]; then
    echo "Error: App path '$app_path' does not exist" >&2
    exit 1
  fi

  echo "Installing app at $app_path to simulator $identifier ($udid)..."
  xcrun simctl install "$udid" "$app_path"
  echo "App installed successfully"
}

# Main command parsing
if [[ $# -eq 0 ]]; then
  show_help
  exit 0
fi

case "$1" in
  list)
    shift
    list_simulators "$@"
    ;;
  create)
    shift
    create_simulator "$@"
    ;;
  boot)
    if [[ $# -ne 2 ]]; then
      echo "Usage: $0 boot <udid_or_name>" >&2
      exit 1
    fi
    boot_simulator "$2"
    ;;
  shutdown)
    if [[ $# -ne 2 ]]; then
      echo "Usage: $0 shutdown <udid_or_name>" >&2
      exit 1
    fi
    shutdown_simulator "$2"
    ;;
  erase)
    if [[ $# -ne 2 ]]; then
      echo "Usage: $0 erase <udid_or_name>" >&2
      exit 1
    fi
    erase_simulator "$2"
    ;;
  delete)
    if [[ $# -ne 2 ]]; then
      echo "Usage: $0 delete <udid_or_name>" >&2
      exit 1
    fi
    delete_simulator "$2"
    ;;
  install)
    if [[ $# -ne 3 ]]; then
      echo "Usage: $0 install <udid_or_name> <app_path>" >&2
      exit 1
    fi
    install_app "$2" "$3"
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