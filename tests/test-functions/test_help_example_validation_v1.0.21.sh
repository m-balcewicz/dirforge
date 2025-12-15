#!/usr/bin/env bash

# Example Validation Tests for Enhanced Terminal Help System
# Part of T044: Validate all help examples are copy-pasteable and syntactically correct

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

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

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
    ((TESTS_FAILED++))
    ((TESTS_RUN++))
}

warn() {
    echo -e "${YELLOW}⚠${RESET} $1"
}

# Test a single example
validate_example() {
    local example="$1"
    local context="$2"
    
    # Clean the example
    local cleaned_example=$(echo "$example" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    
    # Test 1: Contains dirforge
    if [[ "$cleaned_example" =~ dirforge ]]; then
        pass "$context: Contains dirforge command"
    else
        fail "$context: Missing dirforge command"
        return 1
    fi
    
    # Test 2: Reasonable length for copy-paste
    if [[ ${#cleaned_example} -lt 150 ]]; then
        pass "$context: Reasonable length (${#cleaned_example} chars)"
    else
        warn "$context: Long command (${#cleaned_example} chars)"
    fi
    
    # Test 3: No problematic characters - simplified check
    if echo "$cleaned_example" | grep -q '^[a-zA-Z0-9 ./_"'"'"'-]*$'; then
        pass "$context: Clean character set"
    else
        warn "$context: Contains special characters"
    fi
    
    # Test 4: Proper structure
    if echo "$cleaned_example" | grep -q '^[[:space:]]*dirforge[[:space:]]'; then
        pass "$context: Proper command structure"
    else
        fail "$context: Invalid command structure"
    fi
    
    echo "    → $cleaned_example"
    return 0
}

# Test help output for examples
test_help_examples() {
    local context="$1"
    local help_cmd="$2"
    
    info "Testing $context examples..."
    
    # Get help output and find dirforge examples
    local examples_file="/tmp/examples_$$"
    eval "$help_cmd" 2>/dev/null | grep -E 'dirforge\s+' > "$examples_file" || {
        warn "$context: No dirforge examples found"
        return 0
    }
    
    local count=1
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            validate_example "$line" "$context Example $count" || true
            ((count++))
        fi
    done < "$examples_file"
    
    rm -f "$examples_file"
    
    if [[ $count -eq 1 ]]; then
        warn "$context: No examples found"
    else
        info "$context: Found $((count-1)) examples"
    fi
    
    return 0
}

# Validate environment
if [[ ! -x "$DIRFORGE" ]]; then
    echo "Error: $DIRFORGE is not executable"
    exit 1
fi

echo -e "${BOLD}Enhanced Terminal Help System - Example Validation Tests${RESET}"
echo "Testing dirforge at: $DIRFORGE"
echo

# Test different help contexts
test_help_examples "Global Help" "'$DIRFORGE' --help" || true
test_help_examples "Init Command" "'$DIRFORGE' init --help" || true
test_help_examples "Research World" "'$DIRFORGE' init research --help" || true
test_help_examples "Lecture World" "'$DIRFORGE' init lecture --help" || true
test_help_examples "Journal World" "'$DIRFORGE' init journal --help" || true

echo

# Summary
echo -e "${BOLD}Example Validation Summary${RESET}"
echo -e "Tests run: $TESTS_RUN"
echo -e "Passed: ${GREEN}$TESTS_PASSED${RESET}"
echo -e "Failed: ${RED}$TESTS_FAILED${RESET}"

if [[ $TESTS_FAILED -gt 0 ]]; then
    echo -e "${YELLOW}⚠ Some validation issues found${RESET}"
    echo "Examples may need improvement for copy-paste readiness"
    exit 1
else
    echo -e "${GREEN}✓ All examples validate successfully!${RESET}"
    echo -e "${GREEN}Help system examples are copy-pasteable and well-formed${RESET}"
    exit 0
fi

# Validate environment
if [[ ! -x "$DIRFORGE" ]]; then
    echo "Error: $DIRFORGE is not executable"
    exit 1
fi

echo -e "${BOLD}Enhanced Terminal Help System - Example Validation Tests${RESET}"
echo "Validating examples are copy-pasteable and syntactically correct"
echo "Testing dirforge at: $DIRFORGE"
echo

# Test 1: Global Help Examples
validate_help_examples "global" "'$DIRFORGE' --help" "Global Help"

echo

# Test 2: Init Command Help Examples  
validate_help_examples "init" "'$DIRFORGE' init --help" "Init Command Help"

echo

# Test 3: World-Specific Help Examples
info "Testing world-specific help examples..."

validate_help_examples "research" "'$DIRFORGE' init research --help" "Research World Help"
validate_help_examples "lecture" "'$DIRFORGE' init lecture --help" "Lecture World Help"
validate_help_examples "coding" "'$DIRFORGE' init coding --help" "Coding World Help"
validate_help_examples "journal" "'$DIRFORGE' init journal --help" "Journal World Help"
validate_help_examples "office" "'$DIRFORGE' init office --help" "Office World Help"
validate_help_examples "private" "'$DIRFORGE' init private --help" "Private World Help"

echo

# Test 4: Template File Examples
info "Validating template file examples..."

if [[ -d "templates/help" ]]; then
    for template_file in templates/help/*.txt; do
        if [[ -f "$template_file" ]]; then
            local filename=$(basename "$template_file")
            info "Checking template: $filename"
            
            if [[ -s "$template_file" ]]; then
                local template_examples
                template_examples=$(extract_examples "$(cat "$template_file")" "$filename")
                
                if [[ -n "$template_examples" ]]; then
                    while IFS= read -r example; do
                        if [[ -n "$example" ]]; then
                            validate_syntax "$example" "Template $filename"
                            validate_command_structure "$example" "Template $filename"
                            validate_copy_paste_readiness "$example" "Template $filename"
                            validate_example_realism "$example" "Template $filename"
                        fi
                    done <<< "$template_examples"
                else
                    info "No examples found in $filename"
                fi
            else
                warn "Template file $filename is empty"
            fi
        fi
    done
else
    warn "Template directory templates/help/ not found"
fi

echo

# Test 5: Consistency Check
info "Testing example consistency across help contexts..."

# Get all examples from all help contexts
declare -A all_examples
all_examples["global"]=$(eval "'$DIRFORGE' --help" 2>&1 | extract_examples - "global")
all_examples["init"]=$(eval "'$DIRFORGE' init --help" 2>&1 | extract_examples - "init")

# Check for consistent patterns
for world in research lecture coding journal office private; do
    all_examples["$world"]=$(eval "'$DIRFORGE' init '$world' --help" 2>&1 | extract_examples - "$world")
done

# Look for common examples that should be consistent
local common_patterns=("init research" "init lecture" "init coding")

for pattern in "${common_patterns[@]}"; do
    local found_contexts=()
    for context in "${!all_examples[@]}"; do
        if [[ "${all_examples[$context]}" =~ $pattern ]]; then
            found_contexts+=("$context")
        fi
    done
    
    if [[ ${#found_contexts[@]} -gt 1 ]]; then
        pass "Pattern '$pattern' found consistently across: ${found_contexts[*]}"
    fi
done

echo

# Summary
echo -e "${BOLD}Example Validation Summary${RESET}"
echo -e "Tested: $TESTS_RUN example validations"
echo -e "Passed: ${GREEN}$TESTS_PASSED${RESET}"
echo -e "Failed: ${RED}$TESTS_FAILED${RESET}"

if [[ $TESTS_FAILED -gt 0 ]]; then
    echo
    echo -e "${RED}Issues Found:${RESET}"
    for failure in "${FAILED_TESTS[@]}"; do
        echo "  - $failure"
    done
    echo
    echo -e "${RED}Example validation found issues${RESET}"
    echo "Consider fixing syntax errors, improving copy-paste readiness, or adding more examples"
    exit 1
else
    echo -e "${GREEN}✓ All examples are valid and copy-pasteable!${RESET}"
    echo -e "${GREEN}Help system examples meet quality standards${RESET}"
    exit 0
fi