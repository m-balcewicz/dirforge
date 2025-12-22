#!/usr/bin/env bash
# lib/version_detect.sh
# Helpers for detecting project structure version and world type

# ============================================================================
# INTERNAL HELPER FUNCTIONS
# ============================================================================

# Helper: Extract a specific YAML field value
# Usage: _extract_yaml_field <file> <field_name>
# Returns: field value or empty string if not found
_extract_yaml_field() {
  local file="$1"
  local field="$2"
  
  if [[ ! -f "$file" ]]; then
    return 1
  fi
  
  grep -E "^${field}:" "$file" | head -n1 | awk '{print $2}' | tr -d '"'\''' || echo ""
}

# Helper: Check if path contains a world type name
# Usage: _get_world_from_path <path>
# Returns: world type or empty string
_get_world_from_path() {
  local path="$1"
  for world in RESEARCH_WORLD JOURNAL_WORLD CODING_WORLD LECTURE_WORLD LITERATURE_WORLD OFFICE_WORLD PRIVATE_WORLD; do
    [[ "$path" == *"$world"* ]] && { echo "$world"; return 0; }
  done
  echo ""
}

# Helper: Check if directory has expected subdirectories for a world type
# Usage: _matches_world_structure <dir> <dir1> <dir2> [<dir3>...]
# Returns: 0 if match, 1 otherwise
_matches_world_structure() {
  local dir="$1"
  shift
  
  for subdir in "$@"; do
    [[ ! -d "$dir/$subdir" ]] && return 1
  done
  
  return 0
}

# ============================================================================
# DETECTION FUNCTIONS
# ============================================================================
# Detects the constitution version from project.yaml or directory patterns
# Usage: detect_version <project_dir>
# Returns: version string or "unknown"
detect_version() {
  local dir=${1:-.}
  local version=""
  
  # Priority 1: Check .integrity/project.yaml (v1.0.22+)
  if [[ -f "$dir/.integrity/project.yaml" ]]; then
    version=$(_extract_yaml_field "$dir/.integrity/project.yaml" "version")
    [[ -n "$version" ]] && { echo "$version"; return 0; }
  fi
  
  # Priority 2: Check .integrity/workspace.yaml
  if [[ -f "$dir/.integrity/workspace.yaml" ]]; then
    version=$(_extract_yaml_field "$dir/.integrity/workspace.yaml" "version")
    [[ -n "$version" ]] && { echo "$version"; return 0; }
  fi
  
  # Priority 3: Check legacy project.yaml
  if [[ -f "$dir/project.yaml" ]]; then
    version=$(_extract_yaml_field "$dir/project.yaml" "version")
    [[ -z "$version" ]] && version=$(_extract_yaml_field "$dir/project.yaml" "constitution_version")
    [[ -n "$version" ]] && { echo "$version"; return 0; }
  fi
  
  # Fallback: Infer from directory patterns
  _matches_world_structure "$dir" ".integrity" ".integrity/checksums" ".integrity/manifests" && { echo "1.0.22"; return 0; }
  _matches_world_structure "$dir" "00_admin" "01_primary_authorship" "02_coauthor_invites" && { echo "1.0.21"; return 0; }
  _matches_world_structure "$dir" "02_studies" && { echo "1.0.17"; return 0; }
  _matches_world_structure "$dir" "02_admin" && { echo "1.0.16"; return 0; }
  
  # Check if workspace (contains multiple world directories)
  local world_count=0
  for world in RESEARCH_WORLD JOURNAL_WORLD CODING_WORLD LECTURE_WORLD LITERATURE_WORLD OFFICE_WORLD PRIVATE_WORLD; do
    [[ -d "$dir/$world" ]] && ((world_count++))
  done
  [[ $world_count -ge 2 ]] && { echo "1.0.21"; return 0; }
  
  echo "unknown"
  return 1
}

# Detects the world type from project.yaml or directory name
# Usage: detect_world_type <project_dir>
# Priority order: 1) Non-unknown metadata, 2) Directory structure, 3) unknown
# Detects the world type from project.yaml or directory structure
# Usage: detect_world_type <project_dir>
# Returns: world type (RESEARCH_WORLD, JOURNAL_WORLD, etc.) or "unknown"
# 
# Detection Priority:
#   1. Path matching (most reliable - if in a world directory path)
#   2. Directory structure heuristics (.integrity files, subdirectories)
#   3. Metadata files (.integrity/project.yaml, .integrity/lecture.yaml, etc.)
#   4. Legacy project.yaml
#   5. Workspace detection (contains multiple worlds)
detect_world_type() {
  local dir=${1:-.}
  local resolved_dir
  resolved_dir=$(cd "$dir" 2>/dev/null && pwd) || resolved_dir="$dir"
  
  # Priority 1: Check if path contains a world type name (most reliable)
  local detected_world=""
  detected_world=$(_get_world_from_path "$resolved_dir")
  [[ -n "$detected_world" ]] && { echo "$detected_world"; return 0; }
  
  # Priority 2: Check if basename contains world type
  detected_world=$(_get_world_from_path "$(basename "$dir")")
  [[ -n "$detected_world" ]] && { echo "$detected_world"; return 0; }
  
  # Priority 3: Check directory structure for world-type-specific patterns
  _matches_world_structure "$dir" "02_studies" && { echo "RESEARCH_WORLD"; return 0; }
  _matches_world_structure "$dir" "00_admin" "01_primary_authorship" && { echo "JOURNAL_WORLD"; return 0; }
  _matches_world_structure "$dir" "01_courses" && { echo "LECTURE_WORLD"; return 0; }
  _matches_world_structure "$dir" "01_projects" && { echo "CODING_WORLD"; return 0; }
  [[ -d "$dir/courses" ]] && { echo "LECTURE_WORLD"; return 0; }
  [[ -d "$dir/projects" ]] && { echo "CODING_WORLD"; return 0; }
  
  # Priority 4: Check study directory indicator
  if [[ "$resolved_dir" == *"/02_studies/"* || "$(basename "$(dirname "$resolved_dir")")" == "02_studies" ]] && [[ "$resolved_dir" == *"/RESEARCH_WORLD/"* ]]; then
    echo "RESEARCH_WORLD"
    return 0
  fi
  
  # Priority 5: Check .integrity metadata files
  [[ -f "$dir/.integrity/workspace.yaml" ]] && { echo "workspace"; return 0; }
  
  # Check various .integrity metadata files for world_type field
  for metadata_file in "$dir/.integrity/world.yaml" "$dir/.integrity/project.yaml" "$dir/.integrity/lecture.yaml" "$dir/.integrity/coding.yaml" "$dir/.integrity/journal.yaml"; do
    if [[ -f "$metadata_file" ]]; then
      local world=$(_extract_yaml_field "$metadata_file" "world_type")
      [[ -n "$world" && "$world" != "unknown" ]] && { echo "$world"; return 0; }
    fi
  done
  
  # Study indicator in .integrity
  [[ -f "$dir/.integrity/study.yaml" ]] && { echo "RESEARCH_WORLD"; return 0; }
  
  # Priority 6: Check legacy project.yaml
  if [[ -f "$dir/project.yaml" ]]; then
    local world=$(_extract_yaml_field "$dir/project.yaml" "world_type")
    [[ -z "$world" ]] && world=$(_extract_yaml_field "$dir/project.yaml" "type")
    [[ -n "$world" && "$world" != "unknown" ]] && { echo "$world"; return 0; }
  fi
  
  # Priority 7: Check if this is a workspace (contains multiple world directories)
  local world_count=0
  for world in RESEARCH_WORLD JOURNAL_WORLD CODING_WORLD LECTURE_WORLD LITERATURE_WORLD OFFICE_WORLD PRIVATE_WORLD; do
    [[ -d "$dir/$world" ]] && ((world_count++))
  done
  [[ $world_count -ge 2 ]] && { echo "workspace"; return 0; }
  
  # Unable to determine
  echo "unknown"
  return 1
}

# Detects organizational level of a directory (workspace, world, project, study)
# Usage: detect_organizational_level <path>
detect_organizational_level() {
  local dir=${1:-.}
  
  # Resolve absolute path and get directory name
  local resolved_dir
  resolved_dir=$(cd "$dir" 2>/dev/null && pwd) || return 1
  local dir_name=$(basename "$resolved_dir")
  
  # Check for world-type indicators
  case "$dir_name" in
    RESEARCH_WORLD|JOURNAL_WORLD|CODING_WORLD|LECTURE_WORLD|LITERATURE_WORLD|OFFICE_WORLD|PRIVATE_WORLD)
      echo "world"
      return 0
      ;;
  esac
  
  # Check for study directory (RESEARCH_WORLD specific)
  # A study is under a "02_studies" directory
  local resolved_abs_dir
  resolved_abs_dir=$(cd "$dir" 2>/dev/null && pwd) || resolved_abs_dir="$dir"
  if [[ "$resolved_abs_dir" == *"/02_studies/"* || "$(basename "$(dirname "$resolved_abs_dir")")" == "02_studies" ]]; then
    # Verify it's within a RESEARCH_WORLD project structure
    if [[ "$resolved_abs_dir" == *"/RESEARCH_WORLD/"* ]]; then
      echo "study"
      return 0
    fi
  fi
  
  # Check for project level (.integrity/ with metadata file exists)
  # Accepts project.yaml, lecture.yaml, coding.yaml, journal.yaml, office.yaml, etc.
  if [[ -f "$dir/.integrity/project.yaml" ]] || \
     [[ -f "$dir/.integrity/lecture.yaml" ]] || \
     [[ -f "$dir/.integrity/coding.yaml" ]] || \
     [[ -f "$dir/.integrity/journal.yaml" ]] || \
     [[ -f "$dir/.integrity/office.yaml" ]]; then
    echo "project"
    return 0
  fi
  
  # Check for workspace level (.integrity/workspace.yaml exists)
  if [[ -f "$dir/.integrity/workspace.yaml" ]]; then
    echo "workspace"
    return 0
  fi
  
  # Check for workspace level (contains multiple world directories)
  local world_count=0
  for world in RESEARCH_WORLD JOURNAL_WORLD CODING_WORLD LECTURE_WORLD LITERATURE_WORLD OFFICE_WORLD PRIVATE_WORLD; do
    if [[ -d "$dir/$world" ]]; then
      ((world_count++))
    fi
  done
  
  if [[ $world_count -ge 2 ]]; then
    echo "workspace"
    return 0
  fi
  
  # Default to project
  echo "project"
  return 0
}

# Detects if a directory is a study within RESEARCH_WORLD
# Usage: is_study_directory <study_dir>
is_study_directory() {
  local dir=${1:-.}
  
  # Check if parent directory is "02_studies"
  if [[ "$(basename "$(dirname "$dir")")" == "02_studies" ]]; then
    return 0
  fi
  
  return 1
}

# Gets the parent research project of a study
# Usage: get_study_parent_project <study_dir>
get_study_parent_project() {
  local dir=${1:-.}
  
  # Navigate up: study -> 02_studies -> project_root
  local studies_dir=$(dirname "$dir")
  local project_dir=$(dirname "$studies_dir")
  
  if [[ -f "$project_dir/.integrity/project.yaml" ]] || [[ -f "$project_dir/project.yaml" ]]; then
    echo "$project_dir"
    return 0
  fi
  
  return 1
}

# Find the project root by walking up the directory tree
# Usage: find_project_root <path>
# Returns the path to the project root if found, or empty string
find_project_root() {
  local current_dir=${1:-.}
  
  # Resolve to absolute path
  current_dir=$(cd "$current_dir" 2>/dev/null && pwd) || return 1
  
  # Walk up the directory tree looking for .integrity/project.yaml
  while [[ "$current_dir" != "/" ]]; do
    if [[ -f "$current_dir/.integrity/project.yaml" ]] || [[ -f "$current_dir/project.yaml" ]]; then
      echo "$current_dir"
      return 0
    fi
    current_dir=$(dirname "$current_dir")
  done
  
  return 1
}

