#!/usr/bin/env bash
# config_utils.sh - Configuration loading and management utilities for DirForge
# Part of the YAML-Driven World Configuration System (Constitution v1.0.22, Section IV.B)

set -euo pipefail

# Source required libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/colors.sh"
source "$SCRIPT_DIR/yaml_utils.sh"
source "$SCRIPT_DIR/error.sh"

# Initialize colors on library load
init_colors

# ============================================================================
# Configuration Directory Constants
# ============================================================================

# Default location for world configuration files
: "${DIRFORGE_CONFIG_DIR:=templates/world-configs}"

# Cached configuration storage (bash 3-compatible alternative to associative arrays)
# Uses temporary files to store parsed configs and their metadata
CONFIG_CACHE_DIR="${TMPDIR:=/tmp}/dirforge_config_cache_${$}"
mkdir -p "$CONFIG_CACHE_DIR" 2>/dev/null || true

# Maximum cache validity period in seconds (30 minutes)
: "${CONFIG_CACHE_TTL:=1800}"

# Clean up cache directory on exit
trap 'rm -rf "$CONFIG_CACHE_DIR" 2>/dev/null' EXIT

# ============================================================================
# Configuration Path Resolution
# ============================================================================

# infer_config_path() - Infer the config file path for a world type
# Usage: infer_config_path <world_type>
# Example: infer_config_path RESEARCH_WORLD
# Returns: Path to the config file (e.g., templates/world-configs/research.world.yaml)
# Exit Code: 0 if file found, 1 if not found
infer_config_path() {
    local world_type="$1"
    
    if [[ -z "$world_type" ]]; then
        report_config_error "World type not specified"
        return 1
    fi
    
    # Convert world type to lowercase config filename
    # e.g., RESEARCH_WORLD -> research.world.yaml
    local config_name
    config_name=$(echo "$world_type" | tr '[:upper:]' '[:lower:]' | sed 's/_world$//')
    
    local config_file="${DIRFORGE_CONFIG_DIR}/${config_name}.world.yaml"
    
    # If DIRFORGE_CONFIG_DIR doesn't exist or is relative, resolve to repo root
    if [[ ! -d "$DIRFORGE_CONFIG_DIR" ]]; then
        # Try to find from script location
        local script_root
        script_root=$(cd "$SCRIPT_DIR/.." && pwd)
        config_file="${script_root}/${DIRFORGE_CONFIG_DIR}/${config_name}.world.yaml"
    fi
    
    if [[ ! -f "$config_file" ]]; then
        report_config_error "Config file not found for world type '$world_type'" "$config_file"
        return 1
    fi
    
    echo "$config_file"
    return 0
}

# resolve_config_path() - Resolve a config file path with full validation
# Usage: resolve_config_path <path_or_world_type>
# Returns: Absolute path to the config file
# Exit Code: 0 if resolved, 1 if not found
resolve_config_path() {
    local path_or_type="$1"
    
    if [[ -z "$path_or_type" ]]; then
        report_config_error "Config path or world type not specified"
        return 1
    fi
    
    # If it looks like a file path, use it directly
    if [[ "$path_or_type" == *"/"* ]] || [[ "$path_or_type" == *"."* ]]; then
        if [[ ! -f "$path_or_type" ]]; then
            report_config_error "Config file not found" "$path_or_type"
            return 1
        fi
        echo "$(cd "$(dirname "$path_or_type")" && pwd)/$(basename "$path_or_type")"
        return 0
    fi
    
    # Otherwise, try to infer from world type
    infer_config_path "$path_or_type"
}

# find_config_file() - Search for config file by name in standard locations
# Usage: find_config_file <config_name>
# Returns: Path to config file if found
# Exit Code: 0 if found, 1 if not found
find_config_file() {
    local config_name="$1"
    
    local search_paths=(
        "${DIRFORGE_CONFIG_DIR}/${config_name}.world.yaml"
        "${DIRFORGE_CONFIG_DIR}/${config_name}.yaml"
        "${DIRFORGE_CONFIG_DIR}/${config_name}"
    )
    
    for path in "${search_paths[@]}"; do
        if [[ -f "$path" ]]; then
            echo "$path"
            return 0
        fi
    done
    
    return 1
}

# list_available_configs() - List all available world configuration files
# Usage: list_available_configs
# Returns: One config filename per line (without path)
# Exit Code: 0 if configs found, 1 if directory doesn't exist
list_available_configs() {
    local config_dir="$DIRFORGE_CONFIG_DIR"
    
    if [[ ! -d "$config_dir" ]]; then
        return 1
    fi
    
    find "$config_dir" -maxdepth 1 -name "*.world.yaml" -type f -exec basename {} \; | sort
}

# ============================================================================
# Configuration Loading
# ============================================================================

# load_config() - Load a configuration file and export its fields as shell variables
# Usage: load_config <config_path>
# Returns: Exports configuration fields as shell variables (CONFIG_<field>)
# Exit Code: 0 on success, 1 on error
# Notes:
#   - Variables are prefixed with CONFIG_ and field names are UPPERCASE
#   - Supports caching to avoid repeated parsing (30 minute TTL)
#   - All values exported as strings; nested structures as JSON strings
load_config() {
    local config_path="$1"
    
    config_path=$(resolve_config_path "$config_path") || return 1
    
    # Check cache first (bash 3-compatible approach)
    local cache_file="${CONFIG_CACHE_DIR}/$(basename "$config_path" | tr '.' '_')"
    local cache_validity_file="${cache_file}.validity"
    
    if [[ -f "$cache_file" && -f "$cache_validity_file" ]]; then
        local cache_time
        cache_time=$(cat "$cache_validity_file" 2>/dev/null)
        local current_time
        current_time=$(date +%s)
        
        if [[ -n "$cache_time" && $(( current_time - cache_time )) -lt $CONFIG_CACHE_TTL ]]; then
            # Cache is still valid, use it
            source "$cache_file" 2>/dev/null || return 1
            return 0
        fi
    fi
    
    # Validate YAML syntax before parsing
    if ! validate_yaml "$config_path"; then
        report_config_error "Invalid YAML in config file" "$config_path"
        return 1
    fi
    
    # Create temporary files for processing
    local json_file config_vars_file python_script
    json_file=$(mktemp) || return 1
    config_vars_file=$(mktemp) || { rm -f "$json_file"; return 1; }
    python_script=$(mktemp) || { rm -f "$json_file" "$config_vars_file"; return 1; }
    trap "rm -f '$json_file' '$config_vars_file' '$python_script'" RETURN
    
    # Convert YAML to JSON
    if ! yq eval -o=json "$config_path" > "$json_file" 2>/dev/null; then
        report_config_error "Failed to parse config file (YAML conversion)" "$config_path"
        return 1
    fi
    
    # Create a Python script to parse JSON and export variables
    cat > "$python_script" << 'PYTHON_SCRIPT'
import json
import sys

json_file = sys.argv[1]
output_file = sys.argv[2]

try:
    with open(json_file, 'r') as f:
        data = json.load(f)
except Exception as e:
    sys.stderr.write("Failed to parse JSON: {}\n".format(e))
    sys.exit(1)

def flatten(obj, prefix=''):
    """Recursively flatten JSON object into shell export statements"""
    for key, value in obj.items():
        # Build the variable name: CONFIG_<path>
        full_key = 'CONFIG_{}{}'.format(prefix, key) if prefix else 'CONFIG_{}'.format(key)
        full_key = full_key.upper().replace('-', '_')
        
        if isinstance(value, dict):
            # Recursively process nested dicts
            for item in flatten(value, key + '_'):
                yield item
        elif isinstance(value, list):
            # Store lists as JSON strings
            json_str = json.dumps(value)
            escaped = json_str.replace('\\', '\\\\').replace('"', '\\"').replace('$', '\\$')
            yield 'export {}="{}"'.format(full_key, escaped)
        elif value is None:
            yield 'export {}=""'.format(full_key)
        else:
            # Convert to string and escape
            val_str = str(value).lower() if isinstance(value, bool) else str(value)
            escaped = val_str.replace('\\', '\\\\').replace('"', '\\"').replace('$', '\\$').replace('`', '\\`').replace('\n', '\\n')
            yield 'export {}="{}"'.format(full_key, escaped)

try:
    with open(output_file, 'w') as f:
        for line in flatten(data):
            f.write(line + '\n')
except Exception as e:
    sys.stderr.write("Failed to write output: {}\n".format(e))
    sys.exit(1)
PYTHON_SCRIPT
    
    # Run the Python script to parse JSON
    if ! python3 "$python_script" "$json_file" "$config_vars_file" 2>&1; then
        report_config_error "Failed to parse config file (JSON processing)" "$config_path"
        return 1
    fi
    
    # Source the variables
    if ! source "$config_vars_file"; then
        report_config_error "Failed to source config variables" "$config_path"
        return 1
    fi
    
    # Cache the exports for future use
    mkdir -p "$CONFIG_CACHE_DIR" 2>/dev/null || true
    cp "$config_vars_file" "$cache_file" 2>/dev/null || true
    date +%s > "$cache_validity_file" 2>/dev/null || true
    
    return 0
}

# load_config_field() - Load a single field from a configuration file
# Usage: load_config_field <config_path> <field_path>
# Example: load_config_field research.world.yaml "world.default_structure"
# Returns: The value of the field
# Exit Code: 0 on success, 1 if field not found
load_config_field() {
    local config_path="$1"
    local field_path="$2"
    
    config_path=$(resolve_config_path "$config_path") || return 1
    
    if ! validate_yaml "$config_path"; then
        return 1
    fi
    
    parse_yaml "$config_path" "$field_path" || return 1
}

# ============================================================================
# Configuration Validation
# ============================================================================

# has_config_field() - Check if a configuration field exists and is not null
# Usage: has_config_field <config_path> <field_path>
# Exit Code: 0 if field exists, 1 if not
has_config_field() {
    local config_path="$1"
    local field_path="$2"
    
    config_path=$(resolve_config_path "$config_path") || return 1
    
    yaml_has_field "$config_path" "$field_path"
}

# get_config_field_type() - Get the type of a configuration field
# Usage: get_config_field_type <config_path> <field_path>
# Returns: "scalar", "list", or "dict"
# Exit Code: 0 on success, 1 if field not found
get_config_field_type() {
    local config_path="$1"
    local field_path="$2"
    
    config_path=$(resolve_config_path "$config_path") || return 1
    
    yaml_get_type "$config_path" "$field_path"
}

# ============================================================================
# Configuration Merging and Inheritance
# ============================================================================

# merge_configs() - Merge a base config with an override config
# Usage: merge_configs <base_config> <override_config> <output_path>
# The override config values take precedence
# Exit Code: 0 on success, 1 on error
merge_configs() {
    local base_config="$1"
    local override_config="$2"
    local output_path="$3"
    
    base_config=$(resolve_config_path "$base_config") || return 1
    override_config=$(resolve_config_path "$override_config") || return 1
    
    if ! validate_yaml "$base_config" || ! validate_yaml "$override_config"; then
        return 1
    fi
    
    merge_yaml_files "$base_config" "$override_config" "$output_path"
}

# get_inherited_field() - Get a field with inheritance lookup
# Usage: get_inherited_field <world_type> <field_path> [parent_world_type]
# Exit Code: 0 if found, 1 if not found
get_inherited_field() {
    local world_type="$1"
    local field_path="$2"
    local parent_world_type="${3:-}"
    
    local config_path
    if ! config_path=$(infer_config_path "$world_type"); then
        return 1
    fi
    
    # First try to get from current world type
    if has_config_field "$config_path" "$field_path"; then
        load_config_field "$config_path" "$field_path"
        return 0
    fi
    
    # If parent specified, try parent
    if [[ -n "$parent_world_type" ]]; then
        if ! config_path=$(infer_config_path "$parent_world_type"); then
            return 1
        fi
        
        if has_config_field "$config_path" "$field_path"; then
            load_config_field "$config_path" "$field_path"
            return 0
        fi
    fi
    
    return 1
}

# ============================================================================
# Configuration Expansion and Processing
# ============================================================================

# expand_config_file() - Expand variables in a config file and save to output
# Usage: expand_config_file <config_path> <output_path>
# Expands: ${USER}, ${DATE}, ${TIMESTAMP}
# Exit Code: 0 on success, 1 on error
expand_config_file() {
    local config_path="$1"
    local output_path="$2"
    
    config_path=$(resolve_config_path "$config_path") || return 1
    
    expand_yaml_variables "$config_path" "$output_path"
}

# get_config_as_json() - Convert config file to JSON format
# Usage: get_config_as_json <config_path> [output_path]
# Exit Code: 0 on success, 1 on error
get_config_as_json() {
    local config_path="$1"
    local output_path="${2:--}"
    
    config_path=$(resolve_config_path "$config_path") || return 1
    
    yaml_to_json "$config_path" "$output_path"
}

# ============================================================================
# Configuration Utility Functions
# ============================================================================

# get_world_type_from_config() - Extract the world type from a config file
# Usage: get_world_type_from_config <config_path>
# Returns: The world type (e.g., RESEARCH_WORLD)
# Exit Code: 0 on success, 1 if field not found
get_world_type_from_config() {
    local config_path="$1"
    
    config_path=$(resolve_config_path "$config_path") || return 1
    
    load_config_field "$config_path" "world.type"
}

# get_world_description() - Get the description of a world type from config
# Usage: get_world_description <world_type>
# Returns: The description text
# Exit Code: 0 on success, 1 if not found
get_world_description() {
    local world_type="$1"
    
    local config_path
    if ! config_path=$(infer_config_path "$world_type"); then
        return 1
    fi
    
    load_config_field "$config_path" "world.description"
}

# get_world_folder_count() - Get the number of default folders for a world type
# Usage: get_world_folder_count <world_type>
# Returns: The number of default folders
# Exit Code: 0 on success, 1 if not found
get_world_folder_count() {
    local world_type="$1"
    
    local config_path
    if ! config_path=$(infer_config_path "$world_type"); then
        return 1
    fi
    
    yaml_get_array_length "$config_path" "world.default_folders"
}

# list_world_folders() - List all default folders for a world type
# Usage: list_world_folders <world_type>
# Returns: One folder name per line
# Exit Code: 0 on success, 1 if not found
list_world_folders() {
    local world_type="$1"
    
    local config_path
    if ! config_path=$(infer_config_path "$world_type"); then
        return 1
    fi
    
    local length
    length=$(yaml_get_array_length "$config_path" "world.default_folders") || return 1
    
    for (( i = 0; i < length; i++ )); do
        yaml_get_array_element "$config_path" "world.default_folders" "$i"
    done
}

# ============================================================================
# Configuration Validation and Diagnostics
# ============================================================================

# validate_config() - Perform comprehensive validation on a config file
# Usage: validate_config <config_path>
# Checks: Valid YAML, required fields, field types
# Exit Code: 0 if valid, 1 if invalid
validate_config() {
    local config_path="$1"
    
    config_path=$(resolve_config_path "$config_path") || return 1
    
    if ! validate_yaml "$config_path"; then
        report_config_error "Invalid YAML syntax" "$config_path"
        return 1
    fi
    
    # Check for required top-level fields
    local required_fields=("world" "metadata")
    for field in "${required_fields[@]}"; do
        if ! has_config_field "$config_path" "$field"; then
            report_config_error "Missing required field: $field" "$config_path" "$field"
            return 1
        fi
    done
    
    return 0
}

# diagnose_config() - Provide detailed diagnostic information about a config
# Usage: diagnose_config <config_path>
# Displays: File info, validation status, parsed fields
diagnose_config() {
    local config_path="$1"
    
    config_path=$(resolve_config_path "$config_path") || return 1
    
    echo "${COLOR_CYAN}Configuration Diagnostics:${COLOR_RESET}"
    echo "  Path: $config_path"
    echo "  Size: $(stat -f%z "$config_path" 2>/dev/null || stat -c%s "$config_path") bytes"
    echo "  Modified: $(stat -f%Sm -t '%Y-%m-%d %H:%M:%S' "$config_path" 2>/dev/null || stat -c%y "$config_path" | cut -d' ' -f1-2)"
    echo ""
    
    if validate_yaml "$config_path"; then
        echo "  ${COLOR_GREEN}✓ Valid YAML syntax${COLOR_RESET}"
    else
        echo "  ${COLOR_RED}✗ Invalid YAML syntax${COLOR_RESET}"
        return 1
    fi
    
    if validate_config "$config_path"; then
        echo "  ${COLOR_GREEN}✓ Valid schema${COLOR_RESET}"
    else
        echo "  ${COLOR_RED}✗ Invalid schema${COLOR_RESET}"
        return 1
    fi
    
    echo ""
    echo "${COLOR_CYAN}Parsed Fields:${COLOR_RESET}"
    get_config_as_json "$config_path" | python3 -c "
import json
import sys
data = json.load(sys.stdin)

def print_tree(obj, prefix=''):
    if isinstance(obj, dict):
        for key, value in obj.items():
            if isinstance(value, dict):
                print(f'{prefix}{key}:')
                print_tree(value, prefix + '  ')
            elif isinstance(value, list):
                print(f'{prefix}{key}: [{len(value)} items]')
            else:
                print(f'{prefix}{key}: {value}')
    
print_tree(data)
" 2>/dev/null || return 1
    
    return 0
}

# clear_config_cache() - Clear the configuration cache
# Usage: clear_config_cache [cache_key]
# If cache_key is omitted, clears entire cache
clear_config_cache() {
    local cache_key="${1:-}"
    
    if [[ -z "$cache_key" ]]; then
        # Clear all cache files
        rm -rf "$CONFIG_CACHE_DIR" 2>/dev/null || true
        mkdir -p "$CONFIG_CACHE_DIR" 2>/dev/null || true
    else
        # Clear specific cache key
        local cache_file="${CONFIG_CACHE_DIR}/${cache_key}"
        rm -f "$cache_file" "$cache_file.validity" 2>/dev/null || true
    fi
}

# ============================================================================
# Error Reporting Functions
# ============================================================================

# report_config_error() - Report a configuration-related error
# Usage: report_config_error <error_message> [config_file] [field_path]
# Exit Code: Always returns 1
report_config_error() {
    local error_msg="$1"
    local config_file="${2:-unknown}"
    local field_path="${3:-}"
    
    echo "${COLOR_RED}Config Error:${COLOR_RESET}" >&2
    echo "  Message: $error_msg" >&2
    echo "  Config: $config_file" >&2
    if [[ -n "$field_path" ]]; then
        echo "  Field: $field_path" >&2
    fi
    echo "" >&2
    
    return 1
}
