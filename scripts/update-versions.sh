#!/usr/bin/env bash

set -euo pipefail

# Simple version update script for DirForge
# Usage: ./scripts/update-versions.sh <new-version>
# Example: ./scripts/update-versions.sh 1.2.0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# --- Functions ---

usage() {
  cat <<EOF
Usage: update-versions.sh <new-version>

Update all version references throughout the repository.

Arguments:
  new-version    The new version number (e.g., 1.2.0)

Options:
  --dry-run      Show what would be changed without modifying files
  -y             Skip confirmation prompts
  --help         Show this help message

Examples:
  ./scripts/update-versions.sh 1.2.0
  ./scripts/update-versions.sh --dry-run 1.2.0

EOF
}

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

# Find all version references and show them
find_versions() {
  local target_version="$1"
  
  log_info "Scanning for version references..."
  echo ""
  
  # Check dirforge.sh
  if [[ -f "$REPO_ROOT/dirforge.sh" ]]; then
    local current_version
    current_version=$(grep -m1 'VERSION=' "$REPO_ROOT/dirforge.sh" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
    if [[ -n "$current_version" && "$current_version" != "$target_version" ]]; then
      echo "  dirforge.sh: $current_version -> $target_version"
    fi
  fi
  
  # Check YAML files (excluding .specify)
  find "$REPO_ROOT" -name "*.yaml" -type f ! -path "*/.specify/*" ! -path "*/node_modules/*" | while read -r file; do
    local current_version
    current_version=$(grep -oE '(version|@schema-version): [0-9]+\.[0-9]+\.[0-9]+' "$file" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || true)
    if [[ -n "$current_version" && "$current_version" != "$target_version" ]]; then
      echo "  $(basename "$(dirname "$file")")/$(basename "$file"): $current_version -> $target_version"
    fi
  done
  
  # Check markdown files (excluding .specify)
  find "$REPO_ROOT" -name "*.md" -type f ! -path "*/.specify/*" ! -path "*/node_modules/*" | while read -r file; do
    local current_version
    current_version=$(grep -oE '(v|version|DirForge v)[0-9]+\.[0-9]+\.[0-9]+' "$file" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || true)
    if [[ -n "$current_version" && "$current_version" != "$target_version" ]]; then
      echo "  $(basename "$(dirname "$file")")/$(basename "$file"): $current_version -> $target_version"
    fi
  done
}

# Perform the actual update
update_versions() {
  local target_version="$1"
  
  log_info "Updating version references to v$target_version..."
  
  # Update dirforge.sh
  if [[ -f "$REPO_ROOT/dirforge.sh" ]]; then
    local current_version
    current_version=$(grep -m1 'VERSION=' "$REPO_ROOT/dirforge.sh" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
    if [[ -n "$current_version" && "$current_version" != "$target_version" ]]; then
      log_info "  Updating dirforge.sh..."
      sed -i.bak "s/VERSION=\"$current_version\"/VERSION=\"$target_version\"/" "$REPO_ROOT/dirforge.sh"
      rm -f "${REPO_ROOT}/dirforge.sh.bak"
    fi
  fi
  
  # Update YAML files (excluding .specify)
  find "$REPO_ROOT" -name "*.yaml" -type f ! -path "*/.specify/*" ! -path "*/node_modules/*" | while read -r file; do
    local current_version
    current_version=$(grep -oE '(version|@schema-version): [0-9]+\.[0-9]+\.[0-9]+' "$file" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || true)
    if [[ -n "$current_version" && "$current_version" != "$target_version" ]]; then
      log_info "  Updating $(basename "$(dirname "$file")")/$(basename "$file")..."
      sed -i.bak "s/$current_version/$target_version/g" "$file"
      rm -f "${file}.bak"
    fi
  done
  
  # Update markdown files (excluding .specify)
  find "$REPO_ROOT" -name "*.md" -type f ! -path "*/.specify/*" ! -path "*/node_modules/*" | while read -r file; do
    local current_version
    current_version=$(grep -oE '(v|version|DirForge v)[0-9]+\.[0-9]+\.[0-9]+' "$file" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || true)
    if [[ -n "$current_version" && "$current_version" != "$target_version" ]]; then
      log_info "  Updating $(basename "$(dirname "$file")")/$(basename "$file")..."
      sed -i.bak "s/$current_version/$target_version/g" "$file"
      rm -f "${file}.bak"
    fi
  done
  
  log_info "Version update complete!"
}

# --- Main ---

main() {
  local target_version=""
  local dry_run=false
  local skip_confirm=false
  
  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dry-run)
        dry_run=true
        shift
        ;;
      -y)
        skip_confirm=true
        shift
        ;;
      --help)
        usage
        exit 0
        ;;
      *)
        target_version="$1"
        shift
        ;;
    esac
  done
  
  # Validate arguments
  if [[ -z "$target_version" ]]; then
    log_error "No version specified!"
    usage
    exit 1
  fi
  
  # Validate version format
  if ! [[ "$target_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    log_error "Invalid version format: $target_version"
    log_info "Expected format: X.Y.Z (e.g., 1.2.0)"
    exit 1
  fi
  
  log_info "DirForge Version Update Tool"
  log_info "Target version: v$target_version"
  echo ""
  
  # Find current versions
  find_versions "$target_version"
  
  echo ""
  
  if [[ "$dry_run" == "true" ]]; then
    log_info "DRY-RUN MODE: No files will be modified"
    exit 0
  fi
  
  # Ask for confirmation unless skipped
  if [[ "$skip_confirm" == "false" ]]; then
    read -p "Update all version references to v$target_version? [y/N] " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
      log_info "Update cancelled."
      exit 0
    fi
  else
    log_info "Skipping confirmation (auto-confirmed)"
  fi
  
  # Perform update
  update_versions "$target_version"
}

main "$@"
