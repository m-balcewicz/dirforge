#!/usr/bin/env bash
set -euo pipefail

# uninstall_dirforge.sh
# Uninstall the dirforge scaffolder tool from the system
#
# Usage:
#   ./scripts/uninstall_dirforge.sh           # interactive uninstall
#   ./scripts/uninstall_dirforge.sh --local   # remove local installation
#   ./scripts/uninstall_dirforge.sh --system  # remove system installation (requires sudo)
#   ./scripts/uninstall_dirforge.sh --all     # remove all possible installations

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Utility functions
print_header() {
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC} ${CYAN}                    DirForge Uninstallation${NC} ${BLUE}                           ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Get user confirmation
confirm() {
    local prompt="$1"
    local default="${2:-n}"
    local response

    if [[ "$default" == "y" ]]; then
        echo -n "$prompt [Y/n]: "
    else
        echo -n "$prompt [y/N]: "
    fi

    read -r response
    response=${response:-$default}

    case "$response" in
        [Yy]|[Yy][Ee][Ss]) return 0 ;;
        [Nn]|[Nn][Oo]) return 1 ;;
        *) return 1 ;;
    esac
}

# Check if running as root
is_root() {
    [[ $EUID -eq 0 ]]
}

# Check if file/directory exists
exists() {
    [[ -e "$1" ]]
}

# Safely remove file/directory
safe_remove() {
    local path="$1"
    local description="$2"

    if exists "$path"; then
        if [[ -d "$path" ]]; then
            echo "Removing directory: $path"
            rm -rf "$path"
        else
            echo "Removing file: $path"
            rm -f "$path"
        fi
        print_success "Removed $description"
        return 0
    else
        print_info "$description not found (already removed)"
        return 1
    fi
}

# Remove local installation
uninstall_local() {
    local removed_something=false

    echo "Checking for local installation..."

    # Remove main binary
    if safe_remove "$HOME/bin/dirforge" "local binary"; then
        removed_something=true
    fi

    # Remove library directory
    if safe_remove "$HOME/.local/lib/dirforge" "local libraries"; then
        removed_something=true
    fi

    # Check for empty directories and clean up
    if exists "$HOME/bin" && ! find "$HOME/bin" -mindepth 1 -print -quit 2>/dev/null | grep -q .; then
        safe_remove "$HOME/bin" "empty bin directory"
    fi

    if exists "$HOME/.local/lib" && ! find "$HOME/.local/lib" -mindepth 1 -print -quit 2>/dev/null | grep -q .; then
        safe_remove "$HOME/.local/lib" "empty lib directory"
    fi

    if exists "$HOME/.local" && ! find "$HOME/.local" -mindepth 1 -print -quit 2>/dev/null | grep -q .; then
        safe_remove "$HOME/.local" "empty .local directory"
    fi

    if [[ "$removed_something" == true ]]; then
        print_success "Local installation removed"
        return 0
    else
        print_info "No local installation found"
        return 1
    fi
}

# Remove system installation
uninstall_system() {
    local removed_something=false

    echo "Checking for system installation..."

    # Remove main binary
    if safe_remove "/usr/local/bin/dirforge" "system binary"; then
        removed_something=true
    fi

    # Remove library directory
    if safe_remove "/usr/local/lib/dirforge" "system libraries"; then
        removed_something=true
    fi

    if [[ "$removed_something" == true ]]; then
        print_success "System installation removed"
        return 0
    else
        print_info "No system installation found"
        return 1
    fi
}

# Show usage information
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Uninstall dirforge from the system."
    echo
    echo "Options:"
    echo "  --local    Remove local installation (~/.local/ and ~/bin/)"
    echo "  --system   Remove system installation (/usr/local/...) - requires sudo"
    echo "  --all      Remove all possible installations"
    echo "  --help     Show this help message"
    echo
    echo "If no options are specified, runs in interactive mode."
    echo
    echo "Examples:"
    echo "  $0                    # Interactive uninstall"
    echo "  $0 --local            # Remove local installation"
    echo "  sudo $0 --system      # Remove system installation"
    echo "  sudo $0 --all         # Remove everything"
}

# Interactive uninstall mode
interactive_uninstall() {
    echo "DirForge Uninstallation"
    echo "======================="
    echo
    echo "This will remove DirForge from your system."
    echo

    local local_exists=false
    local system_exists=false

    # Check what installations exist
    if exists "$HOME/bin/dirforge" || exists "$HOME/.local/lib/dirforge"; then
        local_exists=true
        echo "Found local installation:"
        exists "$HOME/bin/dirforge" && echo "  • $HOME/bin/dirforge"
        exists "$HOME/.local/lib/dirforge" && echo "  • $HOME/.local/lib/dirforge"
    fi

    if exists "/usr/local/bin/dirforge" || exists "/usr/local/lib/dirforge"; then
        system_exists=true
        echo "Found system installation:"
        exists "/usr/local/bin/dirforge" && echo "  • /usr/local/bin/dirforge"
        exists "/usr/local/lib/dirforge" && echo "  • /usr/local/lib/dirforge"
    fi

    if [[ "$local_exists" == false && "$system_exists" == false ]]; then
        print_warning "No DirForge installation found on this system."
        echo
        echo "DirForge may not be installed, or it may have been installed"
        echo "in a non-standard location."
        return 1
    fi

    echo
    local removed_anything=false

    # Handle local installation
    if [[ "$local_exists" == true ]]; then
        if confirm "Remove local installation?" "y"; then
            if uninstall_local; then
                removed_anything=true
            fi
        fi
    fi

    # Handle system installation
    if [[ "$system_exists" == true ]]; then
        if is_root; then
            if confirm "Remove system installation?" "y"; then
                if uninstall_system; then
                    removed_anything=true
                fi
            fi
        else
            print_warning "System installation found, but not running as root."
            echo "To remove system installation, run: sudo $0 --system"
        fi
    fi

    if [[ "$removed_anything" == true ]]; then
        echo
        print_success "Uninstallation completed!"
        echo
        echo "Note: You may need to restart your shell or remove PATH modifications"
        echo "from your shell configuration file (~/.bashrc, ~/.zshrc, etc.) if you"
        echo "added them during installation."
    else
        echo
        print_info "No installations were removed."
    fi
}

# Main function
main() {
    local mode=""
    local uninstall_all=false

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --local)
                mode="local"
                shift
                ;;
            --system)
                mode="system"
                shift
                ;;
            --all)
                uninstall_all=true
                shift
                ;;
            --help|-h)
                show_usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                echo
                show_usage
                exit 1
                ;;
        esac
    done

    print_header

    # Determine what to do
    if [[ "$uninstall_all" == true ]]; then
        echo "Removing all DirForge installations..."
        echo

        local removed_local=false
        local removed_system=false

        if uninstall_local; then
            removed_local=true
        fi

        if uninstall_system; then
            removed_system=true
        fi

        if [[ "$removed_local" == false && "$removed_system" == false ]]; then
            print_warning "No installations found to remove."
        else
            print_success "All installations removed!"
        fi

    elif [[ -n "$mode" ]]; then
        # Specific mode requested
        case "$mode" in
            local)
                if ! uninstall_local; then
                    print_warning "Local installation not found."
                fi
                ;;
            system)
                if ! is_root && [[ "$mode" == "system" ]]; then
                    print_error "System uninstallation requires sudo privileges."
                    echo "Run: sudo $0 --system"
                    exit 1
                fi
                if ! uninstall_system; then
                    print_warning "System installation not found."
                fi
                ;;
        esac
    else
        # Interactive mode
        interactive_uninstall
    fi
}

# Run main function
main "$@"