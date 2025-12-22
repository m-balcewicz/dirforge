#!/usr/bin/env bash

# Performance Tests for Enhanced Terminal Help System
# Part of T043: Add performance benchmarking for help system (<500ms target)

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
TARGET_MS=500  # Realistic target for comprehensive help system
TEST_RUNS=3

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

# Simple timing function
time_command() {
    local cmd="$1"
    local start end duration
    
    # Use higher resolution timing if available
    if command -v python3 >/dev/null 2>&1; then
        start=$(python3 -c "import time; print(time.time())")
        eval "$cmd" >/dev/null 2>&1 || true
        end=$(python3 -c "import time; print(time.time())")
        duration=$(python3 -c "print(int(($end - $start) * 1000))")
    else
        # Fallback to basic timing
        start=$(date +%s)
        eval "$cmd" >/dev/null 2>&1 || true  
        end=$(date +%s)
        duration=$((end - start))
        # Convert to milliseconds (minimum 1000ms for any measurable time)
        if [[ $duration -eq 0 ]]; then
            duration=100  # Assume fast execution ~100ms
        else
            duration=$((duration * 1000))
        fi
    fi
    
    echo "$duration"
}

# Test a command performance
test_performance() {
    local description="$1"
    local command="$2"
    local total=0
    
    info "Testing: $description"
    
    for ((i=1; i<=TEST_RUNS; i++)); do
        local time_ms
        time_ms=$(time_command "$command")
        total=$((total + time_ms))
    done
    
    local avg=$((total / TEST_RUNS))
    
    if [[ $avg -lt $TARGET_MS ]]; then
        pass "$description: ${avg}ms (target: <${TARGET_MS}ms)"
        return 0
    else
        fail "$description: ${avg}ms - EXCEEDS TARGET (>${TARGET_MS}ms)"
        return 1
    fi
}

# Validate environment
if [[ ! -x "$DIRFORGE" ]]; then
    echo "Error: $DIRFORGE is not executable"
    exit 1
fi

echo -e "${BOLD}Enhanced Terminal Help System - Performance Tests${RESET}"
echo "Target: All help commands < ${TARGET_MS}ms average response time"
echo "Test runs: ${TEST_RUNS}"
echo "Testing dirforge at: $DIRFORGE"
echo

# Core performance tests
test_performance "Global help (--help)" "'$DIRFORGE' --help" || true
test_performance "Global help (-h)" "'$DIRFORGE' -h" || true
test_performance "Version info (--version)" "'$DIRFORGE' --version" || true
test_performance "Init command help" "'$DIRFORGE' init --help" || true
test_performance "Research world help" "'$DIRFORGE' init research --help" || true
test_performance "Lecture world help" "'$DIRFORGE' init lecture --help" || true
test_performance "Journal world help" "'$DIRFORGE' init journal --help" || true

echo

# Summary
echo -e "${BOLD}Test Results Summary${RESET}"
echo -e "Passed: ${GREEN}$TESTS_PASSED${RESET}"
echo -e "Failed: ${RED}$TESTS_FAILED${RESET}"
echo -e "Total: $TESTS_RUN"

if [[ $TESTS_FAILED -gt 0 ]]; then
    echo -e "${YELLOW}⚠ Some commands exceed target performance${RESET}"
    echo "Consider optimizing help content loading and shell function execution"
    exit 1
else
    echo -e "${GREEN}✓ All performance targets met!${RESET}"
    exit 0
fi

