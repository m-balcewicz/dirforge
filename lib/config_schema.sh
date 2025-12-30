#!/usr/bin/env bash
# config_schema.sh - Configuration schema validation for DirForge YAML configs
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
# Schema Definition and Validation
# ============================================================================

# Define required fields for world configuration (v1.0.22)
# These fields MUST be present in all valid world configs
get_required_fields() {
    cat << 'EOF'
world.type
world.description
metadata.version
metadata.constitution_version
metadata.created
metadata.author
metadata.creation_template
metadata.integrity_required
metadata.default_owner
parent_directories
subdirectories
permissions
EOF
}

# Define optional fields for world configuration
get_optional_fields() {
    cat << 'EOF'
world.example
config.creation_method
config.scaffold_type
config.atomic_transactions
config.rollback_on_failure
config.notes
EOF
}

# validate_schema() - Validate a config file against the world schema
# Usage: validate_schema <config_file>
# Returns: 0 if valid, 1 if invalid
# Validates: Required fields, field types, structure consistency per Constitution v1.0.22
validate_schema() {
    local config_file="$1"
    
    if [[ ! -f "$config_file" ]]; then
        report_schema_error "Config file not found" "$config_file"
        return 1
    fi
    
    local validation_errors=0
    
    # Check all required fields (add dot prefix for yq compatibility)
    while IFS= read -r field; do
        [[ -z "$field" ]] && continue
        
        # Add dot prefix if not already present
        local yq_field="$field"
        [[ "$yq_field" != .* ]] && yq_field=".$yq_field"
        
        if ! yaml_has_field "$config_file" "$yq_field"; then
            report_schema_error "Missing required field: $field" "$config_file"
            ((validation_errors++))
        fi
    done < <(get_required_fields)
    
    # Validate world.type is one of the known types
    if yaml_has_field "$config_file" ".world.type"; then
        local world_type
        world_type=$(parse_yaml "$config_file" "world.type" 2>/dev/null) || world_type=""
        
        local valid_types=("CODING_WORLD" "RESEARCH_WORLD" "JOURNAL_WORLD" "LECTURE_WORLD" "OFFICE_WORLD" "PRIVATE_WORLD" "LITERATURE_WORLD")
        local is_valid=0
        for vtype in "${valid_types[@]}"; do
            if [[ "$world_type" == "$vtype" ]]; then
                is_valid=1
                break
            fi
        done
        
        if [[ $is_valid -eq 0 ]]; then
            report_schema_error "Invalid world.type: $world_type (must be one of: CODING_WORLD, RESEARCH_WORLD, JOURNAL_WORLD, LECTURE_WORLD, OFFICE_WORLD, PRIVATE_WORLD, LITERATURE_WORLD)" "$config_file"
            ((validation_errors++))
        fi
    fi
    
    # Validate metadata.constitution_version matches known versions
    if yaml_has_field "$config_file" ".metadata.constitution_version"; then
        local const_version
        const_version=$(parse_yaml "$config_file" "metadata.constitution_version" 2>/dev/null) || const_version=""
        if [[ "$const_version" != "1.0.22" ]]; then
            # Log warning but don't fail
            report_schema_warning "Constitution version $const_version may not be fully supported (expected 1.0.22)" "$config_file"
        fi
    fi
    
    # Validate integrity_required is boolean
    if yaml_has_field "$config_file" ".metadata.integrity_required"; then
        local integrity_val
        integrity_val=$(parse_yaml "$config_file" "metadata.integrity_required" 2>/dev/null) || integrity_val=""
        if ! [[ "$integrity_val" =~ ^(true|false|yes|no|on|off)$ ]]; then
            report_schema_error "Invalid value for metadata.integrity_required: $integrity_val (must be boolean)" "$config_file"
            ((validation_errors++))
        fi
    fi
    
    if [[ $validation_errors -gt 0 ]]; then
        return 1
    fi
    
    return 0
}

# validate_config_schema() - Comprehensive schema validation function
# Usage: validate_config_schema <config_file> [--verbose]
# Returns: 0 if valid, 1 if invalid
# Performs: Full schema validation including required fields, types, and structure
# Exit Code: 0 on success, 1 on validation failure
validate_config_schema() {
    local config_file="$1"
    local verbose="${2:-}"
    
    [[ "$verbose" == "--verbose" ]] && local is_verbose=1 || local is_verbose=0
    
    if [[ ! -f "$config_file" ]]; then
        report_schema_error "Config file not found: $config_file"
        return 1
    fi
    
    [[ $is_verbose -eq 1 ]] && echo "Validating: $config_file" >&2
    
    # Run base validation (checks all required fields)
    if ! validate_schema "$config_file"; then
        return 1
    fi
    
    # Run strict validation (additional checks for valid values and structure)
    if ! validate_schema_strict "$config_file"; then
        return 1
    fi
    
    [[ $is_verbose -eq 1 ]] && echo "  ✓ Schema validation passed" >&2
    
    return 0
}

# validate_schema_strict() - Validate config with strict enforcement
# Usage: validate_schema_strict <config_file>
# Checks: All required fields, all field types, folder name compliance
# Exit Code: 0 if valid, 1 if invalid
validate_schema_strict() {
    local config_file="$1"
    
    if ! validate_schema "$config_file"; then
        return 1
    fi
    
    # Additional strict checks
    local validation_errors=0
    
    # Check world.type is one of the known types
    if yaml_has_field "$config_file" "world.type"; then
        local world_type
        world_type=$(yaml_eval "$config_file" "world.type") || world_type=""
        
        local valid_types=("CODING_WORLD" "RESEARCH_WORLD" "JOURNAL_WORLD" "LECTURE_WORLD" "OFFICE_WORLD" "PRIVATE_WORLD" "LITERATURE_WORLD")
        local is_valid=0
        for vtype in "${valid_types[@]}"; do
            if [[ "$world_type" == "$vtype" ]]; then
                is_valid=1
                break
            fi
        done
        
        if [[ $is_valid -eq 0 ]]; then
            report_schema_error "Invalid world.type: $world_type" "$config_file"
            ((validation_errors++))
        fi
    fi
    
    # Validate folder names (alphanumeric, underscores, hyphens only)
    if yaml_has_field "$config_file" "world.default_folders"; then
        local folder_count
        folder_count=$(yaml_get_array_length "$config_file" "world.default_folders") || folder_count=0
        
        for (( i = 0; i < folder_count; i++ )); do
            local folder_name
            folder_name=$(yaml_get_array_element "$config_file" "world.default_folders" "$i") || folder_name=""
            
            if ! [[ "$folder_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
                report_schema_error "Invalid folder name: '$folder_name' (must contain only alphanumeric, underscore, hyphen)" "$config_file" "world.default_folders[$i]"
                ((validation_errors++))
            fi
        done
    fi
    
    if [[ $validation_errors -gt 0 ]]; then
        return 1
    fi
    
    return 0
}

# ============================================================================
# Field Type Validation
# ============================================================================

# is_valid_string() - Check if a value is a valid string
# Usage: is_valid_string <value>
# Exit Code: 0 if valid, 1 if not
is_valid_string() {
    local value="$1"
    [[ -n "$value" && "$value" != "null" ]]
}

# is_valid_integer() - Check if a value is a valid integer
# Usage: is_valid_integer <value>
# Exit Code: 0 if valid, 1 if not
is_valid_integer() {
    local value="$1"
    [[ "$value" =~ ^[0-9]+$ ]]
}

# is_valid_boolean() - Check if a value is a valid boolean
# Usage: is_valid_boolean <value>
# Exit Code: 0 if valid, 1 if not
is_valid_boolean() {
    local value="$1"
    [[ "$value" == "true" ]] || [[ "$value" == "false" ]] || [[ "$value" == "yes" ]] || [[ "$value" == "no" ]]
}

# is_valid_datetime() - Check if a value is a valid ISO 8601 datetime
# Usage: is_valid_datetime <value>
# Exit Code: 0 if valid, 1 if not
is_valid_datetime() {
    local value="$1"
    # ISO 8601 format: YYYY-MM-DDTHH:MM:SSZ or YYYY-MM-DD
    [[ "$value" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}(T[0-9]{2}:[0-9]{2}:[0-9]{2}Z)?$ ]]
}

# is_valid_version() - Check if a value is a valid semantic version
# Usage: is_valid_version <value>
# Exit Code: 0 if valid, 1 if not
is_valid_version() {
    local value="$1"
    # Semantic version: X.Y.Z
    [[ "$value" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

# validate_field_type() - Validate that a field has the expected type
# Usage: validate_field_type <config_file> <field_path> <expected_type>
# Types: string, integer, boolean, datetime, version, array, object
# Exit Code: 0 if valid, 1 if invalid
validate_field_type() {
    local config_file="$1"
    local field_path="$2"
    local expected_type="$3"
    
    if ! yaml_has_field "$config_file" "$field_path"; then
        return 1
    fi
    
    local actual_type
    actual_type=$(yaml_get_type "$config_file" "$field_path") || return 1
    
    case "$expected_type" in
        string)
            [[ "$actual_type" == "!!str" ]] || [[ "$actual_type" == "scalar" ]]
            ;;
        integer)
            [[ "$actual_type" == "!!int" ]] || [[ "$actual_type" == "scalar" ]]
            ;;
        boolean)
            [[ "$actual_type" == "!!bool" ]] || [[ "$actual_type" == "scalar" ]]
            ;;
        array|list|sequence)
            [[ "$actual_type" == "!!seq" ]] || [[ "$actual_type" == "!!null" ]]
            ;;
        object|dict|map)
            [[ "$actual_type" == "!!map" ]] || [[ "$actual_type" == "!!null" ]]
            ;;
        *)
            return 1
            ;;
    esac
}

# ============================================================================
# Folder Structure Validation
# ============================================================================

# validate_folder_structure() - Validate the default folder structure specification
# Usage: validate_folder_structure <config_file>
# Checks: Folder names, no duplicates, non-empty list
# Exit Code: 0 if valid, 1 if invalid
validate_folder_structure() {
    local config_file="$1"
    
    if ! yaml_has_field "$config_file" "world.default_folders"; then
        # Optional field, return success if missing
        return 0
    fi
    
    local folder_count
    folder_count=$(yaml_get_array_length "$config_file" "world.default_folders") || return 1
    
    if [[ $folder_count -eq 0 ]]; then
        report_schema_error "Folder list is empty" "$config_file" "world.default_folders"
        return 1
    fi
    
    local -a seen_folders=()
    local validation_errors=0
    
    for (( i = 0; i < folder_count; i++ )); do
        local folder_name
        folder_name=$(yaml_get_array_element "$config_file" "world.default_folders" "$i") || folder_name=""
        
        if [[ -z "$folder_name" ]]; then
            report_schema_error "Empty folder name at index $i" "$config_file" "world.default_folders[$i]"
            ((validation_errors++))
            continue
        fi
        
        # Check for invalid characters
        if ! [[ "$folder_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
            report_schema_error "Invalid folder name: '$folder_name'" "$config_file" "world.default_folders[$i]"
            ((validation_errors++))
            continue
        fi
        
        # Check for duplicates
        for seen_folder in "${seen_folders[@]}"; do
            if [[ "$folder_name" == "$seen_folder" ]]; then
                report_schema_error "Duplicate folder name: '$folder_name'" "$config_file" "world.default_folders"
                ((validation_errors++))
                continue 2
            fi
        done
        
        seen_folders+=("$folder_name")
    done
    
    if [[ $validation_errors -gt 0 ]]; then
        return 1
    fi
    
    return 0
}

# ============================================================================
# Comparative Schema Validation
# ============================================================================

# compare_schemas() - Compare two config files for schema compatibility
# Usage: compare_schemas <config1> <config2>
# Returns: 0 if compatible, 1 if incompatible
# Checks: Same world.type, compatible field sets
compare_schemas() {
    local config1="$1"
    local config2="$2"
    
    if [[ ! -f "$config1" ]] || [[ ! -f "$config2" ]]; then
        return 1
    fi
    
    # Get world types
    local type1 type2
    type1=$(yaml_eval "$config1" "world.type" 2>/dev/null) || type1=""
    type2=$(yaml_eval "$config2" "world.type" 2>/dev/null) || type2=""
    
    if [[ "$type1" != "$type2" ]]; then
        report_schema_error "Incompatible world types" "$config1 vs $config2" "world.type: $type1 vs $type2"
        return 1
    fi
    
    return 0
}

# ============================================================================
# Schema Reporting and Diagnostics
# ============================================================================

# report_schema_validation() - Generate a detailed validation report
# Usage: report_schema_validation <config_file>
# Outputs: Detailed validation status with all checks
report_schema_validation() {
    local config_file="$1"
    
    echo "${COLOR_CYAN}Schema Validation Report:${COLOR_RESET}"
    echo "  File: $config_file"
    echo ""
    
    # Basic YAML validation
    if validate_yaml "$config_file"; then
        echo "  ${COLOR_GREEN}✓${COLOR_RESET} Valid YAML syntax"
    else
        echo "  ${COLOR_RED}✗${COLOR_RESET} Invalid YAML syntax"
        return 1
    fi
    
    # Schema validation
    if validate_schema "$config_file"; then
        echo "  ${COLOR_GREEN}✓${COLOR_RESET} Passes basic schema validation"
    else
        echo "  ${COLOR_RED}✗${COLOR_RESET} Fails basic schema validation"
        return 1
    fi
    
    # Strict schema validation
    if validate_schema_strict "$config_file"; then
        echo "  ${COLOR_GREEN}✓${COLOR_RESET} Passes strict schema validation"
    else
        echo "  ${COLOR_YELLOW}⚠${COLOR_RESET} Fails strict schema validation (non-critical)"
    fi
    
    # Folder structure validation
    if validate_folder_structure "$config_file"; then
        echo "  ${COLOR_GREEN}✓${COLOR_RESET} Folder structure is valid"
    else
        echo "  ${COLOR_RED}✗${COLOR_RESET} Folder structure is invalid"
        return 1
    fi
    
    echo ""
    return 0
}

# ============================================================================
# Helper Functions
# ============================================================================

# yaml_eval() - Simple wrapper to evaluate a YAML field
# Usage: yaml_eval <config_file> <field_path>
# Returns: Field value or empty string
yaml_eval() {
    local config_file="$1"
    local field_path="$2"
    
    parse_yaml "$config_file" "$field_path" 2>/dev/null || echo ""
}

# get_schema_rule() - Get the validation rule for a field
# Usage: get_schema_rule <field_path>
# Returns: Rule string (e.g., "required,string")
get_schema_rule() {
    local field_path="$1"
    
    if [[ -n "${SCHEMA_RULES[$field_path]:-}" ]]; then
        echo "${SCHEMA_RULES[$field_path]}"
    else
        echo ""
    fi
}

# validate_against_rule() - Validate a value against a rule
# Usage: validate_against_rule <value> <rule>
# Rule format: "required|optional,type1|type2|type3"
# Exit Code: 0 if valid, 1 if invalid
validate_against_rule() {
    local value="$1"
    local rule="$2"
    
    # Parse rule: required|optional
    local requirement="${rule%%,*}"
    local types="${rule#*,}"
    
    # Check requirement
    if [[ "$requirement" == "required" ]] && [[ -z "$value" ]]; then
        return 1
    fi
    
    # Check type (if value provided)
    if [[ -n "$value" ]]; then
        local valid=0
        for type in $(echo "$types" | tr '|' ' '); do
            case "$type" in
                string) is_valid_string "$value" && valid=1; break ;;
                integer) is_valid_integer "$value" && valid=1; break ;;
                boolean) is_valid_boolean "$value" && valid=1; break ;;
                datetime) is_valid_datetime "$value" && valid=1; break ;;
                version) is_valid_version "$value" && valid=1; break ;;
                *) valid=1; break ;;
            esac
        done
        
        if [[ $valid -eq 0 ]]; then
            return 1
        fi
    fi
    
    return 0
}

# ============================================================================
# Error Reporting Functions
# ============================================================================

# report_schema_error() - Report a schema validation error
# Usage: report_schema_error <error_message> [config_file] [field_path]
# Exit Code: Always returns 1
report_schema_error() {
    local error_msg="$1"
    local config_file="${2:-unknown}"
    local field_path="${3:-}"
    
    echo "${COLOR_RED}Schema Validation Error:${COLOR_RESET}" >&2
    echo "  Message: $error_msg" >&2
    echo "  Config: $config_file" >&2
    if [[ -n "$field_path" ]]; then
        echo "  Field: $field_path" >&2
    fi
    echo "" >&2
    
    return 1
}

# report_schema_warning() - Report a schema validation warning
# Usage: report_schema_warning <warning_message> [config_file] [field_path]
# Exit Code: Always returns 0 (warnings don't cause failure)
report_schema_warning() {
    local warning_msg="$1"
    local config_file="${2:-unknown}"
    local field_path="${3:-}"
    
    echo "${COLOR_YELLOW}Schema Validation Warning:${COLOR_RESET}" >&2
    echo "  Message: $warning_msg" >&2
    echo "  Config: $config_file" >&2
    if [[ -n "$field_path" ]]; then
        echo "  Field: $field_path" >&2
    fi
    echo "" >&2
    
    return 0
}

# ============================================================================
# Schema Export and Documentation
# ============================================================================

# export_schema_as_json() - Export schema definition as JSON
# Usage: export_schema_as_json
# Returns: JSON representation of schema
export_schema_as_json() {
    python3 -c "
import json
schema = {
    'world.type': {'required': True, 'type': 'string'},
    'world.description': {'required': False, 'type': 'string'},
    'world.default_folders': {'required': False, 'type': 'array'},
    'metadata.created': {'required': False, 'type': 'datetime'},
    'metadata.version': {'required': True, 'type': 'string'},
    'metadata.author': {'required': False, 'type': 'string'}
}
print(json.dumps(schema, indent=2))
"
}

# print_schema() - Print the schema definition
# Usage: print_schema
print_schema() {
    echo "${COLOR_CYAN}World Configuration Schema:${COLOR_RESET}"
    echo ""
    echo "Required Fields:"
    echo "  - world.type: World type identifier (e.g., RESEARCH_WORLD)"
    echo "  - metadata.version: Configuration version (semver format)"
    echo ""
    echo "Optional Fields:"
    echo "  - world.description: Human-readable description"
    echo "  - world.default_folders: Array of folder names to create"
    echo "  - metadata.created: ISO 8601 creation timestamp"
    echo "  - metadata.author: Original author or creator"
    echo ""
    echo "Folder Naming Rules:"
    echo "  - Alphanumeric characters, underscores, and hyphens only"
    echo "  - No spaces or special characters"
    echo "  - No duplicate folder names within same config"
    echo ""
}
