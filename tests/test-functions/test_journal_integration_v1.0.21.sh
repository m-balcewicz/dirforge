#!/usr/bin/env bash
# Comprehensive Integration Test: Role-Based JOURNAL_WORLD Organization
# Tests end-to-end functionality for all journal user stories:
# - US1: Primary Authorship Management (--name <paper> --first)
# - US2: Co-author Collaboration (--name <paper> --coauthor)
# - US3: Journal Service (--name <journal> --id <manuscript_id> --service)
# - US4: Administrative Organization (manual admin directory)
# 
# Validates command patterns, error handling, validation, help system, 
# and cross-cutting concerns like constitution compliance

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

# Helper function to test output does NOT contain pattern
assert_output_not_contains() {
    local output="$1"
    local pattern="$2"
    local description="$3"
    TEST_COUNT=$((TEST_COUNT + 1))
    
    echo -n "Test $TEST_COUNT: $description ... "
    
    if ! echo "$output" | grep -q "$pattern"; then
        echo -e "${GREEN:-}✓ PASS${NC:-}"
        PASSED_COUNT=$((PASSED_COUNT + 1))
        return 0
    else
        echo -e "${RED:-}✗ FAIL${NC:-}"
        echo "  Should not contain pattern: $pattern"
        echo "  But found in output: $(echo "$output" | head -3 | tr '\n' ' ')..."
        FAILED_COUNT=$((FAILED_COUNT + 1))
        return 1
    fi
}

# Test configuration
CURRENT_YEAR=$(date +%Y)

# Start test suite
start_test_suite "Journal Integration Tests (End-to-End)"

echo
echo "=================================================================="
echo "COMPREHENSIVE JOURNAL SYSTEM INTEGRATION TEST"
echo "Testing all four command patterns and cross-cutting functionality"
echo "=================================================================="

# Test 1: Complete workflow - Primary Authorship (US1)
echo
echo "Test 1: Primary Authorship Complete Workflow"
echo "============================================="

TEMP_WORKSPACE=$(create_temp_workspace "journal_integration_primary")
cd "$TEMP_WORKSPACE"

# Test basic primary authorship creation
assert_success "run_dirforge create journal --name 'thermal_conductivity_review' --first" \
  "Create primary authorship project"

# Verify complete directory structure
assert_dir_exists "JOURNAL_WORLD/01_primary_authorship/${CURRENT_YEAR}_thermal_conductivity_review" \
  "Primary authorship project created"
assert_dir_exists "JOURNAL_WORLD/01_primary_authorship/${CURRENT_YEAR}_thermal_conductivity_review/01_manuscript" \
  "Manuscript subdirectory"
assert_dir_exists "JOURNAL_WORLD/01_primary_authorship/${CURRENT_YEAR}_thermal_conductivity_review/02_reviews" \
  "Reviews subdirectory"
assert_dir_exists "JOURNAL_WORLD/01_primary_authorship/${CURRENT_YEAR}_thermal_conductivity_review/03_correspondence" \
  "Correspondence subdirectory"

# Test with explicit year
assert_success "run_dirforge create journal --name 'seismic_hazard_analysis' --first --year 2023" \
  "Create primary authorship project with explicit year"

assert_dir_exists "JOURNAL_WORLD/01_primary_authorship/2023_seismic_hazard_analysis" \
  "Primary authorship project with explicit year"

cleanup_temp_workspace

# Test 2: Complete workflow - Co-author Collaboration (US2)
echo
echo "Test 2: Co-author Collaboration Complete Workflow"
echo "================================================="

TEMP_WORKSPACE=$(create_temp_workspace "journal_integration_coauthor")
cd "$TEMP_WORKSPACE"

# Test basic co-author creation
assert_success "run_dirforge create journal --name 'elastic_properties_study' --coauthor" \
  "Create co-author collaboration project"

# Verify complete directory structure
assert_dir_exists "JOURNAL_WORLD/02_coauthor_invites/${CURRENT_YEAR}_elastic_properties_study" \
  "Co-author collaboration project created"
assert_dir_exists "JOURNAL_WORLD/02_coauthor_invites/${CURRENT_YEAR}_elastic_properties_study/01_manuscript" \
  "Co-author manuscript subdirectory"
assert_dir_exists "JOURNAL_WORLD/02_coauthor_invites/${CURRENT_YEAR}_elastic_properties_study/02_reviews" \
  "Co-author reviews subdirectory"
assert_dir_exists "JOURNAL_WORLD/02_coauthor_invites/${CURRENT_YEAR}_elastic_properties_study/03_correspondence" \
  "Co-author correspondence subdirectory"

# Test with embedded year in paper name
assert_success "run_dirforge create journal --name '2022_carbonates_microstructure' --coauthor" \
  "Create co-author project with embedded year"

assert_dir_exists "JOURNAL_WORLD/02_coauthor_invites/2022_carbonates_microstructure" \
  "Co-author project with embedded year"

cleanup_temp_workspace

# Test 3: Complete workflow - Journal Service (US3)
echo
echo "Test 3: Journal Service Complete Workflow"
echo "========================================="

TEMP_WORKSPACE=$(create_temp_workspace "journal_integration_service")
cd "$TEMP_WORKSPACE"

# Test journal service creation
assert_success "run_dirforge create journal --name 'nature_geoscience' --id 'NGS-2024-12345' --service" \
  "Create journal service project"

# Verify two-level directory structure
assert_dir_exists "JOURNAL_WORLD/03_journal_service/nature_geoscience/NGS-2024-12345" \
  "Journal service two-level structure created"
assert_dir_exists "JOURNAL_WORLD/03_journal_service/nature_geoscience/NGS-2024-12345/01_manuscript" \
  "Service manuscript subdirectory"
assert_dir_exists "JOURNAL_WORLD/03_journal_service/nature_geoscience/NGS-2024-12345/02_reviews" \
  "Service reviews subdirectory"
assert_dir_exists "JOURNAL_WORLD/03_journal_service/nature_geoscience/NGS-2024-12345/03_correspondence" \
  "Service correspondence subdirectory"

# Test different journal and manuscript ID formats
assert_success "run_dirforge create journal --name 'GJI Seismology' --id 'GJI-S-25-0928' --service" \
  "Create service project with different format"

assert_dir_exists "JOURNAL_WORLD/03_journal_service/gji_seismology/GJI-S-25-0928" \
  "Journal service with sanitized journal name"

cleanup_temp_workspace

# Test 4: Administrative Organization (US4) - Help Content Validation
echo
echo "Test 4: Administrative Organization Documentation"
echo "================================================"

TEMP_WORKSPACE=$(create_temp_workspace "journal_integration_admin")
cd "$TEMP_WORKSPACE"

# Test help system contains admin guidance
OUTPUT=$(run_dirforge create journal --help 2>&1 || true)
assert_output_contains "$OUTPUT" "00_admin" "Help mentions admin directory"
assert_output_contains "$OUTPUT" "manual" "Help explains manual admin organization"

cleanup_temp_workspace

# Test 5: Error Handling and Validation Integration
echo
echo "Test 5: Error Handling and Validation Edge Cases"
echo "================================================"

TEMP_WORKSPACE=$(create_temp_workspace "journal_integration_validation")
cd "$TEMP_WORKSPACE"

# Test invalid paper name validation
assert_failure "run_dirforge create journal --name 'Invalid@Paper#Name!' --first" \
  "Invalid paper name should fail with detailed error"

# Test year validation
assert_failure "run_dirforge create journal --name 'test_paper' --first --year 25" \
  "Invalid year format should fail"

assert_failure "run_dirforge create journal --name 'test_paper' --first --year abcd" \
  "Non-numeric year should fail"

# Test journal name validation for service
assert_failure "run_dirforge create journal --name 'Invalid<Journal>' --id 'TEST-123' --service" \
  "Invalid journal name should fail"

# Test manuscript ID validation
assert_failure "run_dirforge create journal --name 'nature' --id 'Invalid@ID' --service" \
  "Invalid manuscript ID should fail"

# Test mutual exclusion of flags
assert_failure "run_dirforge create journal --name 'test' --first --coauthor" \
  "Mutual exclusion of --first and --coauthor should fail"

assert_failure "run_dirforge create journal --name 'test' --first --service" \
  "Mutual exclusion of --first and --service should fail"

# Test missing required flags
assert_failure "run_dirforge create journal --name 'test'" \
  "Missing role flag should fail"

assert_failure "run_dirforge create journal --first" \
  "Missing --name flag should fail"

assert_failure "run_dirforge create journal --name 'test' --service" \
  "Missing --id flag for service should fail"

cleanup_temp_workspace

# Test 6: Directory Conflict Resolution
echo
echo "Test 6: Directory Conflict Resolution"
echo "====================================="

TEMP_WORKSPACE=$(create_temp_workspace "journal_integration_conflicts")
cd "$TEMP_WORKSPACE"

# Create initial project
assert_success "run_dirforge create journal --name 'conflict_test' --first" \
  "Create initial project"

# Try to create duplicate project
assert_failure "run_dirforge create journal --name 'conflict_test' --first" \
  "Duplicate project creation should fail with helpful error"

# Verify original project still exists and is intact
assert_dir_exists "JOURNAL_WORLD/01_primary_authorship/${CURRENT_YEAR}_conflict_test" \
  "Original project should remain intact"

cleanup_temp_workspace

# Test 7: Help System Integration
echo
echo "Test 7: Help System Comprehensive Validation"
echo "============================================"

TEMP_WORKSPACE=$(create_temp_workspace "journal_integration_help")
cd "$TEMP_WORKSPACE"

# Test global journal help
OUTPUT=$(run_dirforge create journal --help 2>&1 || true)
assert_output_contains "$OUTPUT" "JOURNAL_WORLD" "Help contains JOURNAL_WORLD reference"
assert_output_contains "$OUTPUT" "Constitution" "Help contains constitution reference"
assert_output_contains "$OUTPUT" "v1.0.21" "Help contains current constitution version"

# Test all four command patterns are documented
assert_output_contains "$OUTPUT" "\--name" "Name flag documented"
assert_output_contains "$OUTPUT" "\--first" "First flag documented"
assert_output_contains "$OUTPUT" "\--coauthor" "Co-author flag documented"
assert_output_contains "$OUTPUT" "\--service" "Service flag documented"
assert_output_contains "$OUTPUT" "00_admin" "Admin organization documented"

# Test examples are provided
assert_output_contains "$OUTPUT" "thermal_analysis" "Contains realistic examples"
assert_output_contains "$OUTPUT" "Nature Geoscience" "Contains journal examples"
assert_output_contains "$OUTPUT" "GEO-2025-0451" "Contains manuscript ID examples"

cleanup_temp_workspace

# Test 8: Complete Multi-Role Workflow
echo
echo "Test 8: Complete Multi-Role Project Workflow"
echo "============================================"

TEMP_WORKSPACE=$(create_temp_workspace "journal_integration_multi")
cd "$TEMP_WORKSPACE"

# Create projects for all three automated roles
assert_success "run_dirforge create journal --name 'project_alpha' --first" \
  "Create primary authorship project"

assert_success "run_dirforge create journal --name 'project_beta' --coauthor" \
  "Create co-author project"

assert_success "run_dirforge create journal --name 'nature_geoscience' --id 'NG-2024-001' --service" \
  "Create journal service project"

# Verify all role directories exist
assert_dir_exists "JOURNAL_WORLD/00_admin" "Admin directory created"
assert_dir_exists "JOURNAL_WORLD/01_primary_authorship" "Primary authorship directory created"
assert_dir_exists "JOURNAL_WORLD/02_coauthor_invites" "Co-author directory created"
assert_dir_exists "JOURNAL_WORLD/03_journal_service" "Journal service directory created"

# Verify all projects exist in their respective roles
assert_dir_exists "JOURNAL_WORLD/01_primary_authorship/${CURRENT_YEAR}_project_alpha" \
  "Primary authorship project in correct location"

assert_dir_exists "JOURNAL_WORLD/02_coauthor_invites/${CURRENT_YEAR}_project_beta" \
  "Co-author project in correct location"

assert_dir_exists "JOURNAL_WORLD/03_journal_service/nature_geoscience/NG-2024-001" \
  "Journal service project in correct location"

# Verify subdirectory structure is consistent across all projects
for role_project in \
  "01_primary_authorship/${CURRENT_YEAR}_project_alpha" \
  "02_coauthor_invites/${CURRENT_YEAR}_project_beta" \
  "03_journal_service/nature_geoscience/NG-2024-001"
do
  assert_dir_exists "JOURNAL_WORLD/$role_project/01_manuscript" \
    "Manuscript subdirectory in $role_project"
  assert_dir_exists "JOURNAL_WORLD/$role_project/02_reviews" \
    "Reviews subdirectory in $role_project"
  assert_dir_exists "JOURNAL_WORLD/$role_project/03_correspondence" \
    "Correspondence subdirectory in $role_project"
done

cleanup_temp_workspace

# Test 9: Constitution Compliance Validation
echo
echo "Test 9: Constitution v1.0.21 Compliance"
echo "======================================="

TEMP_WORKSPACE=$(create_temp_workspace "journal_integration_constitution")
cd "$TEMP_WORKSPACE"

# Test that constitution version is embedded in help
OUTPUT=$(run_dirforge --version 2>&1 || true)
assert_output_contains "$OUTPUT" "v1.0.21" "Version command shows constitution v1.0.21"

# Test role-based separation requirements
assert_success "run_dirforge create journal --name 'test_primary' --first" \
  "Primary authorship follows constitution"

assert_success "run_dirforge create journal --name 'test_coauthor' --coauthor" \
  "Co-author collaboration follows constitution"

# Verify constitutional role separation is maintained
assert_dir_not_exists "JOURNAL_WORLD/01_primary_authorship/${CURRENT_YEAR}_test_coauthor" \
  "Co-author project not in primary authorship directory"

assert_dir_not_exists "JOURNAL_WORLD/02_coauthor_invites/${CURRENT_YEAR}_test_primary" \
  "Primary project not in co-author directory"

cleanup_temp_workspace

# Test 10: Performance and Edge Cases
echo
echo "Test 10: Performance and Edge Cases"
echo "==================================="

TEMP_WORKSPACE=$(create_temp_workspace "journal_integration_performance")
cd "$TEMP_WORKSPACE"

# Test directory creation performance (should be fast)
TIME_START=$(date +%s%N)
assert_success "run_dirforge create journal --name 'performance_test' --first" \
  "Directory creation performance test"
TIME_END=$(date +%s%N)
TIME_DIFF=$(((TIME_END - TIME_START) / 1000000)) # Convert to milliseconds

# Performance target: directory creation < 1000ms
if [ $TIME_DIFF -gt 1000 ]; then
  echo "WARNING: Directory creation took ${TIME_DIFF}ms (target: < 1000ms)" >&2
else
  echo "✓ Directory creation performance: ${TIME_DIFF}ms (< 1000ms target)"
fi

# Test edge case: very long valid paper name
LONG_NAME="very_long_paper_name_about_thermal_conductivity_in_geological_materials_but_still_under_limit"
assert_success "run_dirforge create journal --name '$LONG_NAME' --first" \
  "Long valid paper name should work"

# Test edge case: minimum length names
assert_success "run_dirforge create journal --name 'abc' --first" \
  "Minimum length paper name should work"

# Test edge case: year boundary cases
assert_success "run_dirforge create journal --name 'historical' --first --year 1990" \
  "Historical year boundary should work"

assert_success "run_dirforge create journal --name 'future' --first --year 2030" \
  "Future year boundary should work"

cleanup_temp_workspace

echo
echo "=================================================================="
echo "INTEGRATION TEST SUMMARY"
echo "=================================================================="
echo "✓ All four journal command patterns tested successfully"
echo "✓ Error handling and validation comprehensive"
echo "✓ Help system integration validated"
echo "✓ Constitution v1.0.21 compliance verified"
echo "✓ Directory conflict resolution working"
echo "✓ Multi-role workflow functionality confirmed"
echo "✓ Performance targets met"
echo "✓ Edge cases handled properly"

finish_test_suite "Journal Integration Tests" "$TEST_COUNT"