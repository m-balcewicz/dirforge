#!/usr/bin/env bash
set -euo pipefail

# Unit test: Verify manifest validator rejects forbidden keys
# Constitution requirement: No plaintext credentials in manifests

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
VALIDATOR="$PROJECT_ROOT/tools/manifest.sh"
FIXTURES_DIR="$SCRIPT_DIR/fixtures"

# Test fixture with forbidden key
TEST_MANIFEST="$FIXTURES_DIR/manifest_forbidden_key.yaml"

echo "=== T010: Testing forbidden-key detection ==="
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
"$VALIDATOR" "$TEST_MANIFEST" 2>&1 | tee /tmp/forbidden_key_output.txt
exit_code=$?
set -e

if [ "$exit_code" -eq 0 ]; then
  echo "❌ FAIL: Validator should reject manifest with forbidden keys"
  echo "Expected non-zero exit code, got: $exit_code"
  exit 1
fi

# Check error message mentions forbidden key
if ! grep -qi "forbidden" /tmp/forbidden_key_output.txt; then
  echo "❌ FAIL: Error message should mention 'forbidden' keyword"
  cat /tmp/forbidden_key_output.txt
  exit 1
fi

echo "✅ PASS: Validator correctly rejected manifest with forbidden key"
echo "Exit code: $exit_code"
exit 0
