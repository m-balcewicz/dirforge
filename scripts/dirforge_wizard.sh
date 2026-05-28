#!/usr/bin/env bash
set -euo pipefail

# dirforge_wizard.sh
# Unified management wizard for install/update/uninstall flows.
#
# Usage:
#   ./scripts/dirforge_wizard.sh
#   ./scripts/dirforge_wizard.sh --help

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." >/dev/null 2>&1 && pwd)"

INSTALL_SCRIPT="$SCRIPT_DIR/install_dirforge.sh"
UPDATE_SCRIPT="$SCRIPT_DIR/update_dirforge.sh"
UNINSTALL_SCRIPT="$SCRIPT_DIR/uninstall_dirforge.sh"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

print_header() {
  clear || true
  echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${BLUE}║${NC} ${CYAN}                    DirForge Management Wizard${NC} ${BLUE}                              ║${NC}"
  echo -e "${BLUE}║${NC} ${BOLD}                 Install / Update / Uninstall${NC} ${BLUE}                               ║${NC}"
  echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
  echo
  echo "Repo: $REPO_ROOT"
  echo
}

print_error() {
  echo -e "${RED}Error:${NC} $1" >&2
}

print_info() {
  echo -e "${BLUE}Info:${NC} $1"
}

print_success() {
  echo -e "${GREEN}Success:${NC} $1"
}

pause() {
  echo
  read -r -p "Press Enter to continue..." _
}

require_scripts() {
  local missing=()
  [[ -f "$INSTALL_SCRIPT" ]] || missing+=("$INSTALL_SCRIPT")
  [[ -f "$UPDATE_SCRIPT" ]] || missing+=("$UPDATE_SCRIPT")
  [[ -f "$UNINSTALL_SCRIPT" ]] || missing+=("$UNINSTALL_SCRIPT")

  if [[ ${#missing[@]} -gt 0 ]]; then
    print_error "Required script(s) missing:" 
    for path in "${missing[@]}"; do
      echo "  - $path" >&2
    done
    exit 1
  fi
}

run_install_menu() {
  while true; do
    echo -e "${BOLD}Install Options${NC}"
    echo "  1) Interactive install wizard (--wizard)"
    echo "  2) Local install (--local)"
    echo "  3) System install (--system)"
    echo "  4) Back"
    echo
    read -r -p "Choose [1-4]: " choice

    case "$choice" in
      1)
        bash "$INSTALL_SCRIPT" --wizard
        pause
        return
        ;;
      2)
        bash "$INSTALL_SCRIPT" --local
        pause
        return
        ;;
      3)
        if [[ "$EUID" -ne 0 ]]; then
          print_info "System install may ask for sudo in the called script."
        fi
        bash "$INSTALL_SCRIPT" --system
        pause
        return
        ;;
      4)
        return
        ;;
      *)
        print_error "Invalid choice."
        ;;
    esac
  done
}

run_update_menu() {
  while true; do
    echo -e "${BOLD}Update Options${NC}"
    echo "  1) Interactive update (default)"
    echo "  2) Dry run (--dry-run)"
    echo "  3) Force apply (--force)"
    echo "  4) Tool only (--tool-only)"
    echo "  5) Workspace only (--workspace-only)"
    echo "  6) Bootstrap metadata only (--bootstrap)"
    echo "  7) Custom arguments"
    echo "  8) Back"
    echo
    read -r -p "Choose [1-8]: " choice

    case "$choice" in
      1)
        bash "$UPDATE_SCRIPT"
        pause
        return
        ;;
      2)
        bash "$UPDATE_SCRIPT" --dry-run
        pause
        return
        ;;
      3)
        bash "$UPDATE_SCRIPT" --force
        pause
        return
        ;;
      4)
        bash "$UPDATE_SCRIPT" --tool-only
        pause
        return
        ;;
      5)
        bash "$UPDATE_SCRIPT" --workspace-only
        pause
        return
        ;;
      6)
        bash "$UPDATE_SCRIPT" --bootstrap
        pause
        return
        ;;
      7)
        read -r -p "Enter extra args for update_dirforge.sh: " custom_args
        # shellcheck disable=SC2086
        bash "$UPDATE_SCRIPT" $custom_args
        pause
        return
        ;;
      8)
        return
        ;;
      *)
        print_error "Invalid choice."
        ;;
    esac
  done
}

run_uninstall_menu() {
  while true; do
    echo -e "${BOLD}Uninstall Options${NC}"
    echo "  1) Interactive uninstall (default)"
    echo "  2) Local uninstall (--local)"
    echo "  3) System uninstall (--system)"
    echo "  4) Remove all (--all)"
    echo "  5) Back"
    echo
    read -r -p "Choose [1-5]: " choice

    case "$choice" in
      1)
        bash "$UNINSTALL_SCRIPT"
        pause
        return
        ;;
      2)
        bash "$UNINSTALL_SCRIPT" --local
        pause
        return
        ;;
      3)
        if [[ "$EUID" -ne 0 ]]; then
          print_info "System uninstall may require sudo in the called script."
        fi
        bash "$UNINSTALL_SCRIPT" --system
        pause
        return
        ;;
      4)
        bash "$UNINSTALL_SCRIPT" --all
        pause
        return
        ;;
      5)
        return
        ;;
      *)
        print_error "Invalid choice."
        ;;
    esac
  done
}

show_help() {
  cat <<EOF
DirForge Management Wizard

Usage:
  ./scripts/dirforge_wizard.sh
  ./scripts/dirforge_wizard.sh --help

This wrapper keeps install/update/uninstall scripts separate, and provides
one interactive entrypoint to run them.
EOF
}

main() {
  case "${1:-}" in
    --help|-h)
      show_help
      exit 0
      ;;
    "")
      ;;
    *)
      print_error "Unknown option: $1"
      echo "Use --help for usage."
      exit 1
      ;;
  esac

  require_scripts

  while true; do
    print_header
    echo -e "${BOLD}Main Menu${NC}"
    echo "  1) Install"
    echo "  2) Update"
    echo "  3) Uninstall"
    echo "  4) Exit"
    echo
    read -r -p "Choose [1-4]: " choice

    case "$choice" in
      1) run_install_menu ;;
      2) run_update_menu ;;
      3) run_uninstall_menu ;;
      4)
        print_success "Goodbye."
        exit 0
        ;;
      *)
        print_error "Invalid choice."
        pause
        ;;
    esac
  done
}

main "$@"
