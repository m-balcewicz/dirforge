#!/usr/bin/env bash

# Update Test Syntax - Convert deprecated init syntax to create syntax
# This script updates test files to use the new create command structure

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

echo "🔄 Updating test files to use create syntax instead of deprecated init syntax..."

# Files to update (excluding v1.1.0 test files and intentional backward compatibility tests)
TEST_FILES=(
  "tests/test-functions/test_coding_help_v1.0.21.sh"
  "tests/test-functions/test_dirforge_init_yaml.sh"
  "tests/test-functions/test_dry_run_v1.0.21.sh"
  "tests/test-functions/test_force_backup_v1.0.21.sh"
  "tests/test-functions/test_help_accessibility_v1.0.21.sh"
  "tests/test-functions/test_help_constitution_refs_v1.0.21.sh"
  "tests/test-functions/test_help_example_validation_v1.0.21.sh"
  "tests/test-functions/test_help_help_content_v1.0.21.sh"
  "tests/test-functions/test_help_help_integration_v1.0.21.sh"
  "tests/test-functions/test_help_pager_integration_v1.0.21.sh"
  "tests/test-functions/test_help_performance_v1.0.21.sh"
  "tests/test-functions/test_init_outputs_v1.0.21.sh"
  "tests/test-functions/test_integration_dryrun_v1.0.21.sh"
  "tests/test-functions/test_journal_coauthor_v1.0.21.sh"
  "tests/test-functions/test_journal_primary_authorship_v1.0.21.sh"
  "tests/test-functions/test_journal_service_v1.0.21.sh"
  "tests/test-functions/test_migration_v1.0.21.sh"
  "tests/test-functions/test_parent_only_mode_v1.0.21.sh"
  "tests/test-functions/test_regression_full_project_init_v1.0.21.sh"
  "tests/test-functions/test_regression_quick_v1.0.21.sh"
  "tests/test-functions/test_workspace_init_v1.0.21.sh"
)

# Backup directory
BACKUP_DIR="tests/backups/$(date +%Y%m%d_%H%M%S)_init_to_create_conversion"
mkdir -p "$BACKUP_DIR"

# Function to backup and update a file
update_file() {
  local file="$1"
  local basename_file=$(basename "$file")
  
  echo "  📝 Processing $basename_file..."
  
  # Create backup
  cp "$file" "$BACKUP_DIR/$basename_file"
  
  # Apply replacements
  sed -i '' \
    -e 's/init journal/create journal/g' \
    -e 's/init research/create research/g' \
    -e 's/init coding/create coding/g' \
    -e 's/init lecture/create lecture/g' \
    "$file"
    
  # Count changes
  local old_count=$(grep -c "init journal\|init research\|init coding\|init lecture" "$BACKUP_DIR/$basename_file" 2>/dev/null || echo 0)
  local new_count=$(grep -c "init journal\|init research\|init coding\|init lecture" "$file" 2>/dev/null || echo 0)
  local changes=$((old_count - new_count))
  
  if [ "$changes" -gt 0 ]; then
    echo "    ✅ Updated $changes instances"
  else
    echo "    ℹ️  No changes needed"
  fi
}

# Process each file
for file in "${TEST_FILES[@]}"; do
  if [ -f "$file" ]; then
    update_file "$file"
  else
    echo "  ⚠️  File not found: $file"
  fi
done

echo ""
echo "🎉 Test syntax update complete!"
echo "📁 Backups saved to: $BACKUP_DIR"
echo ""
echo "🔍 Verification - remaining deprecated instances:"

# Verify updates
remaining=0
for file in "${TEST_FILES[@]}"; do
  if [ -f "$file" ]; then
    count=$(grep -c "init journal\|init research\|init coding\|init lecture" "$file" 2>/dev/null || echo 0)
    if [ "$count" -gt 0 ]; then
      echo "  ⚠️  $file: $count instances remaining"
      remaining=$((remaining + count))
    fi
  fi
done

if [ "$remaining" -eq 0 ]; then
  echo "  ✅ All files successfully updated - no deprecated syntax remaining!"
else
  echo "  ❌ $remaining instances of deprecated syntax still found"
  exit 1
fi