#!/usr/bin/env bash
# yaml_utils.sh - YAML parsing and manipulation utilities for DirForge
# Part of the YAML-Driven World Configuration System (Constitution v1.1.0, Section IV.B)

set -euo pipefail

# Source required libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/colors.sh"

# Initialize colors on library load
init_colors

# YAML_PARSER_CMD - Path to yq or fallback YAML parser
# Set this before sourcing if you want to use a different parser
: "${YAML_PARSER_CMD:=yq}"

# ============================================================================
# YAML Parsing Functions
# ============================================================================

# parse_yaml() - Parse a YAML file and extract a field value
# Usage: parse_yaml <yaml_file> <field_path>
# Example: parse_yaml config.yaml "world.type"
# Returns: The value of the specified field (prints to stdout)
# Exit Code: 0 on success, 1 if file not found or field missing
# Notes:
#   - Field paths use dot notation: "world.type", "metadata.version"
#   - Supports nested structures and array access
#   - Returns empty if field is null or missing
parse_yaml() {
    local yaml_file="$1"
    local field_path="$2"
    
    # Validate inputs
    if [[ -z "$yaml_file" || -z "$field_path" ]]; then
        return 1
    fi
    
    if [[ ! -f "$yaml_file" ]]; then
        return 1
    fi
    
    # Use yq if available (preferred - fastest and most reliable)
    if command -v yq >/dev/null 2>&1; then
        # Ensure field_path starts with a dot for yq
        local yq_path="$field_path"
        if [[ "$yq_path" != .* ]]; then
            yq_path=".$yq_path"
        fi
        
        # Use yq to extract the field
        local result
        result=$(yq eval "$yq_path" "$yaml_file" 2>/dev/null)
        
        # Return error if result is "null" or empty
        if [[ -z "$result" || "$result" == "null" ]]; then
            return 1
        fi
        
        echo "$result"
        return 0
    
    # Fallback to Python YAML parser if yq is not available
    elif command -v python3 >/dev/null 2>&1; then
        python3 << PYTHON_EOF 2>/dev/null
import yaml
import sys

try:
    with open('$yaml_file', 'r') as f:
        data = yaml.safe_load(f)
    
    # Navigate through the field path
    keys = '$field_path'.split('.')
    value = data
    for key in keys:
        if isinstance(value, dict):
            value = value.get(key)
        elif isinstance(value, list):
            try:
                index = int(key)
                value = value[index]
            except (ValueError, IndexError):
                sys.exit(1)
        else:
            sys.exit(1)
    
    # Print the value if it exists
    if value is not None:
        print(value)
    else:
        sys.exit(1)
        
except Exception:
    sys.exit(1)
PYTHON_EOF
        return $?
    
    else
        echo "Error: No YAML parser available (yq or python3 required)" >&2
        return 1
    fi
}

# parse_yaml_all() - Parse entire YAML file and return as key=value pairs
# Usage: parse_yaml_all <yaml_file>
# Returns: Lines of "key=value" format suitable for 'eval'
# Exit Code: 0 on success, 1 if file not found or parse error
parse_yaml_all() {
    local yaml_file="$1"
    
    if [[ ! -f "$yaml_file" ]]; then
        return 1
    fi
    
    if command -v yq >/dev/null 2>&1; then
        yq eval -o=json "$yaml_file" 2>/dev/null | python3 -c "
import json
import sys
data = json.load(sys.stdin)

def flatten(obj, prefix=''):
    for key, value in obj.items():
        full_key = f'{prefix}{key}' if prefix else key
        if isinstance(value, dict):
            yield from flatten(value, f'{full_key}.')
        elif isinstance(value, list):
            for i, item in enumerate(value):
                if isinstance(item, dict):
                    yield from flatten(item, f'{full_key}[{i}].')
                else:
                    print(f'{full_key}[{i}]={item}')
        else:
            print(f'{full_key}={value}')

flatten(data)
" 2>/dev/null || return 1
    else
        echo "Error: yq not found for full YAML parsing" >&2
        return 1
    fi
}

# yaml_has_field() - Check if a field exists in YAML file
# Usage: yaml_has_field <yaml_file> <field_path>
# Returns: 0 if field exists, 1 if not
yaml_has_field() {
    local yaml_file="$1"
    local field_path="$2"
    
    if [[ ! -f "$yaml_file" ]]; then
        return 1
    fi
    
    if command -v yq >/dev/null 2>&1; then
        local value
        value=$(yq eval "$field_path" "$yaml_file" 2>/dev/null) || return 1
        
        if [[ "$value" == "null" ]] || [[ -z "$value" ]]; then
            return 1
        fi
        return 0
    else
        return 1
    fi
}

# ============================================================================
# Variable Expansion Functions
# ============================================================================

# expand_yaml_variables() - Expand variables in YAML content
# Supported variables: ${USER}, ${DATE}, ${TIMESTAMP}
# DATE format: ISO 8601 UTC (YYYY-MM-DDTHH:MM:SSZ)
# Usage: expand_yaml_variables <yaml_file> <output_file>
# Exit Code: 0 on success, 1 on error
expand_yaml_variables() {
    local yaml_file="$1"
    local output_file="${2:--}"  # Default to stdout if not specified
    
    if [[ ! -f "$yaml_file" ]]; then
        echo "Error: YAML file not found: $yaml_file" >&2
        return 1
    fi
    
    # Get current date in ISO 8601 UTC format
    local iso_date
    iso_date=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
    
    # Get current timestamp
    local timestamp
    timestamp=$(date -u +'%s')
    
    # Perform variable substitution
    local expanded
    expanded=$(sed \
        -e "s|\${USER}|$USER|g" \
        -e "s|\${DATE}|$iso_date|g" \
        -e "s|\${TIMESTAMP}|$timestamp|g" \
        "$yaml_file")
    
    if [[ "$output_file" == "-" ]]; then
        echo "$expanded"
    else
        echo "$expanded" > "$output_file"
    fi
    
    return 0
}

# expand_variables() - Wrapper function to expand variables in YAML/text files
# Expands: ${USER}, ${DATE} (ISO 8601 UTC), ${TIMESTAMP}
# Usage: expand_variables <input_file> [output_file]
# If output_file is omitted or "-", prints to stdout
# Exit Code: 0 on success, 1 on error
expand_variables() {
    local input_file="$1"
    local output_file="${2:--}"
    
    if [[ ! -f "$input_file" ]]; then
        echo "Error: Input file not found: $input_file" >&2
        return 1
    fi
    
    # Delegate to expand_yaml_variables
    expand_yaml_variables "$input_file" "$output_file"
    return $?
}

# get_yaml_variable() - Get a variable placeholder value
# Usage: get_yaml_variable "USER"
# Returns: The value of the variable
get_yaml_variable() {
    local var_name="$1"
    
    case "$var_name" in
        USER)
            echo "${USER:-unknown}"
            ;;
        DATE)
            date -u +'%Y-%m-%dT%H:%M:%SZ'
            ;;
        TIMESTAMP)
            date -u +'%s'
            ;;
        *)
            echo ""
            return 1
            ;;
    esac
    return 0
}

# ============================================================================
# YAML Validation Functions
# ============================================================================

# validate_yaml() - Check if a file is valid YAML
# Usage: validate_yaml <yaml_file>
# Exit Code: 0 if valid, 1 if invalid
validate_yaml() {
    local yaml_file="$1"
    
    if [[ ! -f "$yaml_file" ]]; then
        return 1
    fi
    
    if command -v yq >/dev/null 2>&1; then
        yq eval '.' "$yaml_file" >/dev/null 2>&1
        return $?
    elif command -v python3 >/dev/null 2>&1; then
        python3 -c "
import yaml
try:
    with open('$yaml_file', 'r') as f:
        yaml.safe_load(f)
except Exception:
    exit(1)
" 2>/dev/null
        return $?
    else
        return 1
    fi
}

# ============================================================================
# YAML Merging Functions
# ============================================================================

# merge_yaml_files() - Merge two YAML files with proper precedence
# Usage: merge_yaml_files <base_file> <override_file> <output_file>
# The override_file values take precedence over base_file
# Exit Code: 0 on success, 1 on error
merge_yaml_files() {
    local base_file="$1"
    local override_file="$2"
    local output_file="$3"
    
    if [[ ! -f "$base_file" ]] || [[ ! -f "$override_file" ]]; then
        echo "Error: Base or override file not found" >&2
        return 1
    fi
    
    if command -v yq >/dev/null 2>&1; then
        yq eval-all 'select(fileIndex==0) * select(fileIndex==1)' \
            "$base_file" "$override_file" > "$output_file" 2>/dev/null || return 1
        return 0
    else
        echo "Error: yq required for YAML merging" >&2
        return 1
    fi
}

# ============================================================================
# YAML Output Functions
# ============================================================================

# yaml_to_json() - Convert YAML file to JSON
# Usage: yaml_to_json <yaml_file> <output_file>
# Output file can be "-" for stdout
# Exit Code: 0 on success, 1 on error
yaml_to_json() {
    local yaml_file="$1"
    local output_file="${2:--}"
    
    if [[ ! -f "$yaml_file" ]]; then
        echo "Error: YAML file not found: $yaml_file" >&2
        return 1
    fi
    
    if command -v yq >/dev/null 2>&1; then
        if [[ "$output_file" == "-" ]]; then
            yq eval -o=json "$yaml_file" 2>/dev/null || return 1
        else
            yq eval -o=json "$yaml_file" > "$output_file" 2>/dev/null || return 1
        fi
        return 0
    else
        echo "Error: yq required for YAML to JSON conversion" >&2
        return 1
    fi
}

# ============================================================================
# YAML Array/List Functions
# ============================================================================

# yaml_get_array_length() - Get the length of an array in YAML
# Usage: yaml_get_array_length <yaml_file> <array_path>
# Example: yaml_get_array_length config.yaml "world.folders"
# Returns: The number of elements in the array
# Exit Code: 0 on success, 1 if not an array or not found
yaml_get_array_length() {
    local yaml_file="$1"
    local array_path="$2"
    
    if [[ ! -f "$yaml_file" ]]; then
        return 1
    fi
    
    if command -v yq >/dev/null 2>&1; then
        local length
        length=$(yq eval "${array_path} | length" "$yaml_file" 2>/dev/null) || return 1
        echo "$length"
        return 0
    else
        return 1
    fi
}

# yaml_get_array_element() - Get a specific element from an array in YAML
# Usage: yaml_get_array_element <yaml_file> <array_path> <index>
# Example: yaml_get_array_element config.yaml "world.folders" 0
# Returns: The value at the specified index
# Exit Code: 0 on success, 1 if index out of bounds
yaml_get_array_element() {
    local yaml_file="$1"
    local array_path="$2"
    local index="$3"
    
    if [[ ! -f "$yaml_file" ]]; then
        return 1
    fi
    
    if command -v yq >/dev/null 2>&1; then
        yq eval "${array_path}[${index}]" "$yaml_file" 2>/dev/null || return 1
        return 0
    else
        return 1
    fi
}

# ============================================================================
# YAML Creation Helper Functions
# ============================================================================

# create_yaml_template() - Create a new YAML file from a template
# Usage: create_yaml_template <template_file> <output_file> [var1=val1] [var2=val2]...
# Exit Code: 0 on success, 1 on error
create_yaml_template() {
    local template_file="$1"
    local output_file="$2"
    shift 2
    
    if [[ ! -f "$template_file" ]]; then
        echo "Error: Template file not found: $template_file" >&2
        return 1
    fi
    
    # Start with template content
    local content
    content=$(<"$template_file")
    
    # Apply variable substitutions
    while [[ $# -gt 0 ]]; do
        local var_assignment="$1"
        if [[ "$var_assignment" == *"="* ]]; then
            local var_name="${var_assignment%%=*}"
            local var_value="${var_assignment#*=}"
            content="${content//\$\{$var_name\}/$var_value}"
        fi
        shift
    done
    
    # Also expand standard variables
    content=$(echo "$content" | sed \
        -e "s|\${USER}|$USER|g" \
        -e "s|\${DATE}|$(date -u +'%Y-%m-%dT%H:%M:%SZ')|g")
    
    echo "$content" > "$output_file"
    return 0
}

# ============================================================================
# Error Reporting Functions
# ============================================================================

# report_yaml_error() - Report a YAML-related error with context
# Usage: report_yaml_error <error_message> <yaml_file> <field_path>
# Exit Code: Always returns 1
report_yaml_error() {
    local error_msg="$1"
    local yaml_file="${2:-unknown}"
    local field_path="${3:-}"
    
    echo "${COLOR_RED}YAML Error:${COLOR_RESET}" >&2
    echo "  Message: $error_msg" >&2
    echo "  File: $yaml_file" >&2
    if [[ -n "$field_path" ]]; then
        echo "  Field: $field_path" >&2
    fi
    echo "" >&2
    
    return 1
}

# yaml_error_context() - Show error context from a YAML file
# Usage: yaml_error_context <yaml_file> <line_number>
# Shows the error line and 2 lines before/after
yaml_error_context() {
    local yaml_file="$1"
    local line_number="${2:-0}"
    
    if [[ ! -f "$yaml_file" ]] || [[ $line_number -le 0 ]]; then
        return 1
    fi
    
    local start_line=$((line_number - 2))
    if [[ $start_line -lt 1 ]]; then
        start_line=1
    fi
    
    local end_line=$((line_number + 2))
    
    echo "${COLOR_YELLOW}Context:${COLOR_RESET}" >&2
    sed -n "${start_line},${end_line}p" "$yaml_file" | nl -v "$start_line" -s ': ' >&2
    echo "" >&2
}

# ============================================================================
# Utility Functions
# ============================================================================

# yaml_get_type() - Get the YAML type of a field (scalar, list, dict)
# Usage: yaml_get_type <yaml_file> <field_path>
# Returns: "scalar", "list", or "dict"
yaml_get_type() {
    local yaml_file="$1"
    local field_path="$2"
    
    if [[ ! -f "$yaml_file" ]]; then
        return 1
    fi
    
    if command -v yq >/dev/null 2>&1; then
        yq eval "($field_path | type)" "$yaml_file" 2>/dev/null || return 1
    else
        return 1
    fi
}

# check_yaml_parser_availability() - Verify YAML parser is available
# Usage: check_yaml_parser_availability
# Exit Code: 0 if parser found, 1 if not
check_yaml_parser_availability() {
    if command -v yq >/dev/null 2>&1; then
        return 0
    elif command -v python3 >/dev/null 2>&1; then
        # Check if PyYAML is available
        if python3 -c "import yaml" 2>/dev/null; then
            return 0
        fi
    fi
    
    echo "Error: No YAML parser available (yq or python3 with PyYAML required)" >&2
    return 1
}

# get_yaml_parser_version() - Get the version of the available YAML parser
# Usage: get_yaml_parser_version
# Returns: Version string of the parser
get_yaml_parser_version() {
    if command -v yq >/dev/null 2>&1; then
        yq --version 2>/dev/null | head -1
    elif command -v python3 >/dev/null 2>&1; then
        python3 -c "import yaml; print('PyYAML', yaml.__version__)" 2>/dev/null
    else
        echo "No YAML parser available"
        return 1
    fi
}
