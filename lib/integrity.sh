#!/usr/bin/env bash
# lib/integrity.sh
# Helpers for managing the .integrity directory system (Constitution v1.0.22)
# Provides functions to create, update, and validate .integrity metadata structure

# Creates the base .integrity directory structure per constitution v1.0.22
# Usage: create_integrity_structure <project_dir> <world_type>
create_integrity_structure() {
  local dir=${1:-.}
  local world_type=${2:-unknown}
  
  # Create base .integrity directory
  mkdir -p "$dir/.integrity" || return 1
  
  # Create subdirectories
  mkdir -p "$dir/.integrity/checksums" || return 1
  mkdir -p "$dir/.integrity/manifests" || return 1
  
  return 0
}

# Creates or updates the .integrity/project.yaml metadata file
# Usage: create_integrity_project_yaml <project_dir> <name> <world_type> <version>
create_integrity_project_yaml() {
  local dir=${1:-.}
  local name=${2:-unknown}
  local world_type=${3:-unknown}
  local version=${4:-1.0.22}
  
  local integrity_yaml="$dir/.integrity/project.yaml"
  
  # Create YAML with proper metadata
  cat > "$integrity_yaml" << EOF
name: "$name"
world_type: "$world_type"
version: "$version"
created: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
updated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
EOF
  
  return $?
}

# Updates the version in .integrity/<name>.yaml files
# Usage: update_integrity_version <project_dir> <target_version>
update_integrity_version() {
  local dir=${1:-.}
  local target_version=${2:-1.0.22}
  
  if [[ ! -d "$dir/.integrity" ]]; then
    return 1
  fi
  
  # Update all YAML files in .integrity directory
  for yaml_file in "$dir/.integrity"/*.yaml; do
    if [[ -f "$yaml_file" ]]; then
      # Use sed to update version line, preserving other content
      if [[ "$(uname)" == "Darwin" ]]; then
        # macOS sed syntax
        sed -i '' "s/^version: .*/version: \"$target_version\"/" "$yaml_file"
      else
        # Linux sed syntax
        sed -i "s/^version: .*/version: \"$target_version\"/" "$yaml_file"
      fi
      
      # Update the 'updated' timestamp
      if [[ "$(uname)" == "Darwin" ]]; then
        sed -i '' "s/^updated: .*/updated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")/" "$yaml_file"
      else
        sed -i "s/^updated: .*/updated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")/" "$yaml_file"
      fi
    fi
  done
  
  return 0
}

# Checks if .integrity directory structure exists
# Usage: has_integrity_structure <project_dir>
has_integrity_structure() {
  local dir=${1:-.}
  
  # Check if all required directories exist
  if [[ -d "$dir/.integrity" && -d "$dir/.integrity/checksums" && -d "$dir/.integrity/manifests" ]]; then
    return 0
  fi
  return 1
}

# Checks if legacy project.yaml exists in root (needs migration to .integrity)
# Usage: has_legacy_project_yaml <project_dir>
has_legacy_project_yaml() {
  local dir=${1:-.}
  
  if [[ -f "$dir/project.yaml" ]]; then
    return 0  # Legacy file exists
  fi
  return 1  # No legacy file
}

# Validates .integrity structure completeness
# Usage: validate_integrity_structure <project_dir>
validate_integrity_structure() {
  local dir=${1:-.}
  local errors=0
  
  # Check base directory
  if [[ ! -d "$dir/.integrity" ]]; then
    echo "ERROR: .integrity directory missing" >&2
    ((errors++))
  fi
  
  # Check required subdirectories
  if [[ ! -d "$dir/.integrity/checksums" ]]; then
    echo "ERROR: .integrity/checksums directory missing" >&2
    ((errors++))
  fi
  
  if [[ ! -d "$dir/.integrity/manifests" ]]; then
    echo "ERROR: .integrity/manifests directory missing" >&2
    ((errors++))
  fi
  
  # Check for project.yaml
  if [[ ! -f "$dir/.integrity/project.yaml" ]]; then
    echo "ERROR: .integrity/project.yaml missing" >&2
    ((errors++))
  fi
  
  return $errors
}

# Gets the version from .integrity/project.yaml
# Usage: get_integrity_version <project_dir>
get_integrity_version() {
  local dir=${1:-.}
  local yaml_file="$dir/.integrity/project.yaml"
  
  if [[ -f "$yaml_file" ]]; then
    grep -E '^version:' "$yaml_file" | head -n1 | awk '{print $2}' | tr -d '"'
    return 0
  fi
  
  return 1
}

# Gets the world_type from .integrity/project.yaml
# Usage: get_integrity_world_type <project_dir>
get_integrity_world_type() {
  local dir=${1:-.}
  local yaml_file="$dir/.integrity/project.yaml"
  
  if [[ -f "$yaml_file" ]]; then
    grep -E '^world_type:' "$yaml_file" | head -n1 | awk '{print $2}' | tr -d '"'
    return 0
  fi
  
  return 1
}

# Gets the name from .integrity/project.yaml
# Usage: get_integrity_name <project_dir>
get_integrity_name() {
  local dir=${1:-.}
  local yaml_file="$dir/.integrity/project.yaml"
  
  if [[ -f "$yaml_file" ]]; then
    grep -E '^name:' "$yaml_file" | head -n1 | awk '{print $2}' | tr -d '"'
    return 0
  fi
  
  return 1
}

# Migrates legacy project.yaml to .integrity/project.yaml
# Usage: migrate_legacy_project_yaml <project_dir> <target_version>
migrate_legacy_project_yaml() {
  local dir=${1:-.}
  local target_version=${2:-1.0.22}
  local legacy_yaml="$dir/project.yaml"
  local integrity_yaml="$dir/.integrity/project.yaml"
  
  # If no legacy file, nothing to migrate
  if [[ ! -f "$legacy_yaml" ]]; then
    return 0
  fi
  
  # If .integrity/project.yaml already exists, backup the legacy file
  if [[ -f "$integrity_yaml" ]]; then
    local backup_name="$legacy_yaml.backup.$(date +%s)"
    mv "$legacy_yaml" "$backup_name" 2>/dev/null
    return 0
  fi
  
  # Extract metadata from legacy project.yaml
  local name
  local world_type
  
  name=$(grep -E '^name:' "$legacy_yaml" | head -n1 | awk '{print $2}' | tr -d '"' 2>/dev/null || echo "unknown")
  world_type=$(grep -E '^(world_type|type):' "$legacy_yaml" | head -n1 | awk '{print $2}' | tr -d '"' 2>/dev/null || echo "unknown")
  
  # Create .integrity directory if needed
  mkdir -p "$dir/.integrity" || return 1
  
  # Create new .integrity/project.yaml with migrated content
  cat > "$integrity_yaml" << EOF
name: "$name"
world_type: "$world_type"
version: "$target_version"
created: $(grep -E '^created:' "$legacy_yaml" | head -n1 | awk '{print $2}' | tr -d '"' 2>/dev/null || echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ")")
updated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
EOF
  
  # Remove legacy project.yaml after successful migration
  if [[ $? -eq 0 ]]; then
    rm "$legacy_yaml" 2>/dev/null
    return 0
  fi
  
  return 1
}

# Checks if a directory has been migrated to .integrity system
# Usage: is_migrated_to_integrity <project_dir>
is_migrated_to_integrity() {
  local dir=${1:-.}
  
  # Check if .integrity structure exists
  if [[ ! -d "$dir/.integrity" ]]; then
    return 1
  fi
  
  # Check if legacy project.yaml still exists
  if [[ -f "$dir/project.yaml" ]]; then
    return 1  # Still has legacy file
  fi
  
  # Check if .integrity/project.yaml exists
  if [[ -f "$dir/.integrity/project.yaml" ]]; then
    return 0  # Fully migrated
  fi
  
  return 1
}

# Creates integrity metadata for all world-type subdirectories
# Usage: create_world_integrity_metadata <project_dir> <world_type> <target_version>
create_world_integrity_metadata() {
  local dir=${1:-.}
  local world_type=${2:-unknown}
  local target_version=${3:-1.0.22}
  
  # Create metadata for the world itself
  local world_yaml="$dir/.integrity/world.yaml"
  cat > "$world_yaml" << EOF
world_type: "$world_type"
version: "$target_version"
updated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
EOF
  
  return 0
}

# Lists all YAML files in .integrity directory
# Usage: list_integrity_yaml_files <project_dir>
list_integrity_yaml_files() {
  local dir=${1:-.}
  local integrity_dir="$dir/.integrity"
  
  if [[ ! -d "$integrity_dir" ]]; then
    return 1
  fi
  
  find "$integrity_dir" -maxdepth 1 -name "*.yaml" -type f | sort
  return 0
}

# Removes the entire .integrity directory (for rollback scenarios)
# Usage: remove_integrity_structure <project_dir>
remove_integrity_structure() {
  local dir=${1:-.}
  
  if [[ -d "$dir/.integrity" ]]; then
    rm -rf "$dir/.integrity" 2>/dev/null
    return $?
  fi
  
  return 0
}

# Creates integrity metadata for a world-type directory
# Usage: create_world_integrity_metadata <world_dir> <world_type> <target_version>
create_world_integrity_metadata() {
  local dir=${1:-.}
  local world_type=${2:-unknown}
  local target_version=${3:-1.0.22}
  
  # Create .integrity directory for the world
  mkdir -p "$dir/.integrity/checksums" || return 1
  mkdir -p "$dir/.integrity/manifests" || return 1
  
  # Create metadata for the world itself
  local world_yaml="$dir/.integrity/world.yaml"
  cat > "$world_yaml" << EOF
world_type: "$world_type"
version: "$target_version"
created: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
updated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
EOF
  
  return 0
}

# Creates integrity metadata for a workspace (contains multiple world types)
# Usage: create_workspace_integrity_metadata <workspace_dir> <target_version>
create_workspace_integrity_metadata() {
  local dir=${1:-.}
  local target_version=${2:-1.0.22}
  
  # Create .integrity directory for the workspace
  mkdir -p "$dir/.integrity/checksums" || return 1
  mkdir -p "$dir/.integrity/manifests" || return 1
  
  # Create metadata for the workspace itself
  local workspace_yaml="$dir/.integrity/workspace.yaml"
  cat > "$workspace_yaml" << EOF
workspace: "true"
version: "$target_version"
created: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
updated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
EOF
  
  return 0
}

# Creates integrity metadata for a study (within RESEARCH_WORLD)
# Usage: create_study_integrity_metadata <study_dir> <study_name> <target_version>
create_study_integrity_metadata() {
  local dir=${1:-.}
  local study_name=${2:-unknown}
  local target_version=${3:-1.0.22}
  
  # Create .integrity directory for the study
  mkdir -p "$dir/.integrity/checksums" || return 1
  mkdir -p "$dir/.integrity/manifests" || return 1
  
  # Create metadata for the study
  local study_yaml="$dir/.integrity/study.yaml"
  cat > "$study_yaml" << EOF
name: "$study_name"
version: "$target_version"
created: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
updated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
EOF
  
  return 0
}

# Updates version in world-level .integrity/world.yaml
# Usage: update_world_integrity_version <world_dir> <target_version>
update_world_integrity_version() {
  local dir=${1:-.}
  local target_version=${2:-1.0.22}
  
  if [[ ! -f "$dir/.integrity/world.yaml" ]]; then
    return 1
  fi
  
  if [[ "$(uname)" == "Darwin" ]]; then
    sed -i '' "s/^version: .*/version: \"$target_version\"/" "$dir/.integrity/world.yaml"
    sed -i '' "s/^updated: .*/updated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")/" "$dir/.integrity/world.yaml"
  else
    sed -i "s/^version: .*/version: \"$target_version\"/" "$dir/.integrity/world.yaml"
    sed -i "s/^updated: .*/updated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")/" "$dir/.integrity/world.yaml"
  fi
  
  return 0
}

# Updates version in study-level .integrity/study.yaml
# Usage: update_study_integrity_version <study_dir> <target_version>
update_study_integrity_version() {
  local dir=${1:-.}
  local target_version=${2:-1.0.22}
  
  if [[ ! -f "$dir/.integrity/study.yaml" ]]; then
    return 1
  fi
  
  if [[ "$(uname)" == "Darwin" ]]; then
    sed -i '' "s/^version: .*/version: \"$target_version\"/" "$dir/.integrity/study.yaml"
    sed -i '' "s/^updated: .*/updated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")/" "$dir/.integrity/study.yaml"
  else
    sed -i "s/^version: .*/version: \"$target_version\"/" "$dir/.integrity/study.yaml"
    sed -i "s/^updated: .*/updated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")/" "$dir/.integrity/study.yaml"
  fi
  
  return 0
}

