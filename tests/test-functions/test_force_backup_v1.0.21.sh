#!/usr/bin/env bash
# Test --force, --backup, and --yes flags for init commands
# Part of T020-T021 - US4

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Create temp directory for tests
TEST_DIR=$(mktemp -d)
trap 'rm -rf "$TEST_DIR"' EXIT

cd "$TEST_DIR"

echo "=== Test force_backup: reject overwrite without flags ==="

# Create initial project
"$REPO_ROOT/tools/dirforge" init research --name "Test" --no-conda >/dev/null 2>&1

# Try to create same project again (should fail)
if "$REPO_ROOT/tools/dirforge" init research --name "Test" --no-conda 2>/dev/null; then
  echo "FAIL: Should reject overwrite without --force or --backup"
  exit 1
fi

echo "✅ Correctly rejects overwrite without flags"

echo "=== Test force_backup: --force overwrites ==="

# Create marker file in existing project
echo "original" > RESEARCH_WORLD/2025_test/marker.txt

# Overwrite with --force --yes (skip prompt)
"$REPO_ROOT/tools/dirforge" init research --name "Test" --no-conda --force --yes >/dev/null 2>&1

# Check marker file is gone
if [ -f "RESEARCH_WORLD/2025_test/marker.txt" ]; then
  echo "FAIL: --force should have overwritten the project"
  exit 1
fi

# Check required files exist
if [ ! -f "RESEARCH_WORLD/2025_test/README.md" ]; then
  echo "FAIL: --force should recreate README.md"
  exit 1
fi

echo "✅ --force overwrites existing project"

echo "=== Test force_backup: --backup creates backup ==="

# Create marker file again
echo "original" > RESEARCH_WORLD/2025_test/marker.txt

# Overwrite with --backup --yes
"$REPO_ROOT/tools/dirforge" init research --name "Test" --no-conda --backup --yes >/dev/null 2>&1

# Check backup exists (should be in RESEARCH_WORLD/)
BACKUP_DIR=$(find RESEARCH_WORLD -maxdepth 1 -type d -name "2025_test.backup-*" | head -1)
if [ -z "$BACKUP_DIR" ]; then
  echo "FAIL: --backup should create backup directory"
  exit 1
fi

# Check marker file is in backup
if [ ! -f "$BACKUP_DIR/marker.txt" ]; then
  echo "FAIL: Backup should contain marker.txt"
  exit 1
fi

# Check original marker is gone
if [ -f "RESEARCH_WORLD/2025_test/marker.txt" ]; then
  echo "FAIL: Original marker should be overwritten"
  exit 1
fi

echo "✅ --backup creates timestamped backup"

echo "=== Test force_backup: lecture support ==="

# Create lecture
"$REPO_ROOT/tools/dirforge" init lecture --name "Test Lecture" --no-conda >/dev/null 2>&1

# Create marker
echo "lecture-marker" > LECTURE_WORLD/test_lecture/marker.txt

# Overwrite with --force --yes
"$REPO_ROOT/tools/dirforge" init lecture --name "Test Lecture" --no-conda --force --yes >/dev/null 2>&1

# Check marker is gone
if [ -f "LECTURE_WORLD/test_lecture/marker.txt" ]; then
  echo "FAIL: Lecture --force should overwrite"
  exit 1
fi

echo "✅ --force works for lectures"

echo "=== Test force_backup: backup naming convention ==="

# Check backup has correct timestamp format (YYYYMMDD-HHMMSS)
if ! echo "$BACKUP_DIR" | grep -qE '\.backup-[0-9]{8}-[0-9]{6}$'; then
  echo "FAIL: Backup should have timestamp format .backup-YYYYMMDD-HHMMSS"
  exit 1
fi

echo "✅ Backup uses correct timestamp format"

echo ""
echo "All force_backup tests passed!"
exit 0
