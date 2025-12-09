#!/usr/bin/env bash
set -euo pipefail

# bootstrap-dev.sh - helper to check/install dev tools used by this repo
# This script prints recommended install commands for your platform.

echo "Checking developer toolchain..."

need_install=()

check_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    need_install+=("$1")
  else
    echo "$1: found -> $(command -v "$1")"
  fi
}

check_cmd yq
check_cmd shellcheck

if [ ${#need_install[@]} -eq 0 ]; then
  echo "All dev tools present.";
  exit 0
fi

echo "Missing tools: ${need_install[*]}"

if [[ "$(uname -s)" == "Darwin" ]]; then
  echo "On macOS you can install with Homebrew (recommended):"
  for t in "${need_install[@]}"; do
    echo "  brew install $t"
  done
else
  echo "On Linux try apt or your package manager. Example (Debian/Ubuntu):"
  for t in "${need_install[@]}"; do
    echo "  sudo apt-get update && sudo apt-get install -y $t"
  done
fi

echo "If you want this script to attempt installation, re-run with --install (not recommended without review)."

if [ "${1:-}" = "--install" ]; then
  echo "Attempting to install: ${need_install[*]}"
  if [[ "$(uname -s)" == "Darwin" ]]; then
    for t in "${need_install[@]}"; do brew install "$t"; done
  else
    sudo apt-get update
    for t in "${need_install[@]}"; do sudo apt-get install -y "$t"; done
  fi
fi
