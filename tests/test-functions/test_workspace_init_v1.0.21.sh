#!/usr/bin/env bash
# Test workspace initialization functionality

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_DIR="$SCRIPT_DIR"
DIRFORGE="$SCRIPT_DIR/../tools/dirforge"

echo "Testing workspace initialization functionality..."

# Test 1: Dry-run workspace init
echo "Test 1: Dry-run workspace initialization"
TMP_DIR=$(mktemp -d)
cd "$TMP_DIR"

output=$($DIRFORGE init workspace-test --dry-run 2>&1)
echo "$output" | grep -q "Initializing DirForge workspace" || {
    echo "FAIL: Expected initialization message not found"
    exit 1
}

echo "$output" | grep -q "DRY RUN: would create complete DirForge workspace" || {
    echo "FAIL: Expected dry-run completion message not found"  
    exit 1
}

# Test 2: Actual workspace creation
echo "Test 2: Actual workspace creation (Constitution v1.0.16 compliance)"
$DIRFORGE init workspace-actual --auto

# Verify all world directories were created (including LITERATURE_WORLD)
for world in CODING_WORLD JOURNAL_WORLD LECTURE_WORLD LITERATURE_WORLD OFFICE_WORLD PRIVATE_WORLD RESEARCH_WORLD; do
    if [ ! -d "workspace-actual/$world" ]; then
        echo "FAIL: $world directory not created"
        exit 1
    fi
done

# Verify EMPTY world directories (per Constitution - should have no subfolders)
for world in CODING_WORLD JOURNAL_WORLD LECTURE_WORLD RESEARCH_WORLD LITERATURE_WORLD; do
    if [ "$(ls -A "workspace-actual/$world" 2>/dev/null | wc -l)" -gt 0 ]; then
        echo "FAIL: $world should be empty but contains: $(ls -A "workspace-actual/$world")"
        exit 1
    fi
done

# Verify OFFICE_WORLD has correct subfolders (Constitution Section III.III)
office_required_dirs="00_admin 01_finance 04_inventory_equipment 05_software_licenses 06_public_relations 90_archive"
for dir in $office_required_dirs; do
    if [ ! -d "workspace-actual/OFFICE_WORLD/$dir" ]; then
        echo "FAIL: OFFICE_WORLD/$dir not created (required by Constitution)"
        exit 1
    fi
done

# Verify PRIVATE_WORLD has correct subfolders (Constitution Section III.IV)
private_required_dirs="01_credentials 02_id_contracts 03_finance 04_documents 05_photos 06_movies 07_hiking 09_installers 90_archive"
for dir in $private_required_dirs; do
    if [ ! -d "workspace-actual/PRIVATE_WORLD/$dir" ]; then
        echo "FAIL: PRIVATE_WORLD/$dir not created (required by Constitution)"
        exit 1
    fi
done

# Verify spelling fix: "equipment" not "equiptment"
test -d "workspace-actual/OFFICE_WORLD/04_inventory_equipment" || {
    echo "FAIL: OFFICE_WORLD/04_inventory_equipment not found (check spelling)"
    exit 1
}

# Verify no old typo directories exist
test ! -d "workspace-actual/OFFICE_WORLD/04_inventory_equiptment" || {
    echo "FAIL: Old typo directory still exists: 04_inventory_equiptment"
    exit 1
}

# Test 3: Current directory initialization
echo "Test 3: Current directory initialization"
mkdir current-test
cd current-test
$DIRFORGE init . --auto

# Verify all world directories were created (including LITERATURE_WORLD)
for world in CODING_WORLD JOURNAL_WORLD LECTURE_WORLD LITERATURE_WORLD OFFICE_WORLD PRIVATE_WORLD RESEARCH_WORLD; do
    if [ ! -d "$world" ]; then
        echo "FAIL: $world directory not created in current directory"
        exit 1
    fi
done

# Test 3b: --here flag
echo "Test 3b: --here flag initialization"
cd "$TMP_DIR"
mkdir here-test
cd here-test
$DIRFORGE init --here --auto

# Verify all directories were created with --here flag (including LITERATURE_WORLD)
for world in CODING_WORLD JOURNAL_WORLD LECTURE_WORLD LITERATURE_WORLD OFFICE_WORLD PRIVATE_WORLD RESEARCH_WORLD; do
    if [ ! -d "$world" ]; then
        echo "FAIL: $world directory not created with --here flag"
        exit 1
    fi
done

# Verify constitution compliance with --here flag
for world in CODING_WORLD JOURNAL_WORLD LECTURE_WORLD RESEARCH_WORLD LITERATURE_WORLD; do
    if [ "$(ls -A "$world" 2>/dev/null | wc -l)" -gt 0 ]; then
        echo "FAIL: $world should be empty with --here flag but contains: $(ls -A "$world")"
        exit 1
    fi
done

# Test 4: JSON output functionality
echo "Test 4: JSON output functionality"
cd "$TMP_DIR"
json_output=$($DIRFORGE init json-test --dry-run --json 2>/dev/null)
echo "$json_output" | grep -q '"dry_run": true' || {
    echo "FAIL: JSON output missing dry_run field"
    exit 1
}

echo "$json_output" | grep -q '"directories":' || {
    echo "FAIL: JSON output missing directories field"
    exit 1
}

echo "$json_output" | grep -q 'LITERATURE_WORLD' || {
    echo "FAIL: JSON output missing LITERATURE_WORLD"
    exit 1
}

# Test 5: Constitution compliance verification
echo "Test 5: Constitution v1.0.16 compliance verification"
cd workspace-actual

# Verify OFFICE_WORLD has exactly 6 subfolders
office_count=$(ls -1 OFFICE_WORLD | wc -l)
if [ "$office_count" -ne 6 ]; then
    echo "FAIL: OFFICE_WORLD should have exactly 6 subfolders, has $office_count"
    exit 1
fi

# Verify PRIVATE_WORLD has exactly 9 subfolders  
private_count=$(ls -1 PRIVATE_WORLD | wc -l)
if [ "$private_count" -ne 9 ]; then
    echo "FAIL: PRIVATE_WORLD should have exactly 9 subfolders, has $private_count"
    exit 1
fi

# Verify equipment spelling is correct
test -d "OFFICE_WORLD/04_inventory_equipment" || {
    echo "FAIL: OFFICE_WORLD/04_inventory_equipment missing (spelling check)"
    exit 1
}

# Test 6: Verify existing world-specific functionality still works
echo "Test 6: Verify world-specific functionality still works"
$DIRFORGE init research --name "Test Research" --dry-run | grep -q "research project" || {
    echo "FAIL: World-specific research init not working"
    exit 1
}

# Cleanup
cd /
rm -rf "$TMP_DIR"

echo "✅ All workspace initialization tests passed!"