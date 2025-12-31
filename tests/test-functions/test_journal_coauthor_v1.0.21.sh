#!/usr/bin/env bash
# Integration test for User Story 2: Co-author Collaboration
# Tests the complete co-author functionality for journal organization

set -euo pipefail

# Source test harness
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/bootstrap_tests.sh"

# Test suite setup
start_test_suite "Co-author Collaboration Integration Tests"

# Test 1: Basic Co-author Project (Current Year Default)
echo
echo "Test 1: Basic Co-author Project (Current Year Default)"
echo "====================================================="

TEMP_WORKSPACE=$(create_temp_workspace "coauthor_basic_test")
cd "$TEMP_WORKSPACE"

assert_success "run_dirforge create journal --name 'collaborative_study' --coauthor" \
  "Create co-author project with current year"
  
assert_dir_exists "JOURNAL_WORLD/02_coauthor_invites/$(date +%Y)_collaborative_study" \
  "Co-author project directory"
  
assert_dir_exists "JOURNAL_WORLD/02_coauthor_invites/$(date +%Y)_collaborative_study/01_manuscript" \
  "Manuscript subdirectory"
  
assert_dir_exists "JOURNAL_WORLD/02_coauthor_invites/$(date +%Y)_collaborative_study/02_reviews" \
  "Reviews subdirectory"
  
assert_dir_exists "JOURNAL_WORLD/02_coauthor_invites/$(date +%Y)_collaborative_study/03_correspondence" \
  "Correspondence subdirectory"

# Verify role structure is created
assert_dir_exists "JOURNAL_WORLD/00_admin" "Admin role directory"
assert_dir_exists "JOURNAL_WORLD/01_primary_authorship" "Primary authorship role directory"
assert_dir_exists "JOURNAL_WORLD/02_coauthor_invites" "Coauthor role directory"
assert_dir_exists "JOURNAL_WORLD/03_journal_service" "Journal service role directory"

cleanup_temp_workspace

# Test 2: Co-author Project with Explicit Year
echo
echo "Test 2: Co-author Project with Explicit Year"
echo "============================================="

TEMP_WORKSPACE=$(create_temp_workspace "coauthor_year_test")
cd "$TEMP_WORKSPACE"

assert_success "run_dirforge create journal --name 'international_study' --coauthor --year 2023" \
  "Create co-author project with explicit year"
  
assert_dir_exists "JOURNAL_WORLD/02_coauthor_invites/2023_international_study" \
  "Project with explicit year"
  
assert_dir_exists "JOURNAL_WORLD/02_coauthor_invites/2023_international_study/01_manuscript" \
  "Manuscript subdirectory"
  
assert_dir_exists "JOURNAL_WORLD/02_coauthor_invites/2023_international_study/02_reviews" \
  "Reviews subdirectory"
  
assert_dir_exists "JOURNAL_WORLD/02_coauthor_invites/2023_international_study/03_correspondence" \
  "Correspondence subdirectory"

cleanup_temp_workspace

# Test 3: Paper Name with Embedded Year (Automatic Extraction)
echo
echo "Test 3: Paper Name with Embedded Year (Automatic Extraction)"
echo "============================================================"

TEMP_WORKSPACE=$(create_temp_workspace "coauthor_embedded_year_test")
cd "$TEMP_WORKSPACE"

assert_success "run_dirforge create journal --name '2021_elastic_properties_of_carbonates' --coauthor" \
  "Create co-author project with embedded year in name"
  
assert_dir_exists "JOURNAL_WORLD/02_coauthor_invites/2021_elastic_properties_of_carbonates" \
  "Project with extracted year"

cleanup_temp_workspace

# Test 4: Complex Paper Name Sanitization
echo
echo "Test 4: Complex Paper Name Sanitization"
echo "======================================="

TEMP_WORKSPACE=$(create_temp_workspace "coauthor_sanitization_test")
cd "$TEMP_WORKSPACE"

assert_success "run_dirforge create journal --name 'Machine Learning for Pore Pressure Analysis' --coauthor" \
  "Create co-author project with complex name requiring sanitization"
  
assert_dir_exists "JOURNAL_WORLD/02_coauthor_invites/$(date +%Y)_machine_learning_for_pore_pressure_analysis" \
  "Project with sanitized name"

cleanup_temp_workspace

# Test 5: Conflict Detection (Existing Directory)
echo
echo "Test 5: Conflict Detection (Existing Directory)"
echo "==============================================="

TEMP_WORKSPACE=$(create_temp_workspace "coauthor_conflict_test")
cd "$TEMP_WORKSPACE"

assert_success "run_dirforge create journal --name 'test_collaboration' --coauthor" \
  "Create first co-author project"

# Attempt to create the same project again should fail
assert_failure "run_dirforge create journal --name 'test_collaboration' --coauthor" \
  "Attempt to create duplicate co-author project should fail"

cleanup_temp_workspace

# Test 6: Dry Run Mode Validation
echo
echo "Test 6: Dry Run Mode Validation"
echo "==============================="

TEMP_WORKSPACE=$(create_temp_workspace "coauthor_dry_run_test")
cd "$TEMP_WORKSPACE"

# Test dry-run mode
output=$(run_dirforge --dry-run create journal --name 'test_coauthor_dry_run' --coauthor 2>&1)

# Check for dry-run indicators in output
if echo "$output" | grep -q "DRY RUN"; then
  echo "✓ Dry-run mode detected in output"
else
  echo "✗ FAIL: Dry-run mode not detected in output"
  FAILED_COUNT=$((FAILED_COUNT + 1))
fi

# Verify no directories are created in dry-run mode
assert_dir_not_exists "JOURNAL_WORLD" \
  "No directories should be created in dry-run mode"

cleanup_temp_workspace

# Test 7: Invalid Paper Name Validation
echo
echo "Test 7: Invalid Paper Name Validation"
echo "====================================="

TEMP_WORKSPACE=$(create_temp_workspace "coauthor_invalid_name_test")
cd "$TEMP_WORKSPACE"

assert_failure "run_dirforge create journal --name 'Invalid@Paper#Name!' --coauthor" \
  "Invalid paper name with special characters should fail"

cleanup_temp_workspace

# Test 8: Year Validation Edge Cases
echo
echo "Test 8: Year Validation Edge Cases"
echo "=================================="

TEMP_WORKSPACE=$(create_temp_workspace "coauthor_year_validation_test")
cd "$TEMP_WORKSPACE"

assert_failure "run_dirforge create journal --name 'test_paper' --coauthor --year 25" \
  "Invalid year format (2 digits) should fail"

assert_failure "run_dirforge create journal --name 'test_paper' --coauthor --year abcd" \
  "Invalid year format (letters) should fail"

assert_success "run_dirforge create journal --name 'historical_collaboration' --coauthor --year 2000" \
  "Valid historical year should succeed"

cleanup_temp_workspace

# Test 9: Missing Required Flags
echo
echo "Test 9: Missing Required Flags"
echo "=============================="

TEMP_WORKSPACE=$(create_temp_workspace "coauthor_missing_flags_test")
cd "$TEMP_WORKSPACE"

assert_failure "run_dirforge create journal --coauthor" \
  "Missing --name flag should fail"

assert_failure "run_dirforge create journal --name 'test_paper'" \
  "Missing role flag (--coauthor) should fail"

cleanup_temp_workspace

# Test 10: Mutual Exclusion with --first Flag
echo
echo "Test 10: Mutual Exclusion with --first Flag"
echo "==========================================="

TEMP_WORKSPACE=$(create_temp_workspace "coauthor_exclusion_test")
cd "$TEMP_WORKSPACE"

assert_failure "run_dirforge create journal --name 'test_paper' --coauthor --first" \
  "Combining --coauthor and --first flags should fail"

cleanup_temp_workspace

# Test 11: JOURNAL_WORLD Root Detection and Creation
echo
echo "Test 11: JOURNAL_WORLD Root Detection and Creation"
echo "=================================================="

TEMP_WORKSPACE=$(create_temp_workspace "coauthor_root_test")
cd "$TEMP_WORKSPACE"

# First co-author project should create JOURNAL_WORLD
assert_success "run_dirforge create journal --name 'first_collaboration' --coauthor" \
  "First co-author project creation should establish JOURNAL_WORLD"

assert_dir_exists "JOURNAL_WORLD" "JOURNAL_WORLD root directory"
assert_dir_exists "JOURNAL_WORLD/00_admin" "Admin role directory"
assert_dir_exists "JOURNAL_WORLD/01_primary_authorship" "Primary authorship role directory"
assert_dir_exists "JOURNAL_WORLD/02_coauthor_invites" "Coauthor role directory"
assert_dir_exists "JOURNAL_WORLD/03_journal_service" "Journal service role directory"

# Second co-author project should use existing JOURNAL_WORLD
assert_success "run_dirforge create journal --name 'second_collaboration' --coauthor" \
  "Second co-author project should use existing JOURNAL_WORLD"

cleanup_temp_workspace

# Test 12: Help System Integration
echo
echo "Test 12: Help System Integration"
echo "================================"

TEMP_WORKSPACE=$(create_temp_workspace "coauthor_help_test")
cd "$TEMP_WORKSPACE"

# Test journal help output
help_output=$(run_dirforge create journal --help 2>&1)

# Verify help contains co-author collaboration examples (case-insensitive)
if echo "$help_output" | grep -qi "Co-author collaboration\|co-author collaboration"; then
  echo "✓ Help contains Co-author Collaboration section"
  PASSED_COUNT=$((PASSED_COUNT + 1))
else
  echo "✗ FAIL: Help missing Co-author Collaboration section"
  FAILED_COUNT=$((FAILED_COUNT + 1))
fi
TEST_COUNT=$((TEST_COUNT + 1))

# Verify help contains command examples (case-insensitive)
if echo "$help_output" | grep -qi "dirforge create journal --name.*--coauthor"; then
  echo "✓ Help contains co-author collaboration command examples"
  PASSED_COUNT=$((PASSED_COUNT + 1))
else
  echo "✗ FAIL: Help missing co-author collaboration command examples"
  FAILED_COUNT=$((FAILED_COUNT + 1))
fi
TEST_COUNT=$((TEST_COUNT + 1))

cleanup_temp_workspace

# Test 13: Path Construction Utilities Validation
echo
echo "Test 13: Path Construction Utilities Validation"
echo "==============================================="

TEMP_WORKSPACE=$(create_temp_workspace "coauthor_path_test")
cd "$TEMP_WORKSPACE"

assert_success "run_dirforge create journal --name 'path_validation_study' --coauthor --year 2023" \
  "Create co-author project for path validation"

# Check path follows YYYY_paper_name pattern
if [ -d "JOURNAL_WORLD/02_coauthor_invites/2023_path_validation_study" ]; then
  echo "✓ Path construction follows YYYY_paper_name pattern"
  PASSED_COUNT=$((PASSED_COUNT + 1))
else
  echo "✗ FAIL: Path construction does not follow expected pattern"
  FAILED_COUNT=$((FAILED_COUNT + 1))
fi
TEST_COUNT=$((TEST_COUNT + 1))

# Verify all standard subdirectories
assert_dir_exists "JOURNAL_WORLD/02_coauthor_invites/2023_path_validation_study/01_manuscript" \
  "Standard subdirectory: 01_manuscript"

assert_dir_exists "JOURNAL_WORLD/02_coauthor_invites/2023_path_validation_study/02_reviews" \
  "Standard subdirectory: 02_reviews"

assert_dir_exists "JOURNAL_WORLD/02_coauthor_invites/2023_path_validation_study/03_correspondence" \
  "Standard subdirectory: 03_correspondence"

cleanup_temp_workspace

# Test 14: Year Extraction from Embedded Names
echo
echo "Test 14: Year Extraction from Embedded Names"
echo "============================================="

TEMP_WORKSPACE=$(create_temp_workspace "coauthor_year_extraction_test")
cd "$TEMP_WORKSPACE"

# Test various year extraction scenarios
assert_success "run_dirforge create journal --name '2019_historical_analysis' --coauthor" \
  "Year extraction: 2019 from paper name"

assert_dir_exists "JOURNAL_WORLD/02_coauthor_invites/2019_historical_analysis" \
  "2019 extracted correctly"

assert_success "run_dirforge create journal --name '2024_modern_methods' --coauthor" \
  "Year extraction: 2024 from paper name"

assert_dir_exists "JOURNAL_WORLD/02_coauthor_invites/2024_modern_methods" \
  "2024 extracted correctly"

cleanup_temp_workspace

# Test 15: Constitution Compliance Validation
echo
echo "Test 15: Constitution Compliance Validation"
echo "==========================================="

TEMP_WORKSPACE=$(create_temp_workspace "coauthor_constitution_test")
cd "$TEMP_WORKSPACE"

assert_success "run_dirforge create journal --name 'constitution_collaboration' --coauthor" \
  "Create co-author project for constitution validation"

# Check that exactly 3 subdirectories are created (constitutional compliance)
subdir_count=$(find "JOURNAL_WORLD/02_coauthor_invites/$(date +%Y)_constitution_collaboration" -mindepth 1 -maxdepth 1 -type d | wc -l)
if [ "$subdir_count" -eq 3 ]; then
  echo "✓ Exactly 3 subdirectories created (constitutional compliance)"
  PASSED_COUNT=$((PASSED_COUNT + 1))
else
  echo "✗ FAIL: Expected 3 subdirectories, got $subdir_count"
  FAILED_COUNT=$((FAILED_COUNT + 1))
fi
TEST_COUNT=$((TEST_COUNT + 1))

# Check that exactly 4 role directories exist in JOURNAL_WORLD (constitutional compliance)
role_count=$(find "JOURNAL_WORLD" -mindepth 1 -maxdepth 1 -type d | wc -l)
if [ "$role_count" -eq 4 ]; then
  echo "✓ Exactly 4 role directories in JOURNAL_WORLD (constitutional compliance)"
  PASSED_COUNT=$((PASSED_COUNT + 1))
else
  echo "✗ FAIL: Expected 4 role directories, got $role_count"
  FAILED_COUNT=$((FAILED_COUNT + 1))
fi
TEST_COUNT=$((TEST_COUNT + 1))

cleanup_temp_workspace

# Test 16: Error Message Validation
echo
echo "Test 16: Error Message Validation"
echo "================================="

TEMP_WORKSPACE=$(create_temp_workspace "coauthor_error_test")
cd "$TEMP_WORKSPACE"

# Test invalid paper name error message
error_output=$(run_dirforge create journal --name 'Invalid@Name!' --coauthor 2>&1 || true)
if echo "$error_output" | grep -q "Error: Paper name can only contain letters, numbers, spaces, hyphens, and underscores."; then
  echo "✓ Correct error message for invalid paper name"
  PASSED_COUNT=$((PASSED_COUNT + 1))
else
  echo "✗ FAIL: Incorrect or missing error message for invalid paper name"
  FAILED_COUNT=$((FAILED_COUNT + 1))
fi
TEST_COUNT=$((TEST_COUNT + 1))

# Test invalid year error message
error_output=$(run_dirforge create journal --name 'test_paper' --coauthor --year 99 2>&1 || true)
if echo "$error_output" | grep -q "Error: Year must be a 4-digit number (YYYY)"; then
  echo "✓ Correct error message for invalid year"
  PASSED_COUNT=$((PASSED_COUNT + 1))
else
  echo "✗ FAIL: Incorrect or missing error message for invalid year"
  FAILED_COUNT=$((FAILED_COUNT + 1))
fi
TEST_COUNT=$((TEST_COUNT + 1))

cleanup_temp_workspace

# Test Summary
echo
echo "==============================================================================="
echo "Co-author Collaboration Integration Test Summary"
echo "==============================================================================="

finish_test_suite "Co-author Collaboration Integration Tests"