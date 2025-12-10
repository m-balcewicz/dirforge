#!/bin/bash
# Enhanced Terminal Help System - Content Validation Script
# Validates help text for spelling, accuracy, constitution compliance, and consistency

set -euo pipefail

# Script directory resolution
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Configuration
HELP_LIB="$PROJECT_ROOT/lib/help.sh"
COLORS_LIB="$PROJECT_ROOT/lib/colors.sh" 
TERMINAL_LIB="$PROJECT_ROOT/lib/terminal.sh"
DIRFORGE_TOOL="$PROJECT_ROOT/tools/dirforge"
CONSTITUTION_VERSION="v1.0.16"

# Validation results
declare -i TOTAL_CHECKS=0
declare -i PASSED_CHECKS=0
declare -i FAILED_CHECKS=0
declare -a VALIDATION_ERRORS=()

# Colors for output (only if terminal supports colors)
RED=''
GREEN=''
YELLOW=''
BLUE=''
RESET=''

# Initialize colors if available
init_validation_colors() {
    if [[ -t 1 ]] && command -v tput >/dev/null 2>&1; then
        RED=$(tput setaf 1 2>/dev/null || echo '')
        GREEN=$(tput setaf 2 2>/dev/null || echo '')
        YELLOW=$(tput setaf 3 2>/dev/null || echo '')
        BLUE=$(tput setaf 4 2>/dev/null || echo '')
        RESET=$(tput sgr0 2>/dev/null || echo '')
    fi
}

# Logging functions
log_info() { echo "${BLUE}[INFO]${RESET} $*"; }
log_success() { echo "${GREEN}[PASS]${RESET} $*"; }
log_warning() { echo "${YELLOW}[WARN]${RESET} $*"; }
log_error() { echo "${RED}[FAIL]${RESET} $*"; }

# Validation result tracking
check_pass() {
    ((TOTAL_CHECKS++))
    ((PASSED_CHECKS++))
    log_success "$1"
}

check_fail() {
    ((TOTAL_CHECKS++))
    ((FAILED_CHECKS++))
    local error_msg="$1"
    VALIDATION_ERRORS+=("$error_msg")
    log_error "$error_msg"
}

# Validate that required files exist
validate_dependencies() {
    log_info "Validating dependencies..."
    
    local deps=("$HELP_LIB" "$COLORS_LIB" "$TERMINAL_LIB" "$DIRFORGE_TOOL")
    for dep in "${deps[@]}"; do
        if [[ -f "$dep" ]]; then
            check_pass "Dependency found: $(basename "$dep")"
        else
            check_fail "Missing dependency: $dep"
        fi
    done
}

# Source help libraries for function testing
source_help_libraries() {
    local libs=("$COLORS_LIB" "$TERMINAL_LIB" "$HELP_LIB")
    for lib in "${libs[@]}"; do
        if [[ -f "$lib" ]]; then
            # shellcheck source=/dev/null
            source "$lib" 2>/dev/null || {
                check_fail "Failed to source library: $(basename "$lib")"
                return 1
            }
        fi
    done
    return 0
}

# Extract help content from functions for analysis
extract_help_content() {
    local help_type="$1"
    local content=""
    
    case "$help_type" in
        "global")
            content=$(PAGER=cat NO_COLOR=1 "$DIRFORGE_TOOL" --help 2>/dev/null || echo "ERROR")
            ;;
        "init")
            content=$(PAGER=cat NO_COLOR=1 "$DIRFORGE_TOOL" init --help 2>/dev/null || echo "ERROR")
            ;;
        "research")
            content=$(PAGER=cat NO_COLOR=1 "$DIRFORGE_TOOL" init research --help 2>/dev/null || echo "ERROR")
            ;;
        "lecture")
            content=$(PAGER=cat NO_COLOR=1 "$DIRFORGE_TOOL" init lecture --help 2>/dev/null || echo "ERROR")
            ;;
        "coding")
            content=$(PAGER=cat NO_COLOR=1 "$DIRFORGE_TOOL" init coding --help 2>/dev/null || echo "ERROR")
            ;;
        "journal")
            content=$(PAGER=cat NO_COLOR=1 "$DIRFORGE_TOOL" init journal --help 2>/dev/null || echo "ERROR")
            ;;
        "office")
            content=$(PAGER=cat NO_COLOR=1 "$DIRFORGE_TOOL" init office --help 2>/dev/null || echo "ERROR")
            ;;
        "private")
            content=$(PAGER=cat NO_COLOR=1 "$DIRFORGE_TOOL" init private --help 2>/dev/null || echo "ERROR")
            ;;
        *)
            content="ERROR: Unknown help type"
            ;;
    esac
    
    echo "$content"
}

# Validate constitution version references
validate_constitution_references() {
    log_info "Validating constitution version references..."
    
    local help_types=("global" "init" "research" "lecture" "coding" "journal" "office" "private")
    for help_type in "${help_types[@]}"; do
        local content
        content=$(extract_help_content "$help_type")
        
        if [[ "$content" == "ERROR"* ]]; then
            check_fail "Failed to extract $help_type help content"
            continue
        fi
        
        if echo "$content" | grep -q "$CONSTITUTION_VERSION"; then
            check_pass "Constitution version $CONSTITUTION_VERSION found in $help_type help"
        else
            check_fail "Constitution version $CONSTITUTION_VERSION missing from $help_type help"
        fi
    done
}

# Common spelling errors and technical terms validation
validate_spelling() {
    log_info "Validating spelling and terminology..."
    
    # Words that should NOT appear (common misspellings)
    local banned_words=("Javascript" "Miniconda" "constitiution" "reserch")
    
    local help_types=("global" "init" "research" "lecture" "coding" "journal" "office" "private")
    for help_type in "${help_types[@]}"; do
        local content
        content=$(extract_help_content "$help_type")
        
        if [[ "$content" == "ERROR"* ]]; then
            continue
        fi
        
        # Check for banned words (exact matches to avoid false positives)
        for banned in "${banned_words[@]}"; do
            if echo "$content" | grep -q "\b$banned\b"; then
                check_fail "Found misspelled/incorrect term '$banned' in $help_type help"
            fi
        done
        
        # Check for correct technical terms
        if echo "$content" | grep -q "JavaScript" || echo "$content" | grep -q "javascript"; then
            if echo "$content" | grep -q "JavaScript"; then
                check_pass "Correct JavaScript spelling in $help_type help"
            else
                check_fail "Incorrect javascript (lowercase) in $help_type help - should be JavaScript"
            fi
        fi
        
        # Check common correct terms are present where expected
        if echo "$content" | grep -qi "constitution"; then
            check_pass "Constitution terminology found in $help_type help"
        fi
        
        if echo "$content" | grep -qi "dirforge"; then
            check_pass "DirForge tool name found in $help_type help"
        fi
    done
}

# Validate world type descriptions and consistency
validate_world_types() {
    log_info "Validating world type descriptions..."
    
    local world_types=("research" "lecture" "coding" "journal" "office" "private")
    
    # Check each world type for expected content
    for world_type in "${world_types[@]}"; do
        local content
        content=$(extract_help_content "$world_type")
        
        if [[ "$content" == "ERROR"* ]]; then
            continue
        fi
        
        # Check for appropriate descriptions based on world type
        case "$world_type" in
            "research")
                if echo "$content" | grep -qi "Academic research projects with data management"; then
                    check_pass "Correct description for research world type"
                else
                    check_fail "Missing or incorrect description for research world type"
                fi
                ;;
            "lecture")
                if echo "$content" | grep -qi "Educational content with grading workflows"; then
                    check_pass "Correct description for lecture world type"
                else
                    check_fail "Missing or incorrect description for lecture world type"
                fi
                ;;
            "coding")
                if echo "$content" | grep -qi "Software development projects"; then
                    check_pass "Correct description for coding world type"
                else
                    check_fail "Missing or incorrect description for coding world type"
                fi
                ;;
            "journal")
                if echo "$content" | grep -qi "journal-related activities"; then
                    check_pass "Correct description for journal world type"
                else
                    check_fail "Missing or incorrect description for journal world type"
                fi
                ;;
            "office")
                if echo "$content" | grep -qi "Administrative and business documents"; then
                    check_pass "Correct description for office world type"
                else
                    check_fail "Missing or incorrect description for office world type"
                fi
                ;;
            "private")
                if echo "$content" | grep -qi "Personal projects with privacy controls"; then
                    check_pass "Correct description for private world type"
                else
                    check_fail "Missing or incorrect description for private world type"
                fi
                ;;
        esac
    done
}

# Validate command examples and syntax
validate_command_examples() {
    log_info "Validating command examples and syntax..."
    
    local help_types=("global" "init" "research" "lecture" "coding" "journal" "office" "private")
    for help_type in "${help_types[@]}"; do
        local content
        content=$(extract_help_content "$help_type")
        
        if [[ "$content" == "ERROR"* ]]; then
            continue
        fi
        
        # Check for proper dirforge command syntax
        if echo "$content" | grep -q "dirforge"; then
            check_pass "Contains dirforge command examples in $help_type help"
        else
            check_fail "Missing dirforge command examples in $help_type help"
        fi
        
        # Check for proper option formatting (--option)
        if echo "$content" | grep -E -q '\-\-[a-z-]+'; then
            check_pass "Contains properly formatted options in $help_type help"
        fi
        
        # Validate no broken command syntax (avoid false positives on normal indentation)
        if echo "$content" | grep -q "dirforge   " || echo "$content" | grep -q "   --"; then
            check_fail "Found improper spacing in commands in $help_type help"
        fi
    done
}

# Validate formatting consistency
validate_formatting() {
    log_info "Validating formatting consistency..."
    
    local help_types=("global" "init" "research" "lecture" "coding" "journal" "office" "private")
    for help_type in "${help_types[@]}"; do
        local content
        content=$(extract_help_content "$help_type")
        
        if [[ "$content" == "ERROR"* ]]; then
            continue
        fi
        
        # Check for header formatting (should have headers with dashes or have consistent structure)
        if echo "$content" | grep -E -q '^[A-Z][A-Za-z ]+$' && echo "$content" | grep -q '^-\+$'; then
            check_pass "Proper header formatting in $help_type help"
        elif echo "$content" | grep -E -q '^[A-Z][A-Za-z ]+$' && echo "$content" | grep -q '^=\+$'; then
            check_pass "Proper header formatting in $help_type help"  
        elif echo "$content" | grep -qi "Purpose\|Usage\|Options"; then
            check_pass "Basic header structure in $help_type help"
        else
            check_fail "Inconsistent header formatting in $help_type help"
        fi
        
        # Check line length (should not exceed reasonable width for help text)
        local max_line_length
        max_line_length=$(echo "$content" | wc -L)
        if [[ $max_line_length -le 140 ]]; then
            check_pass "Reasonable line lengths in $help_type help (max: $max_line_length)"
        else
            check_fail "Excessive line length in $help_type help (max: $max_line_length)"
        fi
    done
}

# Validate required sections in world-type help
validate_required_sections() {
    log_info "Validating required sections in world-type help..."
    
    local world_types=("research" "lecture" "coding" "journal" "office" "private")
    
    for world_type in "${world_types[@]}"; do
        local content
        content=$(extract_help_content "$world_type")
        
        if [[ "$content" == "ERROR"* ]]; then
            continue
        fi
        
        # All world types should have Purpose section
        if echo "$content" | grep -qi "Purpose"; then
            check_pass "Required section 'Purpose' found in $world_type help"
        else
            check_fail "Required section 'Purpose' missing from $world_type help"
        fi
        
        # Only certain world types need Usage sections (more complex ones)
        if [[ "$world_type" =~ ^(research|lecture|coding)$ ]]; then
            if echo "$content" | grep -qi "Usage"; then
                check_pass "Required section 'Usage' found in $world_type help"
            else
                check_fail "Required section 'Usage' missing from $world_type help"
            fi
        fi
    done
}

# Check for accessibility compliance
validate_accessibility() {
    log_info "Validating accessibility compliance..."
    
    # Test NO_COLOR environment variable compliance
    local content_with_color content_no_color
    content_with_color=$(PAGER=cat "$DIRFORGE_TOOL" --help 2>/dev/null || echo "ERROR")
    content_no_color=$(PAGER=cat NO_COLOR=1 "$DIRFORGE_TOOL" --help 2>/dev/null || echo "ERROR")
    
    if [[ "$content_with_color" != "ERROR" && "$content_no_color" != "ERROR" ]]; then
        # Remove potential ANSI codes for comparison
        local clean_with_color clean_no_color
        clean_with_color=$(echo "$content_with_color" | sed 's/\x1b\[[0-9;]*m//g')
        clean_no_color=$(echo "$content_no_color" | sed 's/\x1b\[[0-9;]*m//g')
        
        if [[ "$clean_with_color" == "$clean_no_color" ]]; then
            check_pass "NO_COLOR compliance verified - content identical when colors disabled"
        else
            check_fail "NO_COLOR compliance failed - content differs when colors disabled"
        fi
    else
        check_fail "Failed to test NO_COLOR compliance"
    fi
}

# Performance validation
validate_performance() {
    log_info "Validating help system performance..."
    
    local help_types=("global" "init" "research")
    for help_type in "${help_types[@]}"; do
        local start_time end_time duration
        start_time=$(date +%s%N)
        
        case "$help_type" in
            "global") PAGER=cat "$DIRFORGE_TOOL" --help >/dev/null 2>&1 ;;
            "init") PAGER=cat "$DIRFORGE_TOOL" init --help >/dev/null 2>&1 ;;
            "research") PAGER=cat "$DIRFORGE_TOOL" init research --help >/dev/null 2>&1 ;;
        esac
        
        end_time=$(date +%s%N)
        duration=$(( (end_time - start_time) / 1000000 )) # Convert to milliseconds
        
        if [[ $duration -le 1000 ]]; then
            check_pass "Performance: $help_type help renders in ${duration}ms (≤1000ms)"
        else
            check_fail "Performance: $help_type help takes ${duration}ms (>1000ms target)"
        fi
    done
}

# Main validation runner
run_validation() {
    log_info "Starting help content validation..."
    echo
    
    validate_dependencies
    echo
    
    if ! source_help_libraries; then
        log_error "Cannot continue validation - failed to source help libraries"
        return 1
    fi
    
    validate_constitution_references
    echo
    
    validate_spelling
    echo
    
    validate_world_types
    echo
    
    validate_command_examples
    echo
    
    validate_formatting
    echo
    
    validate_required_sections
    echo
    
    validate_accessibility
    echo
    
    validate_performance
    echo
}

# Report validation results
show_validation_summary() {
    echo "${BLUE}================================${RESET}"
    echo "${BLUE} HELP CONTENT VALIDATION SUMMARY${RESET}"
    echo "${BLUE}================================${RESET}"
    echo
    echo "Total Checks: $TOTAL_CHECKS"
    echo "${GREEN}Passed: $PASSED_CHECKS${RESET}"
    echo "${RED}Failed: $FAILED_CHECKS${RESET}"
    echo
    
    if [[ $FAILED_CHECKS -gt 0 ]]; then
        echo "${RED}VALIDATION FAILED${RESET}"
        echo
        echo "Errors found:"
        for error in "${VALIDATION_ERRORS[@]}"; do
            echo "  ${RED}•${RESET} $error"
        done
        echo
        echo "Please fix the above issues before proceeding."
        return 1
    else
        echo "${GREEN}✓ ALL VALIDATIONS PASSED${RESET}"
        echo
        echo "Help content is valid and ready for use."
        return 0
    fi
}

# Main execution
main() {
    init_validation_colors
    
    # Change to project root for consistent paths
    cd "$PROJECT_ROOT"
    
    if run_validation; then
        show_validation_summary
    else
        show_validation_summary
        return 1
    fi
}

# Run only if executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi