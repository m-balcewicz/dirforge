#!/usr/bin/env bash
# help.sh - Help content formatting and display utilities
# Part of the Enhanced Terminal Help System for dirforge

set -euo pipefail

# Source required libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/terminal.sh"
source "$SCRIPT_DIR/colors.sh"

# Initialize colors on library load
init_colors

# Pager configuration
PAGER_THRESHOLD=150  # Number of lines before triggering pager (high threshold for help UX)
MAX_HELP_WIDTH=100  # Maximum width for help content (improves readability)

# Performance optimization: Help content cache
# Note: Using simple cache with prefix-based keys instead of associative arrays for compatibility
HELP_CACHE_ENABLED=true
HELP_CACHE_MAX_SIZE=50  # Maximum cache entries
HELP_CACHE_DIR="/tmp/dirforge_help_cache_$$"

# Cleanup cache on exit
cleanup_help_cache() {
    if [[ -d "$HELP_CACHE_DIR" ]]; then
        rm -rf "$HELP_CACHE_DIR"
    fi
}
trap cleanup_help_cache EXIT

# Cache management functions
_cache_key() {
    local type="$1"
    shift
    echo "${type}_$(printf '%s_' "$@" | sed 's/_$//')"
}

_cache_get() {
    local key="$1"
    local cache_file="$HELP_CACHE_DIR/$key"
    if [[ "$HELP_CACHE_ENABLED" == "true" && -f "$cache_file" ]]; then
        cat "$cache_file"
        return 0
    fi
    return 1
}

_cache_set() {
    local key="$1"
    local content="$2"
    
    if [[ "$HELP_CACHE_ENABLED" == "true" ]]; then
        # Create cache directory if needed
        mkdir -p "$HELP_CACHE_DIR"
        
        # Simple cache size management: clear if too many files
        local file_count
        file_count=$(find "$HELP_CACHE_DIR" -type f 2>/dev/null | wc -l | tr -d ' ')
        if [[ ${file_count} -ge $HELP_CACHE_MAX_SIZE ]]; then
            rm -rf "$HELP_CACHE_DIR"
            mkdir -p "$HELP_CACHE_DIR"
        fi
        
        echo "$content" > "$HELP_CACHE_DIR/$key"
    fi
}

# Clear help cache (useful for testing or when scaffolder changes)
clear_help_cache() {
    rm -rf "$HELP_CACHE_DIR"
}

# Disable help caching (for debugging)
disable_help_cache() {
    HELP_CACHE_ENABLED=false
}

# Get effective width for help content (constrained for readability)
get_help_width() {
    local terminal_width
    terminal_width=$(get_terminal_width)
    
    # Use smaller of terminal width or max help width for better readability
    if [[ $terminal_width -gt $MAX_HELP_WIDTH ]]; then
        echo $MAX_HELP_WIDTH
    else
        echo $terminal_width
    fi
}

# Detect if we should use a pager for output
# Returns 0 if pager should be used, 1 otherwise
should_use_pager() {
    local content="$1"
    local line_count
    line_count=$(echo -e "$content" | wc -l | tr -d ' ')
    local terminal_height
    terminal_height=$(get_terminal_height)
    
    # Don't use pager if:
    # - Output is redirected (not a terminal)
    # - Content is short enough
    # - PAGER is explicitly disabled
    # - Running in CI/automation (detected by CI env vars)
    if [[ ! -t 1 ]] || \
       [[ ${line_count} -le ${PAGER_THRESHOLD} ]] || \
       [[ ${line_count} -le $((terminal_height - 5)) ]] || \
       [[ "${PAGER:-}" == "cat" ]] || \
       [[ "${PAGER:-}" == "" && "${TERM:-}" == "dumb" ]] || \
       [[ -n "${CI:-}" || -n "${GITHUB_ACTIONS:-}" || -n "${JENKINS_URL:-}" ]]; then
        return 1  # Don't use pager
    fi
    
    return 0  # Use pager
}

# Get the best available pager command
get_pager_command() {
    # Honor user's PAGER setting if available
    if [[ -n "${PAGER:-}" && "${PAGER}" != "cat" ]]; then
        echo "$PAGER"
        return
    fi
    
    # Try common pagers in order of preference
    local pagers=("less -R" "more" "cat")
    for pager in "${pagers[@]}"; do
        local cmd
        cmd=$(echo "$pager" | cut -d' ' -f1)
        if command -v "$cmd" >/dev/null 2>&1; then
            echo "$pager"
            return
        fi
    done
    
    # Fallback to cat
    echo "cat"
}

# Display content with automatic pager integration
# Usage: display_with_pager "content" [force_pager]
display_with_pager() {
    local content="$1"
    local force_pager="${2:-false}"
    
    # If force_pager is true, always use pager (unless output redirected)
    if [[ "$force_pager" == "true" && -t 1 ]]; then
        local pager_cmd
        pager_cmd=$(get_pager_command)
        echo -e "$content" | $pager_cmd
        return
    fi
    
    # Auto-detect if pager is needed
    if should_use_pager "$content"; then
        local pager_cmd
        pager_cmd=$(get_pager_command)
        echo -e "$content" | $pager_cmd
    else
        echo -e "$content"
    fi
}

# Format header with level-based styling
# Usage: format_header "Header Text" [level]
# Level 1: Main title (bold, larger)
# Level 2: Section header (bold)
# Level 3: Subsection header (normal)
format_header() {
    local text="$1"
    local level="${2:-1}"
    local width
    width=$(get_help_width)
    
    case "$level" in
        1)
            # Main title: bold with separator line
            echo
            echo "$(bold "$text")"
            printf "%*s\n" "$width" "" | tr ' ' '='
            echo
            ;;
        2)
            # Section header: bold with underline
            echo
            echo "$(bold "$text")"
            printf "%*s\n" "${#text}" "" | tr ' ' '-'
            echo
            ;;
        3)
            # Subsection header: just bold
            echo
            echo "$(bold "$text")"
            ;;
        *)
            # Default: plain text
            echo "$text"
            ;;
    esac
}

# Format command syntax with highlighting
# Usage: format_command "command" [description]
format_command() {
    local command="$1"
    local description="${2:-}"
    local width
    width=$(get_help_width)
    
    # Highlight the command in cyan/blue
    local formatted_cmd
    formatted_cmd=$(cyan "$command")
    
    if [[ -n "$description" ]]; then
        # Use a more conservative approach - always use two-line format for clarity
        # This avoids line wrapping issues and provides consistent formatting
        printf "  %s\n" "$formatted_cmd"
        printf "    %s\n" "$(dim "$description")"
    else
        printf "  %s\n" "$formatted_cmd"
    fi
}

# Format example block with indentation and styling
# Usage: format_example "example_text" [title]
format_example() {
    local example="$1"
    local title="${2:-Example}"
    
    echo
    echo "$(dim "$title:")"
    echo
    # Indent each line of the example
    while IFS= read -r line; do
        printf "  %s\n" "$(gray "$line")"
    done <<< "$example"
    echo
}

# Format directory tree with ASCII characters
# Usage: format_directory_tree "tree_content"
format_directory_tree() {
    local tree_content="$1"
    local width
    width=$(get_terminal_width)
    
    # Add line break before tree content
    echo
    
    # Ensure tree fits within terminal width
    while IFS= read -r line; do
        if [[ ${#line} -gt $((width - 4)) ]]; then
            # Truncate long lines
            printf "  %s...\n" "${line:0:$((width - 7))}"
        else
            # Colorize tree characters and directories
            local formatted_line="$line"
            # Color tree branches
            formatted_line=$(echo "$formatted_line" | sed -E "s/([├└│─┬┐┌┘]+)/$(printf '\033[90m')\\1$(printf '\033[0m')/g")
            # Color directories (ending with /)
            formatted_line=$(echo "$formatted_line" | sed -E "s/([^/]+\/)/$(printf '\033[34m')\\1$(printf '\033[0m')/g")
            printf "  %s\n" "$formatted_line"
        fi
    done <<< "$tree_content"
    echo
}

# Extract directory structure dynamically from scaffolder code
# Usage: extract_directory_structure "world_type"
extract_directory_structure() {
    local world_type="$1"
    local dirforge_tool="$SCRIPT_DIR/../tools/dirforge"
    
    # Return static fallback if scaffolder not available
    if [[ ! -f "$dirforge_tool" ]]; then
        echo "Directory structure not available (scaffolder not found)"
        return 1
    fi
    
    # Extract directory creation patterns from scaffolder
    case "$world_type" in
        "research")
            # Extract from init_research function
            grep -A 30 "^init_research()" "$dirforge_tool" | \
            grep -E "(do_mkdir_p|for d in)" | \
            sed -E 's/.*do_mkdir_p[^"]*"([^"]*).*/\1/' | \
            sed -E 's/.*for d in ([^;]*); do.*/\1/' | \
            tr ' ' '\n' | \
            grep -v "^$" | \
            sort | \
            uniq
            ;;
        "lecture")
            # Extract from init_lecture function  
            grep -A 20 "^init_lecture()" "$dirforge_tool" | \
            grep -E "(do_mkdir_p|for d in)" | \
            sed -E 's/.*do_mkdir_p[^"]*"([^"]*).*/\1/' | \
            sed -E 's/.*for d in ([^;]*); do.*/\1/' | \
            tr ' ' '\n' | \
            grep -v "^$" | \
            sort | \
            uniq
            ;;
        "coding")
            # Extract from init_coding function
            grep -A 15 "^init_coding()" "$dirforge_tool" | \
            grep -E "(do_mkdir_p)" | \
            sed -E 's/.*do_mkdir_p[^"]*"([^"]*).*/\1/' | \
            tr ' ' '\n' | \
            grep -v "^$" | \
            sort | \
            uniq
            ;;
        *)
            echo "Directory structure extraction not implemented for $world_type"
            return 1
            ;;
    esac
}

# Generate directory tree from scaffolder code dynamically
# Usage: generate_dynamic_tree "world_type" [project_name]
generate_dynamic_tree() {
    local world_type="$1"
    local project_name="${2:-example-project}"
    
    # Check cache first
    local cache_key
    cache_key=$(_cache_key "tree" "$world_type" "$project_name")
    local cached_content
    if cached_content=$(_cache_get "$cache_key"); then
        echo "$cached_content"
        return
    fi
    
    local tree_content=""
    
    # Try dynamic extraction first, fall back to static if needed
    local dirforge_tool="$SCRIPT_DIR/../tools/dirforge"
    
    if [[ -f "$dirforge_tool" ]]; then
        case "$world_type" in
            "research")
                # Extract directories dynamically from scaffolder
                local dirs
                dirs=$(grep -A 30 "^init_research()" "$dirforge_tool" | \
                       grep -E "(for d in|do_mkdir_p.*RESEARCH_ROOT)" | \
                       sed -E 's/.*for d in ([^;]*); do.*/\1/' | \
                       sed -E 's/.*do_mkdir_p.*RESEARCH_ROOT\/([^"]*).*/\1/' | \
                       tr ' ' '\n' | \
                       grep -v "^$" | \
                       grep -v "RESEARCH_ROOT" | \
                       sort | \
                       uniq)
                
                if [[ -n "$dirs" ]]; then
                    tree_content+="RESEARCH_WORLD/\n"
                    tree_content+="└── 2025_project_name/\n"
                    local dir_array=()
                    while IFS= read -r dir; do
                        [[ -n "$dir" ]] && dir_array+=("$dir")
                    done <<< "$dirs"
                    
                    local i=0
                    for dir in "${dir_array[@]}"; do
                        i=$((i + 1))
                        if [[ $i -eq ${#dir_array[@]} ]]; then
                            tree_content+="    └── $dir/\n"
                        else
                            tree_content+="    ├── $dir/\n"
                        fi
                        
                        # Add special files for certain directories
                        if [[ "$dir" == "05_data_analysis" ]]; then
                            tree_content+="    │   └── environment.yml\n"
                        elif [[ "$dir" == ".integrity" ]]; then
                            tree_content+="    │   ├── checksums/\n"
                            tree_content+="    │   └── manifests/\n"
                        fi
                    done
                    
                    # Add standard files
                    tree_content+="    ├── README.md\n"
                    tree_content+="    └── project.yaml"
                    
                    # Cache and return
                    _cache_set "$cache_key" "$tree_content"
                    echo -e "$tree_content"
                    return
                fi
                ;;
            "lecture")
                # Extract directories dynamically from scaffolder
                local dirs
                dirs=$(grep -A 30 "^init_lecture()" "$dirforge_tool" | \
                       grep -E "(for d in|do_mkdir_p.*LECTURE_ROOT)" | \
                       sed -E 's/.*for d in ([^;]*); do.*/\1/' | \
                       sed -E 's/.*do_mkdir_p.*LECTURE_ROOT\/([^"]*).*/\1/' | \
                       tr ' ' '\n' | \
                       grep -v "^$" | \
                       grep -v "LECTURE_ROOT" | \
                       sort | \
                       uniq)
                
                if [[ -n "$dirs" ]]; then
                    tree_content+="LECTURE_WORLD/\n"
                    tree_content+="└── course_name/\n"
                    local dir_array=()
                    while IFS= read -r dir; do
                        [[ -n "$dir" ]] && dir_array+=("$dir")
                    done <<< "$dirs"
                    
                    local i=0
                    for dir in "${dir_array[@]}"; do
                        i=$((i + 1))
                        if [[ $i -eq ${#dir_array[@]} ]]; then
                            tree_content+="    └── $dir/\n"
                        else
                            tree_content+="    ├── $dir/\n"
                        fi
                        
                        # Add special subdirectories for exercises and exams
                        if [[ "$dir" == "05_exercises" || "$dir" == "06_exams" ]]; then
                            tree_content+="    │   ├── problems/\n"
                            tree_content+="    │   ├── solutions/\n"
                            tree_content+="    │   ├── submissions/\n"
                            tree_content+="    │   └── graded/\n"
                        elif [[ "$dir" == "02_data" ]]; then
                            tree_content+="    │   ├── experimental_recordings/\n"
                            tree_content+="    │   └── reference/\n"
                        elif [[ "$dir" == ".integrity" ]]; then
                            tree_content+="    │   ├── checksums/\n"
                            tree_content+="    │   └── manifests/\n"
                        fi
                    done
                    
                    # Add standard files
                    tree_content+="    ├── README.md\n"
                    tree_content+="    └── project.yaml"
                    
                    # Cache and return
                    _cache_set "$cache_key" "$tree_content"
                    echo -e "$tree_content"
                    return
                fi
                ;;
            "coding")
                # Extract directories dynamically from scaffolder
                local dirs
                dirs=$(grep -A 20 "^init_coding()" "$dirforge_tool" | \
                       grep -E "do_mkdir_p.*CODING_ROOT" | \
                       sed -E 's/.*do_mkdir_p.*CODING_ROOT\/([^"]*).*/\1/' | \
                       tr ' ' '\n' | \
                       grep -v "^$" | \
                       grep -v "CODING_ROOT" | \
                       sort | \
                       uniq)
                
                if [[ -n "$dirs" ]]; then
                    tree_content+="CODING_WORLD/\n"
                    tree_content+="└── python/\n"
                    tree_content+="    └── project_name/\n"
                    local dir_array=()
                    while IFS= read -r dir; do
                        [[ -n "$dir" ]] && dir_array+=("$dir")
                    done <<< "$dirs"
                    
                    for dir in "${dir_array[@]}"; do
                        tree_content+="        ├── $dir/\n"
                    done
                    
                    # Add standard files
                    tree_content+="        ├── README.md\n"
                    tree_content+="        └── environment.yml"
                    
                    # Cache and return
                    _cache_set "$cache_key" "$tree_content"
                    echo -e "$tree_content"
                    return
                fi
                ;;
        esac
    fi
    
    # Fallback to static trees if dynamic extraction fails
    case "$world_type" in
        "research")
            tree_content=$(cat <<'EOF'
RESEARCH_WORLD/
└── 2025_project_name/
    ├── 01_project_management/
    ├── 02_admin/
    ├── 03_design_protocols/
    ├── 04_data/
    ├── 05_data_analysis/
    │   └── environment.yml
    ├── 06_data_outputs/
    ├── 07_publication/
    ├── 08_documentation/
    ├── .integrity/
    │   ├── checksums/
    │   └── manifests/
    ├── README.md
    └── project.yaml
EOF
)
            ;;
        "lecture")
            tree_content=$(cat <<'EOF'
LECTURE_WORLD/
└── course_name/
    ├── 00_admin/
    ├── 01_code/
    ├── 02_data/
    │   ├── experimental_recordings/
    │   └── reference/
    ├── 03_slides/
    ├── 04_manuscript/
    ├── 05_exercises/
    │   ├── problems/
    │   ├── solutions/
    │   ├── submissions/
    │   └── graded/
    ├── 06_exams/
    │   ├── problems/
    │   ├── solutions/
    │   ├── submissions/
    │   └── graded/
    ├── 07_grades/
    ├── .integrity/
    │   ├── checksums/
    │   └── manifests/
    ├── README.md
    └── project.yaml
EOF
)
            ;;
        "coding")
            tree_content=$(cat <<'EOF'
CODING_WORLD/
└── python/
    └── project_name/
        ├── src/
        ├── tests/
        ├── docs/
        ├── README.md
        └── environment.yml
EOF
)
            ;;
        "journal")
            tree_content=$(cat <<'EOF'
JOURNAL_WORLD/
└── JOURNAL_NAME/
    └── manuscript_id/
        ├── manuscript/
        ├── reviews/
        └── correspondence/
EOF
)
            ;;
        "office")
            tree_content=$(cat <<'EOF'
OFFICE_WORLD/
└── project_name/
    ├── documents/
    ├── contracts/
    ├── finance/
    └── equipment/
EOF
)
            ;;
        "private")
            tree_content=$(cat <<'EOF'
PRIVATE_WORLD/
└── project_name/
    ├── personal/
    ├── photos/
    ├── finance/
    └── sensitive/
EOF
)
            ;;
        *)
            tree_content="Basic directory structure for $world_type projects"
            ;;
    esac
    
    # Cache and return static content
    _cache_set "$cache_key" "$tree_content"
    echo "$tree_content"
}

# Wrap text to fit help width with proper indentation
# Usage: wrap_text "text" [indent_level]
wrap_text() {
    local text="$1"
    local indent_level="${2:-0}"
    local width
    width=$(get_help_width)
    local available_width=$((width - indent_level * 2))
    
    # Ensure minimum width
    if [[ $available_width -lt 20 ]]; then
        available_width=20
    fi
    
    local indent
    printf -v indent "%*s" $((indent_level * 2)) ""
    
    # Simple word wrapping
    local words
    read -ra words <<< "$text"
    local line="$indent"
    local line_length=$indent_level
    
    for word in "${words[@]}"; do
        local word_length=${#word}
        if [[ $((line_length + word_length + 1)) -gt $available_width && $line_length -gt $indent_level ]]; then
            echo "$line"
            line="$indent$word"
            line_length=$((indent_level + word_length))
        else
            if [[ $line_length -gt $indent_level ]]; then
                line="$line $word"
                line_length=$((line_length + word_length + 1))
            else
                line="$line$word"
                line_length=$((line_length + word_length))
            fi
        fi
    done
    
    if [[ $line_length -gt $indent_level ]]; then
        echo "$line"
    fi
}

# Format a list of items with bullets
# Usage: format_list "item1\nitem2\nitem3" [bullet_char]
format_list() {
    local items="$1"
    local bullet="${2:-}"
    
    # Add line break before list items
    echo
    
    while IFS= read -r item; do
        if [[ -n "$item" ]]; then
            if [[ -n "$bullet" ]]; then
                printf "  %s %s\n" "$(cyan "$bullet")" "$item"
            else
                printf "  %s\n" "$item"
            fi
        fi
    done <<< "$items"
}

# Format key-value pairs with alignment
# Usage: format_key_value "key1:value1\nkey2:value2"
format_key_value() {
    local pairs="$1"
    local max_key_length=0
    
    # Add line break before key-value pairs
    echo
    
    # Find the longest key for alignment
    while IFS=':' read -r key value; do
        if [[ ${#key} -gt $max_key_length ]]; then
            max_key_length=${#key}
        fi
    done <<< "$pairs"
    
    # Format each pair
    while IFS=':' read -r key value; do
        if [[ -n "$key" && -n "$value" ]]; then
            printf "  %s:%*s %s\n" "$(bold "$key")" $((max_key_length - ${#key} + 1)) "" "$value"
        fi
    done <<< "$pairs"
}

# Create a separator line
# Usage: separator [char] [length]
separator() {
    local char="${1:--}"
    local length="${2:-$(get_help_width)}"
    
    printf "%*s\n" "$length" "" | tr ' ' "$char"
}

# Format a box around text
# Usage: format_box "text content"
format_box() {
    local content="$1"
    local width
    width=$(get_help_width)
    local max_content_width=$((width - 4))
    
    # Create top border
    printf "┌%*s┐\n" $((max_content_width + 2)) "" | tr ' ' '─'
    
    # Format content lines
    while IFS= read -r line; do
        if [[ ${#line} -gt $max_content_width ]]; then
            # Wrap long lines
            local wrapped
            wrapped=$(wrap_text "$line" 0)
            while IFS= read -r wrapped_line; do
                printf "│ %-*s │\n" $max_content_width "$wrapped_line"
            done <<< "$wrapped"
        else
            printf "│ %-*s │\n" $max_content_width "$line"
        fi
    done <<< "$content"
    
    # Create bottom border
    printf "└%*s┘\n" $((max_content_width + 2)) "" | tr ' ' '─'
}

# Show global help - top-level help overview for dirforge
show_global_help() {
    local constitution_version="v1.0.17"
    
    # Check cache first
    local cache_key
    cache_key=$(_cache_key "global_help" "$constitution_version")
    local cached_content
    if cached_content=$(_cache_get "$cache_key"); then
        display_with_pager "$cached_content"
        return
    fi
    
    # Build help content first, then display with pager
    local help_content=""
    
    # Main header
    help_content+="$(format_header "dirforge" 1)"
    help_content+="\n"
    
    help_content+="Create standardized directory structures per DirForge Constitution\n"
    help_content+="\n"
    
    # Constitution version reference
    help_content+="$(printf "%s: %s\n" "$(bold "Constitution Version")" "$(cyan "$constitution_version")")\n"
    help_content+="\n"
    
    # Usage pattern
    help_content+="$(format_header "Usage" 2)"
    help_content+="\n"
    help_content+="$(format_command "dirforge <command> [options]")\n"
    help_content+="\n"
    
    # Available commands
    help_content+="$(format_header "Commands" 2)"
    help_content+="\n"
    help_content+="$(format_command "init <world-type>" "Create new project structure")\n"
    help_content+="\n"
    
    # Global options
    help_content+="$(format_header "Global Options" 2)"
    help_content+="\n"
    help_content+="$(format_command "--help, -h" "Show this help message")\n"
    help_content+="$(format_command "--version" "Show version information")\n"
    help_content+="$(format_command "--dry-run, --preview" "Preview changes without writing to filesystem")\n"
    help_content+="$(format_command "--json" "Output machine-readable JSON plan (requires --dry-run)")\n"
    help_content+="\n"
    
    # World types quick reference
    help_content+="$(format_header "World Types" 2)"
    help_content+="\n"
    help_content+="$(format_command "research" "Academic research projects with data management")\n"
    help_content+="$(format_command "lecture" "Educational content with grading workflows")\n"
    help_content+="$(format_command "coding" "Software development projects")\n"
    help_content+="$(format_command "journal" "Journal-related activities: submissions, reviews, editorial work")\n"
    help_content+="$(format_command "office" "Administrative and business documents")\n"
    help_content+="$(format_command "private" "Personal projects with privacy controls")\n"
    help_content+="\n"
    
    # Common usage examples
    help_content+="$(format_header "Examples" 2)"
    help_content+="\n"
    
    local examples="# Create research project with interactive prompts\ndirforge init research --title \"Thermal Analysis\"\n\n# Add study to existing research project\ndirforge init research --project \"2025_thermal_analysis\" --study \"Initial Model\"\n\n# Create lecture project structure\ndirforge init lecture --name \"Digital Rock Physics\"\n\n# Preview project creation with JSON output\ndirforge --dry-run init research --title \"Test\" | jq ."
    
    help_content+="$(format_example "$examples" "Common Usage")\n"
    
    # Footer with additional help info
    help_content+="$(format_header "More Information" 3)"
    help_content+="$(wrap_text "Use 'dirforge <command> --help' for detailed command information." 0)\n"
    help_content+="$(wrap_text "See constitution.md for governance and naming rules." 0)\n"
    help_content+="\n"
    help_content+="$(wrap_text "Constitution compliance ensures consistent project structures across teams and organizations." 0)\n"
    help_content+="\n"
    
    # Cache the content before displaying
    _cache_set "$cache_key" "$help_content"
    
    # Display with automatic pager integration
    display_with_pager "$help_content"
}

# Show command-specific help for the init command
show_command_help() {
    local command="$1"
    
    case "$command" in
        "init")
            show_init_command_help
            ;;
        *)
            echo "$(red "Error: Unknown command '$command'")"
            echo "Use 'dirforge --help' to see available commands."
            return 1
            ;;
    esac
}

# Show detailed help for the init command
show_init_command_help() {
    local constitution_version="v1.0.17"
    
    # Build help content first, then display with pager
    local help_content=""
    
    # Command header
    help_content+="$(format_header "dirforge init" 1)"
    help_content+="\n"
    
    help_content+="Create new project structure based on DirForge Constitution\n"
    help_content+="\n"
    
    # Usage pattern
    help_content+="$(format_header "Usage" 2)"
    help_content+="\n"
    help_content+="$(format_command "dirforge init <world-type> [options]")\n"
    help_content+="$(format_command "dirforge init <world-type> --help" "Show world-type specific help")\n"
    help_content+="\n"
    
    # Available world types with descriptions and constitution references
    help_content+="$(format_header "World Types" 2)"
    help_content+="\n"
    
    help_content+="$(format_command "research" "Academic research projects with data management")\n"
    help_content+="$(format_command "lecture" "Educational content with grading workflows")\n"
    help_content+="$(format_command "coding" "Software development projects")\n"
    help_content+="$(format_command "journal" "Journal-related activities: submissions, reviews, editorial work")\n"
    help_content+="$(format_command "office" "Administrative and business documents")\n"
    help_content+="$(format_command "private" "Personal projects with privacy controls")\n"
    help_content+="\n"
    
    # Common options
    help_content+="$(format_header "Common Options" 2)"
    help_content+="\n"
    help_content+="$(format_command "--help, -h" "Show help for this command or specific world type")\n"
    help_content+="$(format_command "--dry-run, --preview" "Preview directory structure without creating files")\n"
    help_content+="$(format_command "--force" "Overwrite existing directories (use with caution)")\n"
    help_content+="$(format_command "--backup" "Create backup of existing content before overwriting")\n"
    help_content+="$(format_command "--yes" "Skip interactive confirmations (use with --force or --backup)")\n"
    help_content+="$(format_command "--json" "Output machine-readable JSON plan (requires --dry-run)")\n"
    help_content+="$(format_command "--quiet, -q" "Suppress non-error output")\n"
    help_content+="$(format_command "--verbose, -v" "Show detailed progress information")\n"
    help_content+="\n"
    
    # World-type specific options note
    help_content+="$(format_header "World-Type Specific Options" 3)"
    help_content+="$(wrap_text "Each world type has additional options for customization. Use 'dirforge init <world-type> --help' to see specific options and requirements." 0)\n"
    help_content+="\n"
    
    # Examples
    help_content+="$(format_header "Examples" 2)"
    help_content+="\n"
    
    local examples="# Get help for research projects\ndirforge init research --help\n\n# Preview research project structure\ndirforge init research --title \"My Study\" --dry-run\n\n# Create lecture with backup of existing content\ndirforge init lecture --name \"Physics 101\" --backup\n\n# Create coding project with minimal output\ndirforge init coding --name \"my-app\" --quiet"
    
    help_content+="$(format_example "$examples" "Common Usage")\n"
    
    # Footer
    help_content+="$(format_header "Constitution Compliance" 3)"
    help_content+="$(wrap_text "All project structures follow DirForge Constitution $constitution_version for consistency across teams and organizations." 0)\n"
    help_content+="\n"
    help_content+="$(wrap_text "Use 'dirforge init <world-type> --help' for detailed world-specific information including directory trees, naming conventions, and required inputs." 0)\n"
    help_content+="\n"
    
    # Display with automatic pager integration
    display_with_pager "$help_content"
}

# Show world-specific help with routing to appropriate world type
show_world_help() {
    local world_type="$1"
    
    case "$world_type" in
        "research")
            show_research_help
            ;;
        "lecture")
            show_lecture_help
            ;;
        "coding")
            show_coding_help
            ;;
        "journal")
            show_journal_help
            ;;
        "office")
            show_office_help
            ;;
        "private")
            show_private_help
            ;;
        *)
            echo "$(red "Error: Unknown world type '$world_type'")"
            echo "Available world types: research, lecture, coding, journal, office, private"
            echo "Use 'dirforge init --help' to see all available world types."
            return 1
            ;;
    esac
}

# Research project help with directory structure and examples
show_research_help() {
    local constitution_version="v1.0.17"
    
    # Check cache first
    local cache_key
    cache_key=$(_cache_key "research_help" "$constitution_version")
    local cached_content
    if cached_content=$(_cache_get "$cache_key"); then
        display_with_pager "$cached_content"
        return
    fi
    
    # Build help content first, then display with pager (force pager for long content)
    local help_content=""
    
    help_content+="$(format_header "Research Project Creation" 1)"
    help_content+="\n"
    help_content+="Academic research projects with study-based organization\n"
    help_content+="Updated: 2025-12-10 (Constitution $constitution_version)\n"
    help_content+="\n"
    
    # Purpose and compliance
    help_content+="$(format_header "Purpose" 2)"
    help_content+="\n"
    help_content+="$(wrap_text "Creates standardized research project with study-based organization. Each project contains independent studies with complete data analysis workflows. Follows project-by-activity principle with co-located provenance for reproducible research." 0)\n"
    help_content+="\n"
    
    # Usage
    help_content+="$(format_header "Usage" 2)"
    help_content+="\n"
    help_content+="$(format_command "dirforge init research [options]")\n"
    help_content+="$(format_command "dirforge init research --title \"Project Name\"")\n"
    help_content+="$(format_command "dirforge init research --project \"PROJECT_ID\" --study \"Study Name\"")\n"
    help_content+="\n"
    
    # Required inputs
    help_content+="$(format_header "Required Options" 2)"
    help_content+="\n"
    help_content+="$(format_command "--title \"Project Title\"" "Create new project (converted to PROJECT-ID)")\n"
    help_content+="$(format_command "--project \"PROJECT_ID\" --study \"Study Name\"" "Add study to existing project")\n"
    help_content+="\n"
    
    # Optional inputs
    help_content+="$(format_header "Optional Options" 2)"
    help_content+="\n"
    help_content+="$(format_command "--python 3.11" "Python version for conda environment (default: 3.11)")\n"
    help_content+="$(format_command "--no-conda" "Skip conda environment creation")\n"
    help_content+="$(format_command "--conda-packages \"pkg1 pkg2\"" "Additional packages beyond base set")\n"
    help_content+="\n"
    
    # Naming conventions
    help_content+="$(format_header "Naming Conventions" 2)"
    help_content+="$(format_key_value "Project ID Format:YYYY_<snake_case_title>\nExample Input:Thermal Model Analysis\nGenerated ID:2025_thermal_model_analysis\nConda Environment:research_thermal_model_analysis\n\nStudy ID Format:snake_case_name\nExample Input:My First Study\nGenerated ID:my_first_study\nRules:ASCII lowercase [a-z0-9_-] only")\n"
    help_content+="\n"
    
    # Directory structure
    help_content+="$(format_header "Directory Structure" 2)"
    
    # Generate dynamic directory tree from scaffolder code
    local tree_content
    tree_content=$(generate_dynamic_tree "research" "project_name")
    
    help_content+="$(format_directory_tree "$tree_content")\n"
    
    # Examples
    help_content+="$(format_header "Examples" 2)"
    
    local examples="# Create new research project\ndirforge init research --title \"Thermal Analysis\"\n\n# Add study to existing project\ndirforge init research --project \"2025_thermal_analysis\" --study \"Initial Model\"\n\n# Combined: create project and first study\ndirforge init research --title \"Thermal Analysis\" --study \"Initial Model\"\n\n# Custom Python version\ndirforge init research --title \"ML Study\" --python 3.12\n\n# Skip conda environment (theory-only)\ndirforge init research --title \"Theory Work\" --no-conda\n\n# Preview structure without creating\ndirforge --dry-run init research --title \"Test Project\"\n\n# Backup existing project before overwrite\ndirforge init research --title \"Existing\" --backup"
    
    # Add examples directly without title - format them manually
    help_content+="\n"
    while IFS= read -r line; do
        help_content+="  $(gray "$line")\n"
    done <<< "$examples"
    help_content+="\n"
    
    # Best practices
    help_content+="$(format_header "Best Practices" 2)"
    help_content+="$(format_list "Use descriptive PROJECT-ID that will make sense in 5 years\nInclude year prefix for chronological organization\nCreate independent studies within 02_studies/ for different research questions\nUse study-specific conda environments for reproducibility\nPlace large datasets in study 02_data/ with manifests\nUse .integrity/checksums/ for data validation\nVersion control study 01_code/ with Git\nArchive final results in study 04_publication/" "")\n"
    help_content+="\n"
    
    # Cache the content before displaying
    _cache_set "$cache_key" "$help_content"
    
    # Display with automatic pager integration
    display_with_pager "$help_content"
}

# Lecture project help with grading workflow documentation
show_lecture_help() {
    local constitution_version="v1.0.17"
    
    # Build help content first, then display with pager (force pager for long content)
    local help_content=""
    
    help_content+="$(format_header "Lecture Project Creation" 1)"
    help_content+="\n"
    help_content+="Educational content with grading workflows\n"
    help_content+="Updated: 2025-12-09 (Constitution $constitution_version)\n"
    help_content+="\n"
    
    # Purpose
    help_content+="$(format_header "Purpose" 2)"
    help_content+="$(wrap_text "Creates standardized lecture project for course materials, assignments, and student grading workflows with academic integrity tracking." 0)\n"
    help_content+="\n"
    
    # Usage
    help_content+="$(format_header "Usage" 2)"
    help_content+="$(format_command "dirforge init lecture [options]")\n"
    help_content+="$(format_command "dirforge init lecture --name \"Course Name\"")\n"
    help_content+="\n"
    
    # Required inputs
    help_content+="$(format_header "Required Options" 2)"
    help_content+="$(format_command "--name \"Course Name\"" "Course or lecture series name")\n"
    help_content+="\n"
    
    # Optional inputs
    help_content+="$(format_header "Optional Options" 2)"
    help_content+="$(format_command "--term \"2025-spring\"" "Academic term (default: current year-semester)")\n"
    help_content+="$(format_command "--code \"PHYS101\"" "Course code for institutional tracking")\n"
    help_content+="$(format_command "--no-gradebook" "Skip gradebook template creation")\n"
    help_content+="\n"
    
    # Naming conventions
    help_content+="$(format_header "Naming Conventions" 2)"
    help_content+="$(format_key_value "Project ID Format:YYYY-TERM_<snake_case_name>\nExample Input:Digital Rock Physics\nGenerated ID:2025-spring_digital_rock_physics\nCourse Code:Optional institutional identifier\nRules:ASCII lowercase [a-z0-9_-] with term prefix")\n"
    help_content+="\n"
    
    # Directory structure
    help_content+="$(format_header "Directory Structure" 2)"
    
    # Generate dynamic directory tree from scaffolder code
    local tree_content
    tree_content=$(generate_dynamic_tree "lecture" "course_name")
    
    help_content+="$(format_directory_tree "$tree_content")\n"
    
    # Examples
    help_content+="$(format_header "Examples" 2)"
    
    local examples="# Interactive mode\ndirforge init lecture\n# Prompts for: Course name, term, code\n\n# Direct specification\ndirforge init lecture --name \"Digital Rock Physics\"\n\n# With course code and term\ndirforge init lecture --name \"Intro Physics\" --code \"PHYS101\" --term \"2025-fall\"\n\n# Skip gradebook template\ndirforge init lecture --name \"Workshop\" --no-gradebook\n\n# Preview structure\ndirforge --dry-run init lecture --name \"Test Course\""
    
    help_content+="$(format_example "$examples" "Common Usage")\n"
    
    # Best practices
    help_content+="$(format_header "Best Practices" 2)"
    help_content+="$(format_list "Use consistent naming across terms for multi-semester courses\nStore sensitive student data in 05_exercises/submissions/ and 06_exams/submissions/ with appropriate permissions\nVersion control course materials in 01_code/ and 03_slides/\nUse standardized rubrics and grading workflows in 05_exercises/ and 06_exams/\nStore large recordings externally and reference via 02_data/recordings.manifest.yaml\nKeep instructor solutions separate in solutions/ directories with appropriate access controls\nArchive completed courses with final grades in 07_grades/" "")\n"
    help_content+="\n"
    
    # Display with automatic pager integration
    display_with_pager "$help_content"
}

# Coding project help
show_coding_help() {
    local constitution_version="v1.0.17"

    local help_content=""
    help_content+="$(format_header "Coding Projects (CODING_WORLD)" 1)"
    help_content+="\n"
    help_content+="Software development projects with language-specific tooling. Supports python, matlab, fortran, bash.\n"
    help_content+="Updated: 2025-12-09 (Constitution $constitution_version)\n"
    help_content+="\n"
    
    # Purpose and compliance
    help_content+="$(format_header "Purpose" 2)"
    help_content+="\n"
    help_content+="$(wrap_text "Creates standardized coding projects with language-specific tooling and best practices. Ensures consistent project structures across different programming languages." 0)\n"
    help_content+="\n"
    
    help_content+="$(format_header "Usage" 2)"
    help_content+="\n"
    help_content+="$(format_command "dirforge init coding --language <lang> --project <name> [options]")\n"
    help_content+="\n"

    help_content+="$(format_header "Supported Languages" 2)"
    help_content+="\n"
    help_content+="  $(format_command "python" "Python project with conda env, pyproject.toml, tests")\n"
    help_content+="  $(format_command "matlab" "MATLAB project with functions/, tests/, data/")\n"
    help_content+="  $(format_command "fortran" "Fortran project with Makefile and optional conda env (gfortran)")\n"
    help_content+="  $(format_command "bash" "Shell project with executable scripts and lib/")\n"
    help_content+="\n"

    help_content+="$(format_header "Required Arguments" 2)"
    help_content+="\n"
    help_content+="$(format_command "--language <lang>" "One of: python|matlab|fortran|bash (case-insensitive)")\n"
    help_content+="$(format_command "--project <name>" "Project name (converted to lower_snake_case)")\n"
    help_content+="\n"

    help_content+="$(format_header "Optional Arguments" 2)"
    help_content+="\n"
    help_content+="$(format_command "--python <version>" "Python version for conda env (python/fortran). Default: 3.11")\n"
    help_content+="$(format_command "--no-conda" "Skip conda environment creation (applies to python/fortran)")\n"
    help_content+="$(format_command "--no-git" "Skip git initialization")\n"
    help_content+="$(format_command "--dry-run" "Preview structure without creating (use with --json for machine-readable plan)")\n"
    help_content+="$(format_command "--force" "Overwrite existing project without prompting")\n"
    help_content+="$(format_command "--backup" "Create timestamped backup before overwriting")\n"
    help_content+="\n"

    help_content+="$(format_header "Examples" 2)"
    help_content+="\n"
    help_content+="$(format_example "# Python machine learning toolkit\ndirforge init coding --language python --project ml_toolkit\n# Creates: CODING_WORLD/python/ml_toolkit/\n# Conda env: coding_ml_toolkit" "Python Example")\n"
    help_content+="$(format_example "# MATLAB seismic processing\ndirforge init coding --language matlab --project seismic_processing\n# Creates: CODING_WORLD/matlab/seismic_processing/" "MATLAB Example")\n"
    help_content+="$(format_example "# Fortran wave solver\ndirforge init coding --language fortran --project wave_solver --python 3.10\n# Creates: CODING_WORLD/fortran/wave_solver/" "Fortran Example")\n"
    help_content+="$(format_example "# Bash admin scripts\ndirforge init coding --language bash --project admin_scripts\n# Creates: CODING_WORLD/bash/admin_scripts/" "Bash Example")\n"

    help_content+="$(format_header "Directory Structures" 2)"
    help_content+="\n"
    help_content+="$(format_command "Python:" "CODING_WORLD/python/<project>/ with src/, tests/, pyproject.toml, environment.yml")\n"
    help_content+="$(format_command "MATLAB:" "CODING_WORLD/matlab/<project>/ with src/, functions/, tests/, data/, figures/")\n"
    help_content+="$(format_command "Fortran:" "CODING_WORLD/fortran/<project>/ with src/, modules/, Makefile, environment.yml")\n"
    help_content+="$(format_command "Bash:" "CODING_WORLD/bash/<project>/ with bin/, lib/, tests/, config/")\n"
    help_content+="\n"

    help_content+="$(format_header "Conda Environments" 2)"
    help_content+="\n"
    help_content+="Python and Fortran projects create conda env named: coding_<project_name> (unless --no-conda).\n"
    help_content+="Activate with: conda activate coding_<project_name>\n"
    help_content+="\n"

    help_content+="$(format_header "Constitution Compliance" 2)"
    help_content+="\n"
    help_content+="$(dim "Constitution v1.0.17, Section III.I — CODING_WORLD")\n"
    help_content+="The scaffolder creates language directories: matlab, python, bash, fortran (others are future phases).\n"

    display_with_pager "$help_content"
}

# Journal project help
show_journal_help() {
    local constitution_version="v1.0.17"
    
    # Build help content first
    local help_content=""
    
    help_content+="$(format_header "Journal Project Creation" 1)"
    help_content+="\n"
    help_content+="All journal-related activities: submissions, reviews, editorial work\n"
    help_content+="Updated: 2025-12-09 (Constitution $constitution_version)\n"
    help_content+="\n"
    
    help_content+="$(format_header "Purpose" 2)"
    help_content+="\n"
    help_content+="$(wrap_text "Creates journal project for managing all aspects of academic publishing: your own manuscript submissions, reviewer assignments, editorial responsibilities, and any journal-related correspondence. Flexible structure supports diverse workflows." 0)\n"
    help_content+="\n"
    
    help_content+="$(format_header "Structure" 2)"
    help_content+="\n"
    help_content+="JOURNAL_WORLD/JOURNAL_NAME/ID/\n"
    help_content+="├── manuscript/     # Papers, drafts, revisions\n"
    help_content+="├── reviews/        # Peer reviews, comments, responses\n"
    help_content+="└── correspondence/ # Editorial communications\n"
    help_content+="\n"
    
    help_content+="$(format_header "Use Cases" 2)"
    help_content+="\n"
    help_content+="• Your submissions: manuscript drafts and revisions\n"
    help_content+="• Reviewer work: papers to review and your reviews\n"
    help_content+="• Editorial duties: special issues, associate editor work\n"
    help_content+="• Conference abstracts and journal correspondence\n"
    help_content+="\n"
    
    local examples="# Your manuscript submission\ndirforge init journal --journal \"Geophysics\" --id \"GEO-2025-0451\"\n\n# Reviewer batch work\ndirforge init journal --journal \"Nature Geoscience\" --id \"REVIEWER_2024_Q4\"\n\n# Editorial responsibilities\ndirforge init journal --journal \"JGR Solid Earth\" --id \"ASSOC_EDITOR_2024\"\n\n# Special issue coordination\ndirforge init journal --journal \"IEEE TGRS\" --id \"SPECIAL_ISSUE_ML\""
    
    help_content+="$(format_example "$examples" "Examples")\n"
    
    # Display with automatic pager integration
    display_with_pager "$help_content"
}

# Office project help
show_office_help() {
    local constitution_version="v1.0.17"
    
    # Build help content first
    local help_content=""
    
    help_content+="$(format_header "Office Project Creation" 1)"
    help_content+="\n"
    help_content+="Administrative and business documents\n"
    help_content+="Updated: 2025-12-09 (Constitution $constitution_version)\n"
    help_content+="\n"
    
    help_content+="$(format_header "Purpose" 2)"
    help_content+="\n"
    help_content+="$(wrap_text "Creates administrative project for business documents, contracts, finance tracking, and equipment management." 0)\n"
    help_content+="\n"
    
    local examples="# Budget tracking\ndirforge init office --name \"2025-budget\"\n\n# Equipment inventory\ndirforge init office --name \"lab-equipment\"\n\n# Contract management\ndirforge init office --name \"vendor-contracts\""
    
    help_content+="$(format_example "$examples" "Examples")\n"
    
    # Display with automatic pager integration
    display_with_pager "$help_content"
}

# Private project help
show_private_help() {
    local constitution_version="v1.0.17"
    
    # Build help content first
    local help_content=""
    
    help_content+="$(format_header "Private Project Creation" 1)"
    help_content+="\n"
    help_content+="Personal projects with privacy controls\n"
    help_content+="Updated: 2025-12-09 (Constitution $constitution_version)\n"
    help_content+="\n"
    
    help_content+="$(format_header "Purpose" 2)"
    help_content+="\n"
    help_content+="$(wrap_text "Creates private project for personal files, photos, finance, and sensitive documents with enhanced security." 0)\n"
    help_content+="\n"
    
    local examples="# Personal finance\ndirforge init private --name \"finance-2025\" --encrypted\n\n# Photo archive\ndirforge init private --name \"family-photos\"\n\n# Personal documents\ndirforge init private --name \"documents\" --backup-enabled"
    
    help_content+="$(format_example "$examples" "Examples")\n"
    
    # Display with automatic pager integration
    display_with_pager "$help_content"
}