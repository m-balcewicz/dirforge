#!/usr/bin/env bash
# test_terminal.sh - Unit tests for terminal capability detection
# Part of the Enhanced Terminal Help System for dirforge

set -euo pipefail

# Source the library under test
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/terminal.sh"

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
        echo "  Expected: $expected"
        echo "  Actual: $actual"
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

# Test get_terminal_width function
test_terminal_width() {
    echo "Testing get_terminal_width()..."
    
    # Test with COLUMNS set
    COLUMNS=120 width=$(get_terminal_width)
    assert_equals "120" "$width" "get_terminal_width() should use COLUMNS when available"
    
    # Test with invalid COLUMNS
    COLUMNS="invalid" width=$(get_terminal_width)
    assert_equals "80" "$width" "get_terminal_width() should fallback to 80 for invalid COLUMNS"
    
    # Test with very small COLUMNS
    COLUMNS=5 width=$(get_terminal_width)
    assert_equals "80" "$width" "get_terminal_width() should fallback to 80 for COLUMNS < 20"
    
    # Test without COLUMNS (fallback behavior)
    unset COLUMNS
    width=$(get_terminal_width)
    assert_true '[[ "$width" =~ ^[0-9]+$ && "$width" -ge 20 ]]' "get_terminal_width() should return valid width without COLUMNS"
}

# Test get_terminal_height function
test_terminal_height() {
    echo "Testing get_terminal_height()..."
    
    # Test with LINES set
    LINES=50 height=$(get_terminal_height)
    assert_equals "50" "$height" "get_terminal_height() should use LINES when available"
    
    # Test with invalid LINES
    LINES="invalid" height=$(get_terminal_height)
    assert_equals "24" "$height" "get_terminal_height() should fallback to 24 for invalid LINES"
    
    # Test with very small LINES
    LINES=2 height=$(get_terminal_height)
    assert_equals "24" "$height" "get_terminal_height() should fallback to 24 for LINES < 5"
    
    # Test without LINES (fallback behavior)
    unset LINES
    height=$(get_terminal_height)
    assert_true '[[ "$height" =~ ^[0-9]+$ && "$height" -ge 5 ]]' "get_terminal_height() should return valid height without LINES"
}

# Test has_cursor_support function
test_cursor_support() {
    echo "Testing has_cursor_support()..."
    
    # This test depends on environment, so we just check it doesn't crash
    if has_cursor_support; then
        echo "✓ has_cursor_support() returned true (tput available)"
    else
        echo "✓ has_cursor_support() returned false (tput unavailable or non-interactive)"
    fi
    ((test_count++))
    ((pass_count++))
}

# Test is_interactive_terminal function
test_interactive_terminal() {
    echo "Testing is_interactive_terminal()..."
    
    # This test depends on environment, so we just check it doesn't crash
    if is_interactive_terminal; then
        echo "✓ is_interactive_terminal() returned true"
    else
        echo "✓ is_interactive_terminal() returned false"
    fi
    ((test_count++))
    ((pass_count++))
}

# Test has_tput_capability function
test_tput_capability() {
    echo "Testing has_tput_capability()..."
    
    # Test with a capability that should exist if tput is available
    if command -v tput >/dev/null 2>&1; then
        if has_tput_capability "colors"; then
            echo "✓ has_tput_capability('colors') works with tput available"
        else
            echo "✓ has_tput_capability('colors') returned false (capability not supported)"
        fi
    else
        assert_false 'has_tput_capability "colors"' "has_tput_capability() should return false without tput"
    fi
    ((test_count++))
    ((pass_count++))
}

# Run all tests
main() {
    echo "Running terminal.sh unit tests..."
    echo "=================================="
    
    test_terminal_width
    echo
    test_terminal_height
    echo
    test_cursor_support
    echo
    test_interactive_terminal
    echo
    test_tput_capability
    echo
    
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