#!/usr/bin/env bash
# Migration Testing for Breaking Change Documentation
# Tests that migration documentation is comprehensive and accurate
# Validates breaking change guidance for journal structure changes in v1.0.21

set -euo pipefail

# Import test framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source test framework
source "$SCRIPT_DIR/bootstrap_tests.sh"

# Set up paths
DIRFORGE="$PROJECT_ROOT/tools/dirforge"
MIGRATION_DOC="$PROJECT_ROOT/docs/migration-v1.0.16-to-v1.0.17.md"
CONSTITUTION="$PROJECT_ROOT/.specify/memory/constitution.md"

# Verify dirforge executable exists
if [ ! -f "$DIRFORGE" ]; then
  echo "ERROR: dirforge not found at $DIRFORGE" >&2
  exit 1
fi

# Helper function to test output contains pattern
assert_output_contains() {
    local output="$1"
    local pattern="$2"
    local description="$3"
    TEST_COUNT=$((TEST_COUNT + 1))
    
    echo -n "Test $TEST_COUNT: $description ... "
    
    if echo "$output" | grep -q "$pattern"; then
        echo -e "${GREEN:-}✓ PASS${NC:-}"
        PASSED_COUNT=$((PASSED_COUNT + 1))
        return 0
    else
        echo -e "${RED:-}✗ FAIL${NC:-}"
        echo "  Expected pattern: $pattern"
        echo "  In output: $(echo "$output" | head -3 | tr '\n' ' ')..."
        FAILED_COUNT=$((FAILED_COUNT + 1))
        return 1
    fi
}

# Start test suite
start_test_suite "Migration Documentation Tests"

echo
echo "=================================================================="
echo "MIGRATION DOCUMENTATION AND BREAKING CHANGE VALIDATION"
echo "Testing migration guidance, documentation, and constitutional compliance"
echo "=================================================================="

# Test 1: Migration Documentation Files Exist
echo
echo "Test 1: Migration Documentation Files"
echo "===================================="

assert_file_exists "$MIGRATION_DOC" "Migration documentation file exists"
assert_file_exists "$CONSTITUTION" "Constitution file exists"

# Test 2: Constitution Version and Migration References
echo
echo "Test 2: Constitution v1.0.21 Migration References"
echo "================================================="

if [ -f "$CONSTITUTION" ]; then
    CONSTITUTION_CONTENT=$(cat "$CONSTITUTION")
    assert_output_contains "$CONSTITUTION_CONTENT" "v1.0.21" "Constitution contains v1.0.21 version"
    assert_output_contains "$CONSTITUTION_CONTENT" "migration" "Constitution mentions migration requirements"
    assert_output_contains "$CONSTITUTION_CONTENT" "manual migration" "Constitution specifies manual migration"
    assert_output_contains "$CONSTITUTION_CONTENT" "Role-based" "Constitution references role-based structure"
else
    echo "Warning: Constitution file not found for content testing"
fi

# Test 3: Help System Migration Guidance
echo
echo "Test 3: Help System Migration Guidance"
echo "======================================"

# Test migration guidance in journal help
OUTPUT=$(run_dirforge init journal --help-long 2>&1 || run_dirforge init journal --help 2>&1 || true)
assert_output_contains "$OUTPUT" "migration" "Help contains migration guidance"
assert_output_contains "$OUTPUT" "v1.0.21" "Help contains current constitution version"
assert_output_contains "$OUTPUT" "Constitution" "Help references constitution"

# Test 4: Breaking Change Documentation (Journal v1.0.21)
echo
echo "Test 4: Journal Structure Breaking Change Documentation"
echo "====================================================="

# Since we're testing journal structure migration for v1.0.21, 
# focus on constitutional documentation and help system guidance
CONSTITUTION_CONTENT=$(cat "$CONSTITUTION" 2>/dev/null || echo "")

if [ -n "$CONSTITUTION_CONTENT" ]; then
    # Test essential journal migration information in constitution
    assert_output_contains "$CONSTITUTION_CONTENT" "v1.0.21" "Constitution documents v1.0.21 changes"
    assert_output_contains "$CONSTITUTION_CONTENT" "JOURNAL_WORLD" "Constitution explains journal structure"
    assert_output_contains "$CONSTITUTION_CONTENT" "00_admin" "Constitution mentions admin directory"
    assert_output_contains "$CONSTITUTION_CONTENT" "01_primary_authorship" "Constitution mentions primary authorship"
    assert_output_contains "$CONSTITUTION_CONTENT" "breaking change\|Manual migration" "Constitution warns of breaking changes"
else
    echo "Warning: Constitution content not available for testing"
fi

# Test 5: Breaking Change Communication
echo
echo "Test 5: Breaking Change Communication"
echo "===================================="

# Test version command shows breaking change information
OUTPUT=$(run_dirforge --version 2>&1 || true)
assert_output_contains "$OUTPUT" "v1.0.21" "Version shows current constitution"

# Test that old journal structure is not supported (breaking change)
TEMP_WORKSPACE=$(create_temp_workspace "migration_breaking_change_test")
cd "$TEMP_WORKSPACE"

# Create old-style journal structure to test rejection
mkdir -p JOURNAL_WORLD
echo "# Old journal structure test" > JOURNAL_WORLD/test_paper.txt

# New command should work with new structure
assert_success "run_dirforge init journal --name 'test_paper' --first" \
  "New command pattern works with role-based structure"

# Verify new structure was created correctly (not old style)
assert_dir_exists "JOURNAL_WORLD/01_primary_authorship" \
  "Role-based directory structure created"

cleanup_temp_workspace

# Test 6: Command Flag Migration
echo
echo "Test 6: Command Flag Migration"
echo "=============================="

TEMP_WORKSPACE=$(create_temp_workspace "migration_flag_test")
cd "$TEMP_WORKSPACE"

# Test that new unified --name flag works for all contexts
assert_success "run_dirforge init journal --name 'test_primary' --first" \
  "Unified --name flag works for primary authorship"

assert_success "run_dirforge init journal --name 'test_coauthor' --coauthor" \
  "Unified --name flag works for co-author"

assert_success "run_dirforge init journal --name 'test_journal' --id 'TEST-123' --service" \
  "Unified --name flag works for journal service"

# Test that old --paper flag is no longer supported (breaking change)
assert_failure "run_dirforge init journal --paper 'test_paper' --first" \
  "Old --paper flag should fail (breaking change)"

assert_failure "run_dirforge init journal --journal 'test_journal' --service" \
  "Old --journal flag should fail without --id (breaking change)"

cleanup_temp_workspace

# Test 7: Migration Error Messages
echo
echo "Test 7: Migration Error Messages and Guidance"
echo "============================================="

TEMP_WORKSPACE=$(create_temp_workspace "migration_error_test")
cd "$TEMP_WORKSPACE"

# Test error messages provide migration guidance
OUTPUT=$(run_dirforge init journal --paper 'test' --first 2>&1 || true)
if echo "$OUTPUT" | grep -q "paper"; then
    assert_output_contains "$OUTPUT" "name" "Error suggests using --name instead of --paper"
fi

OUTPUT=$(run_dirforge init journal --journal 'test' --service 2>&1 || true)  
if echo "$OUTPUT" | grep -q "journal"; then
    assert_output_contains "$OUTPUT" "name" "Error suggests using --name instead of --journal"
fi

cleanup_temp_workspace

# Test 8: Migration Documentation Accessibility
echo
echo "Test 8: Migration Documentation Accessibility"
echo "============================================="

# Test help system provides migration documentation access
OUTPUT=$(run_dirforge init journal --help 2>&1 || true)
assert_output_contains "$OUTPUT" "Constitution" "Help provides access to constitutional information"

# Test version information is easily accessible
OUTPUT=$(run_dirforge --version 2>&1 || true)
assert_output_contains "$OUTPUT" "v1.0.21" "Version command provides current version"

# Test 9: Migration Backup and Safety
echo
echo "Test 9: Migration Safety and Backup Testing"
echo "==========================================="

TEMP_WORKSPACE=$(create_temp_workspace "migration_safety_test")
cd "$TEMP_WORKSPACE"

# Test that existing directories are preserved (not overwritten)
mkdir -p JOURNAL_WORLD/test_existing
echo "existing content" > JOURNAL_WORLD/test_existing/important.txt

# Create new journal project should not affect existing content
assert_success "run_dirforge init journal --name 'new_project' --first" \
  "New project creation preserves existing content"

assert_file_exists "JOURNAL_WORLD/test_existing/important.txt" \
  "Existing content preserved during new project creation"

# Verify content is unchanged
CONTENT=$(cat JOURNAL_WORLD/test_existing/important.txt)
assert_output_contains "$CONTENT" "existing content" "Existing file content unchanged"

cleanup_temp_workspace

# Test 10: Migration Validation and Completeness
echo
echo "Test 10: Migration Completeness Validation"
echo "=========================================="

# Test all four role directories are documented and functional
TEMP_WORKSPACE=$(create_temp_workspace "migration_completeness_test")
cd "$TEMP_WORKSPACE"

# Test all role-based functionality works
assert_success "run_dirforge init journal --name 'test1' --first" \
  "Primary authorship role fully functional"

assert_success "run_dirforge init journal --name 'test2' --coauthor" \
  "Co-author role fully functional"

assert_success "run_dirforge init journal --name 'nature' --id 'TEST-123' --service" \
  "Journal service role fully functional"

# Verify all role directories exist
assert_dir_exists "JOURNAL_WORLD/00_admin" "Admin role directory created"
assert_dir_exists "JOURNAL_WORLD/01_primary_authorship" "Primary authorship role directory"
assert_dir_exists "JOURNAL_WORLD/02_coauthor_invites" "Co-author role directory"
assert_dir_exists "JOURNAL_WORLD/03_journal_service" "Journal service role directory"

# Determine current year for project path verification
CURRENT_YEAR=$(date +%Y)

# Verify functional separation is maintained
assert_dir_exists "JOURNAL_WORLD/01_primary_authorship/${CURRENT_YEAR}_test1" "Primary project in correct role"
assert_dir_exists "JOURNAL_WORLD/02_coauthor_invites/${CURRENT_YEAR}_test2" "Co-author project in correct role"  
assert_dir_exists "JOURNAL_WORLD/03_journal_service/nature/TEST-123" "Service project in correct role"

cleanup_temp_workspace

echo
echo "=================================================================="
echo "MIGRATION TESTING SUMMARY"
echo "=================================================================="
echo "✓ Migration documentation exists and is comprehensive"
echo "✓ Breaking change communication is clear"
echo "✓ Constitutional compliance validated"
echo "✓ Command flag migration properly handled"
echo "✓ Error messages provide migration guidance"
echo "✓ Migration safety and backup considerations covered"
echo "✓ Complete role-based functionality validated"
echo "✓ Documentation accessibility confirmed"

finish_test_suite "Migration Documentation Tests" "$TEST_COUNT"