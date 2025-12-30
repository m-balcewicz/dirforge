#!/usr/bin/env bash
# help.sh - Help content formatting and display utilities
# Part of the Enhanced Terminal Help System for dirforge

set -euo pipefail

# Source required libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/terminal.sh"
source "$SCRIPT_DIR/colors.sh"
source "$SCRIPT_DIR/help_yaml_parser.sh"

# Initialize colors on library load
init_colors

# Pager configuration
PAGER_THRESHOLD=150  # Number of lines before triggering pager (high threshold for help UX)
MAX_HELP_WIDTH=80   # Maximum width for help content (improves readability)

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
# Show short/quick reference help (default for --help)
show_global_help_short() {
    # Try to load from YAML first
    if get_command_help "global-help" "short" 2>/dev/null; then
        return 0
    fi
    
    # Fallback to hard-coded help if YAML fails
    local constitution_version="v1.0.23"
    
    # Check cache first
    local cache_key
    cache_key=$(_cache_key "global_help_short" "$constitution_version")
    local cached_content
    if cached_content=$(_cache_get "$cache_key"); then
        echo -e "$cached_content"
        return
    fi
    
    # Build short help content - no pager needed for compact output
    local help_content=""
    
    # Main header
    help_content+="$(format_header "dirforge — workspace scaffolder" 1)"
    help_content+="\n"
    help_content+="Constitution Version: $(cyan "$constitution_version")\n"
    help_content+="\n"
    
    # Quick usage
    help_content+="$(format_header "Usage" 2)"
    help_content+="\n"
    help_content+="$(format_command "dirforge init [path] [--auto]              " "Complete workspace")"
    help_content+="\n"
    help_content+="$(format_command "dirforge init <world> [options]           " "Individual world")"
    help_content+="\n"
    help_content+="$(format_command "dirforge update [options]                 " "Update structure")"
    help_content+="\n"
    help_content+="$(format_command "dirforge validate-config <file>          " "Validate config")"
    help_content+="\n"
    help_content+="$(format_command "dirforge list-configs                    " "List configs")"
    help_content+="\n"
    help_content+="\n"
    
    # Essential commands
    help_content+="$(format_header "World Types" 2)"
    help_content+="\n"
    help_content+="$(format_command "research" "Research projects    (flags: -n name, -p project, -s study)")"
    help_content+="\n"
    help_content+="$(format_command "lecture" "Lecture materials    (flags: -n name)")"
    help_content+="\n"
    help_content+="$(format_command "coding" "Software projects    (flags: -l language, -p project)")"
    help_content+="\n"
    help_content+="$(format_command "journal" "Journal activities   (flags: -n name, --first/--coauthor/--service)")"
    help_content+="\n"
    help_content+="$(format_command "office" "Admin documents")"
    help_content+="\n"
    help_content+="$(format_command "private" "Personal projects")"
    help_content+="\n"
    help_content+="\n"
    
    # Key flags
    help_content+="$(format_header "Common Flags" 2)"
    help_content+="\n"
    help_content+="$(format_command "-h, --help" "Show this help    (use --help-long for detailed help)")"
    help_content+="\n"
    help_content+="$(format_command "--dry-run" "Preview only")"
    help_content+="\n"
    help_content+="$(format_command "--force" "Overwrite existing")"
    help_content+="\n"
    help_content+="$(format_command "-y, --yes" "Skip prompts")"
    help_content+="\n"
    help_content+="$(format_command "--version" "Show version")"
    help_content+="\n"
    help_content+="\n"
    
    # Quick examples
    help_content+="$(format_header "Quick Examples" 2)"
    help_content+="\n"
    help_content+="  dirforge init --here --auto                $(dim "# Complete workspace here")"
    help_content+="\n"
    help_content+="  dirforge init research -n \"My Project\"      $(dim "# Research project")"
    help_content+="\n"
    help_content+="  dirforge init coding -l python -p mytool   $(dim "# Python project")"
    help_content+="\n"
    help_content+="  dirforge init lecture -n \"My Course\"        $(dim "# Lecture materials")"
    help_content+="\n"
    help_content+="\n"
    
    # Footer
    help_content+="$(dim "Use 'dirforge init <world> --help' for world-specific help")"
    help_content+="\n"
    help_content+="$(dim "Use 'dirforge --help-long' for comprehensive documentation")"
    help_content+="\n"
    
    # Cache the content
    _cache_set "$cache_key" "$help_content"
    
    # Display directly (no pager for short help)
    echo -e "$help_content"
}

# Show comprehensive/long help (for --help-long)
show_global_help() {
    # Load and display help from YAML file
    get_command_help "global-help" "long"
}

# Show command-specific help for the init command
show_command_help() {
    local command="$1"
    case "$command" in
        "init")
            show_init_command_help
            ;;
        "update")
            show_update_command_help
            ;;
        "validate-config")
            show_validate_config_help
            ;;
        "list-configs")
            show_list_configs_help
            ;;
        *)
            echo "$(red "Error: Unknown command '$command'")"
            echo "Use 'dirforge --help' to see available commands."
            return 1
            ;;
    esac
}

# Show detailed help for the update command
show_update_command_help() {
    # Load and display help from YAML file
    get_command_help "update" "long"
}

# Show detailed help for the init command
show_init_command_help() {
    # Load and display help from YAML file
    get_command_help "init" "long"
}

# Unified journal help - integrates all role-specific content (T033)
show_journal_help_short() {
    # Try YAML-based help first
    if get_command_help "journal-world" "short" 2>/dev/null; then
        return 0
    fi
    
    # Fallback to hard-coded help if YAML unavailable
    local constitution_version="$1"
    local help_content=""
    
    help_content+="$(format_header "Journal Activities — Unified Role-Based Organization" 1)"
    help_content+="\nConstitution $constitution_version — Complete workflow integration\n\n"
    
    help_content+="$(format_header "Four-Role Integration" 2)\n"
    help_content+="  $(green "1. Primary Authorship")    Your papers as lead author\n"
    help_content+="  $(green "2. Co-author Collaboration") Joint projects and invitations\n"
    help_content+="  $(green "3. Journal Service")        Reviews, editorial duties\n"
    help_content+="  $(green "4. Administrative")         Subscriptions, memberships (manual)\n\n"
    
    help_content+="$(format_header "Command Patterns" 2)\n"
    help_content+="  dirforge init journal                         # Create JOURNAL_WORLD/\n"
    help_content+="  dirforge init journal --name \"Paper\" --first         # → 01_primary_authorship/\n"
    help_content+="  dirforge init journal --name \"Paper\" --coauthor      # → 02_coauthor_invites/\n"
    help_content+="  dirforge init journal --name \"Journal\" --id \"ID\" --service # → 03_journal_service/\n"
    help_content+="  \n"
    help_content+="  $(yellow "Administrative:") 00_admin/ organization is manual-only (no dirforge command)\n\n"
    
    help_content+="$(format_header "Core Flags (Role-Specific)" 2)\n"
    help_content+="  --name \"Name\"             Paper name (authorship) or journal name (service)\n"
    help_content+="  --first                 Primary authorship role\n"
    help_content+="  --coauthor              Co-author collaboration role\n"
    help_content+="  --service               Journal service role (peer review/editorial)\n"
    help_content+="  --year YYYY             Authorship: explicit year (default: current or extracted)\n"
    help_content+="  --id \"Manuscript ID\"     Service: manuscript identifier (required with --service)\n\n"
    
    help_content+="$(format_header "Integrated Examples by Role" 2)\n"
    help_content+="  # Role 1: Primary Authorship Projects (Your Papers)\n"
    help_content+="  dirforge init journal --name \"thermal_analysis\" --first\n"
    help_content+="  dirforge init journal --name \"seismic_modeling_study\" --first --year 2024\n"
    help_content+="  dirforge init journal --name \"ML in Geophysics\" --first  # Auto-formats\n\n"
    help_content+="  # Role 2: Co-author Collaboration (Joint Projects)\n"
    help_content+="  dirforge init journal --name \"2021_elastic_properties\" --coauthor  # Year extracted\n"
    help_content+="  dirforge init journal --name \"international_consortium_study\" --coauthor\n"
    help_content+="  dirforge init journal --name \"industry_academic_partnership\" --coauthor --year 2023\n\n"
    help_content+="  # Role 3: Journal Service (Reviews/Editorial)\n"
    help_content+="  dirforge init journal --name \"Geophysics\" --id \"GEO-2025-0451\" --service\n"
    help_content+="  dirforge init journal --name \"Nature Geoscience\" --id \"REVIEWER_2024_Q4\" --service\n"
    help_content+="  dirforge init journal --name \"JGR Solid Earth\" --id \"EDITORIAL_BOARD_2025\" --service\n\n"
    help_content+="  # Role 4: Administrative Organization (Manual Setup)\n"
    help_content+="  mkdir -p JOURNAL_WORLD/00_admin/{subscriptions,memberships,general}\n"
    help_content+="  mkdir -p JOURNAL_WORLD/00_admin/subscriptions/{nature_journals,ieee_access}\n"
    help_content+="  mkdir -p JOURNAL_WORLD/00_admin/memberships/{agu,seg,ieee_geoscience}\n"
    help_content+="  echo \"Complete admin examples: dirforge init journal --help-long\"\n\n"
    
    help_content+="$(cyan "Comprehensive documentation:") 'dirforge init journal --help-long'\n"
    
    echo -e "$help_content"
}

# Journal project help
show_journal_help() {
    local mode="${1:-short}"  # default to short
    
    if [ "$mode" = "short" ]; then
        show_journal_help_short "$constitution_version"
        return
    fi
    
    # Try YAML-based long help
    if get_command_help "journal-world" "long" 2>/dev/null; then
        return 0
    fi
    
    # Fallback: if YAML unavailable, call short help
    show_journal_help_short "v1.0.21"
}

# Short help for office projects
show_office_help_short() {
    local constitution_version="$1"
    local help_content=""
    
    help_content+="$(format_header "Office Documents" 1)"
    help_content+="\nConstitution $constitution_version\n\n"
    
    help_content+="$(format_header "Usage" 2)\n"
    help_content+="  dirforge init office    # Creates OFFICE_WORLD/ with standard structure\n\n"
    
    help_content+="$(format_header "Structure" 2)\n"
    help_content+="  00_admin, 01_finance, 02_hr_administration, 03_faculty,\n"
    help_content+="  04_inventory_equipment, 05_software_licenses, 06_public_relations\n\n"
    
    help_content+="Use 'dirforge init office --help-long' for detailed documentation\n"
    
    echo -e "$help_content"
}

# Office project help
show_office_help() {
    local mode="${1:-short}"  # default to short
    
    if [ "$mode" = "short" ]; then
        # Try YAML first
        if get_command_help "office-world" "short" 2>/dev/null; then
            return 0
        fi
        
        # Fallback
        show_office_help_short "v1.0.23"
        return
    fi
    
    # Try YAML-based long help
    if get_command_help "office-world" "long" 2>/dev/null; then
        return 0
    fi
    
    # Fallback: show short help
    show_office_help_short "v1.0.23"
}

# Short help for private projects
show_private_help_short() {
    local constitution_version="$1"
    local help_content=""
    
    help_content+="$(format_header "Private Projects" 1)"
    help_content+="\nConstitution $constitution_version\n\n"
    
    help_content+="$(format_header "Usage" 2)\n"
    help_content+="  dirforge init private   # Creates PRIVATE_WORLD/ with standard structure\n\n"
    
    help_content+="$(format_header "Structure" 2)\n"
    help_content+="  00_admin, 01_credentials, 02_id_contracts, 03_finance, 04_documents,\n"
    help_content+="  05_photos, 06_movies, 07_hiking, 09_installers, 90_archive\n\n"
    
    help_content+="Use 'dirforge init private --help-long' for detailed documentation\n"
    
    echo -e "$help_content"
}

# Private project help
show_private_help() {
    local mode="${1:-short}"  # default to short
    
    if [ "$mode" = "short" ]; then
        # Try YAML first
        if get_command_help "private-world" "short" 2>/dev/null; then
            return 0
        fi
        
        # Fallback
        show_private_help_short "v1.0.23"
        return
    fi
    
    # Try YAML-based long help
    if get_command_help "private-world" "long" 2>/dev/null; then
        return 0
    fi
    
    # Fallback: show short help
    show_private_help_short "v1.0.23"
}

# Show detailed help for the validate-config command
show_validate_config_help() {
    # Load and display help from YAML file
    get_command_help "validate-config" "long"
}

# Show detailed help for the list-configs command
show_list_configs_help() {
    # Load and display help from YAML file
    get_command_help "list-configs" "long"
}

################################################################################
# World-Specific Help Functions (YAML-Integrated)
################################################################################

# Show help for a specific world type (using YAML parser)
show_world_help() {
    local world_type="$1"
    local help_file=""
    
    # Map world type to YAML help file
    case "$world_type" in
        "research")
            help_file="research-world.yaml"
            ;;
        "lecture")
            help_file="lecture-world.yaml"
            ;;
        "coding")
            help_file="coding-world.yaml"
            ;;
        "journal")
            help_file="journal-world.yaml"
            ;;
        "office")
            help_file="office-world.yaml"
            ;;
        "private")
            help_file="private-world.yaml"
            ;;
        *)
            echo "$(red "Error: Unknown world type '$world_type'")"
            return 1
            ;;
    esac
    
    # Try to load from YAML parser first (remove .yaml suffix since get_command_help uses help name)
    local help_name="${help_file%.yaml}"
    if get_command_help "$help_name" "long" 2>/dev/null; then
        return 0
    fi
    
    # Fallback to hardcoded help if YAML not available
    echo "$(yellow "Note: Using fallback help (YAML parser unavailable)")"
    case "$world_type" in
        "research")
            show_research_world_help
            ;;
        "lecture")
            show_lecture_world_help
            ;;
        "coding")
            show_coding_world_help
            ;;
        "journal")
            show_journal_world_help
            ;;
        "office")
            show_office_world_help
            ;;
        "private")
            show_private_world_help
            ;;
    esac
}

# Fallback: Show detailed help for research world
show_research_world_help() {
    local help_content=""
    help_content+="$(format_header "dirforge init research" 1)\n"
    help_content+="\nCreate research project with study-based organization\n\n"
    help_content+="$(format_header "Usage" 2)\n"
    help_content+="$(format_command "dirforge init research [options]")\n"
    help_content+="\n$(format_header "Common Options" 2)\n"
    help_content+="$(format_command "--title=TITLE" "Title of the research project")\n"
    help_content+="$(format_command "--python" "Include Python environment")\n"
    help_content+="$(format_command "--no-conda" "Skip Conda environment setup")\n"
    help_content+="\n"
    display_with_pager "$help_content"
}

# Fallback: Show detailed help for lecture world
show_lecture_world_help() {
    local help_content=""
    help_content+="$(format_header "dirforge init lecture" 1)\n"
    help_content+="\nCreate lecture/course project with grading workflows\n\n"
    help_content+="$(format_header "Usage" 2)\n"
    help_content+="$(format_command "dirforge init lecture [options]")\n"
    help_content+="\n$(format_header "Common Options" 2)\n"
    help_content+="$(format_command "--name=NAME" "Name of the lecture/course")\n"
    help_content+="$(format_command "--term=TERM" "Term or semester")\n"
    help_content+="$(format_command "--code=CODE" "Course code")\n"
    help_content+="\n"
    display_with_pager "$help_content"
}

# Fallback: Show detailed help for coding world
show_coding_world_help() {
    local help_content=""
    help_content+="$(format_header "dirforge init coding" 1)\n"
    help_content+="\nCreate software development project (multi-language)\n\n"
    help_content+="$(format_header "Usage" 2)\n"
    help_content+="$(format_command "dirforge init coding [options]")\n"
    help_content+="\n$(format_header "Common Options" 2)\n"
    help_content+="$(format_command "--language=LANG" "Language: python, matlab, fortran, bash")\n"
    help_content+="$(format_command "--project=NAME" "Project name")\n"
    help_content+="\n"
    display_with_pager "$help_content"
}

# Fallback: Show detailed help for journal world
show_journal_world_help() {
    local help_content=""
    help_content+="$(format_header "dirforge init journal" 1)\n"
    help_content+="\nCreate journal-related activities structure\n\n"
    help_content+="$(format_header "Usage" 2)\n"
    help_content+="$(format_command "dirforge init journal")\n"
    help_content+="\n$(format_header "Use Cases" 2)\n"
    help_content+="- Submissions and reviews\n"
    help_content+="- Editorial workflows\n"
    help_content+="- Meeting notes and records\n"
    help_content+="\n"
    display_with_pager "$help_content"
}

# Fallback: Show detailed help for office world
show_office_world_help() {
    local help_content=""
    help_content+="$(format_header "dirforge init office" 1)\n"
    help_content+="\nCreate administrative project for business documents\n\n"
    help_content+="$(format_header "Usage" 2)\n"
    help_content+="$(format_command "dirforge init office")\n"
    help_content+="\n$(format_header "Use Cases" 2)\n"
    help_content+="- Budget tracking\n"
    help_content+="- Equipment inventory\n"
    help_content+="- Contract management\n"
    help_content+="\n"
    display_with_pager "$help_content"
}

# Fallback: Show detailed help for private world
show_private_world_help() {
    local help_content=""
    help_content+="$(format_header "dirforge init private" 1)\n"
    help_content+="\nCreate private project for personal documents\n\n"
    help_content+="$(format_header "Usage" 2)\n"
    help_content+="$(format_command "dirforge init private")\n"
    help_content+="\n$(format_header "Use Cases" 2)\n"
    help_content+="- Personal finance tracking\n"
    help_content+="- Photo archive\n"
    help_content+="- Personal learning projects\n"
    help_content+="\n"
    display_with_pager "$help_content"

}