#!/usr/bin/env bash
set -euo pipefail

# dirforge_install_wizard.sh
# Interactive installation wizard for dirforge
# Provides user-friendly installation with options and validation

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
    # Terminal supports colors and cursor control
    HAS_COLORS=true
    COLS=$(tput cols 2>/dev/null || echo 80)
else
    HAS_COLORS=false
    COLS=80
fi

# Utility functions
print_header() {
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC} ${CYAN}                    DirForge Installation Wizard${NC} ${BLUE}                            ║${NC}"
    echo -e "${BLUE}║${NC} ${PURPLE}         Create standardized directory structures per Constitution${NC} ${BLUE}          ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo
}

print_step() {
    local step_num="$1"
    local step_text="$2"
    echo -e "${GREEN}[$step_num/6]${NC} $step_text"
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

center_text() {
    local text="$1"
    local width="$COLS"
    local text_len=${#text}
    local padding=$(( (width - text_len) / 2 ))
    printf "%*s%s\n" $padding "" "$text"
}

# Check if running on macOS
is_macos() {
    [[ "$OSTYPE" == "darwin"* ]]
}

# Check if running as root
is_root() {
    [[ $EUID -eq 0 ]]
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
        response="$default"  # Default if read fails
    fi

    case "$response" in
        [Yy]|[Yy][Ee][Ss]) return 0 ;;
        [Nn]|[Nn][Oo]) return 1 ;;
        *) return 1 ;;
    esac
}

# Detect shell
detect_shell() {
    # Check if we're in zsh or bash directly
    if [[ -n "${ZSH_VERSION:-}" ]]; then
        echo "zsh"
    elif [[ -n "${BASH_VERSION:-}" ]]; then
        echo "bash"
    else
        # Check the parent process shell
        local ppid=$(ps -p $$ -o ppid= 2>/dev/null | tr -d ' ')
        if [[ -n "$ppid" ]]; then
            local parent_shell=$(ps -p "$ppid" -o comm= 2>/dev/null | tr -d ' ')
            if [[ -n "$parent_shell" ]]; then
                basename "$parent_shell"
                return
            fi
        fi
        # Fallback to $SHELL
        basename "${SHELL:-unknown}"
    fi
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Select shell with user choice
select_shell() {
    # Check if running interactively
    if [[ -t 0 ]]; then
        echo "Select your shell:"
        echo "  1) bash"
        echo "  2) zsh"
        echo "  3) fish"
        echo "  4) tcsh"
        echo "  5) ksh"
        echo -n "Enter choice [1-5]: "
        if read -r choice; then
            case "$choice" in
                1) echo "bash" ;;
                2) echo "zsh" ;;
                3) echo "fish" ;;
                4) echo "tcsh" ;;
                5) echo "ksh" ;;
                *) echo "bash" ;;  # Default to bash if invalid
            esac
        else
            echo "bash"  # Default if read fails
        fi
    else
        # Non-interactive, default to bash
        echo "bash"
    fi
}

# Main installation wizard
main() {
    local install_mode=""
    local run_tests=false
    local shell_rc=""

    # Clear screen and show header
    clear
    print_header

    echo -e "${CYAN}Welcome to the DirForge Installation Wizard!${NC}"
    echo
    echo "This wizard will help you install DirForge, a tool for creating"
    echo "standardized directory structures according to the DirForge Constitution."
    echo
    echo "DirForge enables you to scaffold research projects, lecture materials,"
    echo "coding workspaces, and more with consistent, organized structures."
    echo

    if ! confirm "Continue with installation?" "y"; then
        echo
        echo "Installation cancelled. Goodbye!"
        exit 0
    fi

    echo
    print_step 1 "System Detection"

    # Detect system information
    if is_macos; then
        print_success "macOS detected"
    else
        print_warning "Non-macOS system detected - some features may not work as expected"
    fi

    # Auto-detect shell based on config files
    local shell_type="bash"  # default
    if [[ -f ~/.zshrc ]]; then
        shell_type="zsh"
    elif [[ -f ~/.config/fish/config.fish ]]; then
        shell_type="fish"
    elif [[ -f ~/.tcshrc ]] || [[ -f ~/.cshrc ]]; then
        shell_type="tcsh"
    elif [[ -f ~/.kshrc ]]; then
        shell_type="ksh"
    fi
    print_success "Shell detected: $shell_type"

    # Determine shell RC file
    case "$shell_type" in
        bash)
            if [[ -f ~/.bashrc ]]; then
                shell_rc="$HOME/.bashrc"
            elif [[ -f ~/.bash_profile ]]; then
                shell_rc="$HOME/.bash_profile"
            fi
            ;;
        zsh)
            shell_rc="$HOME/.zshrc"
            ;;
        fish)
            shell_rc="$HOME/.config/fish/config.fish"
            ;;
        tcsh)
            if [[ -f ~/.tcshrc ]]; then
                shell_rc="$HOME/.tcshrc"
            elif [[ -f ~/.cshrc ]]; then
                shell_rc="$HOME/.cshrc"
            fi
            ;;
        ksh)
            shell_rc="$HOME/.kshrc"
            ;;
    esac

    if [[ -n "$shell_rc" ]]; then
        print_success "Shell configuration file: $shell_rc"
    else
        print_warning "Could not determine shell configuration file"
    fi

    echo
    print_step 2 "Installation Mode Selection"

    echo "Choose installation mode:"
    echo "  1) Local (recommended) - Install to ~/bin (no sudo required)"
    echo "     • Available only to your user account"
    echo "     • No administrator privileges needed"
    echo "     • Can be easily removed"
    echo
    echo "  2) System-wide - Install to /usr/local/bin (requires sudo)"
    echo "     • Available to all users on this system"
    echo "     • Requires administrator privileges"
    echo "     • More complex to remove"
    echo

    local choice=""
    while [[ ! "$choice" =~ ^[12]$ ]]; do
        echo -n "Enter your choice [1-2]: "
        read -r choice
        case "$choice" in
            1) install_mode="local" ;;
            2) install_mode="system" ;;
            *) print_error "Invalid choice. Please enter 1 or 2." ;;
        esac
    done

    if [[ "$install_mode" == "system" ]]; then
        if is_root; then
            print_success "System-wide installation selected (running as root)"
        else
            print_warning "System-wide installation requires sudo privileges"
            echo
            if ! confirm "Do you have sudo access and want to continue?" "y"; then
                echo "Falling back to local installation..."
                install_mode="local"
            fi
        fi
    else
        print_success "Local installation selected"
    fi

    echo
    print_step 3 "Prerequisites Check"

    local missing_deps=()

    # Check for required commands
    for cmd in cp chmod mkdir grep tr; do
        if ! command_exists "$cmd"; then
            missing_deps+=("$cmd")
        fi
    done

    if [[ ${#missing_deps[@]} -eq 0 ]]; then
        print_success "All required system commands available"
    else
        print_error "Missing required commands: ${missing_deps[*]}"
        echo "Please install the missing commands and try again."
        exit 1
    fi

    # Check if dirforge source exists
    local script_dir
    if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
        script_dir="$(dirname "${BASH_SOURCE[0]}")"
    else
        script_dir="$(dirname "$0")"
    fi
    local repo_root="$(cd "$script_dir/.." >/dev/null 2>&1 && pwd)"
    local src="$repo_root/tools/dirforge"

    if [[ ! -f "$src" ]]; then
        print_error "Cannot find dirforge source at $src"
        echo "Please run this script from the dirforge repository."
        exit 1
    fi

    print_success "DirForge source found"

    echo
    print_step 4 "Installation Options"

    if confirm "Run tests after installation to verify everything works?" "y"; then
        run_tests=true
        print_success "Tests will be run after installation"
    else
        print_info "Tests will be skipped"
    fi

    echo
    print_step 5 "Installation"

    # Perform the actual installation
    local install_cmd=("$repo_root/scripts/install_dirforge.sh")

    if [[ "$install_mode" == "system" ]]; then
        install_cmd=("sudo" "${install_cmd[@]}")
    fi

    install_cmd+=("--$install_mode")

    echo "Running installation command..."
    echo "Command: ${install_cmd[*]}"
    echo

    if "${install_cmd[@]}"; then
        print_success "Installation completed successfully!"
    else
        print_error "Installation failed!"
        exit 1
    fi

    echo
    print_step 6 "Post-Installation Setup"

    # Check PATH
    local bin_dir=""
    if [[ "$install_mode" == "system" ]]; then
        bin_dir="/usr/local/bin"
    else
        bin_dir="$HOME/bin"
    fi

    if ! echo "$PATH" | tr ':' '\n' | grep -qx "$bin_dir"; then
        print_warning "$bin_dir is not in your PATH"
        echo
        echo "To add it to your PATH, add this line to your shell configuration:"
        echo "  export PATH=\"$bin_dir:\$PATH\""
        echo

        if [[ -n "$shell_rc" ]] && confirm "Add this to your $shell_rc automatically?" "y"; then
            if ! grep -q "export PATH=\"$bin_dir:\$PATH\"" "$shell_rc" 2>/dev/null; then
                echo "export PATH=\"$bin_dir:\$PATH\"" >> "$shell_rc"
                print_success "Added to $shell_rc"
                echo "Please restart your shell or run: source $shell_rc"
            else
                print_info "PATH export already exists in $shell_rc"
            fi
        fi
    else
        print_success "PATH is correctly configured"
    fi

    # Run tests if requested
    if [[ "$run_tests" == true ]]; then
        echo
        print_info "Running tests to verify installation..."
        if cd "$repo_root" && bash tests/run_tests.sh >/dev/null 2>&1; then
            print_success "All tests passed!"
        else
            print_warning "Some tests failed - you may want to check the installation"
        fi
    fi

    echo
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${NC} ${CYAN}                        Installation Complete!${NC} ${GREEN}                              ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${GREEN}DirForge has been successfully installed!${NC}"
    echo
    echo "You can now use dirforge to create standardized directory structures:"
    echo
    echo "  dirforge --help                    # Show help and available commands"
    echo "  dirforge init                      # Create a complete workspace"
    echo "  dirforge init research --title \"My Project\"    # Create a research project"
    echo "  dirforge init research --project my_project --study \"Study Name\"  # Add a study"
    echo
    echo "For more information, visit the documentation or run: dirforge --help"
    echo
    echo "If you encounter any issues, you can uninstall with:"
    echo "  $repo_root/scripts/uninstall_dirforge.sh"
    echo

    if [[ "$run_tests" == false ]]; then
        echo "Tip: You can verify your installation by running: bash tests/run_tests.sh"
    fi
}

# Run main function
main "$@"