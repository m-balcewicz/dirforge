#!/bin/bash
# Quick regression tests for full project init mode
# Focuses on directory structure validation without conda environment setup

set -euo pipefail

# Path to dirforge (determine before changing directory)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
DIRFORGE_PATH="$PROJECT_ROOT/tools/dirforge"

# Test workspace setup
TEST_WORKSPACE="/tmp/dirforge_quick_regression_$$"
mkdir -p "$TEST_WORKSPACE"
cd "$TEST_WORKSPACE"

pass() { echo "✅ PASS: $1"; }
fail() { echo "❌ FAIL: $1"; exit 1; }
info() { echo "📋 INFO: $1"; }

info "=== Quick regression tests for full project init mode ==="

# Test 1: Research project with dry-run (no conda environment)
info "Testing: Research project with --dry-run --no-conda"
CURRENT_YEAR=$(date +%Y)
EXPECTED_RESEARCH_PROJECT="RESEARCH_WORLD/${CURRENT_YEAR}_test-research"

output=$("$DIRFORGE_PATH" create research --name "test-research" --dry-run --no-conda 2>&1 || echo "FAILED")
if [[ "$output" == *"FAILED"* ]]; then
    fail "Research project dry-run failed: $output"
fi

if [[ "$output" == *"$EXPECTED_RESEARCH_PROJECT"* ]]; then
    pass "Research project dry-run shows correct directory structure"
else
    fail "Research project dry-run missing expected directory: $EXPECTED_RESEARCH_PROJECT"
fi

# Test 2: Journal project with dry-run
info "Testing: Journal project with --dry-run"
output=$("$DIRFORGE_PATH" create journal --journal "test-journal" --id "TEST-001" --dry-run 2>&1 || echo "FAILED")
if [[ "$output" == *"FAILED"* ]]; then
    fail "Journal project dry-run failed: $output"
fi

if [[ "$output" == *"JOURNAL_WORLD"* ]] && [[ "$output" == *"TEST_JOURNAL"* ]]; then
    pass "Journal project dry-run shows correct directory structure"
else
    fail "Journal project dry-run missing expected directories"
fi

# Test 3: Coding project with dry-run
info "Testing: Coding project with --dry-run"
output=$("$DIRFORGE_PATH" create coding --language "python" --project "test-python" --dry-run 2>&1 || echo "FAILED")
if [[ "$output" == *"FAILED"* ]]; then
    fail "Coding project dry-run failed: $output"
fi

if [[ "$output" == *"CODING_WORLD/python/test-python"* ]]; then
    pass "Coding project dry-run shows correct directory structure"
else
    fail "Coding project dry-run missing expected directory"
fi

# Test 4: Lecture project with dry-run and no-conda
info "Testing: Lecture project with --dry-run --no-conda"
output=$("$DIRFORGE_PATH" init lecture --name "test-lecture" --dry-run --no-conda 2>&1 || echo "FAILED")
if [[ "$output" == *"FAILED"* ]]; then
    fail "Lecture project dry-run failed: $output"
fi

if [[ "$output" == *"LECTURE_WORLD/test-lecture"* ]]; then
    pass "Lecture project dry-run shows correct directory structure"
else
    fail "Lecture project dry-run missing expected directory"
fi

# Test 5: Office and private projects (standard structures) 
info "Testing: Office project with --dry-run"
output=$("$DIRFORGE_PATH" init office --dry-run 2>&1 || echo "FAILED")
if [[ "$output" == *"FAILED"* ]]; then
    fail "Office project dry-run failed: $output"
fi

if [[ "$output" == *"OFFICE_WORLD"* ]]; then
    pass "Office project dry-run shows correct directory structure"
else
    fail "Office project dry-run missing expected directory"
fi

info "Testing: Private project with --dry-run"
output=$("$DIRFORGE_PATH" init private --dry-run 2>&1 || echo "FAILED")
if [[ "$output" == *"FAILED"* ]]; then
    fail "Private project dry-run failed: $output"
fi

if [[ "$output" == *"PRIVATE_WORLD"* ]]; then
    pass "Private project dry-run shows correct directory structure"
else
    fail "Private project dry-run missing expected directory"
fi

# Test 6: Verify error handling is preserved for invalid full project options
info "Testing: Error handling for invalid full project options"

# Test invalid research project name
output=$("$DIRFORGE_PATH" create research --name "" 2>&1 || echo "EXPECTED_ERROR")
if [[ "$output" == *"EXPECTED_ERROR"* ]] || [[ "$output" == *"Error"* ]] || [[ "$output" == *"error"* ]]; then
    pass "Error handling works correctly for invalid project name"
else
    fail "Error handling not working for invalid project name"
fi

# Test invalid coding language
output=$("$DIRFORGE_PATH" create coding --language "invalid_language" --project "test" 2>&1 || echo "EXPECTED_ERROR")
if [[ "$output" == *"EXPECTED_ERROR"* ]] || [[ "$output" == *"Error"* ]] || [[ "$output" == *"error"* ]] || [[ "$output" == *"Unknown language"* ]]; then
    pass "Error handling works correctly for invalid coding language"
else
    fail "Error handling not working for invalid coding language"
fi

info "=== All quick regression tests passed! ==="

# Cleanup
cd /
rm -rf "$TEST_WORKSPACE"

info "✅ T017 validation complete: Full project init mode unchanged by parent-only feature"