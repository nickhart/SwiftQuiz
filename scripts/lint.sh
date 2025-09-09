

#!/usr/bin/env bash
set -euo pipefail

# Lint helper script for SwiftQuiz
# Usage:
#   ./scripts/lint.sh         # check only (no modifications)

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT_DIR"

echo "==> Running SwiftLint (check)..."
swiftlint --strict

echo "==> Running SwiftFormat (check)..."
swiftformat --lint .

echo "✅ Lint checks passed."