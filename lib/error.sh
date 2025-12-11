#!/usr/bin/env bash
# error.sh - Error handling and user-friendly error messages
# Part of the Enhanced Error System for dirforge

set -euo pipefail

# Source required libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/colors.sh"

# Initialize colors on library load
init_colors

# Generic error message with context
# Usage: show_error_with_context "Error message" "user_input" "examples" "help_command"
show_error_with_context() {
    local error_msg="$1"
    local user_input="$2"
    local examples="$3"
    local help_cmd="$4"
    
    echo "$error_msg" >&2
    echo "" >&2
    echo "Users input:" >&2
    echo "  $user_input" >&2
    echo "" >&2
    echo "$examples" >&2
    echo "" >&2
    echo "For more help: $help_cmd" >&2
}

# Show coding project error with language-specific examples
# Usage: show_coding_missing_args_error "language" "project" "user_flags"
show_coding_missing_args_error() {
    local language="$1"
    local project="$2"
    local skip_conda="$3"
    local skip_git="$4"
    local py_ver="$5"
    local prog_name="$6"
    
    # Build user input string
    local user_input="$prog_name init coding"
    local missing_args=""
    
    if [ -n "$language" ]; then
        user_input="$user_input --language $language"
    else
        missing_args="$missing_args --language <lang>"
    fi
    
    if [ -n "$project" ]; then
        user_input="$user_input --project \"$project\""
    else
        missing_args="$missing_args --project \"<project_name>\""
    fi
    
    # Add other provided options to the user input
    if [ "$skip_conda" = true ]; then
        user_input="$user_input --no-conda"
    fi
    if [ "$skip_git" = true ]; then
        user_input="$user_input --no-git"
    fi
    if [ "$py_ver" != "3.11" ]; then
        user_input="$user_input --python $py_ver"
    fi
    
    echo "Error: Missing required arguments$missing_args" >&2
    echo "" >&2
    echo "Users input:" >&2
    echo "  $user_input" >&2
    echo "" >&2
    
    # Show examples based on what was provided
    if [ -n "$language" ]; then
        # Language specified, show language-specific examples
        case "$language" in
            python)
                echo "Python project examples:" >&2
                echo "  $prog_name init coding --language python --project \"data_analysis_tool\" --python 3.12" >&2
                echo "  $prog_name init coding --language python --project \"ml_pipeline\" --no-conda" >&2
                ;;
            matlab)
                echo "MATLAB project examples:" >&2
                echo "  $prog_name init coding --language matlab --project \"signal_processing\" --preview" >&2
                echo "  $prog_name init coding --language matlab --project \"finite_element_solver\" --no-git" >&2
                ;;
            fortran)
                echo "Fortran project examples:" >&2
                echo "  $prog_name init coding --language fortran --project \"numerical_solver\" --python 3.11" >&2
                echo "  $prog_name init coding --language fortran --project \"physics_simulation\" --no-conda" >&2
                ;;
            bash)
                echo "Bash project examples:" >&2
                echo "  $prog_name init coding --language bash --project \"backup_script\" --preview" >&2
                echo "  $prog_name init coding --language bash --project \"automation_tool\" --no-git" >&2
                ;;
        esac
    elif [ "$py_ver" != "3.11" ]; then
        # Python version specified, show Python examples
        echo "Python project example:" >&2
        echo "  $prog_name init coding --language python --project \"data_analysis_tool\" --python $py_ver" >&2
        echo "" >&2
        echo "Supported languages: python, matlab, fortran, bash" >&2
    else
        # No language specified, show one example per language
        echo "Language examples:" >&2
        echo "  $prog_name init coding --language python --project \"data_analysis_tool\" --python 3.12" >&2
        echo "  $prog_name init coding --language matlab --project \"signal_processing\" --preview" >&2
        echo "  $prog_name init coding --language fortran --project \"numerical_solver\" --python 3.11" >&2
        echo "  $prog_name init coding --language bash --project \"backup_script\" --preview" >&2
        echo "" >&2
        echo "Supported languages: python, matlab, fortran, bash" >&2
    fi
    
    echo "" >&2
    echo "For more help: $prog_name init coding --help" >&2
}

# Show unsupported language error
# Usage: show_unsupported_language_error "language" "prog_name"
show_unsupported_language_error() {
    local language="$1"
    local prog_name="$2"
    
    echo "Error: Unsupported language '$language'" >&2
    echo "Supported languages: python, matlab, fortran, bash" >&2
    echo "For help: $prog_name init coding --help" >&2
}

# Show template not found error
# Usage: show_template_not_found_error "template_file"
show_template_not_found_error() {
    local template_file="$1"
    
    echo "ERROR: template not found: $template_file" >&2
}

# Show research project/study error
# Usage: show_research_missing_args_error "prog_name"
show_research_missing_args_error() {
    local prog_name="$1"
    
    echo "Error: Either --title (for new project) or --project and --study (for new study) must be specified" >&2
    echo "" >&2
    echo "Examples:" >&2
    echo "  # Create new project:" >&2
    echo "  $prog_name init research --title \"Thermal Analysis\"" >&2
    echo "" >&2
    echo "  # Add study to existing project:" >&2
    echo "  $prog_name init research --project \"2025_thermal_analysis\" --study \"Initial Model\"" >&2
    echo "" >&2
    echo "For more help: $prog_name init research --help" >&2
}

# Show research project not found error
# Usage: show_project_not_found_error "project_id" "project_root"
show_project_not_found_error() {
    local project_id="$1"
    local project_root="$2"
    
    echo "Error: Project '$project_id' does not exist at $project_root" >&2
    echo "" >&2
    echo "To create this project first, run:" >&2
    echo "  dirforge init research --title \"Project Title\"" >&2
}

# Show generic required argument error
# Usage: show_required_arg_error "arg_name" "prog_name" "command"
show_required_arg_error() {
    local arg_name="$1"
    local prog_name="$2"
    local command="$3"
    
    echo "Error: $arg_name is required" >&2
    echo "For help: $prog_name init $command --help" >&2
}

# Show project already exists error
# Usage: show_project_exists_error "project_id" "project_path"
show_project_exists_error() {
    local project_id="$1"
    local project_path="$2"
    
    echo "Project '$project_id' already exists at $project_path" >&2
    echo "Use --force to overwrite or --backup to create a backup before overwriting" >&2
}

# Show JSON requires dry-run error
# Usage: show_json_requires_dryrun_error
show_json_requires_dryrun_error() {
    echo "ERROR: --json requires --dry-run" >&2
}

# Show unknown argument error
# Usage: show_unknown_arg_error "arg" "context"
show_unknown_arg_error() {
    local arg="$1"
    local context="${2:-}"
    
    if [ -n "$context" ]; then
        echo "Unknown arg for $context: $arg" >&2
    else
        echo "Unknown arg: $arg" >&2
    fi
}
