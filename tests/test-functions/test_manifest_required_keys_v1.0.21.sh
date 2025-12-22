#!/usr/bin/env bash
set -euo pipefail

# Unit test: Verify manifest validator fails when required keys are missing
# Constitution requirement: storage_location, server_or_nas, path_on_store, naming, checksum, access

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
VALIDATOR="$PROJECT_ROOT/tools/manifest.sh"
FIXTURES_DIR="$SCRIPT_DIR/fixtures"

# Test fixture with missing required key
TEST_MANIFEST="$FIXTURES_DIR/manifest_missing_key.yaml"

echo "=== T011: Testing missing-required-keys detection ==="
echo "Manifest: $TEST_MANIFEST"

if [ ! -f "$VALIDATOR" ]; then
  echo "ERROR: Validator not found at $VALIDATOR" >&2
  exit 1
fi

if [ ! -f "$TEST_MANIFEST" ]; then
  echo "ERROR: Test fixture not found at $TEST_MANIFEST" >&2
  exit 1
fi

# Expect validator to FAIL (exit code != 0)
set +e
"$VALIDATOR" "$TEST_MANIFEST" 2>&1 | tee /tmp/missing_key_output.txt
exit_code=$?
set -e

if [ "$exit_code" -eq 0 ]; then
  echo "❌ FAIL: Validator should reject manifest with missing required keys"
  echo "Expected non-zero exit code, got: $exit_code"
  exit 1
fi

# Check error message mentions missing key
if ! grep -qi "missing" /tmp/missing_key_output.txt; then
  echo "❌ FAIL: Error message should mention 'missing' key"
  cat /tmp/missing_key_output.txt
  exit 1
fi

echo "✅ PASS: Validator correctly rejected manifest with missing required key"
echo "Exit code: $exit_code"
exit 0
