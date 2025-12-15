#!/usr/bin/env bash
# Test pager integration functionality
# Part of T047: Implement pager integration for long help content

set -euo pipefail

# Colors
RESET="\033[0m"
GREEN="\033[32m" 
RED="\033[31m"
BLUE="\033[34m"
BOLD="\033[1m"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0

# Helper functions
pass() {
    echo -e "✓ ${GREEN}$1${RESET}"
    ((TESTS_PASSED++))
    ((TESTS_RUN++))
}

fail() {
    echo -e "✗ ${RED}$1${RESET}"
    ((TESTS_RUN++))
}

info() {
    echo -e "${BLUE}ℹ${RESET} $1"
}

# Configuration
DIRFORGE="$PWD/tools/dirforge"
LIB_DIR="$PWD/lib"

# Source help library for testing pager functions
source "$LIB_DIR/terminal.sh"
source "$LIB_DIR/colors.sh"
source "$LIB_DIR/help.sh"

echo -e "${BOLD}Enhanced Terminal Help System - Pager Integration Tests${RESET}"
echo "Testing pager functionality for long help content"
echo

# Test 1: Pager detection for short content
info "Testing pager detection for short content..."
short_content="Line 1\nLine 2\nLine 3"
if ! should_use_pager "$short_content"; then
    pass "Short content correctly detected as not needing pager"
else
    fail "Short content incorrectly detected as needing pager"
fi

# Test 2: Pager detection for long content  
info "Testing pager detection for long content..."
long_content=""
for i in {1..50}; do
    long_content+="Line $i\n"
done
if should_use_pager "$long_content"; then
    pass "Long content correctly detected as needing pager" 
else
    fail "Long content incorrectly detected as not needing pager"
fi

# Test 3: Pager command selection
info "Testing pager command selection..."
pager_cmd=$(get_pager_command)
if [[ -n "$pager_cmd" ]]; then
    pass "Pager command selected: $pager_cmd"
else
    fail "No pager command selected"
fi

# Test 4: CI detection (should disable pager)
info "Testing CI environment detection..."
CI=true should_use_pager "$long_content" && fail "Pager used in CI environment" || pass "Pager correctly disabled in CI environment"

# Test 5: Non-terminal detection (should disable pager)
info "Testing non-terminal detection..."
if echo "$long_content" | display_with_pager "$long_content" > /dev/null 2>&1; then
    pass "Non-terminal output handled correctly"
else
    fail "Non-terminal output failed"
fi

# Test 6: Global help pager integration
info "Testing global help pager integration..."
global_help_output=$($DIRFORGE --help 2>&1)
global_help_lines=$(echo "$global_help_output" | wc -l | tr -d ' ')
if [[ $global_help_lines -gt 0 ]]; then
    pass "Global help generates output ($global_help_lines lines)"
else
    fail "Global help generates no output"
fi

# Test 7: Research help pager integration (long content)
info "Testing research help pager integration..."
research_help_output=$(PAGER=cat $DIRFORGE init research --help 2>&1)
research_help_lines=$(echo "$research_help_output" | wc -l | tr -d ' ')
if [[ $research_help_lines -gt 40 ]]; then
    pass "Research help generates long output ($research_help_lines lines, should use pager)"
else
    fail "Research help output too short ($research_help_lines lines)"
fi

# Test 8: PAGER environment variable respected
info "Testing PAGER environment variable handling..."
pager_with_env=$(PAGER="less -R" get_pager_command)
if [[ "$pager_with_env" == "less -R" ]]; then
    pass "PAGER environment variable correctly respected"
else
    fail "PAGER environment variable not respected (got: $pager_with_env)"
fi

# Test 9: PAGER=cat disables pager features
info "Testing PAGER=cat handling..."
if PAGER=cat should_use_pager "$long_content"; then
    fail "PAGER=cat should disable pager features"
else
    pass "PAGER=cat correctly disables pager features"
fi

# Summary
echo
echo -e "${BOLD}Pager Integration Test Summary${RESET}"
echo -e "Tests run: $TESTS_RUN"
echo -e "Passed: ${GREEN}$TESTS_PASSED${RESET}"
echo -e "Failed: ${RED}$((TESTS_RUN - TESTS_PASSED))${RESET}"

if [[ $TESTS_PASSED -eq $TESTS_RUN ]]; then
    echo -e "${GREEN}✓ All pager integration tests passed!${RESET}"
    exit 0
else
    echo -e "${RED}✗ Some pager tests failed${RESET}"
    exit 1
fi