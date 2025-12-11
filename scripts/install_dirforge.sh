#!/usr/bin/env bash
set -euo pipefail

# install_dirforge.sh
# Install the dirforge scaffolder tool to a user or system bin directory
#
# Usage:
#   ./scripts/install_dirforge.sh           # install to ~/bin (default, no sudo)
#   ./scripts/install_dirforge.sh --local   # install to ~/bin (explicit)
#   sudo ./scripts/install_dirforge.sh --system   # install to /usr/local/bin (system-wide)
#
# The --local mode is the default and recommended for single-user setups.
# The --system mode installs for all users and requires sudo privileges.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null 2>&1 && pwd)"
SRC="$REPO_ROOT/tools/dirforge"

if [ ! -f "$SRC" ]; then
  echo "ERROR: cannot find $SRC. Run this script from the repository root." >&2
  exit 1
fi

# Parse installation mode
INSTALL_MODE="local"  # default
if [ $# -gt 0 ]; then
  case "${1:-}" in
    --system)
      INSTALL_MODE="system"
      ;;
    --local)
      INSTALL_MODE="local"
      ;;
    --help|-h)
      echo "Usage: $0 [--local|--system]"
      echo
      echo "Install dirforge scaffolder tool:"
      echo "  --local   Install to ~/bin (default, no sudo required)"
      echo "  --system  Install to /usr/local/bin (requires sudo)"
      echo
      echo "Examples:"
      echo "  $0                    # Install locally to ~/bin"
      echo "  $0 --local            # Same as above (explicit)"
      echo "  sudo $0 --system      # Install system-wide to /usr/local/bin"
      exit 0
      ;;
    *)
      echo "ERROR: Unknown option: $1" >&2
      echo "Use --help for usage information." >&2
      exit 1
      ;;
  esac
fi

# Perform installation
if [ "$INSTALL_MODE" = "system" ]; then
  DEST="/usr/local/bin/dirforge"
  LIB_DEST="/usr/local/lib/dirforge"
  
  # Check for sudo if not running as root
  if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: System installation requires sudo privileges." >&2
    echo "Run: sudo $0 --system" >&2
    exit 1
  fi
  
  echo "Installing system-wide to $DEST..."
  mkdir -p /usr/local/bin
  mkdir -p "$LIB_DEST"
  
  # Copy main script
  cp "$SRC" "$DEST"
  chmod 755 "$DEST"
  
  # Copy help system and error handling libraries
  if [ -d "$REPO_ROOT/lib" ]; then
    cp -r "$REPO_ROOT/lib"/* "$LIB_DEST/"
    chmod 755 "$LIB_DEST"/*.sh
    echo "✓ Installed help system and error handling libraries to $LIB_DEST"
  fi
  
  # Copy templates
  if [ -d "$REPO_ROOT/templates" ]; then
    cp -r "$REPO_ROOT/templates" "$LIB_DEST/"
    echo "✓ Installed templates to $LIB_DEST"
  fi
  
  echo "✓ Installed to $DEST (available to all users)"
  
else  # local mode
  BIN_DIR="$HOME/bin"
  LIB_DIR="$HOME/.local/lib/dirforge"
  DEST="$BIN_DIR/dirforge"
  
  echo "Installing locally to $DEST..."
  mkdir -p "$BIN_DIR"
  mkdir -p "$LIB_DIR"
  
  # Copy main script
  cp "$SRC" "$DEST"
  chmod 755 "$DEST"
  
  # Copy help system and error handling libraries
  if [ -d "$REPO_ROOT/lib" ]; then
    cp -r "$REPO_ROOT/lib"/* "$LIB_DIR/"
    chmod 755 "$LIB_DIR"/*.sh
    echo "✓ Installed help system and error handling libraries to $LIB_DIR"
  fi
  
  # Copy templates
  if [ -d "$REPO_ROOT/templates" ]; then
    cp -r "$REPO_ROOT/templates" "$LIB_DIR/"
    echo "✓ Installed templates to $LIB_DIR"
  fi
  
  echo "✓ Installed to $DEST"
  
  # Check PATH and suggest update if needed
  if ! printf '%s\n' "$PATH" | tr ':' '\n' | grep -xq "$BIN_DIR"; then
    echo
    echo "⚠ Note: $BIN_DIR is not currently in your PATH."
    echo
    echo "To add it to your PATH:"
    
    # Detect shell and provide appropriate instructions
    if [ -n "${BASH_VERSION:-}" ]; then
      echo "  (bash) echo 'export PATH=\"$HOME/bin:$PATH\"' >> ~/.bashrc"
      echo "         source ~/.bashrc"
    elif [ -n "${ZSH_VERSION:-}" ]; then
      echo "  (zsh)  echo 'export PATH=\"$HOME/bin:$PATH\"' >> ~/.zshrc"
      echo "         source ~/.zshrc"
    else
      echo "  Add the following to your shell's RC file (~/.bashrc, ~/.zshrc, etc.):"
      echo "    export PATH=\"$HOME/bin:$PATH\""
    fi
    echo
  fi
fi

echo
echo "Installation complete!"
echo "You can now run: dirforge --help"
if [ "$INSTALL_MODE" = "local" ]; then
  echo "(Restart your shell if you updated PATH)"
fi
