#!/usr/bin/env bash
# config_error.sh - Error handling and reporting utilities for configuration system
# Part of the YAML-Driven World Configuration System (Constitution v1.1.0, Section IV.B)

set -euo pipefail

# Source required libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/colors.sh"

# Initialize colors on library load
init_colors

# ============================================================================
# Error Code Constants
# ============================================================================

# Configuration system error codes
readonly ERR_CONFIG_NOT_FOUND=101
readonly ERR_INVALID_YAML=102
readonly ERR_SCHEMA_VALIDATION=103
readonly ERR_FIELD_NOT_FOUND=104
readonly ERR_FIELD_TYPE_MISMATCH=105
readonly ERR_INVALID_FOLDER_NAME=106
readonly ERR_DUPLICATE_FOLDER=107
readonly ERR_MISSING_REQUIRED_FIELD=108
readonly ERR_YAML_PARSE_ERROR=109
readonly ERR_PARSER_NOT_AVAILABLE=110

# Transaction error codes
readonly ERR_TRANSACTION_FAILED=201
readonly ERR_ROLLBACK_FAILED=202
readonly ERR_PERMISSION_DENIED=203
readonly ERR_INVALID_PERMISSIONS=204

# ============================================================================
# Error Tracking
# ============================================================================

# Global error tracking (bash 3.2 compatible - no declare -g)
CONFIG_ERROR_COUNT=0
CONFIG_LAST_ERROR=""
CONFIG_ERROR_STACK=()

# Track which configuration file is being processed (for context)
CURRENT_CONFIG_FILE=""
CURRENT_CONFIG_FIELD=""

# ============================================================================
# Core Error Reporting Functions
# ============================================================================

# report_error() - Report a general error with context
# Usage: report_error <error_code> <error_message> [context...]
# Exit Code: Returns the error code provided
report_error() {
    local error_code="$1"
    local error_msg="$2"
    shift 2
    local context=("$@")
    
    ((CONFIG_ERROR_COUNT++))
    CONFIG_LAST_ERROR="$error_msg"
    CONFIG_ERROR_STACK+=("[$error_code] $error_msg")
    
    echo "${COLOR_RED}ERROR [${error_code}]:${COLOR_RESET} $error_msg" >&2
    
    if [[ -n "$CURRENT_CONFIG_FILE" ]]; then
        echo "  ${COLOR_DIM}Config:${COLOR_RESET} $CURRENT_CONFIG_FILE" >&2
    fi
    
    if [[ -n "$CURRENT_CONFIG_FIELD" ]]; then
        echo "  ${COLOR_DIM}Field:${COLOR_RESET} $CURRENT_CONFIG_FIELD" >&2
    fi
    
    # Print additional context
    for item in "${context[@]}"; do
        echo "  ${COLOR_DIM}$item${COLOR_RESET}" >&2
    done
    
    echo "" >&2
    
    return "$error_code"
}

# report_warning() - Report a non-fatal warning
# Usage: report_warning <warning_message> [context...]
report_warning() {
    local warning_msg="$1"
    shift
    local context=("$@")
    
    echo "${COLOR_YELLOW}WARNING:${COLOR_RESET} $warning_msg" >&2
    
    for item in "${context[@]}"; do
        echo "  ${COLOR_DIM}$item${COLOR_RESET}" >&2
    done
    
    echo "" >&2
}

# report_info() - Report informational message
# Usage: report_info <info_message>
report_info() {
    local info_msg="$1"
    
    echo "${COLOR_BLUE}INFO:${COLOR_RESET} $info_msg" >&2
}

# ============================================================================
# Configuration-Specific Error Reporters
# ============================================================================

# report_config_not_found() - Report that a config file was not found
# Usage: report_config_not_found <config_name> [search_paths]
# Exit Code: Returns ERR_CONFIG_NOT_FOUND (101)
report_config_not_found() {
    local config_name="$1"
    shift
    local search_paths=("$@")
    
    local context=("Searched paths:")
    for path in "${search_paths[@]}"; do
        context+=("  - $path")
    done
    
    report_error "$ERR_CONFIG_NOT_FOUND" "Configuration file not found: '$config_name'" "${context[@]}"
}

# report_invalid_yaml() - Report YAML parsing error
# Usage: report_invalid_yaml <config_file> <line_number> <error_details>
# Exit Code: Returns ERR_INVALID_YAML (102)
report_invalid_yaml() {
    local config_file="$1"
    local line_number="${2:-unknown}"
    local error_details="${3:-syntax error}"
    
    CURRENT_CONFIG_FILE="$config_file"
    
    local context=("Line: $line_number" "Details: $error_details")
    
    report_error "$ERR_INVALID_YAML" "Invalid YAML syntax" "${context[@]}"
}

# report_schema_error() - Report schema validation error
# Usage: report_schema_error <field_path> <expected> <actual>
# Exit Code: Returns ERR_SCHEMA_VALIDATION (103)
report_schema_error() {
    local field_path="$1"
    local expected="${2:-unknown}"
    local actual="${3:-unknown}"
    
    CURRENT_CONFIG_FIELD="$field_path"
    
    local context=("Expected: $expected" "Actual: $actual")
    
    report_error "$ERR_SCHEMA_VALIDATION" "Schema validation failed for '$field_path'" "${context[@]}"
}

# report_field_not_found() - Report that a required field is missing
# Usage: report_field_not_found <field_path>
# Exit Code: Returns ERR_MISSING_REQUIRED_FIELD (108)
report_field_not_found() {
    local field_path="$1"
    
    CURRENT_CONFIG_FIELD="$field_path"
    
    report_error "$ERR_MISSING_REQUIRED_FIELD" "Required field not found: '$field_path'"
}

# report_field_type_mismatch() - Report field type mismatch
# Usage: report_field_type_mismatch <field_path> <expected_type> <actual_type>
# Exit Code: Returns ERR_FIELD_TYPE_MISMATCH (105)
report_field_type_mismatch() {
    local field_path="$1"
    local expected_type="$2"
    local actual_type="$3"
    
    CURRENT_CONFIG_FIELD="$field_path"
    
    local context=("Expected type: $expected_type" "Actual type: $actual_type")
    
    report_error "$ERR_FIELD_TYPE_MISMATCH" "Type mismatch in '$field_path'" "${context[@]}"
}

# report_invalid_folder_name() - Report invalid folder name
# Usage: report_invalid_folder_name <folder_name> [reason]
# Exit Code: Returns ERR_INVALID_FOLDER_NAME (106)
report_invalid_folder_name() {
    local folder_name="$1"
    local reason="${2:-Invalid characters in folder name}"
    
    local context=("Folder: $folder_name" "Reason: $reason")
    
    report_error "$ERR_INVALID_FOLDER_NAME" "Invalid folder name" "${context[@]}"
}

# report_duplicate_folder() - Report duplicate folder name
# Usage: report_duplicate_folder <folder_name> [locations]
# Exit Code: Returns ERR_DUPLICATE_FOLDER (107)
report_duplicate_folder() {
    local folder_name="$1"
    shift
    local locations=("$@")
    
    local context=("Duplicate folder: $folder_name")
    
    if [[ ${#locations[@]} -gt 0 ]]; then
        context+=("Found in:")
        for loc in "${locations[@]}"; do
            context+=("  - $loc")
        done
    fi
    
    report_error "$ERR_DUPLICATE_FOLDER" "Duplicate folder name: '$folder_name'" "${context[@]}"
}

# report_parser_not_available() - Report YAML parser not available
# Usage: report_parser_not_available [alternative_suggestions]
# Exit Code: Returns ERR_PARSER_NOT_AVAILABLE (110)
report_parser_not_available() {
    local suggestions="${1:-Install yq or ensure Python 3 with PyYAML is available}"
    
    local context=("Suggestion: $suggestions")
    
    report_error "$ERR_PARSER_NOT_AVAILABLE" "No YAML parser available" "${context[@]}"
}

# ============================================================================
# Transaction Error Reporters
# ============================================================================

# report_transaction_error() - Report transaction failure
# Usage: report_transaction_error <transaction_id> <error_message> [context]
# Exit Code: Returns ERR_TRANSACTION_FAILED (201)
report_transaction_error() {
    local transaction_id="$1"
    local error_msg="$2"
    local context="${3:-}"
    
    local ctx_arr=("Transaction ID: $transaction_id")
    if [[ -n "$context" ]]; then
        ctx_arr+=("Context: $context")
    fi
    
    report_error "$ERR_TRANSACTION_FAILED" "Transaction failed: $error_msg" "${ctx_arr[@]}"
}

# report_rollback_failed() - Report rollback failure
# Usage: report_rollback_failed <transaction_id> <rollback_error>
# Exit Code: Returns ERR_ROLLBACK_FAILED (202)
report_rollback_failed() {
    local transaction_id="$1"
    local rollback_error="$2"
    
    local context=("Transaction ID: $transaction_id" "Rollback failed: $rollback_error")
    
    report_error "$ERR_ROLLBACK_FAILED" "Failed to rollback transaction" "${context[@]}"
}

# report_permission_denied() - Report permission error
# Usage: report_permission_denied <resource_path> [required_permission]
# Exit Code: Returns ERR_PERMISSION_DENIED (203)
report_permission_denied() {
    local resource_path="$1"
    local required_perm="${2:-}"
    
    local context=("Resource: $resource_path")
    if [[ -n "$required_perm" ]]; then
        context+=("Required: $required_perm")
    fi
    
    report_error "$ERR_PERMISSION_DENIED" "Permission denied" "${context[@]}"
}

# report_invalid_permissions() - Report invalid permission specification
# Usage: report_invalid_permissions <permission_spec> [reason]
# Exit Code: Returns ERR_INVALID_PERMISSIONS (204)
report_invalid_permissions() {
    local perm_spec="$1"
    local reason="${2:-Invalid format}"
    
    local context=("Permission: $perm_spec" "Reason: $reason")
    
    report_error "$ERR_INVALID_PERMISSIONS" "Invalid permission specification" "${context[@]}"
}

# ============================================================================
# Error Context and Stack Management
# ============================================================================

# set_config_context() - Set the current configuration context
# Usage: set_config_context <config_file> [field_path]
set_config_context() {
    CURRENT_CONFIG_FILE="$1"
    CURRENT_CONFIG_FIELD="${2:-}"
}

# clear_config_context() - Clear the current configuration context
clear_config_context() {
    CURRENT_CONFIG_FILE=""
    CURRENT_CONFIG_FIELD=""
}

# push_error() - Push an error onto the error stack
# Usage: push_error <error_message>
push_error() {
    local error_msg="$1"
    CONFIG_ERROR_STACK+=("$error_msg")
}

# pop_error() - Pop the most recent error from the stack
# Usage: pop_error
# Returns: The popped error message
pop_error() {
    if [[ ${#CONFIG_ERROR_STACK[@]} -gt 0 ]]; then
        local last_error="${CONFIG_ERROR_STACK[-1]}"
        unset 'CONFIG_ERROR_STACK[-1]'
        echo "$last_error"
    fi
}

# get_error_stack() - Get the entire error stack
# Usage: get_error_stack
# Returns: All errors, one per line
get_error_stack() {
    printf '%s\n' "${CONFIG_ERROR_STACK[@]}"
}

# clear_error_stack() - Clear the error stack
clear_error_stack() {
    CONFIG_ERROR_STACK=()
    CONFIG_ERROR_COUNT=0
    CONFIG_LAST_ERROR=""
}

# print_error_summary() - Print a summary of all errors
print_error_summary() {
    if [[ $CONFIG_ERROR_COUNT -eq 0 ]]; then
        echo "${COLOR_GREEN}✓ No errors${COLOR_RESET}" >&2
        return 0
    fi
    
    echo "${COLOR_RED}Error Summary:${COLOR_RESET}" >&2
    echo "  Total errors: $CONFIG_ERROR_COUNT" >&2
    echo "  Last error: $CONFIG_LAST_ERROR" >&2
    
    if [[ ${#CONFIG_ERROR_STACK[@]} -gt 0 ]]; then
        echo "  Error stack:" >&2
        local count=0
        for error in "${CONFIG_ERROR_STACK[@]}"; do
            ((count++))
            echo "    $count. $error" >&2
        done
    fi
    
    echo "" >&2
}

# ============================================================================
# Error Handling Utilities
# ============================================================================

# handle_error_with_recovery() - Handle error with optional recovery action
# Usage: handle_error_with_recovery <error_code> <error_message> <recovery_command>
# Exit Code: Returns error code if recovery fails, 0 if recovery succeeds
handle_error_with_recovery() {
    local error_code="$1"
    local error_msg="$2"
    local recovery_cmd="$3"
    
    report_error "$error_code" "$error_msg" "Attempting recovery..."
    
    if eval "$recovery_cmd" 2>/dev/null; then
        report_info "Recovery succeeded"
        return 0
    else
        report_error "$error_code" "Recovery failed: $error_msg"
        return "$error_code"
    fi
}

# assert_field_exists() - Assert that a field exists, fail if not
# Usage: assert_field_exists <config_file> <field_path>
# Exit Code: 0 if exists, error code if not
assert_field_exists() {
    local config_file="$1"
    local field_path="$2"
    
    # This requires yaml_utils to be sourced
    if ! yaml_has_field "$config_file" "$field_path" 2>/dev/null; then
        report_field_not_found "$field_path"
        return "$ERR_MISSING_REQUIRED_FIELD"
    fi
    
    return 0
}

# ============================================================================
# YAML-Specific Error Handling
# ============================================================================

# handle_yaml_error() - Handle and report YAML parsing errors
# Usage: handle_yaml_error <error_message> <yaml_file> [line_number] [field_path]
# Exit Code: Returns ERR_YAML_PARSE_ERROR (109)
handle_yaml_error() {
    local error_msg="$1"
    local yaml_file="$2"
    local line_number="${3:-0}"
    local field_path="${4:-}"
    
    CURRENT_CONFIG_FILE="$yaml_file"
    CURRENT_CONFIG_FIELD="$field_path"
    
    echo "${COLOR_RED}YAML Parse Error:${COLOR_RESET}" >&2
    echo "  Message: $error_msg" >&2
    echo "  File: $yaml_file" >&2
    
    if [[ $line_number -gt 0 ]]; then
        echo "  Line: $line_number" >&2
    fi
    
    if [[ -n "$field_path" ]]; then
        echo "  Field: $field_path" >&2
    fi
    
    # Show file context if file exists
    if [[ -f "$yaml_file" ]] && [[ $line_number -gt 0 ]]; then
        echo "" >&2
        echo "${COLOR_YELLOW}Context:${COLOR_RESET}" >&2
        
        # Calculate context window (2 lines before and after)
        local start_line=$((line_number - 2))
        if [[ $start_line -lt 1 ]]; then
            start_line=1
        fi
        
        local end_line=$((line_number + 2))
        
        # Show context with line numbers
        sed -n "${start_line},${end_line}p" "$yaml_file" | nl -v "$start_line" -s ': ' | sed 's/^/  /' >&2
    fi
    
    echo "" >&2
    
    return "$ERR_YAML_PARSE_ERROR"
}

# ============================================================================
# Error Code Translation
# ============================================================================

# get_error_description() - Get human-readable description for error code
# Usage: get_error_description <error_code>
# Returns: Description string
get_error_description() {
    local error_code="$1"
    
    case "$error_code" in
        101) echo "Configuration file not found" ;;
        102) echo "Invalid YAML syntax" ;;
        103) echo "Schema validation failed" ;;
        104) echo "Field not found" ;;
        105) echo "Field type mismatch" ;;
        106) echo "Invalid folder name" ;;
        107) echo "Duplicate folder name" ;;
        108) echo "Missing required field" ;;
        109) echo "YAML parse error" ;;
        110) echo "YAML parser not available" ;;
        201) echo "Transaction failed" ;;
        202) echo "Rollback failed" ;;
        203) echo "Permission denied" ;;
        204) echo "Invalid permission specification" ;;
        *) echo "Unknown error" ;;
    esac
}

# is_recoverable_error() - Determine if error is recoverable
# Usage: is_recoverable_error <error_code>
# Exit Code: 0 if recoverable, 1 if not
is_recoverable_error() {
    local error_code="$1"
    
    # These errors might be recoverable
    case "$error_code" in
        101|104|110) return 0 ;;  # Config not found, field not found, parser not found
        *) return 1 ;;
    esac
}

# ============================================================================
# Detailed Error Reports
# ============================================================================

# print_detailed_error_report() - Print detailed error diagnostics
# Usage: print_detailed_error_report <error_code> [config_file]
print_detailed_error_report() {
    local error_code="$1"
    local config_file="${2:-}"
    
    echo "${COLOR_RED}=== DETAILED ERROR REPORT ===${COLOR_RESET}" >&2
    echo "Error Code: $error_code" >&2
    echo "Description: $(get_error_description "$error_code")" >&2
    echo "Recoverable: $(is_recoverable_error "$error_code" && echo "Yes" || echo "No")" >&2
    
    if [[ -n "$config_file" ]] && [[ -f "$config_file" ]]; then
        echo "" >&2
        echo "File Information:" >&2
        echo "  Path: $config_file" >&2
        echo "  Size: $(stat -f%z "$config_file" 2>/dev/null || stat -c%s "$config_file") bytes" >&2
        echo "  Modified: $(stat -f%Sm -t '%Y-%m-%d %H:%M:%S' "$config_file" 2>/dev/null || stat -c%y "$config_file" | cut -d' ' -f1-2)" >&2
    fi
    
    echo "" >&2
    echo "Error Stack:" >&2
    get_error_stack | nl -v 1 -s '. ' | sed 's/^/  /' >&2
    
    echo "" >&2
    echo "=== END ERROR REPORT ===" >&2
}

# ============================================================================
# Cleanup and Termination
# ============================================================================

# cleanup_on_error() - Cleanup function to run on error
# Usage: cleanup_on_error <exit_code>
cleanup_on_error() {
    local exit_code="${1:-1}"
    
    # Print error summary
    print_error_summary
    
    # Clear context
    clear_config_context
    
    exit "$exit_code"
}

# enable_error_tracing() - Enable detailed error tracing for debugging
enable_error_tracing() {
    set -x
    export PS4='+ [${BASH_SOURCE}:${LINENO}] ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
}

# disable_error_tracing() - Disable error tracing
disable_error_tracing() {
    set +x
}
