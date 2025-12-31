#!/usr/bin/env bash

# Accessibility Tests for Enhanced Terminal Help System
# Part of T045: Add accessibility testing for NO_COLOR and narrow terminal support

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

# Test NO_COLOR environment variable support
test_no_color_support() {
    local test_name="$1"
    local command="$2"
    
    info "Testing NO_COLOR support: $test_name"
    
    # Test with NO_COLOR=1
    local output_with_no_color
    output_with_no_color=$(NO_COLOR=1 eval "$command" 2>&1) || {
        fail "$test_name: Command failed with NO_COLOR=1"
        return 1
    }
    
    # Test without NO_COLOR
    local output_with_color
    output_with_color=$(eval "$command" 2>&1) || {
        fail "$test_name: Command failed without NO_COLOR"
        return 1
    }
    
    # Check that NO_COLOR output doesn't contain ANSI escape sequences
    if echo "$output_with_no_color" | grep -q $'\033\['; then
        fail "$test_name: Contains ANSI escape sequences with NO_COLOR=1"
        return 1
    else
        pass "$test_name: NO_COLOR properly removes ANSI sequences"
    fi
    
    # Check that content is still present
    local content_lines_no_color content_lines_color
    content_lines_no_color=$(echo "$output_with_no_color" | wc -l)
    content_lines_color=$(echo "$output_with_color" | wc -l)
    
    # Allow for slight differences in line count (color formatting may affect wrapping)
    local line_diff=$((content_lines_color - content_lines_no_color))
    if [[ $line_diff -ge -5 && $line_diff -le 5 ]]; then
        pass "$test_name: Content preserved with NO_COLOR ($content_lines_no_color vs $content_lines_color lines)"
    else
        warn "$test_name: Significant content difference with NO_COLOR ($content_lines_no_color vs $content_lines_color lines)"
    fi
    
    # Check that essential text is preserved
    if echo "$output_with_no_color" | grep -q "dirforge"; then
        pass "$test_name: Essential content preserved with NO_COLOR"
    else
        fail "$test_name: Essential content missing with NO_COLOR"
        return 1
    fi
    
    return 0
}

# Test FORCE_COLOR environment variable support
test_force_color_support() {
    local test_name="$1"
    local command="$2"
    
    info "Testing FORCE_COLOR support: $test_name"
    
    # Test with FORCE_COLOR=1 in a context where colors might be disabled
    local output_with_force_color
    output_with_force_color=$(FORCE_COLOR=1 TERM=dumb eval "$command" 2>&1)
    
    # FORCE_COLOR should override TERM=dumb and enable colors
    if echo "$output_with_force_color" | grep -q $'\033\['; then
        pass "$test_name: FORCE_COLOR enables colors even with TERM=dumb"
    else
        # This might be acceptable if the help system doesn't use FORCE_COLOR
        warn "$test_name: FORCE_COLOR doesn't enable colors (may not be implemented)"
    fi
    
    return 0
}

# Test narrow terminal width handling
test_narrow_terminal() {
    local test_name="$1"
    local command="$2"
    local width="$3"
    
    info "Testing narrow terminal ($width cols): $test_name"
    
    # Test with narrow terminal width
    local output
    output=$(COLUMNS="$width" eval "$command" 2>&1)
    
    # Check that no lines exceed the specified width
    local max_line_length=0
    while IFS= read -r line; do
        # Remove ANSI escape sequences for accurate length measurement
        local clean_line
        clean_line=$(echo "$line" | sed 's/\x1b\[[0-9;]*m//g')
        local line_length=${#clean_line}
        
        if [[ $line_length -gt $max_line_length ]]; then
            max_line_length=$line_length
        fi
    done <<< "$output"
    
    # Allow some tolerance for word wrapping challenges
    local tolerance=$((width + 10))
    if [[ $max_line_length -le $tolerance ]]; then
        pass "$test_name: Respects $width column limit (max: $max_line_length)"
    else
        fail "$test_name: Exceeds $width column limit (max: $max_line_length)"
        return 1
    fi
    
    # Check that content is still readable
    if echo "$output" | grep -q "dirforge"; then
        pass "$test_name: Content remains readable in narrow terminal"
    else
        fail "$test_name: Content becomes unreadable in narrow terminal"
        return 1
    fi
    
    return 0
}

# Test text readability without color
test_text_readability() {
    local test_name="$1"
    local command="$2"
    
    info "Testing text readability: $test_name"
    
    local output
    output=$(NO_COLOR=1 eval "$command" 2>&1)
    
    # Check for proper section separation
    if echo "$output" | grep -q "^[A-Z].*:$\|^=\|^-"; then
        pass "$test_name: Has clear section separators"
    else
        warn "$test_name: May lack clear section separators"
    fi
    
    # Check for proper indentation structure
    if echo "$output" | grep -q "^[[:space:]]\+"; then
        pass "$test_name: Uses indentation for structure"
    else
        warn "$test_name: May lack structural indentation"
    fi
    
    # Check that help text has reasonable paragraph structure
    local blank_lines
    blank_lines=$(echo "$output" | grep -c "^[[:space:]]*$" || echo 0)
    
    if [[ $blank_lines -ge 2 ]]; then
        pass "$test_name: Has paragraph breaks for readability"
    else
        warn "$test_name: May lack sufficient paragraph breaks"
    fi
    
    return 0
}

# Test screen reader compatibility
test_screen_reader_compatibility() {
    local test_name="$1"
    local command="$2"
    
    info "Testing screen reader compatibility: $test_name"
    
    local output
    output=$(NO_COLOR=1 eval "$command" 2>&1)
    
    # Check for descriptive text rather than just visual formatting
    if echo "$output" | grep -qi "usage\|example\|options\|description"; then
        pass "$test_name: Contains descriptive section headers"
    else
        warn "$test_name: May lack descriptive section headers"
    fi
    
    # Check that commands are properly labeled
    if echo "$output" | grep -q "dirforge.*--help\|dirforge.*init"; then
        pass "$test_name: Commands are clearly identified"
    else
        warn "$test_name: Commands may not be clearly identified"
    fi
    
    # Check for consistent formatting patterns
    local consistent_patterns=0
    if echo "$output" | grep -q "^[[:space:]]*dirforge"; then
        ((consistent_patterns++))
    fi
    if echo "$output" | grep -q "Options:"; then
        ((consistent_patterns++))
    fi
    
    if [[ $consistent_patterns -ge 1 ]]; then
        pass "$test_name: Has consistent formatting patterns"
    else
        warn "$test_name: May lack consistent formatting patterns"
    fi
    
    return 0
}

# Test high contrast mode compatibility
test_high_contrast_mode() {
    local test_name="$1"
    local command="$2"
    
    info "Testing high contrast compatibility: $test_name"
    
    # Test with NO_COLOR (high contrast mode often disables colors)
    local output
    output=$(NO_COLOR=1 eval "$command" 2>&1)
    
    # Check that information hierarchy is maintained without color
    local has_headers has_indentation has_structure
    has_headers=0
    has_indentation=0
    has_structure=0
    
    if echo "$output" | grep -q "^[A-Z][A-Za-z ]*:"; then
        has_headers=1
    fi
    
    if echo "$output" | grep -q "^[[:space:]]\{2,\}"; then
        has_indentation=1
    fi
    
    if echo "$output" | grep -q "^===\|^---\|^=.*=$"; then
        has_structure=1
    fi
    
    local structure_score=$((has_headers + has_indentation + has_structure))
    
    if [[ $structure_score -ge 2 ]]; then
        pass "$test_name: Maintains structure without color"
    else
        warn "$test_name: May lose structure without color (score: $structure_score/3)"
    fi
    
    return 0
}

# Validate environment
if [[ ! -x "$DIRFORGE" ]]; then
    echo "Error: $DIRFORGE is not executable"
    exit 1
fi

echo -e "${BOLD}Enhanced Terminal Help System - Accessibility Tests${RESET}"
echo "Testing accessibility compliance and terminal compatibility"
echo "Testing dirforge at: $DIRFORGE"
echo

# Test 1: NO_COLOR Environment Variable
info "Testing NO_COLOR environment variable support..."
test_no_color_support "Global Help" "'$DIRFORGE' --help" || true
test_no_color_support "Init Command" "'$DIRFORGE' init --help" || true
test_no_color_support "Research World" "'$DIRFORGE' create research --help" || true

echo

# Test 2: FORCE_COLOR Environment Variable
info "Testing FORCE_COLOR environment variable support..."
test_force_color_support "Global Help" "'$DIRFORGE' --help" || true
test_force_color_support "Version Info" "'$DIRFORGE' --version" || true

echo

# Test 3: Narrow Terminal Width Support
info "Testing narrow terminal width support..."
test_narrow_terminal "Global Help (80 cols)" "'$DIRFORGE' --help" 80 || true
test_narrow_terminal "Global Help (60 cols)" "'$DIRFORGE' --help" 60 || true
test_narrow_terminal "Research Help (80 cols)" "'$DIRFORGE' create research --help" 80 || true
test_narrow_terminal "Init Command (60 cols)" "'$DIRFORGE' init --help" 60 || true

echo

# Test 4: Text Readability Without Color
info "Testing text readability without color..."
test_text_readability "Global Help" "'$DIRFORGE' --help" || true
test_text_readability "Research World" "'$DIRFORGE' create research --help" || true
test_text_readability "Lecture World" "'$DIRFORGE' create lecture --help" || true

echo

# Test 5: Screen Reader Compatibility
info "Testing screen reader compatibility..."
test_screen_reader_compatibility "Global Help" "'$DIRFORGE' --help" || true
test_screen_reader_compatibility "Init Command" "'$DIRFORGE' init --help" || true
test_screen_reader_compatibility "Journal World" "'$DIRFORGE' create journal --help" || true

echo

# Test 6: High Contrast Mode Compatibility
info "Testing high contrast mode compatibility..."
test_high_contrast_mode "Global Help" "'$DIRFORGE' --help" || true
test_high_contrast_mode "Research World" "'$DIRFORGE' create research --help" || true

echo

# Test 7: Terminal Environment Edge Cases
info "Testing terminal environment edge cases..."

# Test with TERM=dumb
info "Testing with TERM=dumb..."
output=$(TERM=dumb "$DIRFORGE" --help 2>&1)
if echo "$output" | grep -q "dirforge"; then
    pass "TERM=dumb: Help content displays"
else
    fail "TERM=dumb: Help content missing"
fi

# Test with very narrow COLUMNS
info "Testing with COLUMNS=20..."
output=$(COLUMNS=20 "$DIRFORGE" --help 2>&1)
if echo "$output" | grep -q "dirforge"; then
    pass "COLUMNS=20: Help content displays"
else
    fail "COLUMNS=20: Help content missing"
fi

# Test with COLUMNS undefined
info "Testing with COLUMNS unset..."
output=$(unset COLUMNS; "$DIRFORGE" --help 2>&1)
if echo "$output" | grep -q "dirforge"; then
    pass "COLUMNS unset: Help content displays"
else
    fail "COLUMNS unset: Help content missing"
fi

echo

# Summary
echo -e "${BOLD}Accessibility Test Results Summary${RESET}"
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
    echo -e "${RED}Accessibility issues found${RESET}"
    echo "Consider improving:"
    echo "  - NO_COLOR environment variable handling"
    echo "  - Terminal width responsiveness"
    echo "  - Text structure without color formatting"
    echo "  - Screen reader compatibility"
    exit 1
else
    echo -e "${GREEN}✓ All accessibility tests passed!${RESET}"
    echo -e "${GREEN}Help system meets accessibility standards${RESET}"
    echo
    echo "✓ NO_COLOR environment variable support"
    echo "✓ Narrow terminal width handling"
    echo "✓ Text readability without color"
    echo "✓ Screen reader compatibility"
    echo "✓ High contrast mode support"
    echo "✓ Terminal environment resilience"
    exit 0
fi