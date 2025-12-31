#!/usr/bin/env bash
# Integration test for User Story 3: Journal Service
# Tests the complete journal service functionality for reviews and editorial work

set -euo pipefail

# Source test harness
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/bootstrap_tests.sh"

# Test suite setup
start_test_suite "Journal Service Integration Tests"

# Test 1: Basic Journal Service Project
echo
echo "Test 1: Basic Journal Service Project"
echo "====================================="

TEMP_WORKSPACE=$(create_temp_workspace "journal_service_basic_test")
cd "$TEMP_WORKSPACE"

assert_success "run_dirforge create journal --name 'Geophysics' --id 'GEO-2025-0451' --service" \
  "Create journal service project"
  
assert_dir_exists "JOURNAL_WORLD/03_journal_service/geophysics/GEO-2025-0451" \
  "Journal service project directory"
  
assert_dir_exists "JOURNAL_WORLD/03_journal_service/geophysics/GEO-2025-0451/01_manuscript" \
  "Manuscript subdirectory"
  
assert_dir_exists "JOURNAL_WORLD/03_journal_service/geophysics/GEO-2025-0451/02_reviews" \
  "Reviews subdirectory"
  
assert_dir_exists "JOURNAL_WORLD/03_journal_service/geophysics/GEO-2025-0451/03_correspondence" \
  "Correspondence subdirectory"

# Verify role structure is created
assert_dir_exists "JOURNAL_WORLD/00_admin" "Admin role directory"
assert_dir_exists "JOURNAL_WORLD/01_primary_authorship" "Primary authorship role directory"
assert_dir_exists "JOURNAL_WORLD/02_coauthor_invites" "Coauthor role directory"
assert_dir_exists "JOURNAL_WORLD/03_journal_service" "Journal service role directory"

cleanup_temp_workspace

# Test 2: Complex Journal Name Processing
echo
echo "Test 2: Complex Journal Name Processing"
echo "======================================"

TEMP_WORKSPACE=$(create_temp_workspace "journal_service_complex_test")
cd "$TEMP_WORKSPACE"

assert_success "run_dirforge create journal --name 'Nature Geoscience' --id 'NG-2024-12345' --service" \
  "Create project with complex journal name"
  
assert_dir_exists "JOURNAL_WORLD/03_journal_service/nature_geoscience/NG-2024-12345" \
  "Complex journal name converted to lowercase with underscores"
  
assert_dir_exists "JOURNAL_WORLD/03_journal_service/nature_geoscience/NG-2024-12345/01_manuscript" \
  "Manuscript subdirectory"

cleanup_temp_workspace

# Test 3: Special Characters in Journal Name
echo
echo "Test 3: Special Characters in Journal Name"
echo "=========================================="

TEMP_WORKSPACE=$(create_temp_workspace "journal_service_special_chars_test")
cd "$TEMP_WORKSPACE"

assert_success "run_dirforge create journal --name 'IEEE Trans. Geoscience & Remote Sensing' --id 'TGRS-2025-0789' --service" \
  "Create project with special characters in journal name"
  
assert_dir_exists "JOURNAL_WORLD/03_journal_service/ieee_trans_geoscience_remote_sensing/TGRS-2025-0789" \
  "Special characters converted to underscores"

cleanup_temp_workspace

# Test 4: Multiple Projects in Same Journal
echo
echo "Test 4: Multiple Projects in Same Journal"
echo "========================================="

TEMP_WORKSPACE=$(create_temp_workspace "journal_service_multiple_test")
cd "$TEMP_WORKSPACE"

assert_success "run_dirforge create journal --name 'Geophysics' --id 'GEO-2025-0451' --service" \
  "Create first project in journal"
  
assert_success "run_dirforge create journal --name 'Geophysics' --id 'GEO-2024-1234' --service" \
  "Create second project in same journal"
  
assert_dir_exists "JOURNAL_WORLD/03_journal_service/geophysics/GEO-2025-0451" \
  "First project exists"
  
assert_dir_exists "JOURNAL_WORLD/03_journal_service/geophysics/GEO-2024-1234" \
  "Second project exists"

cleanup_temp_workspace

# Test 5: Conflict Detection (Existing Directory)
echo
echo "Test 5: Conflict Detection (Existing Directory)"
echo "==============================================="

TEMP_WORKSPACE=$(create_temp_workspace "journal_service_conflict_test")
cd "$TEMP_WORKSPACE"

assert_success "run_dirforge create journal --name 'Test Journal' --id 'TEST-123' --service" \
  "Create first journal service project"

# Attempt to create the same project again should fail
assert_failure "run_dirforge create journal --name 'Test Journal' --id 'TEST-123' --service" \
  "Attempt to create duplicate journal service project should fail"

cleanup_temp_workspace

# Test 6: Dry Run Mode Validation
echo
echo "Test 6: Dry Run Mode Validation"
echo "==============================="

TEMP_WORKSPACE=$(create_temp_workspace "journal_service_dry_run_test")
cd "$TEMP_WORKSPACE"

# Test dry-run mode
output=$(run_dirforge --dry-run create journal --name 'Test Journal' --id 'DRY-RUN-123' --service 2>&1)

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

# Test 7: Journal Name Validation
echo
echo "Test 7: Journal Name Validation"
echo "==============================="

TEMP_WORKSPACE=$(create_temp_workspace "journal_service_journal_validation_test")
cd "$TEMP_WORKSPACE"

assert_failure "run_dirforge create journal --name '' --id 'TEST-123' --service" \
  "Empty journal name should fail"

cleanup_temp_workspace

# Test 8: Manuscript ID Validation
echo
echo "Test 8: Manuscript ID Validation"
echo "================================"

TEMP_WORKSPACE=$(create_temp_workspace "journal_service_id_validation_test")
cd "$TEMP_WORKSPACE"

assert_failure "run_dirforge create journal --name 'Test Journal' --id '' --service" \
  "Empty manuscript ID should fail"

assert_failure "run_dirforge create journal --name 'Test Journal' --id 'INVALID@ID#' --service" \
  "Invalid characters in manuscript ID should fail"

assert_success "run_dirforge create journal --name 'Test Journal' --id 'VALID-ID_123.v2' --service" \
  "Valid manuscript ID with dots, hyphens, and underscores should succeed"

cleanup_temp_workspace

# Test 9: Missing Required Flags
echo
echo "Test 9: Missing Required Flags"
echo "=============================="

TEMP_WORKSPACE=$(create_temp_workspace "journal_service_missing_flags_test")
cd "$TEMP_WORKSPACE"

assert_failure "run_dirforge create journal --name 'Test Journal'" \
  "Missing --id flag should fail"

assert_failure "run_dirforge create journal --id 'TEST-123' --service" \
  "Missing --name flag should fail"

cleanup_temp_workspace

# Test 10: Mutual Exclusion with Other Flags
echo
echo "Test 10: Mutual Exclusion with Other Flags"
echo "=========================================="

TEMP_WORKSPACE=$(create_temp_workspace "journal_service_exclusion_test")
cd "$TEMP_WORKSPACE"

assert_failure "run_dirforge create journal --name 'Test Journal' --id 'TEST-123' --service --first" \
  "Combining --service with --first should fail"

cleanup_temp_workspace

# Test 11: JOURNAL_WORLD Root Detection and Creation
echo
echo "Test 11: JOURNAL_WORLD Root Detection and Creation"
echo "=================================================="

TEMP_WORKSPACE=$(create_temp_workspace "journal_service_root_test")
cd "$TEMP_WORKSPACE"

# First journal service project should create JOURNAL_WORLD
assert_success "run_dirforge create journal --name 'First Journal' --id 'FIRST-123' --service" \
  "First journal service project creation should establish JOURNAL_WORLD"

assert_dir_exists "JOURNAL_WORLD" "JOURNAL_WORLD root directory"
assert_dir_exists "JOURNAL_WORLD/00_admin" "Admin role directory"
assert_dir_exists "JOURNAL_WORLD/01_primary_authorship" "Primary authorship role directory"
assert_dir_exists "JOURNAL_WORLD/02_coauthor_invites" "Coauthor role directory"
assert_dir_exists "JOURNAL_WORLD/03_journal_service" "Journal service role directory"

# Second journal service project should use existing JOURNAL_WORLD
assert_success "run_dirforge create journal --name 'Second Journal' --id 'SECOND-456' --service" \
  "Second journal service project should use existing JOURNAL_WORLD"

cleanup_temp_workspace

# Test 12: Help System Integration
echo
echo "Test 12: Help System Integration"
echo "================================"

TEMP_WORKSPACE=$(create_temp_workspace "journal_service_help_test")
cd "$TEMP_WORKSPACE"

# Test journal help output
help_output=$(run_dirforge create journal --help 2>&1)

# Verify help contains journal service examples (case-insensitive)
if echo "$help_output" | grep -qi "Journal service\|journal service"; then
  echo "✓ Help contains Journal Service section"
  PASSED_COUNT=$((PASSED_COUNT + 1))
else
  echo "✗ FAIL: Help missing Journal Service section"
  FAILED_COUNT=$((FAILED_COUNT + 1))
fi
TEST_COUNT=$((TEST_COUNT + 1))

# Verify help contains command examples (case-insensitive)
if echo "$help_output" | grep -qi "dirforge create journal --name.*--id"; then
  echo "✓ Help contains journal service command examples"
  PASSED_COUNT=$((PASSED_COUNT + 1))
else
  echo "✗ FAIL: Help missing journal service command examples"
  FAILED_COUNT=$((FAILED_COUNT + 1))
fi
TEST_COUNT=$((TEST_COUNT + 1))

cleanup_temp_workspace

# Test 13: Path Construction Validation
echo
echo "Test 13: Path Construction Validation"
echo "====================================="

TEMP_WORKSPACE=$(create_temp_workspace "journal_service_path_test")
cd "$TEMP_WORKSPACE"

assert_success "run_dirforge create journal --name 'Path Test Journal' --id 'PATH-TEST-123' --service" \
  "Create journal service project for path validation"

# Check path follows journal_name/MANUSCRIPT_ID pattern
if [ -d "JOURNAL_WORLD/03_journal_service/path_test_journal/PATH-TEST-123" ]; then
  echo "✓ Path construction follows journal_name/MANUSCRIPT_ID pattern"
  PASSED_COUNT=$((PASSED_COUNT + 1))
else
  echo "✗ FAIL: Path construction does not follow expected pattern"
  FAILED_COUNT=$((FAILED_COUNT + 1))
fi
TEST_COUNT=$((TEST_COUNT + 1))

# Verify all standard subdirectories
assert_dir_exists "JOURNAL_WORLD/03_journal_service/path_test_journal/PATH-TEST-123/01_manuscript" \
  "Standard subdirectory: 01_manuscript"

assert_dir_exists "JOURNAL_WORLD/03_journal_service/path_test_journal/PATH-TEST-123/02_reviews" \
  "Standard subdirectory: 02_reviews"

assert_dir_exists "JOURNAL_WORLD/03_journal_service/path_test_journal/PATH-TEST-123/03_correspondence" \
  "Standard subdirectory: 03_correspondence"

cleanup_temp_workspace

# Test 14: Journal Name Sanitization Edge Cases
echo
echo "Test 14: Journal Name Sanitization Edge Cases"
echo "============================================="

TEMP_WORKSPACE=$(create_temp_workspace "journal_service_sanitization_test")
cd "$TEMP_WORKSPACE"

# Test various journal name sanitization scenarios
assert_success "run_dirforge create journal --name 'IEEE Trans. on Signal Processing' --id 'TSP-2025-01' --service" \
  "Journal name with periods and 'on'"

assert_dir_exists "JOURNAL_WORLD/03_journal_service/ieee_trans_on_signal_processing/TSP-2025-01" \
  "Complex journal name sanitized correctly"

assert_success "run_dirforge create journal --name 'Nature/Science/Technology' --id 'NST-2025-01' --service" \
  "Journal name with slashes"

assert_dir_exists "JOURNAL_WORLD/03_journal_service/nature_science_technology/NST-2025-01" \
  "Journal name with slashes sanitized"

cleanup_temp_workspace

# Test 15: Constitution Compliance Validation
echo
echo "Test 15: Constitution Compliance Validation"
echo "==========================================="

TEMP_WORKSPACE=$(create_temp_workspace "journal_service_constitution_test")
cd "$TEMP_WORKSPACE"

assert_success "run_dirforge create journal --name 'Constitution Journal' --id 'CONST-123' --service" \
  "Create journal service project for constitution validation"

# Check that exactly 3 subdirectories are created (constitutional compliance)
subdir_count=$(find "JOURNAL_WORLD/03_journal_service/constitution_journal/CONST-123" -mindepth 1 -maxdepth 1 -type d | wc -l)
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

TEMP_WORKSPACE=$(create_temp_workspace "journal_service_error_test")
cd "$TEMP_WORKSPACE"

# Test invalid manuscript ID error message
error_output=$(run_dirforge create journal --name 'Test Journal' --id 'INVALID@ID!' --service 2>&1 || true)
if echo "$error_output" | grep -q "Error: Manuscript ID can only contain letters, numbers, dots, hyphens, and underscores."; then
  echo "✓ Correct error message for invalid manuscript ID"
  PASSED_COUNT=$((PASSED_COUNT + 1))
else
  echo "✗ FAIL: Incorrect or missing error message for invalid manuscript ID"
  FAILED_COUNT=$((FAILED_COUNT + 1))
fi
TEST_COUNT=$((TEST_COUNT + 1))

# Test empty journal name error message
error_output=$(run_dirforge create journal --name '' --id 'TEST-123' --service 2>&1 || true)
if echo "$error_output" | grep -q "Error: --name requires a value (paper name or journal name)"; then
  echo "✓ Correct error message for empty journal name"
  PASSED_COUNT=$((PASSED_COUNT + 1))
else
  echo "✗ FAIL: Incorrect or missing error message for empty journal name"
  FAILED_COUNT=$((FAILED_COUNT + 1))
fi
TEST_COUNT=$((TEST_COUNT + 1))

cleanup_temp_workspace

# Test 17: Two-Level Directory Structure Validation
echo
echo "Test 17: Two-Level Directory Structure Validation"
echo "================================================="

TEMP_WORKSPACE=$(create_temp_workspace "journal_service_two_level_test")
cd "$TEMP_WORKSPACE"

# Create multiple projects to test two-level structure
assert_success "run_dirforge create journal --name 'Journal A' --id 'A-001' --service" \
  "Create first project in Journal A"

assert_success "run_dirforge create journal --name 'Journal A' --id 'A-002' --service" \
  "Create second project in Journal A"

assert_success "run_dirforge create journal --name 'Journal B' --id 'B-001' --service" \
  "Create project in Journal B"

# Verify two-level structure is maintained
assert_dir_exists "JOURNAL_WORLD/03_journal_service/journal_a" \
  "First-level journal directory A"

assert_dir_exists "JOURNAL_WORLD/03_journal_service/journal_b" \
  "First-level journal directory B"

assert_dir_exists "JOURNAL_WORLD/03_journal_service/journal_a/A-001" \
  "Second-level manuscript directory A-001"

assert_dir_exists "JOURNAL_WORLD/03_journal_service/journal_a/A-002" \
  "Second-level manuscript directory A-002"

assert_dir_exists "JOURNAL_WORLD/03_journal_service/journal_b/B-001" \
  "Second-level manuscript directory B-001"

# Count directories in each journal to ensure proper organization
journal_a_count=$(find "JOURNAL_WORLD/03_journal_service/journal_a" -mindepth 1 -maxdepth 1 -type d | wc -l)
if [ "$journal_a_count" -eq 2 ]; then
  echo "✓ Journal A contains exactly 2 manuscript directories"
  PASSED_COUNT=$((PASSED_COUNT + 1))
else
  echo "✗ FAIL: Journal A expected 2 directories, got $journal_a_count"
  FAILED_COUNT=$((FAILED_COUNT + 1))
fi
TEST_COUNT=$((TEST_COUNT + 1))

cleanup_temp_workspace

# Test Summary
echo
echo "==============================================================================="
echo "Journal Service Integration Test Summary"
echo "==============================================================================="

finish_test_suite "Journal Service Integration Tests"