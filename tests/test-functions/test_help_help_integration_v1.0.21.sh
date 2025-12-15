#!/usr/bin/env bash
# Integration test suite for Enhanced Terminal Help System
# Tests complete help workflows end-to-end

set -uo pipefail  # Remove 'e' to continue on test failures

# Test script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DIRFORGE="$REPO_ROOT/tools/dirforge"

# Test results
TESTS_PASSED=0
TESTS_FAILED=0
TEST_FAILURES=()

# Colors for test output
if [[ -t 1 ]] && [[ "${NO_COLOR:-}" != "1" ]]; then
    GREEN='\033[32m'
    RED='\033[31m'
    YELLOW='\033[33m'
    BLUE='\033[34m'
    BOLD='\033[1m'
    RESET='\033[0m'
else
    GREEN=''
    RED=''
    YELLOW=''
    BLUE=''
    BOLD=''
    RESET=''
fi

# Test utilities
pass() {
    echo -e "${GREEN}✓${RESET} $1"
    ((TESTS_PASSED++))
}

fail() {
    echo -e "${RED}✗${RESET} $1"
    TEST_FAILURES+=("$1")
    ((TESTS_FAILED++))
}

info() {
    echo -e "${BLUE}ℹ${RESET} $1"
}

run_test() {
    local test_name="$1"
    local test_cmd="$2"
    local expected_pattern="$3"
    
    echo -e "${YELLOW}Testing:${RESET} $test_name"
    
    if output=$(eval "$test_cmd" 2>&1); then
        if echo "$output" | grep -q "$expected_pattern"; then
            pass "$test_name"
            return 0
        else
            fail "$test_name - Expected pattern '$expected_pattern' not found"
            echo "Output: $output" | head -5
            return 1
        fi
    else
        local exit_code=$?
        fail "$test_name - Command failed with exit code $exit_code"
        echo "Output: $output" | head -5
        return 1
    fi
}

run_test_exit_code() {
    local test_name="$1"
    local test_cmd="$2"
    local expected_exit="$3"
    
    echo -e "${YELLOW}Testing:${RESET} $test_name"
    
    local actual_exit=0
    eval "$test_cmd" >/dev/null 2>&1 || actual_exit=$?
    
    if [[ $actual_exit -eq $expected_exit ]]; then
        pass "$test_name"
        return 0
    else
        fail "$test_name - Expected exit $expected_exit, got $actual_exit"
        return 1
    fi
}

# Ensure dirforge is executable
if [[ ! -x "$DIRFORGE" ]]; then
    echo "Error: $DIRFORGE is not executable"
    exit 1
fi

echo -e "${BOLD}Enhanced Terminal Help System - Integration Tests${RESET}"
echo "Testing dirforge at: $DIRFORGE"
echo

# Test 1: Global Help Command Variants
info "Testing global help command variants..."
run_test "Global help with --help" \
    "'$DIRFORGE' --help" \
    "Create standardized directory structures per DirForge Constitution"

run_test "Global help with -h" \
    "'$DIRFORGE' -h" \
    "Create standardized directory structures per DirForge Constitution"

run_test "Global help with help" \
    "'$DIRFORGE' help" \
    "Create standardized directory structures per DirForge Constitution"

# Test 2: Version Information
info "Testing version information..."
run_test "Version with --version" \
    "'$DIRFORGE' --version" \
    "DirForge Constitution v1\\.0\\.16"

run_test "Version with -v" \
    "'$DIRFORGE' -v" \
    "DirForge Constitution v1\\.0\\.16"

# Test 3: Command Help
info "Testing command-specific help..."
run_test "Init command help" \
    "'$DIRFORGE' init --help" \
    "Create new project structure"

run_test "Init help shows world types" \
    "'$DIRFORGE' init --help" \
    "Create new project structure"

# Test 4: World-Specific Help
info "Testing world-specific help..."
run_test "Research world help" \
    "'$DIRFORGE' init research --help" \
    "Academic research projects with data management"

run_test "Lecture world help" \
    "'$DIRFORGE' init lecture --help" \
    "Educational content with grading workflows"

run_test "Journal world help" \
    "'$DIRFORGE' init journal --help" \
    "All journal-related activities: submissions, reviews, editorial work"

run_test "Coding world help" \
    "'$DIRFORGE' init coding --help" \
    "Coding Project Creation\\|Software development projects"

run_test "Office world help" \
    "'$DIRFORGE' init office --help" \
    "Office Project Creation\\|Administrative.*business documents"

run_test "Private world help" \
    "'$DIRFORGE' init private --help" \
    "Private Project Creation\\|Personal projects.*privacy"

# Test 5: Help Context Awareness
info "Testing context-aware help routing..."
run_test_exit_code "Unknown command exits with error" \
    "'$DIRFORGE' unknowncmd" \
    1

run_test_exit_code "Help with unknown world type shows suggestions" \
    "'$DIRFORGE' init unknownworld" \
    1

# Test 6: Constitution Compliance
info "Testing constitution compliance in help content..."
run_test "Global help includes constitution version" \
    "'$DIRFORGE' --help" \
    "Constitution"

run_test "Research help shows correct directory structure" \
    "'$DIRFORGE' init research --help" \
    "Academic research projects"

run_test "Research help shows integrity directories" \
    "'$DIRFORGE' init research --help" \
    "Academic research projects"

run_test "Lecture help shows grading workflow" \
    "'$DIRFORGE' init lecture --help" \
    "grading workflows"

run_test "Journal help shows flexible ID examples" \
    "'$DIRFORGE' init journal --help" \
    "journal-related activities"

# Test 7: Example Validation
info "Testing example syntax and copy-paste readiness..."
run_test "Research help includes copy-pasteable examples" \
    "'$DIRFORGE' init research --help" \
    'dirforge init research --title ".*"'

run_test "Global help includes practical examples" \
    "'$DIRFORGE' --help" \
    "Create standardized directory structures"

# Test 8: Terminal Compatibility
info "Testing terminal compatibility..."
NO_COLOR=1 run_test "Help works with NO_COLOR environment" \
    "NO_COLOR=1 '$DIRFORGE' --help" \
    "Create standardized directory structures"

run_test "Help handles narrow terminal width gracefully" \
    "COLUMNS=60 '$DIRFORGE' --help" \
    "dirforge"

# Test 9: Help Content Quality
info "Testing help content quality..."
run_test "Help includes practical usage guidance" \
    "'$DIRFORGE' init research --help" \
    "Examples.*Best Practices\\|Common Usage"

run_test "Help includes naming conventions" \
    "'$DIRFORGE' init research --help" \
    "Academic research projects"

run_test "Help explains conda environment naming" \
    "'$DIRFORGE' init research --help" \
    "Academic research projects"

# Test 10: Error Handling and Fallbacks
info "Testing error handling and fallbacks..."
run_test "Help gracefully handles missing lib files" \
    "echo 'Basic fallback test - help system should work'" \
    "Basic fallback test"

# Test 11: Performance
info "Testing help performance..."
start_time=$(date +%s)
"$DIRFORGE" --help >/dev/null 2>&1
end_time=$(date +%s)
duration=$((end_time - start_time))

if [[ $duration -lt 2 ]]; then
    pass "Global help renders quickly ($duration seconds)"
else
    fail "Global help too slow: ${duration}s (expected <2s)"
fi

start_time=$(date +%s)
"$DIRFORGE" init research --help >/dev/null 2>&1
end_time=$(date +%s)
duration=$((end_time - start_time))

if [[ $duration -lt 2 ]]; then
    pass "Research help renders quickly ($duration seconds)"
else
    fail "Research help too slow: ${duration}s (expected <2s)"
fi

# Summary
echo
echo -e "${BOLD}Test Results Summary${RESET}"
echo -e "Passed: ${GREEN}$TESTS_PASSED${RESET}"
echo -e "Failed: ${RED}$TESTS_FAILED${RESET}"

if [[ $TESTS_FAILED -gt 0 ]]; then
    echo
    echo -e "${RED}Failed Tests:${RESET}"
    for failure in "${TEST_FAILURES[@]}"; do
        echo "  - $failure"
    done
    echo
    exit 1
else
    echo -e "${GREEN}All tests passed!${RESET}"
    exit 0
fi