

#!/usr/bin/env bash
set -euo pipefail

# Format helper script for SwiftQuiz
# Usage:
#   ./scripts/format.sh         # check only
#   ./scripts/format.sh --fix   # auto-fix

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIX_MODE=false

if [[ "${1:-}" == "--fix" ]]; then
  FIX_MODE=true
fi

cd "$ROOT_DIR"

if $FIX_MODE; then
  echo "==> Running SwiftFormat (auto-fix)..."
  swiftformat .

  echo "==> Running SwiftLint (auto-fix where possible)..."
  swiftlint --fix
else
  echo "==> Checking SwiftFormat (lint)..."
  swiftformat --lint .
fi

echo "✅ Format checks passed."