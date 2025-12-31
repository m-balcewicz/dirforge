#!/usr/bin/env bash
# Integration test: Primary Authorship Management for JOURNAL_WORLD Role-Based Organization
# Tests the complete workflow for User Story 1: Primary Authorship Management
# Validates command parsing, directory creation, error handling, and help system

set -euo pipefail

# Import test framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source test framework
source "$SCRIPT_DIR/bootstrap_tests.sh"

# Set up paths
DIRFORGE="$PROJECT_ROOT/tools/dirforge"
FIXTURE_DIR="$SCRIPT_DIR/fixtures"

# Verify dirforge executable exists
if [ ! -f "$DIRFORGE" ]; then
  echo "ERROR: dirforge not found at $DIRFORGE" >&2
  exit 1
fi

# Start test suite
start_test_suite "Primary Authorship Integration Tests"

# Test 1: Basic primary authorship project creation (current year)
echo
echo "Test 1: Basic Primary Authorship Project (Current Year Default)"
echo "==============================================================="

TEMP_WORKSPACE=$(create_temp_workspace "journal_primary_test")
cd "$TEMP_WORKSPACE"

# Create primary authorship project with current year default
CURRENT_YEAR=$(date +%Y)
assert_success "run_dirforge create journal --name 'thermal_conductivity_review' --first" \
  "Create primary authorship project with current year"

# Verify directory structure
PROJECT_PATH="JOURNAL_WORLD/01_primary_authorship/${CURRENT_YEAR}_thermal_conductivity_review"
assert_dir_exists "$PROJECT_PATH" "Primary authorship project directory"
assert_dir_exists "$PROJECT_PATH/01_manuscript" "Manuscript subdirectory"
assert_dir_exists "$PROJECT_PATH/02_reviews" "Reviews subdirectory"
assert_dir_exists "$PROJECT_PATH/03_correspondence" "Correspondence subdirectory"

# Verify JOURNAL_WORLD role structure was created
assert_dir_exists "JOURNAL_WORLD/00_admin" "Admin role directory"
assert_dir_exists "JOURNAL_WORLD/01_primary_authorship" "Primary authorship role directory"
assert_dir_exists "JOURNAL_WORLD/02_coauthor_invites" "Coauthor role directory"
assert_dir_exists "JOURNAL_WORLD/03_journal_service" "Journal service role directory"

cleanup_temp_workspace

# Test 2: Primary authorship project with explicit year
echo
echo "Test 2: Primary Authorship Project with Explicit Year"
echo "====================================================="

TEMP_WORKSPACE=$(create_temp_workspace "journal_primary_year_test")
cd "$TEMP_WORKSPACE"

# Create project with explicit year
assert_success "run_dirforge create journal --name 'ai_geophysics_survey' --first --year 2024" \
  "Create primary authorship project with explicit year"

# Verify correct year in path
PROJECT_PATH="JOURNAL_WORLD/01_primary_authorship/2024_ai_geophysics_survey"
assert_dir_exists "$PROJECT_PATH" "Project with explicit year"
assert_dir_exists "$PROJECT_PATH/01_manuscript" "Manuscript subdirectory"
assert_dir_exists "$PROJECT_PATH/02_reviews" "Reviews subdirectory"
assert_dir_exists "$PROJECT_PATH/03_correspondence" "Correspondence subdirectory"

cleanup_temp_workspace

# Test 3: Paper name with embedded year (automatic extraction)
echo
echo "Test 3: Paper Name with Embedded Year (Automatic Extraction)"
echo "============================================================"

TEMP_WORKSPACE=$(create_temp_workspace "journal_embedded_year_test")
cd "$TEMP_WORKSPACE"

# Create project with year embedded in name
assert_success "run_dirforge create journal --name '2021_elastic_properties_of_carbonates' --first" \
  "Create project with embedded year in name"

# Verify year was extracted correctly
PROJECT_PATH="JOURNAL_WORLD/01_primary_authorship/2021_elastic_properties_of_carbonates"
assert_dir_exists "$PROJECT_PATH" "Project with extracted year"

cleanup_temp_workspace

# Test 4: Complex paper name sanitization
echo
echo "Test 4: Complex Paper Name Sanitization"
echo "======================================="

TEMP_WORKSPACE=$(create_temp_workspace "journal_sanitization_test")
cd "$TEMP_WORKSPACE"

# Create project with complex paper name requiring sanitization
assert_success "run_dirforge create journal --name 'Biot Coefficient Analysis in Porous Media' --first" \
  "Create project with complex name requiring sanitization"

# Verify name was sanitized correctly
CURRENT_YEAR=$(date +%Y)
PROJECT_PATH="JOURNAL_WORLD/01_primary_authorship/${CURRENT_YEAR}_biot_coefficient_analysis_in_porous_media"
assert_dir_exists "$PROJECT_PATH" "Project with sanitized name"

cleanup_temp_workspace

# Test 5: Conflict detection (existing directory)
echo
echo "Test 5: Conflict Detection (Existing Directory)"
echo "==============================================="

TEMP_WORKSPACE=$(create_temp_workspace "journal_conflict_test")
cd "$TEMP_WORKSPACE"

# Create first project
assert_success "run_dirforge create journal --name 'test_paper' --first" \
  "Create first project"

# Try to create project with same name (should fail)
assert_failure "run_dirforge create journal --name 'test_paper' --first" \
  "Attempt to create duplicate project should fail"

cleanup_temp_workspace

# Test 6: Dry run mode validation
echo
echo "Test 6: Dry Run Mode Validation"
echo "==============================="

TEMP_WORKSPACE=$(create_temp_workspace "journal_dryrun_test")
cd "$TEMP_WORKSPACE"

# Run in dry-run mode
output=$(run_dirforge --dry-run create journal --name 'test_paper_dry_run' --first 2>&1)

# Verify dry-run message appears
if echo "$output" | grep -q "DRY RUN"; then
  echo "✓ Dry-run mode detected in output"
  PASSED_COUNT=$((PASSED_COUNT + 1))
else
  echo "✗ FAIL: No 'DRY RUN' marker in output"
  FAILED_COUNT=$((FAILED_COUNT + 1))
fi
TEST_COUNT=$((TEST_COUNT + 1))

# Verify no directories were created
assert_dir_not_exists "JOURNAL_WORLD" "No directories should be created in dry-run mode"

cleanup_temp_workspace

# Test 7: Invalid paper name validation
echo
echo "Test 7: Invalid Paper Name Validation"
echo "====================================="

TEMP_WORKSPACE=$(create_temp_workspace "journal_invalid_name_test")
cd "$TEMP_WORKSPACE"

# Test invalid characters in paper name
assert_failure "run_dirforge create journal --name 'Invalid@Paper#Name!' --first" \
  "Invalid paper name with special characters should fail"

cleanup_temp_workspace

# Test 8: Year validation edge cases
echo
echo "Test 8: Year Validation Edge Cases"
echo "=================================="

TEMP_WORKSPACE=$(create_temp_workspace "journal_year_validation_test")
cd "$TEMP_WORKSPACE"

# Test invalid year formats
assert_failure "run_dirforge create journal --name 'test_paper' --first --year 25" \
  "Invalid year format (2 digits) should fail"

assert_failure "run_dirforge create journal --name 'test_paper' --first --year abcd" \
  "Invalid year format (letters) should fail"

# Test valid historical year
assert_success "run_dirforge create journal --name 'historical_paper' --first --year 2000" \
  "Valid historical year should succeed"

cleanup_temp_workspace

# Test 9: Missing required flags
echo
echo "Test 9: Missing Required Flags"
echo "=============================="

TEMP_WORKSPACE=$(create_temp_workspace "journal_missing_flags_test")
cd "$TEMP_WORKSPACE"

# Test missing paper name
assert_failure "run_dirforge create journal --first" \
  "Missing --name flag should fail"

# Test missing role flag
assert_failure "run_dirforge create journal --name 'test_paper'" \
  "Missing role flag (--first) should fail"

cleanup_temp_workspace

# Test 10: JOURNAL_WORLD root detection and creation
echo
echo "Test 10: JOURNAL_WORLD Root Detection and Creation"
echo "=================================================="

TEMP_WORKSPACE=$(create_temp_workspace "journal_root_test")
cd "$TEMP_WORKSPACE"

# First project should create JOURNAL_WORLD structure
assert_success "run_dirforge create journal --name 'first_project' --first" \
  "First project creation should establish JOURNAL_WORLD"

# Verify role structure exists
assert_dir_exists "JOURNAL_WORLD" "JOURNAL_WORLD root directory"
assert_dir_exists "JOURNAL_WORLD/00_admin" "Admin role directory"
assert_dir_exists "JOURNAL_WORLD/01_primary_authorship" "Primary authorship role directory"
assert_dir_exists "JOURNAL_WORLD/02_coauthor_invites" "Coauthor role directory"
assert_dir_exists "JOURNAL_WORLD/03_journal_service" "Journal service role directory"

# Second project should use existing structure
assert_success "run_dirforge create journal --name 'second_project' --first" \
  "Second project should use existing JOURNAL_WORLD"

cleanup_temp_workspace

# Test 11: Integration with help system
echo
echo "Test 11: Help System Integration"
echo "================================"

TEMP_WORKSPACE=$(create_temp_workspace "journal_help_test")
cd "$TEMP_WORKSPACE"

# Test journal help output
help_output=$(run_dirforge create journal --help 2>&1)

# Verify help contains primary authorship examples (case-insensitive)
if echo "$help_output" | grep -qi "Primary Authorship\|Primary authorship"; then
  echo "✓ Help contains Primary Authorship section"
  PASSED_COUNT=$((PASSED_COUNT + 1))
else
  echo "✗ FAIL: Help missing Primary Authorship section"
  FAILED_COUNT=$((FAILED_COUNT + 1))
fi
TEST_COUNT=$((TEST_COUNT + 1))

# Verify help contains command examples (case-insensitive)
if echo "$help_output" | grep -qi "dirforge create journal --name.*--first"; then
  echo "✓ Help contains primary authorship command examples"
  PASSED_COUNT=$((PASSED_COUNT + 1))
else
  echo "✗ FAIL: Help missing primary authorship command examples"
  FAILED_COUNT=$((FAILED_COUNT + 1))
fi
TEST_COUNT=$((TEST_COUNT + 1))

cleanup_temp_workspace

# Test 12: Path construction utilities validation
echo
echo "Test 12: Path Construction Utilities Validation"
echo "==============================================="

TEMP_WORKSPACE=$(create_temp_workspace "journal_path_test")
cd "$TEMP_WORKSPACE"

# Create project and verify path construction is correct
assert_success "run_dirforge create journal --name 'path_test_paper' --first --year 2023" \
  "Create project for path validation"

# Check if the constructed path follows the expected pattern
EXPECTED_PATH="JOURNAL_WORLD/01_primary_authorship/2023_path_test_paper"
assert_dir_exists "$EXPECTED_PATH" "Path construction follows YYYY_paper_name pattern"

# Verify subdirectories follow naming convention
assert_dir_exists "$EXPECTED_PATH/01_manuscript" "Standard subdirectory: 01_manuscript"
assert_dir_exists "$EXPECTED_PATH/02_reviews" "Standard subdirectory: 02_reviews"  
assert_dir_exists "$EXPECTED_PATH/03_correspondence" "Standard subdirectory: 03_correspondence"

cleanup_temp_workspace

# Test 13: Command flag combinations
echo
echo "Test 13: Command Flag Combinations"
echo "=================================="

TEMP_WORKSPACE=$(create_temp_workspace "journal_flag_combo_test")
cd "$TEMP_WORKSPACE"

# Test all valid primary authorship flag combinations
assert_success "run_dirforge create journal --name 'combo_test1' --first" \
  "Valid: --name and --first only"

assert_success "run_dirforge create journal --name 'combo_test2' --first --year 2023" \
  "Valid: --name, --first, and --year"

# Test invalid flag combinations (conflicting roles)
assert_failure "run_dirforge create journal --name 'combo_test3' --first --coauthor" \
  "Invalid: --first and --coauthor together should fail"

cleanup_temp_workspace

# Test 14: Constitution compliance validation
echo
echo "Test 14: Constitution Compliance Validation"
echo "==========================================="

TEMP_WORKSPACE=$(create_temp_workspace "journal_constitution_test")
cd "$TEMP_WORKSPACE"

# Create project and validate it follows constitutional requirements
assert_success "run_dirforge create journal --name 'constitution_test' --first" \
  "Create project for constitution validation"

# Verify the structure matches constitutional requirements from fixtures
CURRENT_YEAR=$(date +%Y)
PROJECT_PATH="JOURNAL_WORLD/01_primary_authorship/${CURRENT_YEAR}_constitution_test"

# Check that only required subdirectories exist (no extra directories)
SUBDIR_COUNT=$(find "$PROJECT_PATH" -maxdepth 1 -type d | grep -v "^$PROJECT_PATH$" | wc -l)
if [ "$SUBDIR_COUNT" -eq 3 ]; then
  echo "✓ Exactly 3 subdirectories created (constitutional compliance)"
  PASSED_COUNT=$((PASSED_COUNT + 1))
else
  echo "✗ FAIL: Expected 3 subdirectories, found $SUBDIR_COUNT"
  FAILED_COUNT=$((FAILED_COUNT + 1))
fi
TEST_COUNT=$((TEST_COUNT + 1))

# Verify no unconstitutional subdirectories were created in JOURNAL_WORLD root
JOURNAL_ROLES=$(find "JOURNAL_WORLD" -maxdepth 1 -type d | grep -v "^JOURNAL_WORLD$" | wc -l)
if [ "$JOURNAL_ROLES" -eq 4 ]; then
  echo "✓ Exactly 4 role directories in JOURNAL_WORLD (constitutional compliance)"
  PASSED_COUNT=$((PASSED_COUNT + 1))
else
  echo "✗ FAIL: Expected 4 role directories, found $JOURNAL_ROLES"
  FAILED_COUNT=$((FAILED_COUNT + 1))
fi
TEST_COUNT=$((TEST_COUNT + 1))

cleanup_temp_workspace

# Test 15: Error message validation
echo
echo "Test 15: Error Message Validation"
echo "================================="

TEMP_WORKSPACE=$(create_temp_workspace "journal_error_msg_test")
cd "$TEMP_WORKSPACE"

# Test specific error messages match expected content from fixtures
error_output=$(run_dirforge create journal --name 'Invalid@Name!' --first 2>&1 || true)

if echo "$error_output" | grep -q "Error: Paper name can only contain letters, numbers, spaces, hyphens, and underscores"; then
  echo "✓ Correct error message for invalid paper name"
  PASSED_COUNT=$((PASSED_COUNT + 1))
else
  echo "✗ FAIL: Incorrect error message for invalid paper name"
  echo "Expected: 'Error: Paper name can only contain letters, numbers, spaces, hyphens, and underscores'"
  echo "Got: $error_output"
  FAILED_COUNT=$((FAILED_COUNT + 1))
fi
TEST_COUNT=$((TEST_COUNT + 1))

# Test year validation error message
year_error_output=$(run_dirforge create journal --name 'test_paper' --first --year abc 2>&1 || true)

if echo "$year_error_output" | grep -q "Error: Year must be a 4-digit number (YYYY)"; then
  echo "✓ Correct error message for invalid year"
  PASSED_COUNT=$((PASSED_COUNT + 1))
else
  echo "✗ FAIL: Incorrect error message for invalid year"
  echo "Expected: 'Error: Year must be a 4-digit number (YYYY)'"
  echo "Got: $year_error_output"
  FAILED_COUNT=$((FAILED_COUNT + 1))
fi
TEST_COUNT=$((TEST_COUNT + 1))

cleanup_temp_workspace

echo
echo "==============================================================================="
echo "Primary Authorship Integration Test Summary"
echo "==============================================================================="

# Finish test suite
finish_test_suite "Primary Authorship Integration Tests"