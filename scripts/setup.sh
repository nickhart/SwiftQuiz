

#!/usr/bin/env bash
set -euo pipefail

# Setup script for SwiftQuiz project
# - Installs Homebrew dependencies from Brewfile
# - Installs Git pre-commit hook

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> Installing Homebrew dependencies..."
brew bundle install --file="$ROOT_DIR/Brewfile"

echo "==> Setting up Git pre-commit hook..."
HOOKS_DIR="$ROOT_DIR/.git/hooks"
PRE_COMMIT_HOOK="$HOOKS_DIR/pre-commit"

mkdir -p "$HOOKS_DIR"
cat > "$PRE_COMMIT_HOOK" <<EOF
#!/usr/bin/env bash
exec "$ROOT_DIR/scripts/pre-commit.sh" "\$@"
EOF
chmod +x "$PRE_COMMIT_HOOK"

echo "Setup complete!"