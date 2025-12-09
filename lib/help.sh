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

# Format header with level-based styling
# Usage: format_header "Header Text" [level]
# Level 1: Main title (bold, larger)
# Level 2: Section header (bold)
# Level 3: Subsection header (normal)
format_header() {
    local text="$1"
    local level="${2:-1}"
    local width
    width=$(get_terminal_width)
    
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
    width=$(get_terminal_width)
    
    # Highlight the command in cyan/blue
    local formatted_cmd
    formatted_cmd=$(cyan "$command")
    
    if [[ -n "$description" ]]; then
        # Calculate padding for alignment
        local cmd_length
        cmd_length=$(strip_colors "$command" | wc -c)
        ((cmd_length--)) # Remove newline from wc
        
        local padding_needed=$((width - cmd_length - ${#description} - 4))
        if [[ $padding_needed -gt 0 ]]; then
            printf "  %s%*s%s\n" "$formatted_cmd" $padding_needed "" "$(dim "$description")"
        else
            printf "  %s\n    %s\n" "$formatted_cmd" "$(dim "$description")"
        fi
    else
        printf "  %s\n" "$formatted_cmd"
    fi
}

# Format example block with indentation and styling
# Usage: format_example "example_text" [title]
format_example() {
    local example="$1"
    local title="${2:-Example}"
    
    echo "$(dim "$title:"))"
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

# Wrap text to fit terminal width with proper indentation
# Usage: wrap_text "text" [indent_level]
wrap_text() {
    local text="$1"
    local indent_level="${2:-0}"
    local width
    width=$(get_terminal_width)
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
    local bullet="${2:-•}"
    
    while IFS= read -r item; do
        if [[ -n "$item" ]]; then
            printf "  %s %s\n" "$(cyan "$bullet")" "$item"
        fi
    done <<< "$items"
}

# Format key-value pairs with alignment
# Usage: format_key_value "key1:value1\nkey2:value2"
format_key_value() {
    local pairs="$1"
    local max_key_length=0
    
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
    local length="${2:-$(get_terminal_width)}"
    
    printf "%*s\n" "$length" "" | tr ' ' "$char"
}

# Format a box around text
# Usage: format_box "text content"
format_box() {
    local content="$1"
    local width
    width=$(get_terminal_width)
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
    local constitution_version="v1.0.16"
    
    # Main header
    format_header "dirforge" 1
    
    echo "Create standardized directory structures per DirForge Constitution"
    echo
    
    # Constitution version reference
    printf "%s: %s\n" "$(bold "Constitution Version")" "$(cyan "$constitution_version")"
    echo
    
    # Usage pattern
    format_header "Usage" 2
    format_command "dirforge <command> [options]"
    echo
    
    # Available commands
    format_header "Commands" 2
    format_command "init <world-type>" "Create new project structure"
    echo
    
    # Global options
    format_header "Global Options" 2
    format_command "--help, -h" "Show this help message"
    format_command "--version" "Show version information"
    format_command "--dry-run, --preview" "Preview changes without writing to filesystem"
    format_command "--json" "Output machine-readable JSON plan (requires --dry-run)"
    echo
    
    # World types quick reference
    format_header "World Types" 2
    format_command "research" "Academic research projects with data management"
    format_command "lecture" "Educational content with grading workflows"
    format_command "coding" "Software development projects"
    format_command "journal" "Journal-related activities: submissions, reviews, editorial work"
    format_command "office" "Administrative and business documents"
    format_command "private" "Personal projects with privacy controls"
    echo
    
    # Common usage examples
    format_header "Examples" 2
    
    local examples="# Create research project with interactive prompts
dirforge init research --title \"Thermal Analysis\"

# Create lecture project structure
dirforge init lecture --name \"Digital Rock Physics\"

# Preview project creation with JSON output
dirforge --dry-run init research --title \"Test\" | jq ."
    
    format_example "$examples" "Common Usage"
    
    # Footer with additional help info
    format_header "More Information" 3
    wrap_text "Use 'dirforge <command> --help' for detailed command information." 0
    wrap_text "See constitution.md for governance and naming rules." 0
    echo
    wrap_text "Constitution compliance ensures consistent project structures across teams and organizations." 0
    echo
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
    local constitution_version="v1.0.16"
    
    # Command header
    format_header "dirforge init" 1
    
    echo "Create new project structure based on DirForge Constitution"
    echo
    
    # Usage pattern
    format_header "Usage" 2
    format_command "dirforge init <world-type> [options]"
    format_command "dirforge init <world-type> --help" "Show world-type specific help"
    echo
    
    # Available world types with descriptions and constitution references
    format_header "World Types" 2
    
    format_command "research" "Academic research projects with data management"
    format_command "lecture" "Educational content with grading workflows"
    format_command "coding" "Software development projects"
    format_command "journal" "Journal-related activities: submissions, reviews, editorial work"
    format_command "office" "Administrative and business documents"
    format_command "private" "Personal projects with privacy controls"
    echo
    
    # Common options
    format_header "Common Options" 2
    format_command "--help, -h" "Show help for this command or specific world type"
    format_command "--dry-run, --preview" "Preview directory structure without creating files"
    format_command "--force" "Overwrite existing directories (use with caution)"
    format_command "--backup" "Create backup of existing content before overwriting"
    format_command "--yes" "Skip interactive confirmations (use with --force or --backup)"
    format_command "--json" "Output machine-readable JSON plan (requires --dry-run)"
    format_command "--quiet, -q" "Suppress non-error output"
    format_command "--verbose, -v" "Show detailed progress information"
    echo
    
    # World-type specific options note
    format_header "World-Type Specific Options" 3
    wrap_text "Each world type has additional options for customization. Use 'dirforge init <world-type> --help' to see specific options and requirements." 0
    echo
    
    # Examples
    format_header "Examples" 2
    
    local examples="# Get help for research projects
dirforge init research --help

# Preview research project structure
dirforge init research --title \"My Study\" --dry-run

# Create lecture with backup of existing content
dirforge init lecture --name \"Physics 101\" --backup

# Create coding project with minimal output
dirforge init coding --name \"my-app\" --quiet"
    
    format_example "$examples" "Common Usage"
    
    # Footer
    format_header "Constitution Compliance" 3
    wrap_text "All project structures follow DirForge Constitution $constitution_version for consistency across teams and organizations." 0
    echo
    wrap_text "Use 'dirforge init <world-type> --help' for detailed world-specific information including directory trees, naming conventions, and required inputs." 0
    echo
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
    local constitution_version="v1.0.16"
    
    format_header "Research Project Creation" 1
    echo "Academic research projects with data management"
    echo "Updated: 2025-12-09 (Constitution $constitution_version)"
    echo
    
    # Purpose and compliance
    format_header "Purpose" 2
    wrap_text "Creates standardized research project with data analysis workflow. Follows project-by-activity principle with co-located provenance for reproducible research." 0
    echo
    
    # Usage
    format_header "Usage" 2
    format_command "dirforge init research [options]"
    format_command "dirforge init research --title \"Project Name\""
    echo
    
    # Required inputs
    format_header "Required Options" 2
    format_command "--title \"Project Title\"" "Human-readable project title (converted to PROJECT-ID)"
    echo
    
    # Optional inputs
    format_header "Optional Options" 2
    format_command "--python 3.11" "Python version for conda environment (default: 3.11)"
    format_command "--no-conda" "Skip conda environment creation"
    format_command "--conda-packages \"pkg1 pkg2\"" "Additional packages beyond base set"
    echo
    
    # Naming conventions
    format_header "Naming Conventions" 2
    format_key_value "Project ID Format:YYYY_<snake_case_title>
Example Input:Thermal Model Analysis
Generated ID:2025_thermal_model_analysis
Conda Environment:research_thermal_model_analysis
Rules:ASCII lowercase [a-z0-9_-] only"
    echo
    
    # Directory structure
    format_header "Directory Structure" 2
    local tree_content="RESEARCH_WORLD/2025_project_name/
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
└── project.yaml"
    
    format_directory_tree "$tree_content"
    
    # Examples
    format_header "Examples" 2
    
    local examples="# Interactive mode with prompts
dirforge init research
# Prompts for: Project title

# Direct specification
dirforge init research --title \"Thermal Analysis\"

# Custom Python version
dirforge init research --title \"ML Study\" --python 3.12

# Skip conda environment (theory-only)
dirforge init research --title \"Theory Work\" --no-conda

# Preview structure without creating
dirforge --dry-run init research --title \"Test Project\"

# Backup existing project before overwrite
dirforge init research --title \"Existing\" --backup"
    
    format_example "$examples" "Common Usage"
    
    # Best practices
    format_header "Best Practices" 2
    format_list "Use descriptive PROJECT-ID that will make sense in 5 years
Include year prefix for chronological organization
Place large datasets in external storage with manifests in 04_data/
Use .integrity/checksums/ for data validation
Version control 05_data_analysis/ with Git
Archive final results in 06_data_outputs/ with version tags"
    echo
}

# Lecture project help with grading workflow documentation
show_lecture_help() {
    local constitution_version="v1.0.16"
    
    format_header "Lecture Project Creation" 1
    echo "Educational content with grading workflows"
    echo "Updated: 2025-12-09 (Constitution $constitution_version)"
    echo
    
    # Purpose
    format_header "Purpose" 2
    wrap_text "Creates standardized lecture project for course materials, assignments, and student grading workflows with academic integrity tracking." 0
    echo
    
    # Usage
    format_header "Usage" 2
    format_command "dirforge init lecture [options]"
    format_command "dirforge init lecture --name \"Course Name\""
    echo
    
    # Required inputs
    format_header "Required Options" 2
    format_command "--name \"Course Name\"" "Course or lecture series name"
    echo
    
    # Optional inputs
    format_header "Optional Options" 2
    format_command "--term \"2025-spring\"" "Academic term (default: current year-semester)"
    format_command "--code \"PHYS101\"" "Course code for institutional tracking"
    format_command "--no-gradebook" "Skip gradebook template creation"
    echo
    
    # Naming conventions
    format_header "Naming Conventions" 2
    format_key_value "Project ID Format:YYYY-TERM_<snake_case_name>
Example Input:Digital Rock Physics
Generated ID:2025-spring_digital_rock_physics
Course Code:Optional institutional identifier
Rules:ASCII lowercase [a-z0-9_-] with term prefix"
    echo
    
    # Directory structure
    format_header "Directory Structure" 2
    local tree_content="LECTURE_WORLD/2025-spring_course_name/
├── 00_admin/
│   ├── syllabus/
│   └── policies/
├── 01_code/
│   ├── notebooks/
│   ├── scripts/
│   └── environment.yml
├── 02_data/
│   ├── experimental_recordings/
│   └── reference/
├── 03_slides/
│   ├── sources/
│   └── exported/
├── 04_manuscript/
│   └── lecture_notes/
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
│   └── gradebook/
├── .integrity/
│   ├── checksums/
│   └── manifests/
├── README.md
└── project.yaml"
    
    format_directory_tree "$tree_content"
    
    # Examples
    format_header "Examples" 2
    
    local examples="# Interactive mode
dirforge init lecture
# Prompts for: Course name, term, code

# Direct specification
dirforge init lecture --name \"Digital Rock Physics\"

# With course code and term
dirforge init lecture --name \"Intro Physics\" --code \"PHYS101\" --term \"2025-fall\"

# Skip gradebook template
dirforge init lecture --name \"Workshop\" --no-gradebook

# Preview structure
dirforge --dry-run init lecture --name \"Test Course\""
    
    format_example "$examples" "Common Usage"
    
    # Best practices
    format_header "Best Practices" 2
    format_list "Use consistent naming across terms for multi-semester courses
Store sensitive student data in 05_exercises/submissions/ and 06_exams/submissions/ with appropriate permissions
Version control course materials in 01_code/ and 03_slides/
Use standardized rubrics and grading workflows in 05_exercises/ and 06_exams/
Store large recordings externally and reference via 02_data/recordings.manifest.yaml
Keep instructor solutions separate in solutions/ directories with appropriate access controls
Archive completed courses with final grades in 07_grades/"
    echo
}

# Coding project help
show_coding_help() {
    local constitution_version="v1.0.16"
    
    format_header "Coding Project Creation" 1
    echo "Software development projects"
    echo "Updated: 2025-12-09 (Constitution $constitution_version)"
    echo
    
    format_header "Purpose" 2
    wrap_text "Creates standardized software development project with version control, testing, and documentation structure." 0
    echo
    
    format_header "Usage" 2
    format_command "dirforge init coding [options]"
    format_command "dirforge init coding --name \"project-name\""
    echo
    
    format_header "Required Options" 2
    format_command "--name \"project-name\"" "Project name (kebab-case recommended)"
    echo
    
    format_header "Optional Options" 2
    format_command "--lang python|javascript|rust|go" "Primary language (default: python)"
    format_command "--license mit|apache|gpl3" "Software license (default: mit)"
    format_command "--no-git" "Skip Git repository initialization"
    echo
    
    local examples="# Python project with MIT license
dirforge init coding --name \"data-processor\" --lang python

# JavaScript project
dirforge init coding --name \"web-app\" --lang javascript

# Rust project with Apache license
dirforge init coding --name \"cli-tool\" --lang rust --license apache"
    
    format_example "$examples" "Examples"
}

# Journal project help
show_journal_help() {
    local constitution_version="v1.0.16"
    
    format_header "Journal Project Creation" 1
    echo "All journal-related activities: submissions, reviews, editorial work"
    echo "Updated: 2025-12-09 (Constitution $constitution_version)"
    echo
    
    format_header "Purpose" 2
    wrap_text "Creates journal project for managing all aspects of academic publishing: your own manuscript submissions, reviewer assignments, editorial responsibilities, and any journal-related correspondence. Flexible structure supports diverse workflows." 0
    echo
    
    format_header "Structure" 2
    echo "JOURNAL_WORLD/JOURNAL_NAME/ID/"
    echo "├── manuscript/     # Papers, drafts, revisions"
    echo "├── reviews/        # Peer reviews, comments, responses"
    echo "└── correspondence/ # Editorial communications"
    echo
    
    format_header "Use Cases" 2
    echo "• Your submissions: manuscript drafts and revisions"
    echo "• Reviewer work: papers to review and your reviews"
    echo "• Editorial duties: special issues, associate editor work"
    echo "• Conference abstracts and journal correspondence"
    echo
    
    local examples="# Your manuscript submission
dirforge init journal --journal \"Geophysics\" --id \"GEO-2025-0451\"

# Reviewer batch work
dirforge init journal --journal \"Nature Geoscience\" --id \"REVIEWER_2024_Q4\"

# Editorial responsibilities
dirforge init journal --journal \"JGR Solid Earth\" --id \"ASSOC_EDITOR_2024\"

# Special issue coordination
dirforge init journal --journal \"IEEE TGRS\" --id \"SPECIAL_ISSUE_ML\""
    
    format_example "$examples" "Examples"
}

# Office project help
show_office_help() {
    local constitution_version="v1.0.16"
    
    format_header "Office Project Creation" 1
    echo "Administrative and business documents"
    echo "Updated: 2025-12-09 (Constitution $constitution_version)"
    echo
    
    format_header "Purpose" 2
    wrap_text "Creates administrative project for business documents, contracts, finance tracking, and equipment management." 0
    echo
    
    local examples="# Budget tracking
dirforge init office --name \"2025-budget\"

# Equipment inventory
dirforge init office --name \"lab-equipment\"

# Contract management
dirforge init office --name \"vendor-contracts\""
    
    format_example "$examples" "Examples"
}

# Private project help
show_private_help() {
    local constitution_version="v1.0.16"
    
    format_header "Private Project Creation" 1
    echo "Personal projects with privacy controls"
    echo "Updated: 2025-12-09 (Constitution $constitution_version)"
    echo
    
    format_header "Purpose" 2
    wrap_text "Creates private project for personal files, photos, finance, and sensitive documents with enhanced security." 0
    echo
    
    local examples="# Personal finance
dirforge init private --name \"finance-2025\" --encrypted

# Photo archive
dirforge init private --name \"family-photos\"

# Personal documents
dirforge init private --name \"documents\" --backup-enabled"
    
    format_example "$examples" "Examples"
}