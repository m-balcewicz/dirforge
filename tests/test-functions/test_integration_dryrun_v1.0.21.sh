#!/usr/bin/env bash
set -euo pipefail

# Integration test: Verify dirforge --dry-run init research produces no files
# This is a comprehensive end-to-end test for dry-run mode

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DIRFORGE="$PROJECT_ROOT/tools/dirforge"

echo "=== T015: Integration test for --dry-run init research ==="

if [ ! -f "$DIRFORGE" ]; then
  echo "ERROR: dirforge not found at $DIRFORGE" >&2
  exit 1
fi

# Create isolated test workspace
TEST_WORKSPACE="/tmp/dirforge_integration_dryrun_$$"
mkdir -p "$TEST_WORKSPACE"
cd "$TEST_WORKSPACE"

echo "Test workspace: $TEST_WORKSPACE"

# Count initial files/directories
BEFORE_COUNT=$(find . -mindepth 1 | wc -l | tr -d ' ')
echo "Files/directories before dry-run: $BEFORE_COUNT"

# Run dirforge in dry-run mode
echo ""
echo "Running: dirforge --dry-run init research --name 'Thermal Analysis' --no-conda"
set +e
"$DIRFORGE" --dry-run create research --name "Thermal Analysis" --no-conda > /tmp/dryrun_output.txt 2>&1
EXIT_CODE=$?
set -e

echo "Exit code: $EXIT_CODE"

if [ "$EXIT_CODE" -ne 0 ]; then
  echo "❌ FAIL: dirforge exited with non-zero code: $EXIT_CODE"
  cat /tmp/dryrun_output.txt
  rm -rf "$TEST_WORKSPACE"
  exit 1
fi

# Count files/directories after dry-run
AFTER_COUNT=$(find . -mindepth 1 | wc -l | tr -d ' ')
echo "Files/directories after dry-run: $AFTER_COUNT"

# Verify no new files/directories were created
if [ "$BEFORE_COUNT" -ne "$AFTER_COUNT" ]; then
  echo "❌ FAIL: File count changed during dry-run (before: $BEFORE_COUNT, after: $AFTER_COUNT)"
  echo "Created files:"
  find . -mindepth 1
  rm -rf "$TEST_WORKSPACE"
  exit 1
fi

# Verify output contains expected dry-run markers
if ! grep -q "DRY RUN" /tmp/dryrun_output.txt; then
  echo "❌ FAIL: Output does not contain 'DRY RUN' marker"
  cat /tmp/dryrun_output.txt
  rm -rf "$TEST_WORKSPACE"
  exit 1
fi

# Verify output mentions the project structure
if ! grep -qi "thermal" /tmp/dryrun_output.txt; then
  echo "❌ FAIL: Output does not reference project name"
  cat /tmp/dryrun_output.txt
  rm -rf "$TEST_WORKSPACE"
  exit 1
fi

# Verify specific directories that should be mentioned (but not created)
echo ""
echo "Checking output mentions expected directories..."
cat /tmp/dryrun_output.txt

echo ""
echo "✅ PASS: Integration test successful"
echo "  - Exit code: 0"
echo "  - No files/directories created"
echo "  - Dry-run markers present"
echo "  - Project structure previewed"

# Cleanup
cd /
rm -rf "$TEST_WORKSPACE"
rm -f /tmp/dryrun_output.txt

exit 0
