#!/usr/bin/env bash
# Test script for version detection functionality
# Tests lib/version_detect.sh functions for detecting project versions and world types
set -euo pipefail

# Test configuration
TEST_NAME="Version Detection Tests"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIRFORGE="$SCRIPT_DIR/../../tools/dirforge"
LIB_DIR="$SCRIPT_DIR/../../lib"
TEST_ROOT="/tmp/dirforge_version_test_$$"

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

# Source version detection functions
source_version_detect() {
    source "$LIB_DIR/version_detect.sh"
}

# Test version detection from YAML files
test_yaml_version_detection() {
    echo -e "\n${YELLOW}=== YAML Version Detection ===${NC}"
    
    mkdir -p "$TEST_ROOT/yaml_test"
    cd "$TEST_ROOT/yaml_test"
    
    # Test quoted version
    test_start "Detect version from quoted YAML value"
    cat > project.yaml << 'EOF'
version: "1.0.20"
world_type: "JOURNAL_WORLD"
EOF
    source_version_detect
    if [[ "$(detect_version .)" == "1.0.20" ]]; then
        test_pass
    else
        test_fail "Expected 1.0.20, got $(detect_version .)"
    fi
    
    # Test unquoted version
    test_start "Detect version from unquoted YAML value"
    cat > project.yaml << 'EOF'
version: 1.0.17
world_type: RESEARCH_WORLD
EOF
    source_version_detect
    if [[ "$(detect_version .)" == "1.0.17" ]]; then
        test_pass
    else
        test_fail "Expected 1.0.17, got $(detect_version .)"
    fi
    
    # Test constitution_version field
    test_start "Detect version from constitution_version field"
    cat > project.yaml << 'EOF'
constitution_version: 1.0.21
world_type: OFFICE_WORLD
EOF
    source_version_detect
    if [[ "$(detect_version .)" == "1.0.21" ]]; then
        test_pass
    else
        test_fail "Expected 1.0.21, got $(detect_version .)"
    fi
}

# Test world type detection from YAML files
test_yaml_world_detection() {
    echo -e "\n${YELLOW}=== YAML World Type Detection ===${NC}"
    
    mkdir -p "$TEST_ROOT/world_test"
    cd "$TEST_ROOT/world_test"
    
    # Test quoted world type
    test_start "Detect world type from quoted YAML value"
    cat > project.yaml << 'EOF'
version: 1.0.20
world_type: "JOURNAL_WORLD"
EOF
    source_version_detect
    if [[ "$(detect_world_type .)" == "JOURNAL_WORLD" ]]; then
        test_pass
    else
        test_fail "Expected JOURNAL_WORLD, got $(detect_world_type .)"
    fi
    
    # Test unquoted world type
    test_start "Detect world type from unquoted YAML value" 
    cat > project.yaml << 'EOF'
version: 1.0.16
world_type: RESEARCH_WORLD
EOF
    source_version_detect
    if [[ "$(detect_world_type .)" == "RESEARCH_WORLD" ]]; then
        test_pass
    else
        test_fail "Expected RESEARCH_WORLD, got $(detect_world_type .)"
    fi
}

# Test version detection from directory structure
test_structure_detection() {
    echo -e "\n${YELLOW}=== Structure-Based Detection ===${NC}"
    
    mkdir -p "$TEST_ROOT/structure_test"
    cd "$TEST_ROOT/structure_test"
    
    # Test RESEARCH_WORLD 1.0.17 detection (02_studies directory)
    test_start "Detect RESEARCH_WORLD 1.0.17 from 02_studies directory"
    mkdir -p 02_studies
    source_version_detect
    version=$(detect_version .)
    world=$(detect_world_type .)
    if [[ "$version" == "1.0.17" && "$world" == "RESEARCH_WORLD" ]]; then
        test_pass
    else
        test_fail "Expected 1.0.17/RESEARCH_WORLD, got $version/$world"
    fi
    
    # Test JOURNAL_WORLD 1.0.21 detection (role directories)
    test_start "Detect JOURNAL_WORLD 1.0.21 from role directories"
    rm -rf 02_studies
    mkdir -p 00_admin 01_primary_authorship 02_coauthor_invites 03_journal_service
    source_version_detect
    version=$(detect_version .)
    world=$(detect_world_type .)
    if [[ "$version" == "1.0.21" && "$world" == "JOURNAL_WORLD" ]]; then
        test_pass
    else
        test_fail "Expected 1.0.21/JOURNAL_WORLD, got $version/$world"
    fi
    
    # Test RESEARCH_WORLD 1.0.16 detection (02_admin directory)
    test_start "Detect RESEARCH_WORLD 1.0.16 from 02_admin directory"
    rm -rf 00_admin 01_primary_authorship 02_coauthor_invites 03_journal_service
    mkdir -p 02_admin
    source_version_detect
    version=$(detect_version .)
    if [[ "$version" == "1.0.16" ]]; then
        test_pass
    else
        test_fail "Expected 1.0.16, got $version"
    fi
}

# Test unknown/fallback cases
test_unknown_cases() {
    echo -e "\n${YELLOW}=== Unknown/Fallback Cases ===${NC}"
    
    mkdir -p "$TEST_ROOT/unknown_test"
    cd "$TEST_ROOT/unknown_test"
    
    # Test unknown version
    test_start "Handle unknown version gracefully"
    source_version_detect
    if version=$(detect_version . 2>/dev/null) && [[ "$version" == "unknown" ]]; then
        test_pass
    elif ! detect_version . >/dev/null 2>&1; then
        # Function returns non-zero for unknown, which is expected
        test_pass
    else
        test_fail "Expected unknown or failure, got $version"
    fi
    
    # Test unknown world type
    test_start "Handle unknown world type gracefully"
    source_version_detect
    if world=$(detect_world_type . 2>/dev/null) && [[ "$world" == "unknown" ]]; then
        test_pass
    elif ! detect_world_type . >/dev/null 2>&1; then
        # Function returns non-zero for unknown, which is expected
        test_pass
    else
        test_fail "Expected unknown or failure, got $world"
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
    test_yaml_version_detection
    test_yaml_world_detection
    test_structure_detection
    test_unknown_cases
    
    # Final summary
    echo ""
    echo -e "${BLUE}=== Test Summary ===${NC}"
    echo "Total Tests: $TESTS_TOTAL"
    echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Failed: ${RED}$TESTS_FAILED${NC}"
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "\n${GREEN}🎉 All version detection tests passed!${NC}"
        exit 0
    else
        echo -e "\n${RED}❌ Some version detection tests failed.${NC}"
        exit 1
    fi
}

# Run tests
main "$@"