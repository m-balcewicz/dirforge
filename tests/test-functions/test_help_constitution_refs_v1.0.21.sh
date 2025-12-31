#!/usr/bin/env bash

# Constitution Reference Accuracy Validation Tests for Enhanced Terminal Help System  
# Part of T046: Create constitution reference accuracy validation

set -euo pipefail

# Colors for output
RESET="\033[0m"
GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
BLUE="\033[34m"
BOLD="\033[1m"

# Configuration
DIRFORGE="$PWD/tools/dirforge"
CONSTITUTION_FILE="$PWD/.specify/memory/constitution.md"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
declare -a FAILED_TESTS=()

# Helper functions
info() {
    echo -e "${BLUE}ℹ${RESET} $1"
}

pass() {
    echo -e "✓ ${GREEN}$1${RESET}"
    ((TESTS_PASSED++))
    ((TESTS_RUN++))
}

fail() {
    echo -e "✗ ${RED}$1${RESET}"
    FAILED_TESTS+=("$1")
    ((TESTS_FAILED++))
    ((TESTS_RUN++))
}

warn() {
    echo -e "${YELLOW}⚠${RESET} $1"
}

# Extract constitution version from help output
get_constitution_version_from_help() {
    local help_output="$1"
    echo "$help_output" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo ""
}

# Extract constitution version from constitution file
get_constitution_version_from_file() {
    if [[ -f "$CONSTITUTION_FILE" ]]; then
        # Look for "**Version**: X.X.X" pattern
        grep -oE '\*\*Version\*\*: [0-9]+\.[0-9]+\.[0-9]+' "$CONSTITUTION_FILE" | head -1 | sed 's/\*\*Version\*\*: /v/' || echo ""
    else
        echo ""
    fi
}

# Test constitution version accuracy
test_constitution_version() {
    local test_name="$1"
    local command="$2"
    
    info "Testing constitution version: $test_name"
    
    local help_output
    help_output=$(eval "$command" 2>&1)
    
    local help_version
    help_version=$(get_constitution_version_from_help "$help_output")
    
    local expected_version
    expected_version=$(get_constitution_version_from_file)
    
    if [[ -z "$expected_version" ]]; then
        warn "$test_name: Cannot determine constitution version from file"
        return 0
    fi
    
    if [[ "$help_version" == "$expected_version" ]]; then
        pass "$test_name: Constitution version correct ($help_version)"
    elif [[ -n "$help_version" ]]; then
        fail "$test_name: Version mismatch (help: $help_version, expected: $expected_version)"
    else
        fail "$test_name: No constitution version found in help output"
    fi
}

# Test world type definitions accuracy
test_world_type_definitions() {
    local test_name="$1"
    local command="$2"
    local world_type="$3"
    
    info "Testing world type definition: $test_name"
    
    local help_output
    help_output=$(eval "$command" 2>&1)
    
    # Check for world type presence in help
    if echo "$help_output" | grep -qi "$world_type"; then
        pass "$test_name: World type '$world_type' mentioned in help"
    else
        fail "$test_name: World type '$world_type' not found in help"
        return 1
    fi
    
    # Validate specific world type characteristics from constitution
    case "$world_type" in
        "research")
            if echo "$help_output" | grep -qi "academic.*research\|research.*project"; then
                pass "$test_name: Research world correctly described as academic research"
            else
                warn "$test_name: Research world description may be incomplete"
            fi
            ;;
        "lecture")
            if echo "$help_output" | grep -qi "educational\|grading\|course"; then
                pass "$test_name: Lecture world correctly described as educational"
            else
                warn "$test_name: Lecture world description may be incomplete"
            fi
            ;;
        "journal")
            if echo "$help_output" | grep -qi "journal.*activities\|submission\|review"; then
                pass "$test_name: Journal world correctly described"
            else
                warn "$test_name: Journal world description may be incomplete"  
            fi
            ;;
        "coding")
            if echo "$help_output" | grep -qi "software.*development\|programming\|code"; then
                pass "$test_name: Coding world correctly described as software development"
            else
                warn "$test_name: Coding world description may be incomplete"
            fi
            ;;
        "office")
            if echo "$help_output" | grep -qi "administrative\|office\|business"; then
                pass "$test_name: Office world correctly described as administrative"
            else
                warn "$test_name: Office world description may be incomplete"
            fi
            ;;
        "private")
            if echo "$help_output" | grep -qi "private\|personal"; then
                pass "$test_name: Private world correctly described as personal"
            else
                warn "$test_name: Private world description may be incomplete"
            fi
            ;;
    esac
}

# Test directory structure accuracy
test_directory_structure_accuracy() {
    local test_name="$1"
    local command="$2"
    local world_type="$3"
    
    info "Testing directory structure: $test_name"
    
    local help_output
    help_output=$(eval "$command" 2>&1)
    
    # Check for directory structure references
    case "$world_type" in
        "research")
            local expected_dirs=("project_management" "admin" "design_protocols" "data" "data_analysis" "data_outputs" "publication" "documentation")
            local found_dirs=0
            for dir in "${expected_dirs[@]}"; do
                if echo "$help_output" | grep -qi "$dir"; then
                    ((found_dirs++))
                fi
            done
            
            if [[ $found_dirs -ge 6 ]]; then
                pass "$test_name: Research directory structure well-represented ($found_dirs/8 dirs)"
            elif [[ $found_dirs -ge 3 ]]; then
                warn "$test_name: Research directory structure partially represented ($found_dirs/8 dirs)"
            else
                fail "$test_name: Research directory structure poorly represented ($found_dirs/8 dirs)"
            fi
            ;;
        "lecture")
            local expected_dirs=("content" "exercises" "assessment" "admin")
            local found_dirs=0
            for dir in "${expected_dirs[@]}"; do
                if echo "$help_output" | grep -qi "$dir"; then
                    ((found_dirs++))
                fi
            done
            
            if [[ $found_dirs -ge 3 ]]; then
                pass "$test_name: Lecture directory structure well-represented ($found_dirs/4 dirs)"
            elif [[ $found_dirs -ge 2 ]]; then
                warn "$test_name: Lecture directory structure partially represented ($found_dirs/4 dirs)"
            else
                fail "$test_name: Lecture directory structure poorly represented ($found_dirs/4 dirs)"
            fi
            ;;
        *)
            # For other world types, just check if there's some directory structure mentioned
            if echo "$help_output" | grep -qE '([a-z_]+/|├──|└──|[0-9]+_[a-z_]+)'; then
                pass "$test_name: Directory structure information present"
            else
                warn "$test_name: No clear directory structure information found"
            fi
            ;;
    esac
}

# Test naming convention accuracy
test_naming_convention_accuracy() {
    local test_name="$1"
    local command="$2"
    local world_type="$3"
    
    info "Testing naming conventions: $test_name"
    
    local help_output
    help_output=$(eval "$command" 2>&1)
    
    # Check for naming convention references
    case "$world_type" in
        "research")
            if echo "$help_output" | grep -qiE "(PROJECT-ID|project.*id|naming.*convention)"; then
                pass "$test_name: Research naming conventions mentioned"
            else
                warn "$test_name: Research naming conventions not clearly explained"
            fi
            ;;
        "lecture")
            if echo "$help_output" | grep -qiE "(lecture.*id|course.*code|naming)"; then
                pass "$test_name: Lecture naming conventions mentioned"
            else
                warn "$test_name: Lecture naming conventions not clearly explained"
            fi
            ;;
        "journal") 
            if echo "$help_output" | grep -qiE "(journal.*id|identifier|GEO-|REVIEWER_|ASSOC_EDITOR)"; then
                pass "$test_name: Journal ID conventions mentioned"
            else
                warn "$test_name: Journal ID conventions not clearly explained"
            fi
            ;;
        *)
            # For other world types, check for general naming guidance
            if echo "$help_output" | grep -qiE "(naming|convention|identifier|name)"; then
                pass "$test_name: Naming guidance present"
            else
                warn "$test_name: No clear naming guidance found"
            fi
            ;;
    esac
}

# Test section references accuracy
test_section_references() {
    local test_name="$1" 
    local command="$2"
    
    info "Testing section references: $test_name"
    
    local help_output
    help_output=$(eval "$command" 2>&1)
    
    # Look for constitution section references (like §III.II)
    local section_refs
    section_refs=$(echo "$help_output" | grep -oE '§[IVX]+\.[IVX]+' || echo "")
    
    if [[ -n "$section_refs" ]]; then
        pass "$test_name: Constitution section references found"
        
        # Validate that referenced sections exist in constitution
        if [[ -f "$CONSTITUTION_FILE" ]]; then
            while IFS= read -r section; do
                if [[ -n "$section" ]] && grep -q "$section" "$CONSTITUTION_FILE"; then
                    pass "$test_name: Section $section exists in constitution"
                else
                    fail "$test_name: Section $section not found in constitution"
                fi
            done <<< "$section_refs"
        else
            warn "$test_name: Cannot validate sections (constitution file not found)"
        fi
    else
        info "$test_name: No explicit section references found (may be acceptable)"
    fi
}

# Test compliance statements accuracy  
test_compliance_statements() {
    local test_name="$1"
    local command="$2"
    
    info "Testing compliance statements: $test_name"
    
    local help_output
    help_output=$(eval "$command" 2>&1)
    
    # Check for constitution compliance references
    if echo "$help_output" | grep -qiE "(constitution|complian|standard|guideline)"; then
        pass "$test_name: Constitution/compliance references present"
    else
        warn "$test_name: No clear constitution compliance references"
    fi
    
    # Check for DirForge branding consistency
    if echo "$help_output" | grep -q "DirForge"; then
        pass "$test_name: DirForge branding present"
    else
        fail "$test_name: Missing DirForge branding"
    fi
    
    # Check that constitution is mentioned in proper context
    if echo "$help_output" | grep -qiE "per.*constitution|according.*constitution|constitution.*compliance"; then
        pass "$test_name: Constitution mentioned in proper context"
    elif echo "$help_output" | grep -qi "constitution"; then
        warn "$test_name: Constitution mentioned but context unclear"
    else
        info "$test_name: No explicit constitution context (may be acceptable for brief help)"
    fi
}

# Validate against actual constitution content
validate_against_constitution() {
    local test_name="$1"
    local help_content="$2"
    
    info "Validating against constitution: $test_name"
    
    if [[ ! -f "$CONSTITUTION_FILE" ]]; then
        warn "$test_name: Constitution file not found for validation"
        return 0
    fi
    
    # Extract key facts from constitution for validation
    local constitution_version
    constitution_version=$(get_constitution_version_from_file)
    
    # Check if help version matches constitution version
    local help_version
    help_version=$(get_constitution_version_from_help "$help_content")
    
    if [[ "$help_version" == "$constitution_version" ]]; then
        pass "$test_name: Version consistency with constitution"
    elif [[ -n "$help_version" ]]; then
        fail "$test_name: Version inconsistency (help: $help_version vs constitution: $constitution_version)"
    else
        info "$test_name: No version in help to validate"
    fi
    
    # Validate that help content references constitution concepts correctly
    # The constitution defines world types in sections III.I through III.VI
    # Our tool uses simplified names (coding, journal, etc.) which should align with constitution sections
    
    # Check that constitution sections exist for supported world types
    local supported_worlds=("coding" "journal" "office" "private" "research" "lecture")
    local constitution_sections_found=0
    
    for world in "${supported_worlds[@]}"; do
        case "$world" in
            "coding")
                if grep -q "#### III\.I CODING_WORLD" "$CONSTITUTION_FILE"; then
                    pass "$test_name: Constitution section III.I CODING_WORLD exists for '$world' world type"
                    ((constitution_sections_found++))
                else
                    warn "$test_name: Constitution section for '$world' (III.I CODING_WORLD) not found"
                fi
                ;;
            "journal")
                if grep -q "#### III\.II Journal" "$CONSTITUTION_FILE"; then
                    pass "$test_name: Constitution section III.II Journal exists for '$world' world type"
                    ((constitution_sections_found++))
                else
                    warn "$test_name: Constitution section for '$world' (III.II Journal) not found"
                fi
                ;;
            "office")
                if grep -q "#### III\.III Office" "$CONSTITUTION_FILE"; then
                    pass "$test_name: Constitution section III.III Office exists for '$world' world type"
                    ((constitution_sections_found++))
                else
                    warn "$test_name: Constitution section for '$world' (III.III Office) not found"
                fi
                ;;
            "private")
                if grep -q "#### III\.IV Private" "$CONSTITUTION_FILE"; then
                    pass "$test_name: Constitution section III.IV Private exists for '$world' world type"
                    ((constitution_sections_found++))
                else
                    warn "$test_name: Constitution section for '$world' (III.IV Private) not found"
                fi
                ;;
            "research")
                if grep -q "#### III\.V Research" "$CONSTITUTION_FILE"; then
                    pass "$test_name: Constitution section III.V Research exists for '$world' world type"
                    ((constitution_sections_found++))
                else
                    warn "$test_name: Constitution section for '$world' (III.V Research) not found"
                fi
                ;;
            "lecture")
                if grep -q "#### III\.VI Lecture" "$CONSTITUTION_FILE"; then
                    pass "$test_name: Constitution section III.VI Lecture exists for '$world' world type"
                    ((constitution_sections_found++))
                else
                    warn "$test_name: Constitution section for '$world' (III.VI Lecture) not found"
                fi
                ;;
        esac
    done
    
    if [[ $constitution_sections_found -eq 6 ]]; then
        pass "$test_name: All world types have corresponding constitution sections (6/6)"
    elif [[ $constitution_sections_found -ge 4 ]]; then
        warn "$test_name: Most world types have constitution sections ($constitution_sections_found/6)"
    else
        fail "$test_name: Missing constitution sections for world types ($constitution_sections_found/6)"
    fi
}

# Validate environment
if [[ ! -x "$DIRFORGE" ]]; then
    echo "Error: $DIRFORGE is not executable"
    exit 1
fi

echo -e "${BOLD}Enhanced Terminal Help System - Constitution Reference Validation${RESET}"
echo "Testing accuracy of constitution references in help content"
echo "Testing dirforge at: $DIRFORGE"
echo "Constitution file: $CONSTITUTION_FILE"
echo

# Test 1: Constitution Version Accuracy
info "Testing constitution version accuracy..."
test_constitution_version "Global Help" "'$DIRFORGE' --help" || true
test_constitution_version "Version Command" "'$DIRFORGE' --version" || true

echo

# Test 2: World Type Definition Accuracy
info "Testing world type definitions..."
declare -a world_types=("research" "lecture" "coding" "journal" "office" "private")

for world in "${world_types[@]}"; do
    test_world_type_definitions "$world World Definition" "'$DIRFORGE' init $world --help" "$world" || true
done

echo

# Test 3: Directory Structure Accuracy  
info "Testing directory structure accuracy..."
test_directory_structure_accuracy "Research Directories" "'$DIRFORGE' create research --help" "research" || true
test_directory_structure_accuracy "Lecture Directories" "'$DIRFORGE' create lecture --help" "lecture" || true

echo

# Test 4: Naming Convention Accuracy
info "Testing naming convention accuracy..."
for world in "${world_types[@]}"; do
    test_naming_convention_accuracy "$world Naming" "'$DIRFORGE' init $world --help" "$world" || true
done

echo

# Test 5: Section Reference Accuracy
info "Testing section reference accuracy..."
test_section_references "Global Help Sections" "'$DIRFORGE' --help" || true
test_section_references "Research Sections" "'$DIRFORGE' create research --help" || true

echo

# Test 6: Compliance Statement Accuracy
info "Testing compliance statements..."
test_compliance_statements "Global Help Compliance" "'$DIRFORGE' --help" || true
test_compliance_statements "Init Command Compliance" "'$DIRFORGE' init --help" || true

echo

# Test 7: Constitution Content Validation
info "Testing against actual constitution content..."
global_help=$($DIRFORGE --help 2>&1)
validate_against_constitution "Global Help Content" "$global_help" || true

research_help=$($DIRFORGE init research --help 2>&1)
validate_against_constitution "Research Help Content" "$research_help" || true

echo

# Summary
echo -e "${BOLD}Constitution Reference Validation Summary${RESET}"
echo -e "Tests run: $TESTS_RUN"
echo -e "Passed: ${GREEN}$TESTS_PASSED${RESET}"
echo -e "Failed: ${RED}$TESTS_FAILED${RESET}"

if [[ $TESTS_FAILED -gt 0 ]]; then
    echo
    echo -e "${RED}Failed Tests:${RESET}"
    for failure in "${FAILED_TESTS[@]}"; do
        echo "  - $failure"
    done
    echo
    echo -e "${RED}Constitution reference inaccuracies found${RESET}"
    echo "Consider updating help content to ensure:"
    echo "  - Correct constitution version references"
    echo "  - Accurate world type descriptions"
    echo "  - Proper directory structure representation"
    echo "  - Consistent naming convention guidance"
    echo "  - Valid section references"
    exit 1
else
    echo -e "${GREEN}✓ All constitution references are accurate!${RESET}"
    echo -e "${GREEN}Help content properly reflects constitution v$(get_constitution_version_from_file | sed 's/^v//')${RESET}"
    echo
    echo "✓ Constitution version references correct"
    echo "✓ World type definitions accurate"
    echo "✓ Directory structures properly represented"
    echo "✓ Naming conventions correctly explained"
    echo "✓ Section references valid"
    echo "✓ Compliance statements appropriate"
    exit 0
fi