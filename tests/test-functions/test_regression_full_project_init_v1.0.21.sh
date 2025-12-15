#!/bin/bash
# Test: Regression tests for full project init mode
# Ensures that parent-only mode doesn't break existing full project functionality

set -euo pipefail

# Source test utilities if available
if [[ -f "$(dirname "$0")/test_utils.sh" ]]; then
    source "$(dirname "$0")/test_utils.sh"
else
    # Fallback test utilities
    pass() { echo "✅ PASS: $1"; }
    fail() { echo "❌ FAIL: $1"; exit 1; }
    info() { echo "📋 INFO: $1"; }
fi

# Path to dirforge (determine before changing directory)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
DIRFORGE_PATH="$PROJECT_ROOT/tools/dirforge"
if [[ ! -f "$DIRFORGE_PATH" ]]; then
    fail "Cannot find dirforge at $DIRFORGE_PATH"
fi

# Test workspace setup
TEST_WORKSPACE="/tmp/dirforge_regression_test_$$"
mkdir -p "$TEST_WORKSPACE"
cd "$TEST_WORKSPACE"

info "=== T017: Regression tests for full project init mode ==="

# Test 1: Research project with full options still works
info "Testing: Research project with full project options"
CURRENT_YEAR=$(date +%Y)
EXPECTED_RESEARCH_PROJECT="RESEARCH_WORLD/${CURRENT_YEAR}_test-research-project"

output=$("$DIRFORGE_PATH" init research --name "test-research-project" 2>&1 || echo "FAILED")
if [[ "$output" == *"FAILED"* ]]; then
    fail "Research project creation failed: $output"
fi

if [[ -d "$EXPECTED_RESEARCH_PROJECT" ]]; then
    pass "Research project directory created correctly"
else
    fail "Research project directory not found at $EXPECTED_RESEARCH_PROJECT"
fi

# Check for key research directories
if [[ -d "$EXPECTED_RESEARCH_PROJECT/data" ]] && [[ -d "$EXPECTED_RESEARCH_PROJECT/scripts" ]]; then
    pass "Research project contains expected subdirectories"
else
    fail "Research project missing expected subdirectories (data/, scripts/, etc.)"
fi

# Test 2: Journal project with full options still works
info "Testing: Journal project with full project options"
EXPECTED_JOURNAL_PROJECT="JOURNAL_WORLD/TEST_JOURNAL/TEST-001"

output=$("$DIRFORGE_PATH" init journal --journal "test-journal" --id "TEST-001" 2>&1 || echo "FAILED")
if [[ "$output" == *"FAILED"* ]]; then
    fail "Journal project creation failed: $output"
fi

if [[ -d "$EXPECTED_JOURNAL_PROJECT" ]]; then
    pass "Journal project directory created correctly"
else
    fail "Journal project directory not found at $EXPECTED_JOURNAL_PROJECT"
fi

# Test 3: Coding project with full options still works
info "Testing: Coding project with full project options"
EXPECTED_CODING_PROJECT="CODING_WORLD/python/test-python-project"

output=$("$DIRFORGE_PATH" init coding --language "python" --project "test-python-project" 2>&1 || echo "FAILED")
if [[ "$output" == *"FAILED"* ]]; then
    fail "Coding project creation failed: $output"
fi

if [[ -d "$EXPECTED_CODING_PROJECT" ]]; then
    pass "Coding project directory created correctly"
else
    fail "Coding project directory not found at $EXPECTED_CODING_PROJECT"
fi

# Check for Python-specific files
if [[ -f "$EXPECTED_CODING_PROJECT/requirements.txt" ]] || [[ -f "$EXPECTED_CODING_PROJECT/setup.py" ]] || [[ -f "$EXPECTED_CODING_PROJECT/README.md" ]]; then
    pass "Coding project contains expected Python project files"
else
    fail "Coding project missing expected Python project structure"
fi

# Test 4: Lecture project with full options still works
info "Testing: Lecture project with full project options"
EXPECTED_LECTURE_PROJECT="LECTURE_WORLD/test-lecture-course"

output=$("$DIRFORGE_PATH" init lecture --name "test-lecture-course" 2>&1 || echo "FAILED")
if [[ "$output" == *"FAILED"* ]]; then
    fail "Lecture project creation failed: $output"
fi

if [[ -d "$EXPECTED_LECTURE_PROJECT" ]]; then
    pass "Lecture project directory created correctly"
else
    fail "Lecture project directory not found at $EXPECTED_LECTURE_PROJECT"
fi

# Test 5: Office and private projects (standard structures) still work
info "Testing: Office project creation"
output=$("$DIRFORGE_PATH" init office 2>&1 || echo "FAILED")
if [[ "$output" == *"FAILED"* ]]; then
    fail "Office project creation failed: $output"
fi

if [[ -d "OFFICE_WORLD" ]] && [[ -d "OFFICE_WORLD/documents" ]] && [[ -d "OFFICE_WORLD/templates" ]]; then
    pass "Office project created with expected standard structure"
else
    fail "Office project missing expected standard structure"
fi

info "Testing: Private project creation"
output=$("$DIRFORGE_PATH" init private 2>&1 || echo "FAILED")
if [[ "$output" == *"FAILED"* ]]; then
    fail "Private project creation failed: $output"
fi

if [[ -d "PRIVATE_WORLD" ]] && [[ -d "PRIVATE_WORLD/personal" ]] && [[ -d "PRIVATE_WORLD/finance" ]]; then
    pass "Private project created with expected standard structure"
else
    fail "Private project missing expected standard structure"
fi

# Test 6: Verify --dry-run still works correctly for full projects
info "Testing: Dry-run mode with full project options"
cd /tmp  # Change to a clean directory for dry-run tests

# Test dry-run with research project
output=$("$DIRFORGE_PATH" init research --name "dry-run-test" --dry-run 2>&1 || echo "FAILED")
if [[ "$output" == *"FAILED"* ]]; then
    fail "Dry-run mode failed for research project: $output"
fi

# Ensure no directories were actually created
if [[ -d "RESEARCH_WORLD" ]]; then
    fail "Dry-run mode created directories when it shouldn't have"
else
    pass "Dry-run mode correctly simulated without creating directories"
fi

# Test 7: Verify --json flag works with full projects
info "Testing: JSON output with full project options"
output=$("$DIRFORGE_PATH" init research --name "json-test" --dry-run --json 2>&1 || echo "FAILED")
if [[ "$output" == *"FAILED"* ]]; then
    fail "JSON output failed for full project: $output"
fi

# Basic JSON validation - should contain expected structure
if [[ "$output" == *"created_directories"* ]] && [[ "$output" == *"RESEARCH_WORLD"* ]]; then
    pass "JSON output contains expected structure for full projects"
else
    fail "JSON output missing expected structure: $output"
fi

# Test 8: Verify error handling is preserved for invalid full project options
info "Testing: Error handling for invalid full project options"

# Test invalid research project name
output=$("$DIRFORGE_PATH" init research --name "" 2>&1 || echo "EXPECTED_ERROR")
if [[ "$output" == *"EXPECTED_ERROR"* ]] || [[ "$output" == *"Error"* ]] || [[ "$output" == *"error"* ]]; then
    pass "Error handling works correctly for invalid project name"
else
    fail "Error handling not working for invalid project name"
fi

# Test invalid coding language
output=$("$DIRFORGE_PATH" init coding --language "invalid_language" --project "test" 2>&1 || echo "EXPECTED_ERROR")
if [[ "$output" == *"EXPECTED_ERROR"* ]] || [[ "$output" == *"Error"* ]] || [[ "$output" == *"error"* ]]; then
    pass "Error handling works correctly for invalid coding language"
else
    fail "Error handling not working for invalid coding language"
fi

info "=== All regression tests passed! ==="

# Cleanup
cd /
rm -rf "$TEST_WORKSPACE"

info "✅ T017 complete: Full project init mode unchanged by parent-only feature"