#!/usr/bin/env bash
set -euo pipefail

# Pre-commit hook for SwiftQuiz
# This script runs lint and format checks before allowing commits

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "==> Running pre-commit checks..."

# Check formatting first
echo "==> Checking code formatting..."
if ! ./scripts/format.sh; then
  echo ""
  echo "L Code formatting issues found!"
  echo "   Run './scripts/format.sh --fix' to auto-fix formatting issues"
  exit 1
fi

# Check linting
echo "==> Checking code style..."
if ! ./scripts/lint.sh; then
  echo ""
  echo "L Code style issues found!"
  echo "   Run './scripts/lint.sh --fix' to auto-fix some issues"
  exit 1
fi

echo " Pre-commit checks passed"