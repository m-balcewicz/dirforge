#!/usr/bin/env bash
# Metadata Generator for DirForge (T064-T068)
#
# Generates metadata files at different levels (workspace, world, project, study)
# with automatic template expansion and integrity tracking.
#
# Part of YAML-Driven World Configuration System (Constitution v1.1.0, Section IV.B)
#
# Usage:
#   source lib/metadata_generator.sh
#   generate_workspace_metadata "$base_path" "$workspace_name"
#   generate_world_metadata "$base_path" "$world_name" "$world_type" "$config_file"
#   generate_project_metadata "$base_path" "$project_name" "$world_type"
#   generate_study_metadata "$base_path" "$project_name" "$study_name"
#
# Exit Code: 0 on success, 1 on failure
#
# Dependencies:
#   - lib/scaffold_generator.sh (for create_file_safe, _log_scaffold_message)
#   - lib/yaml_utils.sh (for expand_variables)
#   - lib/colors.sh (for colored output)

set -euo pipefail

# Get script directory for sourcing libraries
METADATA_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source required libraries
source "$METADATA_SCRIPT_DIR/colors.sh" || { echo "Error: Cannot source colors.sh" >&2; exit 1; }
source "$METADATA_SCRIPT_DIR/yaml_utils.sh" || { echo "Error: Cannot source yaml_utils.sh" >&2; exit 1; }

# Initialize colors
init_colors 2>/dev/null || true

# ============================================================================
# TEMPLATE MANAGEMENT
# ============================================================================

# Get the path to a metadata template file
# Usage: get_template_path "<template_name>"
# Arguments:
#   template_name: Name of template (workspace, world, project, study)
# Returns: Path to template file
get_template_path() {
  local template_name="$1"
  
  # Get script root directory
  local script_root
  script_root=$(cd "$METADATA_SCRIPT_DIR/.." && pwd)
  
  local template_path="${script_root}/templates/${template_name}.yaml.template"
  
  if [ ! -f "$template_path" ]; then
    echo "Error: Template file not found: $template_path" >&2
    return 1
  fi
  
  echo "$template_path"
  return 0
}

# Load and expand a metadata template
# Usage: load_and_expand_template "$template_path"
# Arguments:
#   template_path: Path to template file
#   Expects variables to be set in environment (WORKSPACE_NAME, WORLD_NAME, etc.)
# Returns: Expanded template content
load_and_expand_template() {
  local template_path="$1"
  
  if [ ! -f "$template_path" ]; then
    echo "Error: Template file not found: $template_path" >&2
    return 1
  fi
  
  # Read template
  local template_content
  template_content=$(<"$template_path")
  
  # Expand all variables using sed to avoid bash parameter expansion issues
  # Standard variables first
  template_content=$(echo "$template_content" | sed "s/\${USER}/$(whoami)/g")
  template_content=$(echo "$template_content" | sed "s/\${DATE}/$(date -u +'%Y-%m-%dT%H:%M:%SZ')/g")
  
  # Custom metadata variables
  [ -n "${WORKSPACE_NAME:-}" ] && template_content=$(echo "$template_content" | sed "s/\${WORKSPACE_NAME}/$WORKSPACE_NAME/g")
  [ -n "${WORLD_NAME:-}" ] && template_content=$(echo "$template_content" | sed "s/\${WORLD_NAME}/$WORLD_NAME/g")
  [ -n "${WORLD_TYPE:-}" ] && template_content=$(echo "$template_content" | sed "s/\${WORLD_TYPE}/$WORLD_TYPE/g")
  [ -n "${PROJECT_NAME:-}" ] && template_content=$(echo "$template_content" | sed "s/\${PROJECT_NAME}/$PROJECT_NAME/g")
  [ -n "${STUDY_NAME:-}" ] && template_content=$(echo "$template_content" | sed "s/\${STUDY_NAME}/$STUDY_NAME/g")
  [ -n "${CONFIG_FILE:-}" ] && template_content=$(echo "$template_content" | sed "s|\${CONFIG_FILE}|$CONFIG_FILE|g")
  [ -n "${PARENT_COUNT:-}" ] && template_content=$(echo "$template_content" | sed "s/\${PARENT_COUNT}/$PARENT_COUNT/g")
  [ -n "${SUBDIR_COUNT:-}" ] && template_content=$(echo "$template_content" | sed "s/\${SUBDIR_COUNT}/$SUBDIR_COUNT/g")
  [ -n "${DIRFORGE_VERSION:-}" ] && template_content=$(echo "$template_content" | sed "s/\${DIRFORGE_VERSION}/$DIRFORGE_VERSION/g")
  
  echo "$template_content"
  
  return 0
}

# ============================================================================
# WORKSPACE METADATA (T065)
# ============================================================================

# generate_workspace_metadata() - Generate workspace-level metadata file
# Implements T065: Workspace-level metadata generation
# Usage: generate_workspace_metadata "$integrity_path" "$workspace_name"
# Arguments:
#   integrity_path: Path to .integrity/ directory
#   workspace_name: Name of workspace being scaffolded
# Returns: 0 on success, 1 on failure
generate_workspace_metadata() {
  local integrity_path="$1"
  local workspace_name="${2:-workspace}"
  
  # Export variables for template expansion
  export WORKSPACE_NAME="$workspace_name"
  
  # Get template path
  local template_path
  template_path=$(get_template_path "workspace") || return 1
  
  # Load and expand template
  local metadata_content
  metadata_content=$(load_and_expand_template "$template_path") || return 1
  
  # Apply custom variable expansion
  
  # Write metadata file
  local metadata_file="${integrity_path}/workspace.yaml"
  
  if ! echo "$metadata_content" > "$metadata_file" 2>/dev/null; then
    echo "Error: Failed to create workspace metadata file" >&2
    return 1
  fi
  
  # Set restricted permissions: 600 (rw-------)
  if ! chmod 600 "$metadata_file" 2>/dev/null; then
    echo "Warning: Failed to set permissions on workspace metadata" >&2
  fi
  
  echo "✓ Workspace metadata generated: $metadata_file"
  return 0
}

# ============================================================================
# WORLD METADATA (T066)
# ============================================================================

# generate_world_metadata() - Generate world-level metadata file
# Implements T066: World-level metadata generation
# Usage: generate_world_metadata "$integrity_path" "$world_name" "$world_type" "$config_file"
# Arguments:
#   integrity_path: Path to .integrity/ directory
#   world_name: Name of world being created
#   world_type: Type of world (CODING_WORLD, RESEARCH_WORLD, etc.)
#   config_file: Path to the config file used for generation
# Returns: 0 on success, 1 on failure
generate_world_metadata() {
  local integrity_path="$1"
  local world_name="${2:-world}"
  local world_type="${3:-UNKNOWN}"
  local config_file="${4:-.}"
  
  # Export variables for template expansion
  export WORLD_NAME="$world_name"
  export WORLD_TYPE="$world_type"
  export CONFIG_FILE="$config_file"
  
  # Get template path
  local template_path
  template_path=$(get_template_path "world") || return 1
  
  # Load and expand template
  local metadata_content
  metadata_content=$(load_and_expand_template "$template_path") || return 1
  
  # Apply custom variable expansion
  
  # Write metadata file
  local metadata_file="${integrity_path}/world.yaml"
  
  if ! echo "$metadata_content" > "$metadata_file" 2>/dev/null; then
    echo "Error: Failed to create world metadata file" >&2
    return 1
  fi
  
  # Set restricted permissions: 600 (rw-------)
  if ! chmod 600 "$metadata_file" 2>/dev/null; then
    echo "Warning: Failed to set permissions on world metadata" >&2
  fi
  
  echo "✓ World metadata generated: $metadata_file"
  return 0
}

# ============================================================================
# PROJECT METADATA (T067)
# ============================================================================

# generate_project_metadata() - Generate project-level metadata file
# Implements T067: Project-level metadata generation
# Usage: generate_project_metadata "$integrity_path" "$project_name" "$world_type"
# Arguments:
#   integrity_path: Path to .integrity/ directory within project
#   project_name: Name of project being created
#   world_type: Type of world (for context)
# Returns: 0 on success, 1 on failure
generate_project_metadata() {
  local integrity_path="$1"
  local project_name="${2:-project}"
  local world_type="${3:-UNKNOWN}"
  
  # Export variables for template expansion
  export PROJECT_NAME="$project_name"
  export WORLD_TYPE="$world_type"
  
  # Get template path
  local template_path
  template_path=$(get_template_path "project") || return 1
  
  # Load and expand template
  local metadata_content
  metadata_content=$(load_and_expand_template "$template_path") || return 1
  
  # Apply custom variable expansion
  
  # Write metadata file
  local metadata_file="${integrity_path}/project.yaml"
  
  if ! echo "$metadata_content" > "$metadata_file" 2>/dev/null; then
    echo "Error: Failed to create project metadata file" >&2
    return 1
  fi
  
  # Set restricted permissions: 600 (rw-------)
  if ! chmod 600 "$metadata_file" 2>/dev/null; then
    echo "Warning: Failed to set permissions on project metadata" >&2
  fi
  
  echo "✓ Project metadata generated: $metadata_file"
  return 0
}

# ============================================================================
# STUDY METADATA (T068 - RESEARCH_WORLD ONLY)
# ============================================================================

# generate_study_metadata() - Generate study-level metadata file (RESEARCH_WORLD only)
# Implements T068: Study-level metadata generation for RESEARCH_WORLD
# Usage: generate_study_metadata "$integrity_path" "$project_name" "$study_name"
# Arguments:
#   integrity_path: Path to .integrity/ directory within study
#   project_name: Name of parent project
#   study_name: Name of study being created
# Returns: 0 on success, 1 on failure
generate_study_metadata() {
  local integrity_path="$1"
  local project_name="${2:-project}"
  local study_name="${3:-study}"
  
  # Export variables for template expansion
  export PROJECT_NAME="$project_name"
  export STUDY_NAME="$study_name"
  export WORLD_TYPE="RESEARCH_WORLD"
  
  # Get template path
  local template_path
  template_path=$(get_template_path "study") || return 1
  
  # Load and expand template
  local metadata_content
  metadata_content=$(load_and_expand_template "$template_path") || return 1
  
  # Apply custom variable expansion
  
  # Write metadata file
  local metadata_file="${integrity_path}/study.yaml"
  
  if ! echo "$metadata_content" > "$metadata_file" 2>/dev/null; then
    echo "Error: Failed to create study metadata file" >&2
    return 1
  fi
  
  # Set restricted permissions: 600 (rw-------)
  if ! chmod 600 "$metadata_file" 2>/dev/null; then
    echo "Warning: Failed to set permissions on study metadata" >&2
  fi
  
  echo "✓ Study metadata generated: $metadata_file"
  return 0
}

# ============================================================================
# BATCH METADATA GENERATION
# ============================================================================

# generate_all_metadata() - Generate all required metadata files for a scaffold
# Usage: generate_all_metadata "$base_path" "$workspace_name" "$world_name" "$world_type" "$config_file" [$project_name] [$study_name]
# Arguments:
#   base_path: Base path of scaffold
#   workspace_name: Name of workspace
#   world_name: Name of world
#   world_type: Type of world
#   config_file: Path to config file
#   project_name: Optional project name (for RESEARCH_WORLD)
#   study_name: Optional study name (for RESEARCH_WORLD)
# Returns: 0 on success, 1 on failure
generate_all_metadata() {
  local base_path="$1"
  local workspace_name="$2"
  local world_name="$3"
  local world_type="$4"
  local config_file="$5"
  local project_name="${6:-}"
  local study_name="${7:-}"
  
  local integrity_path="${base_path}/.integrity"
  
  # Ensure .integrity directory exists with proper permissions
  if [ ! -d "$integrity_path" ]; then
    if ! mkdir -p "$integrity_path" 2>/dev/null; then
      echo "Error: Failed to create .integrity directory" >&2
      return 1
    fi
    if ! chmod 700 "$integrity_path" 2>/dev/null; then
      echo "Warning: Failed to set permissions on .integrity directory" >&2
    fi
  fi
  
  # Generate workspace metadata
  if ! generate_workspace_metadata "$integrity_path" "$workspace_name"; then
    echo "Error: Failed to generate workspace metadata" >&2
    return 1
  fi
  
  # Generate world metadata
  if ! generate_world_metadata "$integrity_path" "$world_name" "$world_type" "$config_file"; then
    echo "Error: Failed to generate world metadata" >&2
    return 1
  fi
  
  # Generate project metadata if provided
  if [ -n "$project_name" ]; then
    # Create project integrity directory if needed
    local project_integrity_path="${base_path}/${project_name}/.integrity"
    if [ ! -d "$project_integrity_path" ]; then
      if ! mkdir -p "$project_integrity_path" 2>/dev/null; then
        echo "Error: Failed to create project .integrity directory" >&2
        return 1
      fi
      if ! chmod 700 "$project_integrity_path" 2>/dev/null; then
        echo "Warning: Failed to set permissions on project .integrity directory" >&2
      fi
    fi
    
    if ! generate_project_metadata "$project_integrity_path" "$project_name" "$world_type"; then
      echo "Error: Failed to generate project metadata" >&2
      return 1
    fi
    
    # Generate study metadata if provided (RESEARCH_WORLD only)
    if [ -n "$study_name" ] && [ "$world_type" = "RESEARCH_WORLD" ]; then
      # Create study integrity directory
      local study_integrity_path="${base_path}/${project_name}/${study_name}/.integrity"
      if [ ! -d "$study_integrity_path" ]; then
        if ! mkdir -p "$study_integrity_path" 2>/dev/null; then
          echo "Error: Failed to create study .integrity directory" >&2
          return 1
        fi
        if ! chmod 700 "$study_integrity_path" 2>/dev/null; then
          echo "Warning: Failed to set permissions on study .integrity directory" >&2
        fi
      fi
      
      if ! generate_study_metadata "$study_integrity_path" "$project_name" "$study_name"; then
        echo "Error: Failed to generate study metadata" >&2
        return 1
      fi
    fi
  fi
  
  echo "✓ All metadata files generated successfully"
  return 0
}

# ============================================================================
# PUBLIC API EXPORTS
# ============================================================================

# Export main functions
export -f generate_workspace_metadata
export -f generate_world_metadata
export -f generate_project_metadata
export -f generate_study_metadata
export -f generate_all_metadata
export -f get_template_path
export -f load_and_expand_template
