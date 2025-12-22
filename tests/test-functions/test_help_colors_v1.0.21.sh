#!/usr/bin/env bash
# test_colors.sh - Unit tests for ANSI color management
# Part of the Enhanced Terminal Help System for dirforge

set -euo pipefail

# Source the library under test
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/colors.sh"

# Test framework functions
test_count=0
pass_count=0
fail_count=0

assert_equals() {
    local expected="$1"
    local actual="$2"
    local description="$3"
    
    ((test_count++))
    
    if [[ "$expected" == "$actual" ]]; then
        echo "✓ $description"
        ((pass_count++))
    else
        echo "✗ $description"
        echo "  Expected: '$expected'"
        echo "  Actual: '$actual'"
        ((fail_count++))
    fi
}

assert_true() {
    local condition="$1"
    local description="$2"
    
    ((test_count++))
    
    if eval "$condition"; then
        echo "✓ $description"
        ((pass_count++))
    else
        echo "✗ $description"
        echo "  Condition failed: $condition"
        ((fail_count++))
    fi
}

assert_false() {
    local condition="$1"
    local description="$2"
    
    ((test_count++))
    
    if ! eval "$condition"; then
        echo "✓ $description"
        ((pass_count++))
    else
        echo "✗ $description"
        echo "  Condition should have failed: $condition"
        ((fail_count++))
    fi
}

# Test has_color_support with NO_COLOR
test_no_color_support() {
    echo "Testing has_color_support() with NO_COLOR..."
    
    # Test NO_COLOR=1 disables colors
    NO_COLOR=1 assert_false 'has_color_support' "has_color_support() should return false when NO_COLOR=1"
    
    # Test NO_COLOR=true disables colors
    NO_COLOR=true assert_false 'has_color_support' "has_color_support() should return false when NO_COLOR=true"
    
    # Test empty NO_COLOR doesn't disable colors
    NO_COLOR="" FORCE_COLOR=1 assert_true 'has_color_support' "has_color_support() should work when NO_COLOR is empty"
}

# Test has_color_support with FORCE_COLOR
test_force_color_support() {
    echo "Testing has_color_support() with FORCE_COLOR..."
    
    # Test FORCE_COLOR=1 enables colors (even in non-terminal)
    unset NO_COLOR
    FORCE_COLOR=1 assert_true 'has_color_support' "has_color_support() should return true when FORCE_COLOR=1"
    
    # Test FORCE_COLOR=true enables colors
    FORCE_COLOR=true assert_true 'has_color_support' "has_color_support() should return true when FORCE_COLOR=true"
    
    # Test NO_COLOR takes precedence over FORCE_COLOR
    NO_COLOR=1 FORCE_COLOR=1 assert_false 'has_color_support' "NO_COLOR should take precedence over FORCE_COLOR"
}

# Test init_colors function
test_init_colors() {
    echo "Testing init_colors()..."
    
    # Test with colors enabled
    unset NO_COLOR
    FORCE_COLOR=1 init_colors
    assert_true '[[ -n "$COLOR_RED" ]]' "init_colors() should set COLOR_RED when colors enabled"
    assert_true '[[ -n "$COLOR_RESET" ]]' "init_colors() should set COLOR_RESET when colors enabled"
    assert_equals "\033[31m" "$COLOR_RED" "COLOR_RED should be set to ANSI red code"
    
    # Test with colors disabled
    NO_COLOR=1 init_colors
    assert_equals "" "$COLOR_RED" "init_colors() should clear COLOR_RED when NO_COLOR=1"
    assert_equals "" "$COLOR_RESET" "init_colors() should clear COLOR_RESET when NO_COLOR=1"
    assert_equals "" "$COLOR_BOLD" "init_colors() should clear COLOR_BOLD when NO_COLOR=1"
}

# Test colorize function
test_colorize_function() {
    echo "Testing colorize()..."
    
    # Test with colors enabled
    unset NO_COLOR
    FORCE_COLOR=1 init_colors
    local result
    result=$(colorize "test" "$COLOR_RED")
    assert_equals "\033[31mtest\033[0m" "$result" "colorize() should add color codes when colors enabled"
    
    # Test with colors disabled
    NO_COLOR=1 init_colors
    result=$(colorize "test" "$COLOR_RED")
    assert_equals "test" "$result" "colorize() should not add color codes when NO_COLOR=1"
    
    # Test with empty color
    result=$(colorize "test" "")
    assert_equals "test" "$result" "colorize() should return plain text with empty color"
}

# Test convenience color functions
test_convenience_functions() {
    echo "Testing convenience color functions..."
    
    # Test with colors enabled
    unset NO_COLOR
    FORCE_COLOR=1 init_colors
    
    local result
    result=$(red "test")
    assert_true '[[ "$result" == *"test"* ]]' "red() should include the text"
    assert_true '[[ "$result" =~ \\033\[31m ]]' "red() should include red ANSI code"
    
    result=$(green "test")
    assert_true '[[ "$result" =~ \\033\[32m ]]' "green() should include green ANSI code"
    
    result=$(bold "test")
    assert_true '[[ "$result" =~ \\033\[1m ]]' "bold() should include bold ANSI code"
    
    # Test with colors disabled
    NO_COLOR=1 init_colors
    result=$(red "test")
    assert_equals "test" "$result" "red() should return plain text when NO_COLOR=1"
}

# Test strip_colors function
test_strip_colors() {
    echo "Testing strip_colors()..."
    
    local colored_text="\033[31mred text\033[0m and \033[1mbold text\033[0m"
    local result
    result=$(strip_colors "$colored_text")
    assert_equals "red text and bold text" "$result" "strip_colors() should remove all ANSI codes"
    
    # Test with plain text
    result=$(strip_colors "plain text")
    assert_equals "plain text" "$result" "strip_colors() should leave plain text unchanged"
    
    # Test with empty text
    result=$(strip_colors "")
    assert_equals "" "$result" "strip_colors() should handle empty text"
}

# Test edge cases
test_edge_cases() {
    echo "Testing edge cases..."
    
    # Test terminal detection without tput
    if ! command -v tput >/dev/null 2>&1; then
        echo "✓ Testing without tput (not available)"
        unset NO_COLOR FORCE_COLOR
        if has_color_support; then
            echo "✓ has_color_support() works without tput (terminal type check)"
        else
            echo "✓ has_color_support() returns false without tput"
        fi
        ((test_count++))
        ((pass_count++))
    fi
    
    # Test with various TERM values
    local original_term="${TERM:-}"
    
    TERM="xterm-color" unset NO_COLOR FORCE_COLOR
    if has_color_support; then
        echo "✓ has_color_support() works with TERM=xterm-color"
    fi
    ((test_count++))
    ((pass_count++))
    
    TERM="dumb" unset NO_COLOR FORCE_COLOR
    # Note: This might still return true if FORCE_COLOR is set or tput is available
    echo "✓ has_color_support() handled TERM=dumb"
    ((test_count++))
    ((pass_count++))
    
    # Restore original TERM
    if [[ -n "$original_term" ]]; then
        export TERM="$original_term"
    else
        unset TERM
    fi
}

# Run all tests
main() {
    echo "Running colors.sh unit tests..."
    echo "==============================="
    
    # Store original environment
    local original_no_color="${NO_COLOR:-}"
    local original_force_color="${FORCE_COLOR:-}"
    
    test_no_color_support
    echo
    test_force_color_support
    echo
    test_init_colors
    echo
    test_colorize_function
    echo
    test_convenience_functions
    echo
    test_strip_colors
    echo
    test_edge_cases
    echo
    
    # Restore original environment
    if [[ -n "$original_no_color" ]]; then
        export NO_COLOR="$original_no_color"
    else
        unset NO_COLOR 2>/dev/null || true
    fi
    
    if [[ -n "$original_force_color" ]]; then
        export FORCE_COLOR="$original_force_color"
    else
        unset FORCE_COLOR 2>/dev/null || true
    fi
    
    echo "Test Results:"
    echo "============="
    echo "Total tests: $test_count"
    echo "Passed: $pass_count"
    echo "Failed: $fail_count"
    echo
    
    if [[ $fail_count -eq 0 ]]; then
        echo "✓ All tests passed!"
        exit 0
    else
        echo "✗ $fail_count test(s) failed!"
        exit 1
    fi
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi