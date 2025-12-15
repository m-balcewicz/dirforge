#!/usr/bin/env bash
# Test script for migration logic functionality (developed in v1.0.21)
# Tests lib/migrate.sh functions for additive migrations across world types
set -euo pipefail

# Test configuration
TEST_NAME="Migration Logic Tests (v1.0.21)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIRFORGE="$SCRIPT_DIR/../../tools/dirforge"
LIB_DIR="$SCRIPT_DIR/../../lib"
TEST_ROOT="/tmp/dirforge_migration_test_$$"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test state tracking
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

# Cleanup function
cleanup() {
    rm -rf "$TEST_ROOT" 2>/dev/null || true
}

trap cleanup EXIT

# Test utilities
test_start() {
    ((TESTS_TOTAL++))
    echo -e "${BLUE}Test $TESTS_TOTAL: $1${NC}"
}

test_pass() {
    ((TESTS_PASSED++))
    echo -e "  ${GREEN}✓ PASS${NC}"
}

test_fail() {
    ((TESTS_FAILED++))
    echo -e "  ${RED}✗ FAIL: $1${NC}"
}

# Source migration functions
source_migration() {
    source "$LIB_DIR/migrate.sh"
}

# Test JOURNAL_WORLD 1.0.20 → 1.0.21 migration
test_journal_migration() {
    echo -e "\n${YELLOW}=== JOURNAL_WORLD Migration Tests ===${NC}"
    
    mkdir -p "$TEST_ROOT/journal_test"
    cd "$TEST_ROOT/journal_test"
    
    # Test migration creates role directories
    test_start "JOURNAL_WORLD 1.0.20 → 1.0.21 creates role directories"
    source_migration
    changes=$(migrate_additive . "JOURNAL_WORLD" "1.0.20" "1.0.21" 0)
    if echo "$changes" | grep -q "ADD 00_admin/" && 
       echo "$changes" | grep -q "ADD 01_primary_authorship/" &&
       echo "$changes" | grep -q "ADD 02_coauthor_invites/" &&
       echo "$changes" | grep -q "ADD 03_journal_service/"; then
        test_pass
    else
        test_fail "Expected role directories not created: $changes"
    fi
    
    # Test actual directory creation
    test_start "JOURNAL_WORLD migration creates actual directories"
    rm -rf * 2>/dev/null || true
    source_migration
    migrate_additive . "JOURNAL_WORLD" "1.0.20" "1.0.21" 0 >/dev/null
    if [[ -d "00_admin" && -d "01_primary_authorship" && -d "02_coauthor_invites" && -d "03_journal_service" ]]; then
        test_pass
    else
        test_fail "Physical directories not created"
    fi
}

# Test RESEARCH_WORLD 1.0.16 → 1.0.17 migration
test_research_migration() {
    echo -e "\n${YELLOW}=== RESEARCH_WORLD Migration Tests ===${NC}"
    
    mkdir -p "$TEST_ROOT/research_test"
    cd "$TEST_ROOT/research_test"
    
    # Test migration creates studies directory
    test_start "RESEARCH_WORLD 1.0.16 → 1.0.17 creates studies directory"
    source_migration
    changes=$(migrate_additive . "RESEARCH_WORLD" "1.0.16" "1.0.17" 0)
    if echo "$changes" | grep -q "ADD 02_studies/"; then
        test_pass
    else
        test_fail "Expected studies directory not created: $changes"
    fi
    
    # Test actual directory creation
    test_start "RESEARCH_WORLD migration creates actual directory"
    rm -rf * 2>/dev/null || true
    source_migration
    migrate_additive . "RESEARCH_WORLD" "1.0.16" "1.0.17" 0 >/dev/null
    if [[ -d "02_studies" ]]; then
        test_pass
    else
        test_fail "Physical directory not created"
    fi
}

# Test dry run mode
test_dry_run_mode() {
    echo -e "\n${YELLOW}=== Dry Run Mode Tests ===${NC}"
    
    mkdir -p "$TEST_ROOT/dryrun_test"
    cd "$TEST_ROOT/dryrun_test"
    
    # Test dry run doesn't create directories
    test_start "Dry run mode doesn't create physical directories"
    source_migration
    migrate_additive . "JOURNAL_WORLD" "1.0.20" "1.0.21" 1 >/dev/null
    if [[ ! -d "00_admin" && ! -d "01_primary_authorship" ]]; then
        test_pass
    else
        test_fail "Dry run created physical directories"
    fi
    
    # Test dry run still reports changes
    test_start "Dry run mode reports expected changes"
    source_migration
    changes=$(migrate_additive . "JOURNAL_WORLD" "1.0.20" "1.0.21" 1)
    if echo "$changes" | grep -q "ADD 00_admin/"; then
        test_pass
    else
        test_fail "Dry run didn't report expected changes: $changes"
    fi
}

# Test no-op migrations
test_noop_migrations() {
    echo -e "\n${YELLOW}=== No-op Migration Tests ===${NC}"
    
    mkdir -p "$TEST_ROOT/noop_test"
    cd "$TEST_ROOT/noop_test"
    
    # Test unsupported world type
    test_start "Unsupported world type produces no changes"
    source_migration
    changes=$(migrate_additive . "UNKNOWN_WORLD" "1.0.0" "1.0.21" 0)
    if [[ -z "$changes" ]]; then
        test_pass
    else
        test_fail "Unsupported world type produced changes: $changes"
    fi
    
    # Test already migrated structure
    test_start "Already migrated structure produces no changes"
    mkdir -p 00_admin 01_primary_authorship 02_coauthor_invites 03_journal_service
    source_migration
    changes=$(migrate_additive . "JOURNAL_WORLD" "1.0.20" "1.0.21" 0)
    if [[ -z "$changes" ]]; then
        test_pass
    else
        test_fail "Already migrated structure produced changes: $changes"
    fi
}

# Main test execution
main() {
    echo -e "${BLUE}Starting $TEST_NAME${NC}"
    echo "Test Root: $TEST_ROOT"
    echo "Library Dir: $LIB_DIR"
    echo ""
    
    # Setup test environment
    mkdir -p "$TEST_ROOT"
    
    # Run all test suites
    test_journal_migration
    test_research_migration
    test_dry_run_mode
    test_noop_migrations
    
    # Final summary
    echo ""
    echo -e "${BLUE}=== Test Summary ===${NC}"
    echo "Total Tests: $TESTS_TOTAL"
    echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Failed: ${RED}$TESTS_FAILED${NC}"
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "\n${GREEN}🎉 All migration logic tests passed!${NC}"
        exit 0
    else
        echo -e "\n${RED}❌ Some migration logic tests failed.${NC}"
        exit 1
    fi
}

# Run tests
main "$@"