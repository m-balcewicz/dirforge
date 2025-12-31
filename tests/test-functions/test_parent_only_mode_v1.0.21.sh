#!/usr/bin/env bash
set -euo pipefail

# Unit test: Verify parent-only mode functionality
# Tests that parent-only mode creates only parent directories without subfolders or prompts

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DIRFORGE="$PROJECT_ROOT/tools/dirforge"

echo "=== T014: Testing parent-only mode for all world types ==="

if [ ! -f "$DIRFORGE" ]; then
  echo "ERROR: dirforge not found at $DIRFORGE" >&2
  exit 1
fi

# Create isolated test workspace
TEST_WORKSPACE="/tmp/dirforge_parent_only_test_$$"
mkdir -p "$TEST_WORKSPACE"
cd "$TEST_WORKSPACE"

echo "Test workspace: $TEST_WORKSPACE"
echo ""

# Test function for a single world type
test_world_parent_only() {
  local world="$1"
  local expected_dir="$2"
  
  echo "Testing: dirforge init $world (parent-only mode)"
  
  # Clean up any existing directory
  if [ -d "$expected_dir" ]; then
    rm -rf "$expected_dir"
  fi
  
  # Run parent-only mode
  output=$("$DIRFORGE" init "$world" 2>&1)
  echo "Output: $output"
  
  # Check that parent directory was created
  if [ ! -d "$expected_dir" ]; then
    echo "❌ FAIL: $expected_dir directory was not created"
    return 1
  fi
  
  # Check that directory is empty (parent-only, no subfolders)
  if [ "$world" != "office" ] && [ "$world" != "private" ]; then
    # For research, lecture, coding, journal - should be completely empty
    if [ "$(ls -A "$expected_dir" 2>/dev/null | wc -l)" -gt 0 ]; then
      echo "❌ FAIL: $expected_dir should be empty but contains: $(ls -A "$expected_dir")"
      return 1
    fi
    echo "✅ PASS: $expected_dir created and empty"
  else
    # For office and private - these create standard structure even in parent-only mode
    if [ "$(ls -A "$expected_dir" 2>/dev/null | wc -l)" -eq 0 ]; then
      echo "❌ FAIL: $expected_dir should contain standard structure but is empty"
      return 1
    fi
    echo "✅ PASS: $expected_dir created with standard structure"
  fi
  
  echo ""
}

# Test 1: Research parent-only mode
test_world_parent_only "research" "RESEARCH_WORLD"

# Test 2: Lecture parent-only mode  
test_world_parent_only "lecture" "LECTURE_WORLD"

# Test 3: Coding parent-only mode
test_world_parent_only "coding" "CODING_WORLD"

# Test 4: Journal parent-only mode
test_world_parent_only "journal" "JOURNAL_WORLD"

# Test 5: Office parent-only mode (creates standard structure)
test_world_parent_only "office" "OFFICE_WORLD"

# Test 6: Private parent-only mode (creates standard structure)
test_world_parent_only "private" "PRIVATE_WORLD"

echo "=== T015: Detailed testing for each world type ==="

# Test detailed behavior for each world type
test_world_detailed() {
  local world="$1"
  local expected_dir="$2"
  
  echo "Detailed testing for: $world"
  
  # Clean up
  if [ -d "$expected_dir" ]; then
    rm -rf "$expected_dir"
  fi
  
  # Test parent-only mode output format
  output=$("$DIRFORGE" init "$world" 2>&1)
  
  case "$world" in
    research|lecture|coding|journal)
      # Should show "Created parent directory: WORLD_NAME"
      if echo "$output" | grep -q "Created parent directory: $expected_dir"; then
        echo "✅ PASS: $world shows correct parent-only output message"
      else
        echo "❌ FAIL: $world doesn't show expected output. Got: $output"
        return 1
      fi
      
      # Should create empty directory
      if [ "$(ls -A "$expected_dir" 2>/dev/null | wc -l)" -eq 0 ]; then
        echo "✅ PASS: $world creates empty parent directory"
      else
        echo "❌ FAIL: $world parent directory not empty: $(ls -A "$expected_dir")"
        return 1
      fi
      ;;
    office)
      # Should show "Creating OFFICE_WORLD standard folders..." and "Created OFFICE_WORLD/"
      if echo "$output" | grep -q "Creating OFFICE_WORLD standard folders" && echo "$output" | grep -q "Created OFFICE_WORLD/"; then
        echo "✅ PASS: office shows correct standard structure output"
      else
        echo "❌ FAIL: office doesn't show expected output. Got: $output"
        return 1
      fi
      
      # Should create standard office folders
      expected_folders="00_admin 01_finance 02_hr_administration 03_faculty 04_inventory_equipment 05_software_licenses 06_public_relations"
      for folder in $expected_folders; do
        if [ ! -d "$expected_dir/$folder" ]; then
          echo "❌ FAIL: office missing required folder: $folder"
          return 1
        fi
      done
      echo "✅ PASS: office creates all required standard folders"
      ;;
    private)
      # Should show "Creating PRIVATE_WORLD standard folders..." and "Created PRIVATE_WORLD/"
      if echo "$output" | grep -q "Creating PRIVATE_WORLD standard folders" && echo "$output" | grep -q "Created PRIVATE_WORLD/"; then
        echo "✅ PASS: private shows correct standard structure output"
      else
        echo "❌ FAIL: private doesn't show expected output. Got: $output"
        return 1
      fi
      
      # Should create standard private folders
      expected_folders="00_admin 01_credentials 02_id_contracts 03_finance 04_documents 05_photos 06_movies 07_hiking 09_installers 90_archive"
      for folder in $expected_folders; do
        if [ ! -d "$expected_dir/$folder" ]; then
          echo "❌ FAIL: private missing required folder: $folder"
          return 1
        fi
      done
      echo "✅ PASS: private creates all required standard folders"
      ;;
  esac
  
  echo ""
}

# Test each world type in detail
test_world_detailed "research" "RESEARCH_WORLD"
test_world_detailed "lecture" "LECTURE_WORLD"  
test_world_detailed "coding" "CODING_WORLD"
test_world_detailed "journal" "JOURNAL_WORLD"
test_world_detailed "office" "OFFICE_WORLD"
test_world_detailed "private" "PRIVATE_WORLD"

echo "=== Testing world type specific validation ==="

# Test research-specific behavior
echo "Testing research world type validation..."
rm -rf RESEARCH_WORLD
output=$("$DIRFORGE" create research 2>&1)
if [ -d "RESEARCH_WORLD" ] && [ "$(ls -A RESEARCH_WORLD | wc -l)" -eq 0 ]; then
  echo "✅ PASS: Research creates empty RESEARCH_WORLD directory"
else
  echo "❌ FAIL: Research parent-only mode validation failed"
fi

# Test lecture-specific behavior
echo "Testing lecture world type validation..."
rm -rf LECTURE_WORLD
output=$("$DIRFORGE" create lecture 2>&1)
if [ -d "LECTURE_WORLD" ] && [ "$(ls -A LECTURE_WORLD | wc -l)" -eq 0 ]; then
  echo "✅ PASS: Lecture creates empty LECTURE_WORLD directory"
else
  echo "❌ FAIL: Lecture parent-only mode validation failed"
fi

# Test coding-specific behavior
echo "Testing coding world type validation..."
rm -rf CODING_WORLD
output=$("$DIRFORGE" create coding 2>&1)
if [ -d "CODING_WORLD" ] && [ "$(ls -A CODING_WORLD | wc -l)" -eq 0 ]; then
  echo "✅ PASS: Coding creates empty CODING_WORLD directory"
else
  echo "❌ FAIL: Coding parent-only mode validation failed"
fi

# Test journal-specific behavior
echo "Testing journal world type validation..."
rm -rf JOURNAL_WORLD
output=$("$DIRFORGE" init journal 2>&1)
if [ -d "JOURNAL_WORLD" ] && [ "$(ls -A JOURNAL_WORLD | wc -l)" -eq 0 ]; then
  echo "✅ PASS: Journal creates empty JOURNAL_WORLD directory"
else
  echo "❌ FAIL: Journal parent-only mode validation failed"
fi

# Test office-specific behavior with folder validation
echo "Testing office world type folder structure..."
rm -rf OFFICE_WORLD
output=$("$DIRFORGE" init office 2>&1)
office_folders="00_admin 01_finance 02_hr_administration 03_faculty 04_inventory_equipment 05_software_licenses 06_public_relations"
office_valid=true
for folder in $office_folders; do
  if [ ! -d "OFFICE_WORLD/$folder" ]; then
    echo "❌ FAIL: Office missing folder: $folder"
    office_valid=false
  fi
done
if [ "$office_valid" = true ]; then
  echo "✅ PASS: Office creates all required standard folders"
fi

# Test private-specific behavior with folder validation
echo "Testing private world type folder structure..."
rm -rf PRIVATE_WORLD
output=$("$DIRFORGE" init private 2>&1)
private_folders="00_admin 01_credentials 02_id_contracts 03_finance 04_documents 05_photos 06_movies 07_hiking 09_installers 90_archive"
private_valid=true
for folder in $private_folders; do
  if [ ! -d "PRIVATE_WORLD/$folder" ]; then
    echo "❌ FAIL: Private missing folder: $folder"
    private_valid=false
  fi
done
if [ "$private_valid" = true ]; then
  echo "✅ PASS: Private creates all required standard folders"
fi

echo ""

echo "=== Testing dry-run mode with parent-only ==="

# Test 7: Dry-run parent-only mode
echo "Testing: dirforge create research --dry-run (parent-only mode)"
rm -rf RESEARCH_WORLD

output=$("$DIRFORGE" create research --dry-run 2>&1)
echo "Output: $output"

if echo "$output" | grep -q "DRY RUN: would create parent directory: RESEARCH_WORLD"; then
  echo "✅ PASS: Dry-run mode shows correct parent directory creation"
else
  echo "❌ FAIL: Dry-run output doesn't show expected parent directory message"
  echo "Expected: 'DRY RUN: would create parent directory: RESEARCH_WORLD'"
  rm -rf "$TEST_WORKSPACE"
  exit 1
fi

if [ -d "RESEARCH_WORLD" ]; then
  echo "❌ FAIL: RESEARCH_WORLD directory was created (should not happen in dry-run)"
  rm -rf "$TEST_WORKSPACE"
  exit 1
else
  echo "✅ PASS: No directories created in dry-run mode"
fi

echo ""
echo "=== Testing parent-only mode vs full project mode ==="

# Test 8: Verify parent-only mode vs full project mode distinction
echo "Testing: dirforge create research --name 'Test Project' (full project mode)"
rm -rf RESEARCH_WORLD

output=$("$DIRFORGE" create research --name "Test Project" --no-conda 2>&1)
echo "Output: $output"

if [ -d "RESEARCH_WORLD" ]; then
  # Should contain full project structure
  project_count=$(find RESEARCH_WORLD -mindepth 1 -maxdepth 1 -type d | wc -l)
  if [ "$project_count" -gt 0 ]; then
    echo "✅ PASS: Full project mode creates project structure under RESEARCH_WORLD"
  else
    echo "❌ FAIL: Full project mode should create project directories"
    rm -rf "$TEST_WORKSPACE"
    exit 1
  fi
else
  echo "❌ FAIL: Full project mode should create RESEARCH_WORLD"
  rm -rf "$TEST_WORKSPACE"
  exit 1
fi

echo ""
echo "=== All parent-only mode tests passed! ==="

echo ""
echo "=== T016: Edge case testing ==="

# Test 1: Directory exists - should be idempotent
echo "Testing: Directory already exists (idempotent behavior)"
rm -rf RESEARCH_WORLD
mkdir -p RESEARCH_WORLD
touch RESEARCH_WORLD/existing_file.txt

output=$("$DIRFORGE" create research 2>&1)
echo "Output: $output"

if [ -d "RESEARCH_WORLD" ] && [ -f "RESEARCH_WORLD/existing_file.txt" ]; then
  echo "✅ PASS: Parent-only mode preserves existing directory and files"
else
  echo "❌ FAIL: Existing directory or files were modified unexpectedly"
  rm -rf "$TEST_WORKSPACE"
  exit 1
fi

# Test 2: Global flags with parent-only mode
echo ""
echo "Testing: Global flags with parent-only mode"

# Test --dry-run with parent-only mode
rm -rf RESEARCH_WORLD
output=$("$DIRFORGE" --dry-run create research 2>&1)
echo "Dry-run output: $output"

if echo "$output" | grep -q "DRY RUN: would create parent directory: RESEARCH_WORLD" && [ ! -d "RESEARCH_WORLD" ]; then
  echo "✅ PASS: --dry-run flag works with parent-only mode"
else
  echo "❌ FAIL: --dry-run flag not working properly with parent-only mode"
  rm -rf "$TEST_WORKSPACE"
  exit 1
fi

# Test --json with --dry-run and parent-only mode
rm -rf RESEARCH_WORLD
output=$("$DIRFORGE" --dry-run --json init research 2>&1)
echo "JSON output: $output"

if echo "$output" | grep -q '"directories"' && echo "$output" | grep -q 'RESEARCH_WORLD'; then
  echo "✅ PASS: --json flag works with --dry-run and parent-only mode"
else
  echo "❌ FAIL: --json flag not working properly"
  rm -rf "$TEST_WORKSPACE"
  exit 1
fi

# Test 3: Invalid flag combinations
echo ""
echo "Testing: Invalid flag combinations"

# Test --id without --journal (should fail)
output=$("$DIRFORGE" init journal --id "TEST-ID" 2>&1 || true)
echo "Journal --id without --journal output: $output"

if echo "$output" | grep -q "Error.*--id.*--journal"; then
  echo "✅ PASS: Invalid flag combination --id without --journal is rejected"
else
  echo "❌ FAIL: Invalid flag combination should be rejected. Got: $output"
  rm -rf "$TEST_WORKSPACE"
  exit 1
fi

# Test invalid world type
output=$("$DIRFORGE" init invalid_world_type 2>&1 || true)
echo "Invalid world type output: $output"

if echo "$output" | grep -q -i "unknown\|invalid\|error"; then
  echo "✅ PASS: Invalid world type is rejected"
else
  echo "❌ FAIL: Invalid world type should be rejected. Got: $output"
  rm -rf "$TEST_WORKSPACE"
  exit 1
fi

# Test 4: Parent-only mode with various global flag combinations
echo ""
echo "Testing: Various global flag combinations with parent-only mode"

# Test --force with parent-only mode (should be ignored/work normally)
rm -rf RESEARCH_WORLD
mkdir -p RESEARCH_WORLD
output=$("$DIRFORGE" --force init research 2>&1)
echo "Force flag output: $output"

if [ -d "RESEARCH_WORLD" ] && echo "$output" | grep -q "Created parent directory: RESEARCH_WORLD"; then
  echo "✅ PASS: --force flag works with parent-only mode"
else
  echo "❌ FAIL: --force flag not working properly with parent-only mode"
  rm -rf "$TEST_WORKSPACE"
  exit 1
fi

# Test --yes with parent-only mode (should be ignored/work normally)
rm -rf RESEARCH_WORLD
output=$("$DIRFORGE" --yes init research 2>&1)
echo "Yes flag output: $output"

if [ -d "RESEARCH_WORLD" ] && echo "$output" | grep -q "Created parent directory: RESEARCH_WORLD"; then
  echo "✅ PASS: --yes flag works with parent-only mode"
else
  echo "❌ FAIL: --yes flag not working properly with parent-only mode"
  rm -rf "$TEST_WORKSPACE"
  exit 1
fi

# Test 5: Parent-only mode vs non-parent-only mode distinction
echo ""
echo "Testing: Parent-only vs non-parent-only mode distinction"

# Test that flags disable parent-only mode for research
rm -rf RESEARCH_WORLD
output=$("$DIRFORGE" create research --name "Test Project" --no-conda 2>&1)
echo "Non-parent-only research output: $output"

if [ -d "RESEARCH_WORLD" ]; then
  project_count=$(find RESEARCH_WORLD -mindepth 1 -maxdepth 1 -type d | wc -l)
  if [ "$project_count" -gt 0 ]; then
    echo "✅ PASS: --name flag disables parent-only mode for research"
  else
    echo "❌ FAIL: --name flag should disable parent-only mode and create project structure"
    rm -rf "$TEST_WORKSPACE"
    exit 1
  fi
else
  echo "❌ FAIL: Research project should be created when --name is specified"
  rm -rf "$TEST_WORKSPACE"
  exit 1
fi

# Test that flags disable parent-only mode for journal
rm -rf JOURNAL_WORLD
output=$("$DIRFORGE" init journal --journal "Test Journal" --id "TEST-001" 2>&1)
echo "Non-parent-only journal output: $output"

if [ -d "JOURNAL_WORLD" ]; then
  journal_count=$(find JOURNAL_WORLD -mindepth 1 -type d | wc -l)
  if [ "$journal_count" -gt 0 ]; then
    echo "✅ PASS: --journal flag disables parent-only mode for journal"
  else
    echo "❌ FAIL: --journal flag should disable parent-only mode and create journal structure"
    rm -rf "$TEST_WORKSPACE"
    exit 1
  fi
else
  echo "❌ FAIL: Journal should be created when --journal is specified"
  rm -rf "$TEST_WORKSPACE"
  exit 1
fi

# Test 6: Robustness testing
echo ""
echo "Testing: Robustness and error handling"

# Test with special characters in directory names (should work for parent-only)
mkdir -p "test with spaces"
cd "test with spaces"
output=$("$DIRFORGE" create research 2>&1)
if [ -d "RESEARCH_WORLD" ]; then
  echo "✅ PASS: Parent-only mode works in directories with spaces"
else
  echo "❌ FAIL: Parent-only mode should work in directories with special characters"
  rm -rf "$TEST_WORKSPACE"
  exit 1
fi
cd "$TEST_WORKSPACE"

echo ""
echo "=== All edge case tests passed! ==="

# Cleanup
rm -rf "$TEST_WORKSPACE"