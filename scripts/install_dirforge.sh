#!/usr/bin/env bash
set -euo pipefail

# install_dirforge.sh
# Install the dirforge scaffolder tool with optional interactive wizard
#
# Usage (non-interactive):
#   ./scripts/install_dirforge.sh                 # install to ~/bin (local, default)
#   ./scripts/install_dirforge.sh --local         # explicit local install
#   sudo ./scripts/install_dirforge.sh --system   # install to /usr/local/bin (system-wide)
#
# Usage (interactive wizard):
#   ./scripts/install_dirforge.sh --wizard        # start interactive installation wizard
#
# The --local mode is default and recommended for single-user setups.
# The --system mode installs for all users and requires sudo privileges.
# The --wizard mode provides an interactive guided installation experience.

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Detect terminal capabilities
if [ -t 1 ] && command -v tput >/dev/null 2>&1; then
    HAS_COLORS=true
    COLS=$(tput cols 2>/dev/null || echo 80)
else
    HAS_COLORS=false
    COLS=80
fi

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

print_header() {
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC} ${CYAN}                    DirForge Installation${NC} ${BLUE}                                   ║${NC}"
    echo -e "${BLUE}║${NC} ${PURPLE}         Create standardized directory structures per Constitution${NC} ${BLUE}          ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo
}

print_step() {
    local step_num="$1"
    local step_text="$2"
    echo -e "${GREEN}[$step_num]${NC} $step_text"
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

    if read -r response; then
        response=${response:-$default}
    else
        response="$default"
    fi

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

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# ============================================================================
# CORE INSTALLATION FUNCTION
# ============================================================================

perform_installation() {
    local install_mode="$1"
    local repo_root="$2"
    
    if [ "$install_mode" = "system" ]; then
        install_system_wide "$repo_root"
    else
        install_locally "$repo_root"
    fi
}

install_system_wide() {
    local repo_root="$1"
    local src="$repo_root/tools/dirforge"
    local dest="/usr/local/bin/dirforge"
    local lib_dest="/usr/local/lib/dirforge"
    
    # Check for sudo if not running as root
    if ! is_root; then
        print_error "System installation requires sudo privileges."
        echo "Run: sudo $0 --system"
        return 1
    fi
    
    echo "Installing system-wide to $dest..."
    mkdir -p /usr/local/bin "$lib_dest"
    
    # Copy main script
    cp "$src" "$dest"
    chmod 755 "$dest"
    
    # Copy libraries
    if [ -d "$repo_root/lib" ]; then
        cp -r "$repo_root/lib"/* "$lib_dest/"
        chmod 755 "$lib_dest"/*.sh
        print_success "Installed libraries to $lib_dest"
    fi
    
    # Copy templates
    if [ -d "$repo_root/templates" ]; then
        cp -r "$repo_root/templates" "$lib_dest/"
        chmod -R 755 "$lib_dest/templates"/*.sh 2>/dev/null || true
        print_success "Installed templates to $lib_dest"
    fi
    
    # Verify installation
    if [ -f "$dest" ] && [ -d "$lib_dest" ]; then
        print_success "System-wide installation verified"
        echo "✓ Installed to $dest (available to all users)"
        return 0
    else
        print_error "Installation verification failed"
        return 1
    fi
}

install_locally() {
    local repo_root="$1"
    local src="$repo_root/tools/dirforge"
    local bin_dir="$HOME/bin"
    local lib_dir="$HOME/.local/lib/dirforge"
    local dest="$bin_dir/dirforge"
    
    echo "Installing locally to $dest..."
    mkdir -p "$bin_dir" "$lib_dir"
    
    # Copy main script
    cp "$src" "$dest"
    chmod 755 "$dest"
    
    # Copy libraries
    if [ -d "$repo_root/lib" ]; then
        cp -r "$repo_root/lib"/* "$lib_dir/"
        chmod 755 "$lib_dir"/*.sh
        print_success "Installed libraries to $lib_dir"
    fi
    
    # Copy templates
    if [ -d "$repo_root/templates" ]; then
        cp -r "$repo_root/templates" "$lib_dir/"
        chmod -R 755 "$lib_dir/templates"/*.sh 2>/dev/null || true
        print_success "Installed templates to $lib_dir"
    fi
    
    # Verify installation
    if [ -f "$dest" ] && [ -d "$lib_dir" ]; then
        print_success "Local installation verified"
        echo "✓ Installed to $dest"
    else
        print_error "Installation verification failed"
        return 1
    fi
    
    # Check PATH
    if ! printf '%s\n' "$PATH" | tr ':' '\n' | grep -xq "$bin_dir"; then
        echo
        print_warning "$bin_dir is not in your PATH"
        echo
        echo "Add to your shell configuration:"
        if [ -n "${ZSH_VERSION:-}" ]; then
            echo "  echo 'export PATH=\"\$HOME/bin:\$PATH\"' >> ~/.zshrc && source ~/.zshrc"
        elif [ -n "${BASH_VERSION:-}" ]; then
            echo "  echo 'export PATH=\"\$HOME/bin:\$PATH\"' >> ~/.bashrc && source ~/.bashrc"
        else
            echo "  export PATH=\"\$HOME/bin:\$PATH\""
        fi
        echo
    fi
    
    return 0
}

# ============================================================================
# INTERACTIVE WIZARD MODE
# ============================================================================

run_wizard() {
    local repo_root="$1"
    
    # Clear and show header
    clear
    print_header
    
    echo -e "${CYAN}Welcome to the DirForge Installation Wizard!${NC}"
    echo
    echo "This wizard will guide you through installing DirForge, a tool for"
    echo "creating standardized directory structures per the DirForge Constitution."
    echo

    if ! confirm "Continue with installation?" "y"; then
        echo "Installation cancelled."
        return 1
    fi

    echo
    print_step "1/5" "System Detection"
    
    # Detect shell
    local shell_type="bash"
    local shell_rc=""
    
    if [[ -f ~/.zshrc ]]; then
        shell_type="zsh"
        shell_rc="$HOME/.zshrc"
    elif [[ -f ~/.bashrc ]]; then
        shell_type="bash"
        shell_rc="$HOME/.bashrc"
    elif [[ -f ~/.config/fish/config.fish ]]; then
        shell_type="fish"
        shell_rc="$HOME/.config/fish/config.fish"
    fi
    
    print_success "Shell detected: $shell_type"
    [[ -n "$shell_rc" ]] && print_success "Shell config: $shell_rc"

    echo
    print_step "2/5" "Installation Mode"
    
    echo "Choose installation mode:"
    echo "  1) Local (recommended) - ~/bin, no sudo needed"
    echo "  2) System-wide - /usr/local/bin, requires sudo"
    echo
    
    local choice=""
    while [[ ! "$choice" =~ ^[12]$ ]]; do
        echo -n "Enter choice [1-2]: "
        read -r choice
        case "$choice" in
            1) echo ;;
            2) echo ;;
            *) print_error "Invalid choice. Please enter 1 or 2." ;;
        esac
    done
    
    local install_mode="local"
    [[ "$choice" == "2" ]] && install_mode="system"
    
    if [ "$install_mode" = "system" ] && ! is_root; then
        print_warning "System installation requires sudo"
        if ! confirm "Continue anyway?" "y"; then
            print_info "Falling back to local installation"
            install_mode="local"
        fi
    fi
    
    print_success "Installation mode: $install_mode"

    echo
    print_step "3/5" "Prerequisites Check"
    
    local missing=()
    for cmd in cp chmod mkdir grep; do
        if ! command_exists "$cmd"; then
            missing+=("$cmd")
        fi
    done
    
    if [[ ${#missing[@]} -eq 0 ]]; then
        print_success "All required commands available"
    else
        print_error "Missing: ${missing[*]}"
        return 1
    fi
    
    # Check source
    local src="$repo_root/tools/dirforge"
    if [[ ! -f "$src" ]]; then
        print_error "Cannot find dirforge source at $src"
        return 1
    fi
    print_success "DirForge source found"

    echo
    print_step "4/5" "Installation"
    
    if ! perform_installation "$install_mode" "$repo_root"; then
        print_error "Installation failed"
        return 1
    fi
    
    # Verify help system
    local bin_path=""
    if [[ "$install_mode" == "system" ]]; then
        bin_path="/usr/local/bin/dirforge"
    else
        bin_path="$HOME/bin/dirforge"
    fi
    
    if "$bin_path" --version >/dev/null 2>&1; then
        print_success "Help system verified"
    else
        print_warning "Help system verification failed"
    fi

    echo
    print_step "5/5" "Post-Installation"
    
    if [ "$install_mode" = "local" ] && [[ -n "$shell_rc" ]]; then
        if ! printf '%s\n' "$PATH" | tr ':' '\n' | grep -xq "$HOME/bin"; then
            if confirm "Add ~/bin to PATH in $shell_rc?" "y"; then
                if ! grep -q 'export PATH="$HOME/bin:$PATH"' "$shell_rc" 2>/dev/null; then
                    echo 'export PATH="$HOME/bin:$PATH"' >> "$shell_rc"
                    print_success "Added to $shell_rc"
                fi
            fi
        fi
    fi
    
    if confirm "Run tests to verify installation?" "y"; then
        if cd "$repo_root" && bash tests/run_tests.sh >/dev/null 2>&1; then
            print_success "All tests passed!"
        else
            print_warning "Some tests failed"
        fi
    fi

    echo
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${NC} ${CYAN}                    Installation Complete!${NC} ${GREEN}                                  ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${GREEN}DirForge is ready to use!${NC}"
    echo
    echo "Quick start:"
    echo "  dirforge --help                           Show all commands"
    echo "  dirforge init                             Create complete workspace"
    echo "  dirforge init research --title \"My Project\"   Create research project"
    echo "  dirforge init coding --language python --project mytool"
    echo
    
    if [ "$install_mode" = "local" ]; then
        echo "Restart your shell or run: source $shell_rc"
    fi
    echo
    return 0
}

# ============================================================================
# MAIN ENTRY POINT
# ============================================================================

main() {
    # Get repository root
    local script_dir
    if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
        script_dir="$(dirname "${BASH_SOURCE[0]}")"
    else
        script_dir="$(dirname "$0")"
    fi
    local repo_root="$(cd "$script_dir/.." >/dev/null 2>&1 && pwd)"
    local src="$repo_root/tools/dirforge"
    
    # Validate source
    if [[ ! -f "$src" ]]; then
        echo "ERROR: cannot find $src" >&2
        echo "Run this script from the dirforge repository." >&2
        exit 1
    fi
    
    # Parse arguments
    local install_mode="local"  # default
    local wizard_mode=false
    
    if [ $# -gt 0 ]; then
        case "${1:-}" in
            --wizard|-w)
                wizard_mode=true
                ;;
            --system|-s)
                install_mode="system"
                ;;
            --local|-l)
                install_mode="local"
                ;;
            --help|-h)
                echo "DirForge Installation Script"
                echo
                echo "Usage: $0 [MODE]"
                echo
                echo "Modes:"
                echo "  (none)           Non-interactive local installation (default)"
                echo "  --local, -l      Non-interactive local installation to ~/bin"
                echo "  --system, -s     Non-interactive system installation to /usr/local/bin (requires sudo)"
                echo "  --wizard, -w     Interactive installation wizard"
                echo "  --help, -h       Show this help message"
                echo
                echo "Examples:"
                echo "  $0                    # Install locally without prompts"
                echo "  $0 --wizard           # Run interactive wizard"
                echo "  sudo $0 --system      # Install system-wide"
                echo
                exit 0
                ;;
            *)
                echo "ERROR: Unknown option: $1" >&2
                echo "Use --help for usage information." >&2
                exit 1
                ;;
        esac
    fi
    
    # Run installation
    if [ "$wizard_mode" = true ]; then
        run_wizard "$repo_root"
    else
        print_header
        print_step "Installation" "Starting $([ "$install_mode" = "system" ] && echo "system-wide" || echo "local") installation..."
        echo
        if perform_installation "$install_mode" "$repo_root"; then
            echo
            echo "Installation complete! Run: dirforge --help"
        else
            exit 1
        fi
    fi
}

main "$@"

