#!/usr/bin/env bash
# Integration tests for dirforge update command
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DIRFORGE="$PROJECT_ROOT/tools/dirforge"
FIXTURES_DIR="$SCRIPT_DIR/fixtures"

TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT

# Test: update on up-to-date project (should be no-op)
cp -a "$FIXTURES_DIR/journal_v1.0.21" "$TEST_ROOT/journal_up_to_date"
cd "$TEST_ROOT/journal_up_to_date"
output=$(bash "$DIRFORGE" update --dry-run)
echo "$output" | grep -q "already up to date"

# Test: update with backup
cp -a "$FIXTURES_DIR/journal_v1.0.20" "$TEST_ROOT/journal_backup"
cd "$TEST_ROOT/journal_backup"
bash "$DIRFORGE" update --backup > update.log
backup_path=$(grep 'Backup created at:' update.log | awk '{print $5}')
[ -d "$backup_path" ]

# Test: update with nested subprojects
cp -a "$FIXTURES_DIR/nested_projects" "$TEST_ROOT/nested"
cd "$TEST_ROOT/nested"
bash "$DIRFORGE" update --dry-run | grep -q "Found nested subprojects"

# Test: update with manual migration warning
cp -a "$FIXTURES_DIR/office_v1.0.9" "$TEST_ROOT/office_manual"
cd "$TEST_ROOT/office_manual"
bash "$DIRFORGE" update --dry-run | grep -q "Manual migration steps required"

echo "All integration tests passed."
