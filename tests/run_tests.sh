#!/usr/bin/env bash
set -euo pipefail

# Main test runner for DirForge - Constitutional Compliance v1.0.21
# Discovers and executes all versioned test functions from test-functions/ directory
# Runs tests in isolated temporary environment to prevent workspace interference

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null 2>&1 && pwd)"

# Setup isolated test environment
TIMESTAMP=$(date +%s)
TMPDIR="$REPO_ROOT/tests/dirforge_test_workspace_$TIMESTAMP"
mkdir -p "$TMPDIR"
echo "DirForge Test Suite - Constitutional Compliance v1.0.21"
echo "Using test workspace directory: $TMPDIR"
pushd "$TMPDIR" >/dev/null

# Cleanup function
cleanup() {
  # Restore PATH if we saved it
  if [ -n "${OLD_PATH:-}" ]; then
    export PATH="$OLD_PATH"
  fi
  # Exit temporary directory
  if [ -n "${TMPDIR:-}" ] && { [ "$PWD" = "$TMPDIR" ] || [[ "$PWD" == "$TMPDIR"/* ]]; }; then
    popd >/dev/null || true
  fi
  # Remove temporary workspace unless explicitly kept
  if [ -n "${TMPDIR:-}" ] && [ -d "$TMPDIR" ]; then
    if [ -n "${KEEP_TEST_WORKSPACE:-}" ] && [ "${KEEP_TEST_WORKSPACE}" != "0" ]; then
      echo "KEEP_TEST_WORKSPACE set; leaving workspace in place: $TMPDIR"
    else
      echo "Cleaning up test directory: $TMPDIR"
      rm -rf "$TMPDIR"
    fi
  fi
}
trap cleanup EXIT

# Validate dirforge executable
DIRFORGE="$REPO_ROOT/tools/dirforge"
if [ ! -x "$DIRFORGE" ]; then
  echo "❌ FATAL: dirforge not executable at $DIRFORGE" >&2
  exit 1
fi

# Configure environment for testing
OLD_PATH="$PATH"
export PATH="$OLD_PATH"  # Allow full PATH for test functions

echo ""
echo "🔍 Discovering and executing versioned test functions..."
echo "=================================================="

# Discover and run all versioned test functions
TEST_FUNCTIONS_DIR="$REPO_ROOT/tests/test-functions"
if [ ! -d "$TEST_FUNCTIONS_DIR" ]; then
  echo "❌ FATAL: test-functions directory not found at $TEST_FUNCTIONS_DIR" >&2
  exit 2
fi

TESTS_PASSED=0
TESTS_FAILED=0
TOTAL_TEST_CASES=0

echo "📁 Scanning $TEST_FUNCTIONS_DIR for test scripts..."

# Find all test function scripts (pattern: test_*_v*.sh) and sort them
for test_script in $(find "$TEST_FUNCTIONS_DIR" -name "test_*_v*.sh" -type f | sort); do
  if [ -f "$test_script" ] && [ -x "$test_script" ]; then
    test_name=$(basename "$test_script")
    echo ""
    echo "▶️  Executing: $test_name"
    echo "   Path: $test_script"
    
    # Run each test - they now calculate correct paths
    if "$test_script"; then
      echo "   ✅ $test_name PASSED"
      ((TESTS_PASSED++))
    else
      echo "   ❌ $test_name FAILED"
      ((TESTS_FAILED++))
    fi
  fi
done

# Calculate and display results
TOTAL_TESTS=$((TESTS_PASSED + TESTS_FAILED))

echo ""
echo "🏁 Test Execution Complete"
echo "========================="
echo "Total test scripts executed: $TOTAL_TESTS"
echo "✅ Passed: $TESTS_PASSED"
echo "❌ Failed: $TESTS_FAILED"

if [ $TESTS_FAILED -gt 0 ]; then
  echo ""
  echo "❌ OVERALL RESULT: FAILED ($TESTS_FAILED test script(s) failed)"
  echo "Constitutional Requirement: All tests must pass for code compliance"
  exit 10
else
  echo ""
  echo "✅ OVERALL RESULT: PASSED (All test scripts executed successfully)"
  echo "Constitutional Compliance: Testing infrastructure validated ✓"
fi
