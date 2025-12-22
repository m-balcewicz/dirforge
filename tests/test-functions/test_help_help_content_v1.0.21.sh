#!/usr/bin/env bash
# test_help_content.sh - Unit tests for help content formatting functions
# Part of the Enhanced Terminal Help System for dirforge

set -euo pipefail

# Source the library under test
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/help.sh"

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

assert_contains() {
    local needle="$1"
    local haystack="$2"
    local description="$3"
    
    ((test_count++))
    
    if [[ "$haystack" == *"$needle"* ]]; then
        echo "✓ $description"
        ((pass_count++))
    else
        echo "✗ $description"
        echo "  Expected to contain: '$needle'"
        echo "  Actual: '$haystack'"
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

# Test format_header function
test_format_header() {
    echo "Testing format_header()..."
    
    # Test level 1 header (should have bold and separator)
    local result
    result=$(format_header "Test Header" 1)
    assert_contains "Test Header" "$result" "format_header() level 1 should contain header text"
    assert_contains "=" "$result" "format_header() level 1 should contain separator line"
    
    # Test level 2 header (should have bold and underline)
    result=$(format_header "Section" 2)
    assert_contains "Section" "$result" "format_header() level 2 should contain header text"
    assert_contains "-" "$result" "format_header() level 2 should contain underline"
    
    # Test level 3 header (should have bold only)
    result=$(format_header "Subsection" 3)
    assert_contains "Subsection" "$result" "format_header() level 3 should contain header text"
    
    # Test default level
    result=$(format_header "Default")
    assert_contains "Default" "$result" "format_header() default should contain header text"
}

# Test format_command function
test_format_command() {
    echo "Testing format_command()..."
    
    # Test command without description
    local result
    result=$(format_command "dirforge init")
    assert_contains "dirforge init" "$result" "format_command() should contain command text"
    
    # Test command with description
    result=$(format_command "dirforge init research" "Create a research project")
    assert_contains "dirforge init research" "$result" "format_command() should contain command with description"
    assert_contains "Create a research project" "$result" "format_command() should contain description text"
    
    # Test that command is properly indented
    assert_true '[[ "$result" == "  "* ]]' "format_command() should indent command"
}

# Test format_example function
test_format_example() {
    echo "Testing format_example()..."
    
    # Test basic example formatting
    local example_text="dirforge init my-research\ncd my-research"
    local result
    result=$(format_example "$example_text")
    assert_contains "dirforge init my-research" "$result" "format_example() should contain example content"
    assert_contains "Example:" "$result" "format_example() should contain default title"
    
    # Test custom title
    result=$(format_example "$example_text" "Usage")
    assert_contains "Usage:" "$result" "format_example() should use custom title"
    
    # Test indentation
    local lines
    readarray -t lines <<< "$result"
    local found_indented=false
    for line in "${lines[@]}"; do
        if [[ "$line" == "  "* ]]; then
            found_indented=true
            break
        fi
    done
    assert_true '[[ "$found_indented" == true ]]' "format_example() should indent example lines"
}

# Test format_directory_tree function
test_format_directory_tree() {
    echo "Testing format_directory_tree()..."
    
    # Test basic tree formatting
    local tree_content="project/
├── src/
│   └── main.py
└── README.md"
    local result
    result=$(format_directory_tree "$tree_content")
    assert_contains "project/" "$result" "format_directory_tree() should contain directory structure"
    assert_contains "├──" "$result" "format_directory_tree() should contain tree characters"
    assert_contains "main.py" "$result" "format_directory_tree() should contain file names"
    
    # Test indentation
    assert_true '[[ "$result" == *"  project/"* ]]' "format_directory_tree() should indent tree content"
}

# Test wrap_text function
test_wrap_text() {
    echo "Testing wrap_text()..."
    
    # Test basic text wrapping
    local long_text="This is a very long line of text that should be wrapped to fit within the terminal width constraints"
    local result
    result=$(wrap_text "$long_text")
    
    # Should produce multiple lines
    local line_count
    line_count=$(echo "$result" | wc -l)
    assert_true '[[ "$line_count" -gt 1 ]]' "wrap_text() should wrap long text into multiple lines"
    
    # Test with indentation
    result=$(wrap_text "Short text" 2)
    assert_true '[[ "$result" == "    "* ]]' "wrap_text() should apply indentation"
}

# Test format_list function
test_format_list() {
    echo "Testing format_list()..."
    
    # Test basic list formatting
    local items="First item\nSecond item\nThird item"
    local result
    result=$(format_list "$items")
    assert_contains "First item" "$result" "format_list() should contain list items"
    assert_contains "Second item" "$result" "format_list() should contain all items"
    assert_contains "•" "$result" "format_list() should contain default bullet"
    
    # Test custom bullet
    result=$(format_list "$items" "→")
    assert_contains "→" "$result" "format_list() should use custom bullet"
    
    # Test indentation
    assert_true '[[ "$result" == *"  "* ]]' "format_list() should indent list items"
}

# Test format_key_value function
test_format_key_value() {
    echo "Testing format_key_value()..."
    
    # Test basic key-value formatting
    local pairs="Name:dirforge\nVersion:1.0\nAuthor:Martin"
    local result
    result=$(format_key_value "$pairs")
    assert_contains "Name:" "$result" "format_key_value() should contain keys"
    assert_contains "dirforge" "$result" "format_key_value() should contain values"
    assert_contains "Version:" "$result" "format_key_value() should format all pairs"
    
    # Test alignment (should have consistent spacing)
    assert_true '[[ "$result" == *"  "* ]]' "format_key_value() should indent key-value pairs"
}

# Test separator function
test_separator() {
    echo "Testing separator()..."
    
    # Test default separator
    local result
    result=$(separator)
    assert_contains "-" "$result" "separator() should contain default dash character"
    
    # Test custom character
    result=$(separator "=")
    assert_contains "=" "$result" "separator() should use custom character"
    
    # Test custom length
    result=$(separator "*" 5)
    local expected="*****"
    assert_equals "$expected" "$result" "separator() should create line of specified length"
}

# Test format_box function
test_format_box() {
    echo "Testing format_box()..."
    
    # Test basic box formatting
    local content="This is a test message"
    local result
    result=$(format_box "$content")
    assert_contains "This is a test message" "$result" "format_box() should contain content"
    assert_contains "┌" "$result" "format_box() should contain top-left corner"
    assert_contains "┐" "$result" "format_box() should contain top-right corner"
    assert_contains "└" "$result" "format_box() should contain bottom-left corner"
    assert_contains "┘" "$result" "format_box() should contain bottom-right corner"
    assert_contains "│" "$result" "format_box() should contain vertical borders"
    assert_contains "─" "$result" "format_box() should contain horizontal borders"
}

# Test color integration
test_color_integration() {
    echo "Testing color integration..."
    
    # Test with colors enabled
    unset NO_COLOR
    FORCE_COLOR=1 init_colors
    
    local result
    result=$(format_command "test command")
    # Should contain ANSI color codes when colors enabled
    assert_true '[[ "$result" =~ [[:cntrl:]] ]]' "format_command() should include color codes when colors enabled"
    
    # Test with colors disabled
    NO_COLOR=1 init_colors
    result=$(format_command "test command")
    # Should not contain ANSI color codes when colors disabled
    local stripped
    stripped=$(strip_colors "$result")
    assert_equals "$stripped" "$result" "format_command() should not include color codes when NO_COLOR=1"
}

# Test edge cases
test_edge_cases() {
    echo "Testing edge cases..."
    
    # Test empty inputs
    local result
    result=$(format_header "")
    assert_true '[[ -n "$result" ]]' "format_header() should handle empty input gracefully"
    
    result=$(format_command "")
    assert_true '[[ -n "$result" ]]' "format_command() should handle empty input gracefully"
    
    result=$(format_example "")
    assert_true '[[ -n "$result" ]]' "format_example() should handle empty input gracefully"
    
    # Test very long content
    local long_content="This is an extremely long line of content that should test the wrapping and formatting capabilities of our help system functions to ensure they handle edge cases properly"
    result=$(format_box "$long_content")
    assert_contains "This is an extremely" "$result" "format_box() should handle long content"
    
    # Test special characters
    result=$(format_command "test & echo 'special chars'")
    assert_contains "special chars" "$result" "format_command() should handle special characters"
}

# Run all tests
main() {
    echo "Running help.sh formatting function tests..."
    echo "============================================"
    
    # Store original environment
    local original_no_color="${NO_COLOR:-}"
    local original_force_color="${FORCE_COLOR:-}"
    
    test_format_header
    echo
    test_format_command
    echo
    test_format_example
    echo
    test_format_directory_tree
    echo
    test_wrap_text
    echo
    test_format_list
    echo
    test_format_key_value
    echo
    test_separator
    echo
    test_format_box
    echo
    test_color_integration
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