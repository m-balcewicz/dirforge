#!/usr/bin/env bash
set -euo pipefail

# install_dirforge.sh
# Install the repo-local `tools/dirforge` script into a user or system bin directory
# Usage:
#   ./scripts/install_dirforge.sh          # install to ~/bin (no sudo)
#   sudo ./scripts/install_dirforge.sh --system   # install to /usr/local/bin (system-wide)

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null 2>&1 && pwd)"
SRC="$REPO_ROOT/tools/dirforge"

if [ ! -f "$SRC" ]; then
  echo "ERROR: cannot find $SRC. Run this script from the repository root." >&2
  exit 1
fi

INSTALL_SYSTEM=false
if [ "${1:-}" = "--system" ]; then
  INSTALL_SYSTEM=true
fi

if [ "$INSTALL_SYSTEM" = true ]; then
  DEST="/usr/local/bin/dirforge"
  echo "Installing system-wide to $DEST (requires sudo)..."
  sudo mkdir -p /usr/local/bin
  sudo cp "$SRC" "$DEST"
  sudo chmod 755 "$DEST"
  echo "Installed to $DEST"
else
  BIN_DIR="$HOME/bin"
  DEST="$BIN_DIR/dirforge"
  mkdir -p "$BIN_DIR"
  cp "$SRC" "$DEST"
  chmod 755 "$DEST"
  echo "Installed to $DEST"
  # Suggest PATH update for zsh users
  if ! printf '%s
'"$PATH"' | tr ':' '\n' | grep -xq "$BIN_DIR"; then
    echo
    echo "Note: $BIN_DIR is not currently in your PATH. To add it (zsh):"
    echo '  echo "export PATH=\"$HOME/bin:$PATH\"" >> ~/.zshrc'
    echo '  source ~/.zshrc'
    echo
  fi
fi

echo "You can now run 'dirforge init --help' from any shell (restart shell if PATH changed)."
