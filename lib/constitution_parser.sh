#!/usr/bin/env bash
# lib/constitution_parser.sh - Parse DirForge Constitution for world structure definitions
# Part of constitutional compliance validation system

# Constitution parser library for extracting world structure definitions
# from Constitution markdown file per DirForge Constitution v1.0.17

# Global variables for constitution parsing
CONSTITUTION_FILE=""
CONSTITUTION_VERSION=""

# Initialize constitution parser with file path
init_constitution_parser() {
    local constitution_path="${1:-}"
    
    if [ -z "$constitution_path" ]; then
        # Try to find constitution file in standard locations
        local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        local possible_paths=(
            "$script_dir/../.specify/memory/constitution.md"
            "$script_dir/../constitution.md"
            "./constitution.md"
            "./.specify/memory/constitution.md"
        )
        
        for path in "${possible_paths[@]}"; do
            if [ -f "$path" ]; then
                constitution_path="$path"
                break
            fi
        done
    fi
    
    if [ -z "$constitution_path" ] || [ ! -f "$constitution_path" ]; then
        echo "ERROR: Constitution file not found" >&2
        echo "Searched paths:" >&2
        for path in "${possible_paths[@]:-}"; do
            echo "  $path" >&2
        done
        if [ -n "$1" ]; then
            echo "  $1 (provided path)" >&2
        fi
        echo "Please provide a valid constitution file path or ensure the file exists in a standard location." >&2
        return 1
    fi
    
    # Validate file is readable
    if [ ! -r "$constitution_path" ]; then
        echo "ERROR: Constitution file is not readable: $constitution_path" >&2
        echo "Check file permissions." >&2
        return 1
    fi
    
    # Validate file is not empty
    if [ ! -s "$constitution_path" ]; then
        echo "ERROR: Constitution file is empty: $constitution_path" >&2
        return 1
    fi
    
    CONSTITUTION_FILE="$constitution_path"
    
    # Extract constitution version with error handling
    CONSTITUTION_VERSION=$(grep -o 'Constitution v[0-9]\+\.[0-9]\+\.[0-9]\+' "$CONSTITUTION_FILE" 2>/dev/null | head -n1 | sed 's/Constitution //')
    if [ -z "$CONSTITUTION_VERSION" ]; then
        # Try alternative version patterns
        CONSTITUTION_VERSION=$(grep -o 'Version.*[0-9]\+\.[0-9]\+\.[0-9]\+' "$CONSTITUTION_FILE" 2>/dev/null | head -n1 | sed 's/.*Version.*\([0-9]\+\.[0-9]\+\.[0-9]\+\).*/\1/')
        if [ -z "$CONSTITUTION_VERSION" ]; then
            echo "WARNING: Could not extract constitution version from file" >&2
            CONSTITUTION_VERSION="unknown"
        fi
    fi
    
    # Validate constitution has required sections
    validate_constitution_file || return 1
    
    return 0
}

# Parse constitution structure for a specific world type
# Usage: parse_world_structure "WORLD_TYPE"
# Returns: Tab-separated lines of folder_name<TAB>description
parse_world_structure() {
    local world_type="$1"
    
    if [ -z "$world_type" ]; then
        echo "ERROR: World type is required" >&2
        echo "Usage: parse_world_structure WORLD_TYPE" >&2
        return 1
    fi
    
    if [ -z "$CONSTITUTION_FILE" ]; then
        echo "ERROR: Constitution parser not initialized. Call init_constitution_parser first." >&2
        return 1
    fi
    
    if [ ! -f "$CONSTITUTION_FILE" ]; then
        echo "ERROR: Constitution file not found: $CONSTITUTION_FILE" >&2
        echo "Re-run init_constitution_parser to reinitialize." >&2
        return 1
    fi
    
    case "$world_type" in
        "CODING_WORLD")
            # Section III.I - flat structure with language categories
            local result
            result=$(grep -A 20 "#### III.I CODING_WORLD" "$CONSTITUTION_FILE" 2>/dev/null | \
            grep "^-- \`" | \
            sed 's/^-- `\([^`]*\)`.*$/\1\tLanguage-specific development environment/')
            
            if [ -z "$result" ]; then
                echo "ERROR: Could not parse CODING_WORLD structure from constitution" >&2
                return 1
            fi
            echo "$result"
            ;;
        "JOURNAL_WORLD")
            # Section III.II - flexible nested structure
            echo "JOURNAL_NAME/ID/manuscript	manuscript drafts, revisions, final versions, or papers under review"
            echo "JOURNAL_NAME/ID/reviews	peer review reports, reviewer comments, review responses, or your own review work"
            echo "JOURNAL_NAME/ID/correspondence	editorial communications, acceptance letters, publication correspondence, or reviewer instructions"
            ;;
        "LECTURE_WORLD")
            # Section III.VI - numbered project structure
            local result
            result=$(grep -A 30 "#### III.VI Lecture" "$CONSTITUTION_FILE" 2>/dev/null | \
            grep "^- \`[0-9]" | \
            sed 's/^- `\([^`]*\)` — \(.*\)$/\1\t\2/')
            
            if [ -z "$result" ]; then
                echo "ERROR: Could not parse LECTURE_WORLD structure from constitution" >&2
                return 1
            fi
            echo "$result"
            ;;
        "LITERATURE_WORLD")
            # No specific structure defined in constitution
            echo "# No specific structure defined in Constitution $CONSTITUTION_VERSION"
            ;;
        "OFFICE_WORLD")
            # Section III.III - numbered office folders
            local result
            result=$(grep -A 15 "#### III.III Office" "$CONSTITUTION_FILE" 2>/dev/null | \
            grep "^- \`[0-9]" | \
            sed 's/^- `\([^`]*\)` — \(.*\)$/\1\t\2/')
            
            if [ -z "$result" ]; then
                echo "ERROR: Could not parse OFFICE_WORLD structure from constitution" >&2
                return 1
            fi
            echo "$result"
            ;;
        "PRIVATE_WORLD")
            # Section III.IV - personal folders with substructure
            local result
            result=$(grep -A 50 "#### III.IV Private" "$CONSTITUTION_FILE" 2>/dev/null | \
            grep -E "^- \`[0-9]|^-- \`[0-9]" | \
            sed 's/^-- \?`\([^`]*\)`[^—]*— \?\(.*\)$/\1\t\2/' | \
            sed 's/^- `\([^`]*\)`[^—]*— \?\(.*\)$/\1\t\2/')
            
            if [ -z "$result" ]; then
                echo "ERROR: Could not parse PRIVATE_WORLD structure from constitution" >&2
                return 1
            fi
            echo "$result"
            ;;
        "RESEARCH_WORLD")
            # Section III.V - project-based numbered structure
            local result
            result=$(grep -A 30 "Each research activity" "$CONSTITUTION_FILE" 2>/dev/null | \
            grep "^- \`RESEARCH_WORLD" | \
            sed 's/^- `RESEARCH_WORLD\/<PROJECT-ID>\/\([^`]*\)` — \(.*\)$/\1\t\2/')
            
            if [ -z "$result" ]; then
                echo "ERROR: Could not parse RESEARCH_WORLD structure from constitution" >&2
                return 1
            fi
            echo "$result"
            ;;
        *)
            echo "ERROR: Unknown world type: $world_type" >&2
            echo "Valid world types: CODING_WORLD, JOURNAL_WORLD, LECTURE_WORLD, LITERATURE_WORLD, OFFICE_WORLD, PRIVATE_WORLD, RESEARCH_WORLD" >&2
            return 1
            ;;
    esac
}

# Main constitution parsing function - extracts all world structures
# Usage: parse_constitution_structure
# Returns: JSON-like structure with all world definitions
parse_constitution_structure() {
    if [ -z "$CONSTITUTION_FILE" ]; then
        echo "ERROR: Constitution parser not initialized. Call init_constitution_parser first." >&2
        return 1
    fi
    
    if [ ! -f "$CONSTITUTION_FILE" ]; then
        echo "ERROR: Constitution file not found: $CONSTITUTION_FILE" >&2
        return 1
    fi
    
    local worlds=(
        "CODING_WORLD"
        "JOURNAL_WORLD" 
        "LECTURE_WORLD"
        "LITERATURE_WORLD"
        "OFFICE_WORLD"
        "PRIVATE_WORLD"
        "RESEARCH_WORLD"
    )
    
    local failed_worlds=()
    local total_errors=0
    
    echo "# Constitution Structure Analysis"
    echo "# Constitution Version: $CONSTITUTION_VERSION"
    echo "# Generated: $(date)"
    echo "# Source: $CONSTITUTION_FILE"
    echo
    
    for world in "${worlds[@]}"; do
        echo "[$world]"
        
        local structure
        structure=$(parse_world_structure "$world" 2>/dev/null)
        local parse_status=$?
        
        if [ $parse_status -eq 0 ] && [ -n "$structure" ]; then
            echo "$structure"
        else
            echo "# ERROR: Failed to parse structure for $world"
            failed_worlds+=("$world")
            total_errors=$((total_errors + 1))
        fi
        echo
    done
    
    # Report any failures
    if [ $total_errors -gt 0 ]; then
        echo "# PARSING ERRORS SUMMARY:" >&2
        echo "# Failed to parse $total_errors world(s): ${failed_worlds[*]}" >&2
        echo "# Check constitution file format and structure" >&2
        return 1
    fi
    
    return 0
}

# Get constitution version
get_constitution_version() {
    echo "$CONSTITUTION_VERSION"
}

# Get constitution file path
get_constitution_file() {
    echo "$CONSTITUTION_FILE"
}

# Validate that constitution file contains expected sections
validate_constitution_file() {
    if [ -z "$CONSTITUTION_FILE" ] || [ ! -f "$CONSTITUTION_FILE" ]; then
        echo "ERROR: Constitution file not available" >&2
        return 1
    fi
    
    local required_sections=(
        "#### III.I CODING_WORLD"
        "#### III.II Journal"
        "#### III.III Office"
        "#### III.IV Private"
        "#### III.V Research"
        "#### III.VI Lecture"
    )
    
    local missing_sections=0
    
    for section in "${required_sections[@]}"; do
        if ! grep -q "$section" "$CONSTITUTION_FILE"; then
            echo "ERROR: Missing section: $section" >&2
            missing_sections=$((missing_sections + 1))
        fi
    done
    
    if [ $missing_sections -gt 0 ]; then
        echo "ERROR: Constitution file is missing $missing_sections required sections" >&2
        return 1
    fi
    
    echo "Constitution file validation: PASSED"
    return 0
}

# Extract folder count for a world type
get_world_folder_count() {
    local world_type="$1"
    
    local structure
    structure=$(parse_world_structure "$world_type" 2>/dev/null)
    
    if [ $? -ne 0 ] || [ -z "$structure" ]; then
        echo "0"
        return 1
    fi
    
    # Count non-comment lines
    echo "$structure" | grep -v "^#" | wc -l | tr -d ' '
}

# Check if a world should have subfolders during workspace initialization
world_has_subfolders_at_init() {
    local world_type="$1"
    
    case "$world_type" in
        "OFFICE_WORLD"|"PRIVATE_WORLD")
            echo "true"
            ;;
        "CODING_WORLD"|"JOURNAL_WORLD"|"LECTURE_WORLD"|"RESEARCH_WORLD"|"LITERATURE_WORLD")
            echo "false"
            ;;
        *)
            echo "unknown"
            return 1
            ;;
    esac
}

# Get expected subfolder names for a world (first-level only)
get_world_subfolders() {
    local world_type="$1"
    
    local structure
    structure=$(parse_world_structure "$world_type" 2>/dev/null)
    
    if [ $? -ne 0 ] || [ -z "$structure" ]; then
        return 1
    fi
    
    # Extract just the folder names (before tab)
    echo "$structure" | grep -v "^#" | cut -d$'\t' -f1 | grep -E "^[0-9]" | head -20
}