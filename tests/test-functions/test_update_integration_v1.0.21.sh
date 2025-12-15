#!/usr/bin/env bash
# Integration tests for dirforge update command
set -euo pipefail

TEST_ROOT="$(dirname "$0")/dirforge_test_workspace_$$"
mkdir -p "$TEST_ROOT"
trap 'rm -rf "$TEST_ROOT"' EXIT

# Test: update on up-to-date project (should be no-op)
cp -a "$TEST_ROOT/../fixtures/journal_v1.0.21" "$TEST_ROOT/journal_up_to_date"
cd "$TEST_ROOT/journal_up_to_date"
output=$(../../../tools/dirforge update --dry-run)
echo "$output" | grep -q "already up to date"

# Test: update with backup
cp -a "$TEST_ROOT/../fixtures/journal_v1.0.20" "$TEST_ROOT/journal_backup"
cd "$TEST_ROOT/journal_backup"
../../../tools/dirforge update --backup > update.log
backup_path=$(grep 'Backup created at:' update.log | awk '{print $5}')
[ -d "$backup_path" ]

# Test: update with nested subprojects
cp -a "$TEST_ROOT/../fixtures/nested_projects" "$TEST_ROOT/nested"
cd "$TEST_ROOT/nested"
../../../tools/dirforge update --dry-run | grep -q "Found nested subprojects"

# Test: update with manual migration warning
cp -a "$TEST_ROOT/../fixtures/office_v1.0.9" "$TEST_ROOT/office_manual"
cd "$TEST_ROOT/office_manual"
../../../tools/dirforge update --dry-run | grep -q "Manual migration steps required"

echo "All integration tests passed."
