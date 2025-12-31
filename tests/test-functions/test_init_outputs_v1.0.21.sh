#!/usr/bin/env bash
# Test that init commands create required output files (project.yaml, README.md, environment.yml)
# Part of T018 - US3

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Create temp directory for tests
TEST_DIR=$(mktemp -d)
trap 'rm -rf "$TEST_DIR"' EXIT

cd "$TEST_DIR"

echo "=== Test init_outputs: research scaffold ==="

# Test 1: Research project creates required files
"$REPO_ROOT/tools/dirforge" create research --name "Test Research" --no-conda >/dev/null 2>&1

title="Test Research"
# compute PROJECT_ID using same logic as tools/dirforge: to_snake_case + year prefix
id_raw=$(printf "%s" "$title" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9_-]+/_/g' | sed -E 's/^_+|_+$//g')
year=$(date +%Y)
PROJECT_ID="${year}_${id_raw}"
RESEARCH_DIR="RESEARCH_WORLD/$PROJECT_ID"

# Check project.yaml exists
if [ ! -f "$RESEARCH_DIR/project.yaml" ]; then
  echo "FAIL: Research project.yaml not created"
  exit 1
fi

# Check README.md exists
if [ ! -f "$RESEARCH_DIR/README.md" ]; then
  echo "FAIL: Research README.md not created"
  exit 1
fi

# Check new directory structure exists
if [ ! -d "$RESEARCH_DIR/00_admin" ]; then
  echo "FAIL: Research 00_admin/ directory not created"
  exit 1
fi

if [ ! -d "$RESEARCH_DIR/01_project_management" ]; then
  echo "FAIL: Research 01_project_management/ directory not created"
  exit 1
fi

if [ ! -d "$RESEARCH_DIR/02_studies" ]; then
  echo "FAIL: Research 02_studies/ directory not created"
  exit 1
fi

# Check .integrity directories exist
if [ ! -d "$RESEARCH_DIR/.integrity/checksums" ]; then
  echo "FAIL: Research .integrity/checksums/ directory not created"
  exit 1
fi

if [ ! -d "$RESEARCH_DIR/.integrity/manifests" ]; then
  echo "FAIL: Research .integrity/manifests/ directory not created"
  exit 1
fi

# Check old directories do NOT exist (breaking change validation)
if [ -d "$RESEARCH_DIR/03_design_protocols" ]; then
  echo "FAIL: Old 03_design_protocols/ directory should not exist"
  exit 1
fi

if [ -d "$RESEARCH_DIR/04_data" ]; then
  echo "FAIL: Old 04_data/ directory should not exist"
  exit 1
fi

if [ -d "$RESEARCH_DIR/05_data_analysis" ]; then
  echo "FAIL: Old 05_data_analysis/ directory should not exist"
  exit 1
fi

if [ -d "$RESEARCH_DIR/06_data_outputs" ]; then
  echo "FAIL: Old 06_data_outputs/ directory should not exist"
  exit 1
fi

if [ -d "$RESEARCH_DIR/07_publication" ]; then
  echo "FAIL: Old 07_publication/ directory should not exist"
  exit 1
fi

if [ -d "$RESEARCH_DIR/08_documentation" ]; then
  echo "FAIL: Old 08_documentation/ directory should not exist"
  exit 1
fi

# Check project management subdirectories exist
if [ ! -d "$RESEARCH_DIR/01_project_management/01_proposal/01_draft" ]; then
  echo "FAIL: Research 01_project_management/01_proposal/01_draft/ directory not created"
  exit 1
fi

if [ ! -d "$RESEARCH_DIR/01_project_management/01_proposal/02_submission" ]; then
  echo "FAIL: Research 01_project_management/01_proposal/02_submission/ directory not created"
  exit 1
fi

if [ ! -d "$RESEARCH_DIR/01_project_management/01_proposal/03_review" ]; then
  echo "FAIL: Research 01_project_management/01_proposal/03_review/ directory not created"
  exit 1
fi

if [ ! -d "$RESEARCH_DIR/01_project_management/01_proposal/04_final" ]; then
  echo "FAIL: Research 01_project_management/01_proposal/04_final/ directory not created"
  exit 1
fi

if [ ! -d "$RESEARCH_DIR/01_project_management/02_finance" ]; then
  echo "FAIL: Research 01_project_management/02_finance/ directory not created"
  exit 1
fi

if [ ! -d "$RESEARCH_DIR/01_project_management/03_reports" ]; then
  echo "FAIL: Research 01_project_management/03_reports/ directory not created"
  exit 1
fi

if [ ! -d "$RESEARCH_DIR/01_project_management/04_presentations" ]; then
  echo "FAIL: Research 01_project_management/04_presentations/ directory not created"
  exit 1
fi

# Check that 04_presentations is flat (no subdirectories)
presentations_subdirs=$(find "$RESEARCH_DIR/01_project_management/04_presentations" -type d | wc -l)
if [ "$presentations_subdirs" -gt 1 ]; then
  echo "FAIL: Research 01_project_management/04_presentations/ should be flat (no subdirectories)"
  exit 1
fi

# Check README files exist and contain project name
if [ ! -f "$RESEARCH_DIR/01_project_management/README.md" ]; then
  echo "FAIL: Research 01_project_management/README.md not created"
  exit 1
fi

if ! grep -q "Test Research" "$RESEARCH_DIR/01_project_management/README.md"; then
  echo "FAIL: Research 01_project_management/README.md does not contain project name"
  exit 1
fi

if [ ! -f "$RESEARCH_DIR/01_project_management/01_proposal/README.md" ]; then
  echo "FAIL: Research 01_project_management/01_proposal/README.md not created"
  exit 1
fi

if ! grep -q "Test Research" "$RESEARCH_DIR/01_project_management/01_proposal/README.md"; then
  echo "FAIL: Research 01_project_management/01_proposal/README.md does not contain project name"
  exit 1
fi

if [ ! -f "$RESEARCH_DIR/01_project_management/02_finance/README.md" ]; then
  echo "FAIL: Research 01_project_management/02_finance/README.md not created"
  exit 1
fi

if ! grep -q "Test Research" "$RESEARCH_DIR/01_project_management/02_finance/README.md"; then
  echo "FAIL: Research 01_project_management/02_finance/README.md does not contain project name"
  exit 1
fi

if [ ! -f "$RESEARCH_DIR/01_project_management/03_reports/README.md" ]; then
  echo "FAIL: Research 01_project_management/03_reports/README.md not created"
  exit 1
fi

if ! grep -q "Test Research" "$RESEARCH_DIR/01_project_management/03_reports/README.md"; then
  echo "FAIL: Research 01_project_management/03_reports/README.md does not contain project name"
  exit 1
fi

if [ ! -f "$RESEARCH_DIR/01_project_management/04_presentations/README.md" ]; then
  echo "FAIL: Research 01_project_management/04_presentations/README.md not created"
  exit 1
fi

if ! grep -q "Test Research" "$RESEARCH_DIR/01_project_management/04_presentations/README.md"; then
  echo "FAIL: Research 01_project_management/04_presentations/README.md does not contain project name"
  exit 1
fi

echo "✅ Research scaffold creates correct new structure and removes old structure"

echo "=== Test init_outputs: dry-run JSON includes README paths ==="
# Verify dry-run JSON contains expected README file paths (paths-only policy)
json_out=$($REPO_ROOT/tools/dirforge --dry-run --json init research --name "PM Dryrun Test" --no-conda 2>/dev/null || true)
if ! printf '%s' "$json_out" | grep -q '01_project_management/README.md'; then
  echo "FAIL: dry-run JSON missing 01_project_management/README.md"
  exit 1
fi
if ! printf '%s' "$json_out" | grep -q '01_project_management/01_proposal/README.md'; then
  echo "FAIL: dry-run JSON missing 01_project_management/01_proposal/README.md"
  exit 1
fi
echo "✅ Dry-run JSON contains README paths"

echo "=== Test init_outputs: template escaping ==="
# Ensure render_template handles special characters in substitutions (|, &, \)
SPECIAL_TITLE=$'Special | Title & Backslash \\\n+'
"$REPO_ROOT/tools/dirforge" create research --name "$SPECIAL_TITLE" --no-conda >/dev/null 2>&1
id_raw=$(printf "%s" "$SPECIAL_TITLE" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9_-]+/_/g' | sed -E 's/^_+|_+$//g')
year=$(date +%Y)
PROJECT_ID_SPECIAL="${year}_${id_raw}"
RESEARCH_DIR_SPECIAL="RESEARCH_WORLD/$PROJECT_ID_SPECIAL"

if [ ! -f "$RESEARCH_DIR_SPECIAL/01_project_management/README.md" ]; then
  echo "FAIL: Template escaping - README not created for special title"
  exit 1
fi

# Use fixed-string grep to avoid regex interpretation of special chars
if ! grep -F -q "$SPECIAL_TITLE" "$RESEARCH_DIR_SPECIAL/01_project_management/README.md"; then
  echo "FAIL: Template escaping failed - project name not found verbatim in README"
  exit 1
fi

echo "✅ Template escaping works for special characters"

echo "=== Test init_outputs: lecture scaffold ==="

# Test 2: Lecture project creates required files
"$REPO_ROOT/tools/dirforge" init lecture --name "Test Lecture" --no-conda >/dev/null 2>&1

LECTURE_DIR="LECTURE_WORLD/test_lecture"

# Check project.yaml exists
if [ ! -f "$LECTURE_DIR/project.yaml" ]; then
  echo "FAIL: Lecture project.yaml not created"
  exit 1
fi

# Check README.md exists
if [ ! -f "$LECTURE_DIR/README.md" ]; then
  echo "FAIL: Lecture README.md not created"
  exit 1
fi

echo "✅ Lecture scaffold creates all required files"

echo "=== Test init_outputs: project.yaml content validation ==="

# Test 3: Verify project.yaml has required fields (research)
if ! grep -q 'owner:' "$RESEARCH_DIR/project.yaml"; then
  echo "FAIL: Research project.yaml missing 'owner' field"
  exit 1
fi

if ! grep -q 'sync_policy:' "$RESEARCH_DIR/project.yaml"; then
  echo "FAIL: Research project.yaml missing 'sync_policy' field"
  exit 1
fi

# Test 4: Verify project.yaml has required fields (lecture)
if ! grep -q 'course_code:' "$LECTURE_DIR/project.yaml"; then
  echo "FAIL: Lecture project.yaml missing 'course_code' field"
  exit 1
fi

if ! grep -q 'instructor:' "$LECTURE_DIR/project.yaml"; then
  echo "FAIL: Lecture project.yaml missing 'instructor' field"
  exit 1
fi

echo "✅ project.yaml files contain required fields"

echo "=== Test init_outputs: research study creation ==="

# Test 5: Research study creates required structure
"$REPO_ROOT/tools/dirforge" create research --project "2025_test_research" --study "Test Study" >/dev/null 2>&1

STUDY_DIR="$RESEARCH_DIR/02_studies/test_study"

# Check study README.md exists
if [ ! -f "$STUDY_DIR/README.md" ]; then
  echo "FAIL: Study README.md not created"
  exit 1
fi

# Check study subdirectories exist
if [ ! -d "$STUDY_DIR/00_protocols" ]; then
  echo "FAIL: Study 00_protocols/ directory not created"
  exit 1
fi

if [ ! -d "$STUDY_DIR/01_code" ]; then
  echo "FAIL: Study 01_code/ directory not created"
  exit 1
fi

if [ ! -d "$STUDY_DIR/02_data" ]; then
  echo "FAIL: Study 02_data/ directory not created"
  exit 1
fi

if [ ! -d "$STUDY_DIR/03_outputs" ]; then
  echo "FAIL: Study 03_outputs/ directory not created"
  exit 1
fi

if [ ! -d "$STUDY_DIR/04_publication" ]; then
  echo "FAIL: Study 04_publication/ directory not created"
  exit 1
fi

if [ ! -d "$STUDY_DIR/05_presentations" ]; then
  echo "FAIL: Study 05_presentations/ directory not created"
  exit 1
fi

# Check study .integrity directories exist
if [ ! -d "$STUDY_DIR/.integrity/checksums" ]; then
  echo "FAIL: Study .integrity/checksums/ directory not created"
  exit 1
fi

if [ ! -d "$STUDY_DIR/.integrity/manifests" ]; then
  echo "FAIL: Study .integrity/manifests/ directory not created"
  exit 1
fi

echo "✅ Research study creates correct subdirectory structure"

echo "=== Test init_outputs: study name sanitization ==="

# Test 6: Study name sanitization (spaces to underscores)
"$REPO_ROOT/tools/dirforge" create research --project "2025_test_research" --study "My Amazing Study" >/dev/null 2>&1

SANITIZED_STUDY_DIR="$RESEARCH_DIR/02_studies/my_amazing_study"

# Check that the sanitized directory exists
if [ ! -d "$SANITIZED_STUDY_DIR" ]; then
  echo "FAIL: Study name not properly sanitized (spaces to underscores)"
  exit 1
fi

# Check that the original name with spaces does NOT exist
SPACED_STUDY_DIR="$RESEARCH_DIR/02_studies/My Amazing Study"
if [ -d "$SPACED_STUDY_DIR" ]; then
  echo "FAIL: Study directory with spaces should not exist"
  exit 1
fi

echo "✅ Study name sanitization works correctly (spaces → underscores)"

echo "=== Test init_outputs: multiple studies creation ==="

# Test 7: Multiple studies can be created independently
"$REPO_ROOT/tools/dirforge" create research --project "2025_test_research" --study "Study One" >/dev/null 2>&1
"$REPO_ROOT/tools/dirforge" create research --project "2025_test_research" --study "Study Two" >/dev/null 2>&1

STUDY_ONE_DIR="$RESEARCH_DIR/02_studies/study_one"
STUDY_TWO_DIR="$RESEARCH_DIR/02_studies/study_two"

# Check both studies exist
if [ ! -d "$STUDY_ONE_DIR" ]; then
  echo "FAIL: First study directory not created"
  exit 1
fi

if [ ! -d "$STUDY_TWO_DIR" ]; then
  echo "FAIL: Second study directory not created"
  exit 1
fi

# Check both have their own README.md
if [ ! -f "$STUDY_ONE_DIR/README.md" ]; then
  echo "FAIL: First study README.md not created"
  exit 1
fi

if [ ! -f "$STUDY_TWO_DIR/README.md" ]; then
  echo "FAIL: Second study README.md not created"
  exit 1
fi

# Check both have their own directory structures
if [ ! -d "$STUDY_ONE_DIR/01_code" ]; then
  echo "FAIL: First study 01_code/ directory not created"
  exit 1
fi

if [ ! -d "$STUDY_TWO_DIR/01_code" ]; then
  echo "FAIL: Second study 01_code/ directory not created"
  exit 1
fi

echo "✅ Multiple studies can be created independently in same project"

echo "=== Test init_outputs: backward compatibility (breaking changes) ==="

# Test 8: Document breaking changes - old structure assertions
# This test documents that the old v1.0.16 structure is no longer created
# and validates that the new v1.0.17 structure is enforced

# Verify new required directories exist
if [ ! -d "$RESEARCH_DIR/00_admin" ] || [ ! -d "$RESEARCH_DIR/01_project_management" ] || [ ! -d "$RESEARCH_DIR/02_studies" ]; then
  echo "FAIL: New v1.0.17 directory structure not properly created"
  exit 1
fi

# Verify old directories are NOT present (breaking change)
OLD_DIRS=("03_design_protocols" "04_data" "05_data_analysis" "06_data_outputs" "07_publication" "08_documentation")
for old_dir in "${OLD_DIRS[@]}"; do
  if [ -d "$RESEARCH_DIR/$old_dir" ]; then
    echo "FAIL: Breaking change not enforced - old directory $old_dir should not exist"
    exit 1
  fi
done

# Verify study-based organization is working
if [ ! -d "$RESEARCH_DIR/02_studies/study_one/01_code" ] || [ ! -d "$RESEARCH_DIR/02_studies/study_two/02_data" ]; then
  echo "FAIL: Study-based organization not working properly"
  exit 1
fi

echo "✅ Backward compatibility test passed - v1.0.17 breaking changes properly enforced"

echo ""
echo "All init_outputs tests passed!"
exit 0
