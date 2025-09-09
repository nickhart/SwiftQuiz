#!/usr/bin/env bash
set -euo pipefail

# Preflight script for SwiftQuiz
# Fixes format/lint issues and runs tests to ensure code is ready

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "==> Running preflight checks..."

# Auto-fix formatting issues
echo "==> Auto-fixing code formatting..."
./scripts/format.sh --fix

# Auto-fix linting issues where possible
echo "==> Auto-fixing code style issues..."
./scripts/lint.sh --fix

echo "==> Verifying format and lint checks..."
# Verify formatting is now clean
if ! ./scripts/format.sh; then
  echo ""
  echo "L Code formatting issues remain after auto-fix"
  echo "   Please manually review and fix remaining issues"
  exit 1
fi

# Verify linting is now clean
if ! ./scripts/lint.sh; then
  echo ""
  echo "L Code style issues remain after auto-fix"
  echo "   Please manually review and fix remaining issues"
  exit 1
fi

# Run unit tests (not UI tests to keep preflight fast)
echo "==> Running unit tests..."
./scripts/test.sh

echo " Preflight checks completed successfully - code is ready!"