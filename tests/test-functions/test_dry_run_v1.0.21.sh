#!/usr/bin/env bash
set -euo pipefail

# Unit test: Verify --dry-run mode does not write to filesystem
# Tests that dry-run parsing works and no directories/files are created

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DIRFORGE="$PROJECT_ROOT/tools/dirforge"

echo "=== T013: Testing dry-run mode (no filesystem writes) ==="

if [ ! -f "$DIRFORGE" ]; then
  echo "ERROR: dirforge not found at $DIRFORGE" >&2
  exit 1
fi

# Create isolated test workspace
TEST_WORKSPACE="/tmp/dirforge_dryrun_test_$$"
mkdir -p "$TEST_WORKSPACE"
cd "$TEST_WORKSPACE"

echo "Test workspace: $TEST_WORKSPACE"

# Test 1: Research project dry-run
echo "Test 1: Research project with --dry-run"
output=$("$DIRFORGE" --dry-run init research --name "Test Project" --no-conda 2>&1)
echo "$output"

if echo "$output" | grep -q "DRY RUN"; then
  echo "✅ Dry-run mode detected in output"
else
  echo "❌ FAIL: No 'DRY RUN' marker in output"
  rm -rf "$TEST_WORKSPACE"
  exit 1
fi

if [ -d "RESEARCH_WORLD" ]; then
  echo "❌ FAIL: RESEARCH_WORLD directory was created (should not happen in dry-run)"
  rm -rf "$TEST_WORKSPACE"
  exit 1
else
  echo "✅ No directories created"
fi

# Test 2: Lecture project dry-run with --preview alias
echo ""
echo "Test 2: Lecture project with --preview"
output=$("$DIRFORGE" --preview init lecture --name "Test Lecture" --no-conda 2>&1)

if echo "$output" | grep -q "DRY RUN"; then
  echo "✅ Preview mode works (--preview alias)"
else
  echo "❌ FAIL: --preview alias not working"
  rm -rf "$TEST_WORKSPACE"
  exit 1
fi

if [ -d "LECTURE_WORLD" ]; then
  echo "❌ FAIL: LECTURE_WORLD directory was created (should not happen in preview)"
  rm -rf "$TEST_WORKSPACE"
  exit 1
else
  echo "✅ No directories created"
fi

# Test 3: Coding project dry-run
echo ""
echo "Test 3: Coding project with --dry-run"
output=$("$DIRFORGE" --dry-run init coding --language python --project test_toolkit 2>&1)

if echo "$output" | grep -q "DRY RUN"; then
  echo "✅ Dry-run mode detected"
else
  echo "❌ FAIL: No dry-run markers in coding output"
  rm -rf "$TEST_WORKSPACE"
  exit 1
fi

if [ -d "CODING_WORLD" ]; then
  echo "❌ FAIL: CODING_WORLD directory was created"
  rm -rf "$TEST_WORKSPACE"
  exit 1
else
  echo "✅ No directories created"
fi

# Cleanup
cd /
rm -rf "$TEST_WORKSPACE"

echo ""
echo "✅ PASS: All dry-run tests passed - no filesystem writes detected"
exit 0
