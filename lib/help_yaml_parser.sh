#!/usr/bin/env bash

################################################################################
# Help YAML Parser Library
#
# Purpose: Dynamically parse and display help content from YAML files
# Version: 1.0.22
# Constitution: v1.0.22, Section IV.B
#
# Functions:
#   - load_help_yaml()        Load a help YAML file by command/topic name
#   - get_help_section()      Extract specific sections from loaded help
#   - get_command_help()      Get command-specific help (short or long)
#   - get_global_help()       Get global help listing all commands
#   - format_help_output()    Format help for terminal display
#   - _format_short_help()    Format short help variant
#   - _format_long_help()     Format long help variant
#   - _cache_help_file()      Cache parsed help files
#   - _get_cached_help()      Retrieve help from cache
#
################################################################################

# Source required libraries
SCRIPT_DIR_HELPER="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR_HELPER}/colors.sh" 2>/dev/null || true
source "${SCRIPT_DIR_HELPER}/terminal.sh" 2>/dev/null || true

# Cache directory for parsed help files
HELP_CACHE_DIR="${HELP_CACHE_DIR:-.cache/help}"
HELP_CACHE_ENABLED="${HELP_CACHE_ENABLED:-1}"
HELP_CACHE_TTL="${HELP_CACHE_TTL:-3600}"  # 1 hour default

# Initialize cache
_init_help_cache() {
    if [[ "$HELP_CACHE_ENABLED" == "1" ]] && [[ ! -d "$HELP_CACHE_DIR" ]]; then
        mkdir -p "$HELP_CACHE_DIR" 2>/dev/null || HELP_CACHE_ENABLED=0
    fi
}

################################################################################
# load_help_yaml()
#
# Load a help YAML file by command or topic name
#
# Usage:
#   load_help_yaml "validate-config"
#   load_help_yaml "yaml-config-system"
#
# Returns:
#   0 if file loaded successfully
#   1 if file not found (non-fatal - warns and continues)
#
# Output:
#   Parsed YAML content to STDOUT
#
# Notes:
#   - Automatically checks cache first if enabled
#   - Falls back to reading file if not cached
#   - Missing files result in warning, not error
#
################################################################################
load_help_yaml() {
    local help_name="${1:?Error: help_name required}"
    
    # Detect the correct base directory (development vs installed)
    local base_dir
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    if [[ -d "$script_dir/../templates/help" ]]; then
        # Development mode: lib/help_yaml_parser.sh -> ../templates/help
        base_dir="$script_dir/.."
    elif [[ -d "$script_dir/templates/help" ]]; then
        # Installation mode: ~/.local/lib/dirforge/help_yaml_parser.sh -> ./templates/help
        base_dir="$script_dir"
    elif [[ -n "${DIRFORGE_HOME:-}" && -d "$DIRFORGE_HOME/templates/help" ]]; then
        # Explicit DIRFORGE_HOME provided
        base_dir="$DIRFORGE_HOME"
    else
        # Fallback to development mode assumption
        base_dir="$script_dir/.."
    fi
    
    local help_file="$base_dir/templates/help/${help_name}.yaml"
    
    # Check cache first
    if [[ "$HELP_CACHE_ENABLED" == "1" ]]; then
        if [[ -f "$HELP_CACHE_DIR/${help_name}.cache" ]]; then
            # Verify cache is fresh
            local cache_age=$(($(date +%s) - $(stat -f%m "$HELP_CACHE_DIR/${help_name}.cache" 2>/dev/null || echo 0)))
            if [[ $cache_age -lt $HELP_CACHE_TTL ]]; then
                cat "$HELP_CACHE_DIR/${help_name}.cache"
                return 0
            fi
        fi
    fi
    
    # Load from file
    if [[ ! -f "$help_file" ]]; then
        printf "%s\n" "⚠ Warning: Help file not found: $help_file" >&2
        printf "%s\n" "⚠ Missing help file will be created during Phase 8 help file creation" >&2
        return 1
    fi
    
    # Read and cache file
    local content
    content=$(cat "$help_file" 2>/dev/null)
    
    if [[ $? -ne 0 ]]; then
        printf "%s\n" "⚠ Warning: Could not read help file: $help_file" >&2
        return 1
    fi
    
    # Cache if enabled
    if [[ "$HELP_CACHE_ENABLED" == "1" ]]; then
        _cache_help_file "$help_name" "$content"
    fi
    
    printf "%s\n" "$content"
    return 0
}

################################################################################
# get_help_section()
#
# Extract a specific section from help YAML content
#
# Usage:
#   get_help_section "$help_content" "syntax"
#   get_help_section "$help_content" "short_help.summary"
#
# Parameters:
#   $1: YAML content (from load_help_yaml)
#   $2: Section path (dot-separated for nested fields)
#
# Returns:
#   0 if section found
#   1 if section not found
#
# Output:
#   Section content to STDOUT
#
# Notes:
#   - Supports nested field access (e.g., "short_help.summary")
#   - Returns empty if section doesn't exist (non-fatal)
#   - Uses basic YAML parsing suitable for help format
#
################################################################################
get_help_section() {
    local yaml_content="${1:?Error: yaml_content required}"
    local section_path="${2:?Error: section_path required}"
    
    # Handle nested paths like "short_help.summary"
    local section="${section_path%%.*}"
    local subsection="${section_path#*.}"
    
    # Extract section using YAML pattern matching
    local section_content
    
    # Simple YAML extraction for top-level sections
    section_content=$(printf "%s\n" "$yaml_content" | \
        awk -v sec="^${section}:" \
        'BEGIN { in_section=0 } 
         $0 ~ sec { in_section=1; next } 
         in_section && /^[a-z_]+:/ && $0 !~ sec { in_section=0 } 
         in_section { print }')
    
    if [[ -z "$section_content" ]]; then
        return 1
    fi
    
    # Handle nested subsections if specified
    if [[ "$subsection" != "$section_path" ]]; then
        section_content=$(printf "%s\n" "$section_content" | \
            awk -v sub="^  ${subsection}:" \
            'BEGIN { in_subsec=0 } 
             $0 ~ sub { in_subsec=1; next } 
             in_subsec && /^  [a-z_]+:/ && $0 !~ sub { in_subsec=0 } 
             in_subsec { print }')
    fi
    
    printf "%s\n" "$section_content"
    return 0
}

################################################################################
# get_command_help()
#
# Get command-specific help (short or long variant)
#
# Usage:
#   get_command_help "validate-config" "short"
#   get_command_help "list-configs" "long"
#
# Parameters:
#   $1: Command/topic name
#   $2: Help variant (short or long)
#
# Returns:
#   0 if help found
#   1 if command not found
#
# Output:
#   Formatted help text to STDOUT
#
# Notes:
#   - Automatically formats output based on variant
#   - Missing help files don't break function (warning displayed)
#   - Always returns successfully unless major error
#
################################################################################
get_command_help() {
    local command_name="${1:?Error: command_name required}"
    local variant="${2:-long}"  # Default to long help
    
    # Format based on variant - pass command name not content
    case "$variant" in
        short)
            _format_short_help "$command_name"
            ;;
        long)
            _format_long_help "$command_name"
            ;;
        *)
            printf "Error: Unknown help variant: %s\n" "$variant" >&2
            return 1
            ;;
    esac
    
    return $?
}

################################################################################
# get_global_help()
#
# Get global help listing all available commands and topics
#
# Usage:
#   get_global_help
#   dirforge --help   # Uses this function
#
# Returns:
#   0 always (informational function)
#
# Output:
#   Global help menu with all available commands to STDOUT
#
# Notes:
#   - Discovers help files automatically from templates/help/
#   - Progressive disclosure: only shows command names and brief descriptions
#   - Sorted alphabetically by command name
#   - Handles missing help files gracefully
#
################################################################################
get_global_help() {
    # Detect the correct base directory
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local help_dir
    
    if [[ -d "$script_dir/../templates/help" ]]; then
        # Development mode
        help_dir="$script_dir/../templates/help"
    elif [[ -d "$script_dir/templates/help" ]]; then
        # Installation mode
        help_dir="$script_dir/templates/help"
    elif [[ -n "${DIRFORGE_HOME:-}" && -d "$DIRFORGE_HOME/templates/help" ]]; then
        # Explicit DIRFORGE_HOME
        help_dir="$DIRFORGE_HOME/templates/help"
    else
        # Fallback
        help_dir="$script_dir/../templates/help"
    fi
    
    printf "%s\n" "DirForge YAML Configuration System - Available Commands"
    printf "%s\n" ""
    
    # List all help files
    if [[ ! -d "$help_dir" ]]; then
        printf "%s\n" "Help directory not found: $help_dir"
        return 0
    fi
    
    local help_files
    help_files=$(find "$help_dir" -maxdepth 1 -name "*.yaml" -type f 2>/dev/null | sort)
    
    if [[ -z "$help_files" ]]; then
        printf "%s\n" "No help files available yet."
        return 0
    fi
    
    # Extract command name and description from each help file
    while IFS= read -r help_file; do
        local command_name
        local description
        
        command_name=$(basename "$help_file" .yaml)
        
        # Extract description field (simple grep approach for global help)
        description=$(grep "^description:" "$help_file" 2>/dev/null | sed 's/^description: "\(.*\)"/\1/' | head -1)
        description="${description:-(No description available)}"
        
        printf "  %-25s %s\n" "$command_name" "$description"
    done <<< "$help_files"
    
    printf "%s\n" ""
    printf "%s\n" "Use: dirforge help <command> for detailed help"
    printf "%s\n" "Use: dirforge <command> --help for quick reference"
    
    return 0
}

################################################################################
# format_help_output()
#
# Format help content for terminal display
#
# Usage:
#   format_help_output "validate-config" "short"
#   format_help_output "list-configs" "long"
#
# Parameters:
#   $1: Command/topic name
#   $2: Help variant (short or long)
#
# Returns:
#   0 if formatted successfully
#   1 if error occurred
#
# Output:
#   Formatted, colorized help text to STDOUT
#
# Notes:
#   - Wraps lines appropriately for terminal width
#   - Uses colors from lib/colors.sh if available
#   - Handles missing help gracefully
#   - Respects terminal capabilities
#
################################################################################
format_help_output() {
    local command_name="${1:?Error: command_name required}"
    local variant="${2:-long}"
    
    get_command_help "$command_name" "$variant"
}

################################################################################
# _format_short_help()
#
# Format short help variant (essential info only)
#
# Parameters:
#   $1: Help file name (without .yaml extension)
#
# Output:
#   Formatted short help to STDOUT
#
################################################################################
_format_short_help() {
    local help_name="${1:?Error: help_name required}"
    
    # Check if yq is available
    if ! command -v yq &>/dev/null; then
        printf "%s\n" "Warning: yq not found. Install it for YAML help support." >&2
        printf "%s\n" "Falling back to basic help..." >&2
        return 1
    fi
    
    # Detect the correct base directory
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local base_dir
    
    if [[ -d "$script_dir/../templates/help" ]]; then
        base_dir="$script_dir/.."
    elif [[ -d "$script_dir/templates/help" ]]; then
        base_dir="$script_dir"
    else
        base_dir="$script_dir/.."
    fi
    
    local help_file="$base_dir/templates/help/${help_name}.yaml"
    
    if [[ ! -f "$help_file" ]]; then
        printf "%s\n" "Help file not found: $help_file" >&2
        return 1
    fi
    
    # Source formatting functions from help.sh if available
    if [[ -f "$script_dir/help.sh" ]]; then
        source "$script_dir/colors.sh" 2>/dev/null || true
        source "$script_dir/terminal.sh" 2>/dev/null || true
    fi
    
    # Extract data using yq
    local command summary
    command=$(yq e '.command' "$help_file" 2>/dev/null)
    summary=$(yq e '.short_help.summary' "$help_file" 2>/dev/null)
    local version=$(yq e '.constitution_section // .updated' "$help_file" 2>/dev/null)
    
    # Build formatted output
    printf "\n%s — %s\n" "$command" "$summary"
    printf "%s\n" "================================================================================"
    [[ -n "$version" && "$version" != "null" ]] && printf "Constitution Version: %s\n" "$version"
    printf "\n"
    
    # Usage section
    printf "\n%s\n" "Usage"
    printf "%s\n" "-----"
    local usage=$(yq e '.short_help.usage' "$help_file" 2>/dev/null)
    [[ -n "$usage" && "$usage" != "null" ]] && printf "  %s\n" "$usage"
    
    # Sections (commands, world_types, global_options, etc.)
    local section_keys=$(yq e '.sections | keys | .[]' "$help_file" 2>/dev/null)
    if [[ -n "$section_keys" && "$section_keys" != "null" ]]; then
        while IFS= read -r section_key; do
            [[ -z "$section_key" || "$section_key" == "null" ]] && continue
            
            local title=$(yq e ".sections.$section_key.title" "$help_file" 2>/dev/null)
            local content=$(yq e ".sections.$section_key.content" "$help_file" 2>/dev/null)
            
            [[ -z "$title" || "$title" == "null" ]] && continue
            
            printf "\n\n%s\n" "$title"
            printf "%s\n" "-----------"
            [[ -n "$content" && "$content" != "null" ]] && echo "$content"
        done <<< "$section_keys"
    fi
    
    # Examples (first 3 only for short help)
    printf "\n\n%s\n" "Quick Examples"
    printf "%s\n" "--------------"
    yq e '.examples[:3] | .[] | "  " + .command + "\n    " + .description' "$help_file" 2>/dev/null | head -15
    
    # Footer
    local related=$(yq e '.related_commands[0]' "$help_file" 2>/dev/null)
    if [[ -n "$related" && "$related" != "null" ]]; then
        printf "\n%s\n" "Use '$related' for world-specific help"
        printf "%s\n" "Use 'dirforge --help-long' for comprehensive documentation"
    fi
    printf "\n"
    
    return 0
}

################################################################################
# _format_long_help()
#
# Format long help variant (complete details)
#
# Parameters:
#   $1: Help file name (without .yaml extension)
#
# Output:
#   Formatted long help to STDOUT
#
################################################################################
_format_long_help() {
    local help_name="${1:?Error: help_name required}"
    
    # Check if yq is available
    if ! command -v yq &>/dev/null; then
        printf "%s\n" "Warning: yq not found. Install it for YAML help support." >&2
        printf "%s\n" "Falling back to basic help..." >&2
        return 1
    fi
    
    # Detect the correct base directory
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local base_dir
    
    if [[ -d "$script_dir/../templates/help" ]]; then
        base_dir="$script_dir/.."
    elif [[ -d "$script_dir/templates/help" ]]; then
        base_dir="$script_dir"
    else
        base_dir="$script_dir/.."
    fi
    
    local help_file="$base_dir/templates/help/${help_name}.yaml"
    
    if [[ ! -f "$help_file" ]]; then
        printf "%s\n" "Help file not found: $help_file" >&2
        return 1
    fi
    
    # Extract data using yq
    local command description
    command=$(yq e '.command' "$help_file" 2>/dev/null)
    description=$(yq e '.description' "$help_file" 2>/dev/null)
    local version=$(yq e '.constitution_section // .updated' "$help_file" 2>/dev/null)
    
    # Header
    printf "\n%s\n" "================================================================================"
    printf "%s\n" "$command"
    printf "%s\n" "================================================================================"
    [[ -n "$version" && "$version" != "null" ]] && printf "Constitution Version: %s\n" "$version"
    printf "\n"
    [[ -n "$description" && "$description" != "null" ]] && printf "%s\n\n" "$description"
    
    # Syntax
    local syntax=$(yq e '.syntax' "$help_file" 2>/dev/null)
    if [[ -n "$syntax" && "$syntax" != "null" ]]; then
        echo "SYNTAX"
        echo "------"
        while IFS= read -r line; do
            echo "  $line"
        done <<< "$syntax"
        echo ""
    fi
    
    # Sections (commands, options, etc.)
    local section_keys=$(yq e '.sections | keys | .[]' "$help_file" 2>/dev/null)
    if [[ -n "$section_keys" && "$section_keys" != "null" ]]; then
        while IFS= read -r section_key; do
            [[ -z "$section_key" || "$section_key" == "null" ]] && continue
            
            local title=$(yq e ".sections.$section_key.title" "$help_file" 2>/dev/null)
            local content=$(yq e ".sections.$section_key.content" "$help_file" 2>/dev/null)
            
            [[ -z "$title" || "$title" == "null" ]] && continue
            
            echo "${title}" | tr '[:lower:]' '[:upper:]'
            printf "%s\n" "$(printf '%*s' ${#title} '' | tr ' ' '-')"
            [[ -n "$content" && "$content" != "null" ]] && echo "$content"
            printf "\n"
        done <<< "$section_keys"
    fi
    
    # Examples
    local has_examples=$(yq e '.examples | length' "$help_file" 2>/dev/null)
    if [[ "$has_examples" != "0" && "$has_examples" != "null" ]]; then
        echo "EXAMPLES"
        echo "--------"
        local example_count=$(yq e '.examples | length' "$help_file" 2>/dev/null)
        for ((i=0; i<example_count; i++)); do
            local ex_title=$(yq e ".examples[$i].title" "$help_file" 2>/dev/null)
            local ex_command=$(yq e ".examples[$i].command" "$help_file" 2>/dev/null)
            local ex_desc=$(yq e ".examples[$i].description" "$help_file" 2>/dev/null)
            
            if [[ -n "$ex_title" && "$ex_title" != "null" ]]; then
                echo ""
                echo "$ex_title:"
            fi
            [[ -n "$ex_command" && "$ex_command" != "null" ]] && echo "  \$ $ex_command"
            [[ -n "$ex_desc" && "$ex_desc" != "null" ]] && echo "  $ex_desc"
        done
        echo ""
    fi
    
    # Related commands
    local has_related=$(yq e '.related_commands | length' "$help_file" 2>/dev/null)
    if [[ "$has_related" != "0" && "$has_related" != "null" ]]; then
        echo "SEE ALSO"
        echo "--------"
        yq e '.related_commands[]' "$help_file" 2>/dev/null | while read -r cmd; do
            [[ -n "$cmd" && "$cmd" != "null" ]] && echo "  $cmd"
        done
        echo ""
    fi
    
    # See also documentation
    local has_see_also=$(yq e '.see_also | length' "$help_file" 2>/dev/null)
    if [[ "$has_see_also" != "0" && "$has_see_also" != "null" ]]; then
        echo "DOCUMENTATION"
        echo "-------------"
        yq e '.see_also[]' "$help_file" 2>/dev/null | while read -r doc; do
            [[ -n "$doc" && "$doc" != "null" ]] && echo "  $doc"
        done
        echo ""
    fi
    
    return 0
}

################################################################################
# _cache_help_file()
#
# Cache parsed help file for performance
#
# Parameters:
#   $1: Help file name (without extension)
#   $2: Help file content
#
# Returns:
#   0 always (caching is non-critical)
#
################################################################################
_cache_help_file() {
    local help_name="${1:?Error: help_name required}"
    local content="${2:?Error: content required}"
    
    if [[ "$HELP_CACHE_ENABLED" != "1" ]]; then
        return 0
    fi
    
    _init_help_cache
    
    if [[ ! -d "$HELP_CACHE_DIR" ]]; then
        return 0  # Caching disabled if directory cannot be created
    fi
    
    printf "%s" "$content" > "$HELP_CACHE_DIR/${help_name}.cache" 2>/dev/null || true
    return 0
}

################################################################################
# _get_cached_help()
#
# Retrieve help from cache if available and fresh
#
# Parameters:
#   $1: Help file name (without extension)
#
# Returns:
#   0 if cache hit and fresh
#   1 if cache miss or stale
#
# Output:
#   Cached help content to STDOUT
#
################################################################################
_get_cached_help() {
    local help_name="${1:?Error: help_name required}"
    
    if [[ "$HELP_CACHE_ENABLED" != "1" ]]; then
        return 1
    fi
    
    local cache_file="$HELP_CACHE_DIR/${help_name}.cache"
    
    if [[ ! -f "$cache_file" ]]; then
        return 1
    fi
    
    # Check cache freshness
    local cache_age=$(($(date +%s) - $(stat -f%m "$cache_file" 2>/dev/null || echo 0)))
    
    if [[ $cache_age -lt $HELP_CACHE_TTL ]]; then
        cat "$cache_file"
        return 0
    fi
    
    return 1
}

################################################################################
# Module initialization
################################################################################

_init_help_cache

################################################################################
# Export public functions for use by other scripts
################################################################################

# Note: In Bash, functions are automatically available in the current shell
# and child shells when sourced. These comments document the public API.
#
# Public API:
#   - load_help_yaml()          Load help YAML file
#   - get_help_section()        Extract sections from help
#   - get_command_help()        Get formatted command help
#   - get_global_help()         Get global help menu
#   - format_help_output()      Format help for display
#
# Internal API (prefixed with _):
#   - _format_short_help()      Format short help variant
#   - _format_long_help()       Format long help variant
#   - _cache_help_file()        Cache help file
#   - _get_cached_help()        Get cached help
#   - _init_help_cache()        Initialize cache directory

