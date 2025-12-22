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
    
    echo "Error: Either --name (for new project) or --project and --study (for new study) must be specified" >&2
    echo "" >&2
    echo "Examples:" >&2
    echo "  # Create new project" >&2
    echo "  $prog_name init research --name \"Thermal Analysis\"" >&2
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
    echo "  dirforge init research --name \"Project Name\"" >&2
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

# ============================================================================
# UPDATE COMMAND ERROR HANDLING - T032 Implementation
# ============================================================================

# Show corrupted YAML file error with diagnosis and recovery
# Usage: show_corrupted_yaml_error "file_path" "yaml_error" "json_flag"
show_corrupted_yaml_error() {
    local file_path="$1"
    local yaml_error="$2"
    local json_flag="${3:-false}"
    
    if [[ "$json_flag" == "true" ]]; then
        echo "{\"ok\":false,\"error\":\"Corrupted YAML file: $file_path\",\"details\":\"$yaml_error\"}"
    else
        echo "❌ Error: Corrupted YAML file detected" >&2
        echo "   File: $file_path" >&2
        echo "   Issue: $yaml_error" >&2
        echo "" >&2
        echo "💡 Recovery suggestions:" >&2
        echo "   1. Check file permissions: ls -la \"$file_path\"" >&2
        echo "   2. View file content: cat \"$file_path\"" >&2
        echo "   3. Validate YAML syntax online or with tools like 'yq'" >&2
        echo "   4. Restore from backup if available" >&2
        echo "   5. Use --force flag to skip corrupted metadata (if safe)" >&2
    fi
}

# Show file system permission error with detailed diagnosis
# Usage: show_permission_error "operation" "file_path" "username" "json_flag"
show_permission_error() {
    local operation="$1"
    local file_path="$2"
    local username="$(whoami)"
    local json_flag="${3:-false}"
    
    if [[ "$json_flag" == "true" ]]; then
        echo "{\"ok\":false,\"error\":\"Permission denied\",\"operation\":\"$operation\",\"path\":\"$file_path\"}"
    else
        echo "❌ Error: Permission denied for $operation" >&2
        echo "   Path: $file_path" >&2
        echo "   User: $username" >&2
        echo "" >&2
        
        # Provide context-specific suggestions
        case "$operation" in
            "write")
                echo "💡 Solutions for write permission:" >&2
                echo "   1. Check ownership: ls -la \"$(dirname "$file_path")\"" >&2
                echo "   2. Fix ownership: sudo chown -R $username \"$file_path\"" >&2
                echo "   3. Fix permissions: chmod u+w \"$file_path\"" >&2
                echo "   4. Check parent directory write permission" >&2
                echo "   5. Ensure no immutable attributes: lsattr \"$file_path\" (Linux)" >&2
                ;;
            "read")
                echo "💡 Solutions for read permission:" >&2
                echo "   1. Check file permissions: ls -la \"$file_path\"" >&2
                echo "   2. Fix permissions: chmod u+r \"$file_path\"" >&2
                echo "   3. Check if file is a broken symlink: file \"$file_path\"" >&2
                ;;
            "create")
                echo "💡 Solutions for create permission:" >&2
                echo "   1. Check parent directory permissions: ls -la \"$(dirname "$file_path")\"" >&2
                echo "   2. Fix parent directory: chmod u+w \"$(dirname "$file_path")\"" >&2
                echo "   3. Check disk space: df -h \"$file_path\"" >&2
                ;;
        esac
        
        echo "" >&2
        echo "⚠️  If this is intentional (write-protected files), consider:" >&2
        echo "   • Using --dry-run to preview changes" >&2
        echo "   • Temporarily adjusting permissions for the update" >&2
    fi
}

# Show disk space error with usage information
# Usage: show_disk_space_error "path" "required_mb" "available_mb" "json_flag"
show_disk_space_error() {
    local path="$1"
    local required_mb="$2"
    local available_mb="$3"
    local json_flag="${4:-false}"
    
    if [[ "$json_flag" == "true" ]]; then
        echo "{\"ok\":false,\"error\":\"Insufficient disk space\",\"path\":\"$path\",\"required_mb\":$required_mb,\"available_mb\":$available_mb}"
    else
        echo "❌ Error: Insufficient disk space" >&2
        echo "   Location: $path" >&2
        echo "   Required: ${required_mb}MB" >&2
        echo "   Available: ${available_mb}MB" >&2
        echo "" >&2
        echo "💡 Solutions:" >&2
        echo "   1. Free up space: df -h to check usage" >&2
        echo "   2. Clean temporary files: rm -rf /tmp/*" >&2
        echo "   3. Remove old backups: find . -name '*.backup*' -type d" >&2
        echo "   4. Move to different location with more space" >&2
        echo "   5. Skip backup with update (not recommended): update without --backup" >&2
    fi
}

# Show backup creation error
# Usage: show_backup_error "source_path" "backup_path" "error_msg" "json_flag"
show_backup_error() {
    local source_path="$1"
    local backup_path="$2"
    local error_msg="$3"
    local json_flag="${4:-false}"
    
    if [[ "$json_flag" == "true" ]]; then
        echo "{\"ok\":false,\"error\":\"Backup creation failed\",\"source\":\"$source_path\",\"destination\":\"$backup_path\",\"details\":\"$error_msg\"}"
    else
        echo "❌ Error: Backup creation failed" >&2
        echo "   Source: $source_path" >&2
        echo "   Destination: $backup_path" >&2
        echo "   Details: $error_msg" >&2
        echo "" >&2
        echo "💡 Solutions:" >&2
        echo "   1. Check disk space in destination: df -h \"$(dirname "$backup_path")\"" >&2
        echo "   2. Check write permissions: ls -la \"$(dirname "$backup_path")\"" >&2
        echo "   3. Try different backup location" >&2
        echo "   4. Proceed without backup (use with caution): update without --backup" >&2
    fi
}

# Show directory traversal error
# Usage: show_traversal_error "path" "error_msg" "json_flag"
show_traversal_error() {
    local path="$1"
    local error_msg="$2"
    local json_flag="${3:-false}"
    
    if [[ "$json_flag" == "true" ]]; then
        echo "{\"ok\":false,\"error\":\"Directory traversal failed\",\"path\":\"$path\",\"details\":\"$error_msg\"}"
    else
        echo "❌ Error: Cannot access directory" >&2
        echo "   Path: $path" >&2
        echo "   Issue: $error_msg" >&2
        echo "" >&2
        echo "💡 Possible causes and solutions:" >&2
        echo "   1. Symlink issues: ls -la \"$path\" to check" >&2
        echo "   2. Permission denied: check directory permissions" >&2
        echo "   3. Network mount issues: check mount status" >&2
        echo "   4. Corrupted filesystem: check with fsck (if safe)" >&2
    fi
}

# Show migration step error
# Usage: show_migration_error "step" "version_from" "version_to" "error_msg" "json_flag"
show_migration_error() {
    local step="$1"
    local version_from="$2"
    local version_to="$3"
    local error_msg="$4"
    local json_flag="${5:-false}"
    
    if [[ "$json_flag" == "true" ]]; then
        echo "{\"ok\":false,\"error\":\"Migration step failed\",\"step\":\"$step\",\"from_version\":\"$version_from\",\"to_version\":\"$version_to\",\"details\":\"$error_msg\"}"
    else
        echo "❌ Error: Migration step failed" >&2
        echo "   Step: $step" >&2
        echo "   Version: $version_from → $version_to" >&2
        echo "   Details: $error_msg" >&2
        echo "" >&2
        echo "💡 Recovery options:" >&2
        echo "   1. Check if backup was created and restore if needed" >&2
        echo "   2. Retry with --dry-run to see what went wrong" >&2
        echo "   3. Check file permissions and disk space" >&2
        echo "   4. Report bug with details above if issue persists" >&2
    fi
}

# ============================================================================
# UTILITY FUNCTIONS FOR ERROR DETECTION - T032 Implementation
# ============================================================================

# Check available disk space in MB
# Usage: check_disk_space "path" "required_mb"
# Returns: 0 if sufficient space, 1 if not, 2 if cannot determine
check_disk_space() {
    local path="$1"
    local required_mb="${2:-100}"  # Default 100MB requirement
    
    # Get available space in MB (works on macOS and Linux)
    local available_mb
    if command -v df >/dev/null 2>&1; then
        # Try different df formats
        available_mb=$(df -m "$path" 2>/dev/null | awk 'NR==2 {print $4}' || df "$path" 2>/dev/null | awk 'NR==2 {print int($4/1024)}' || echo "0")
    else
        echo "2"  # Cannot determine
        return 2
    fi
    
    if [[ "$available_mb" -ge "$required_mb" ]]; then
        return 0  # Sufficient space
    else
        echo "$available_mb"  # Return available space for error reporting
        return 1  # Insufficient space
    fi
}

# Validate YAML file syntax
# Usage: validate_yaml_file "file_path"
# Returns: 0 if valid, 1 if invalid, sets $YAML_ERROR with error details
validate_yaml_file() {
    local file_path="$1"
    YAML_ERROR=""  # Global variable for error details
    
    # Check if file exists and is readable
    if [[ ! -f "$file_path" ]]; then
        YAML_ERROR="File does not exist"
        return 1
    fi
    
    if [[ ! -r "$file_path" ]]; then
        YAML_ERROR="File is not readable"
        return 1
    fi
    
    # Check for common YAML issues
    local line_num=1
    local yaml_content
    
    # Read file line by line to catch encoding issues
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Check for non-printable characters (basic validation)
        if [[ "$line" =~ [[:cntrl:]] ]] && [[ ! "$line" =~ ^[[:space:]]*$ ]]; then
            YAML_ERROR="Line $line_num contains non-printable characters"
            return 1
        fi
        
        # Check for common YAML syntax issues
        if [[ "$line" =~ ^[[:space:]]*[^#]*:[[:space:]]*$ ]]; then
            YAML_ERROR="Line $line_num has key without value: ${line// /}"
            return 1
        fi
        
        ((line_num++))
    done < "$file_path" 2>/dev/null || {
        YAML_ERROR="Cannot read file (encoding issue or file corruption)"
        return 1
    }
    
    # Try to parse with basic tools (if available)
    if command -v python3 >/dev/null 2>&1; then
        local python_result
        python_result=$(python3 -c "import yaml; yaml.safe_load(open('$file_path'))" 2>&1) || {
            YAML_ERROR="YAML syntax error: $python_result"
            return 1
        }
    elif command -v yq >/dev/null 2>&1; then
        local yq_result
        yq_result=$(yq eval . "$file_path" 2>&1) >/dev/null || {
            YAML_ERROR="YAML syntax error: $yq_result"
            return 1
        }
    fi
    
    # Basic sanity check: ensure it looks like project.yaml
    if [[ "$(basename "$file_path")" == "project.yaml" ]]; then
        if ! grep -q "^name:" "$file_path" 2>/dev/null; then
            YAML_ERROR="Missing required 'name:' field in project.yaml"
            return 1
        fi
        if ! grep -q "^version:" "$file_path" 2>/dev/null; then
            YAML_ERROR="Missing required 'version:' field in project.yaml"
            return 1
        fi
    fi
    
    return 0  # Valid YAML
}

# Check if path has potential traversal issues
# Usage: check_path_safety "path"
# Returns: 0 if safe, 1 if potentially unsafe
check_path_safety() {
    local path="$1"
    
    # Check for directory traversal patterns
    if [[ "$path" =~ \.\./  ]] || [[ "$path" =~ /\.\.$  ]] || [[ "$path" =~ /\.\./  ]]; then
        return 1  # Potentially unsafe
    fi
    
    # Check for absolute paths outside safe zones (basic check)
    case "$path" in
        /etc/*|/sys/*|/proc/*|/dev/*)
            return 1  # System directories
            ;;
        /*)
            # Allow absolute paths but be cautious
            if [[ "$path" =~ ^/(home|Users)/  ]] || [[ "$path" =~ ^/(tmp|var/tmp)/  ]] || [[ "$path" =~ ^/opt/  ]]; then
                return 0  # Common safe locations
            else
                return 1  # Potentially unsafe absolute path
            fi
            ;;
    esac
    
    return 0  # Seems safe
}

# Test file/directory permissions comprehensively
# Usage: test_permissions "path" "operation"
# Operations: read, write, create, traverse
# Returns: 0 if has permission, 1 if not, 2 if cannot determine
test_permissions() {
    local path="$1"
    local operation="$2"
    
    case "$operation" in
        "read")
            if [[ -f "$path" ]] && [[ -r "$path" ]]; then
                return 0
            elif [[ -d "$path" ]] && [[ -r "$path" ]] && [[ -x "$path" ]]; then
                return 0
            else
                return 1
            fi
            ;;
        "write")
            if [[ -f "$path" ]] && [[ -w "$path" ]]; then
                return 0
            elif [[ -d "$path" ]] && [[ -w "$path" ]]; then
                return 0
            else
                return 1
            fi
            ;;
        "create")
            local parent_dir
            parent_dir=$(dirname "$path")
            if [[ -d "$parent_dir" ]] && [[ -w "$parent_dir" ]]; then
                return 0
            else
                return 1
            fi
            ;;
        "traverse")
            if [[ -d "$path" ]] && [[ -x "$path" ]]; then
                return 0
            else
                return 1
            fi
            ;;
        *)
            return 2  # Unknown operation
            ;;
    esac
}
