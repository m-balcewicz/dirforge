#!/usr/bin/env bash
# Scaffold Generator for DirForge (T059-T073)
# 
# Generates directory structures from YAML configuration files with atomic
# transactions and automatic rollback on failure.
#
# Part of YAML-Driven World Configuration System (Constitution v1.0.22, Section IV.B)
#
# Usage:
#   source lib/scaffold_generator.sh
#   scaffold_generator "$config_file" "$base_path"
#
# Exit Code: 0 on success, 1 on failure
#
# Dependencies:
#   - lib/transaction.sh (atomic transactions and rollback)
#   - lib/config_utils.sh (config loading and validation)
#   - lib/config_schema.sh (schema validation)
#   - lib/yaml_utils.sh (YAML parsing)
#   - lib/metadata_generator.sh (metadata file generation - T064-T068)
#   - lib/colors.sh (colored output)
#   - lib/error.sh (error handling)

set -euo pipefail

# Get script directory for sourcing libraries
SCAFFOLD_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source required libraries
source "$SCAFFOLD_SCRIPT_DIR/transaction.sh" || { echo "Error: Cannot source transaction.sh" >&2; exit 1; }
source "$SCAFFOLD_SCRIPT_DIR/config_utils.sh" || { echo "Error: Cannot source config_utils.sh" >&2; exit 1; }
source "$SCAFFOLD_SCRIPT_DIR/config_schema.sh" || { echo "Error: Cannot source config_schema.sh" >&2; exit 1; }
source "$SCAFFOLD_SCRIPT_DIR/yaml_utils.sh" || { echo "Error: Cannot source yaml_utils.sh" >&2; exit 1; }
source "$SCAFFOLD_SCRIPT_DIR/colors.sh" || { echo "Error: Cannot source colors.sh" >&2; exit 1; }
source "$SCAFFOLD_SCRIPT_DIR/error.sh" || { echo "Error: Cannot source error.sh" >&2; exit 1; }
source "$SCAFFOLD_SCRIPT_DIR/metadata_generator.sh" || { echo "Error: Cannot source metadata_generator.sh" >&2; exit 1; }

# Initialize colors
init_colors 2>/dev/null || true

# ============================================================================
# GLOBAL VARIABLES
# ============================================================================

# Track created directories and files during scaffold generation
# Using space-separated strings for bash 3.2 compatibility
SCAFFOLD_CREATED_DIRS=""
SCAFFOLD_CREATED_FILES=""
SCAFFOLD_BASE_PATH=""
SCAFFOLD_CONFIG_FILE=""

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

# _log_scaffold_message() - Log a message with appropriate formatting
# Usage: _log_scaffold_message "[PREFIX]" "message"
# Arguments:
#   prefix: Message prefix (e.g., "mkdir", "create", "skip")
#   message: Message to log
_log_scaffold_message() {
  local prefix="$1"
  local message="$2"
  
  case "$prefix" in
    "mkdir"|"create")
      echo "${C_GREEN}✓${C_RESET} $prefix: $message" >&2
      ;;
    "skip"|"warn")
      echo "${C_YELLOW}⚠${C_RESET} $prefix: $message" >&2
      ;;
    "error"|"fail")
      echo "${C_RED}✗${C_RESET} $prefix: $message" >&2
      ;;
    *)
      echo "  $prefix: $message" >&2
      ;;
  esac
}

# ============================================================================
# DIRECTORY CREATION FUNCTIONS
# ============================================================================

# create_directory_safe() - Create a directory with transaction tracking
# Usage: create_directory_safe "$path" [permissions]
# Arguments:
#   path: Directory path to create
#   permissions: Optional permissions (default: 755)
# Returns: 0 on success, 1 on failure
create_directory_safe() {
  local dir_path="$1"
  local perms="${2:-755}"
  
  # Skip if directory already exists
  if [ -d "$dir_path" ]; then
    _log_scaffold_message "skip" "Directory already exists: $dir_path"
    return 0
  fi
  
  # Create directory
  if ! mkdir -p "$dir_path" 2>/dev/null; then
    _log_scaffold_message "error" "Failed to create directory: $dir_path"
    return 1
  fi
  
  # Set permissions
  if ! chmod "$perms" "$dir_path" 2>/dev/null; then
    _log_scaffold_message "warn" "Failed to set permissions $perms on $dir_path"
    # Continue anyway - directory was created
  fi
  
  # Log operation in transaction
  if [ "$TRANSACTION_ACTIVE" -eq 1 ]; then
    transaction_log_operation "mkdir" "$dir_path" "$perms" || return 1
    transaction_record_mkdir_rollback "$dir_path" || return 1
  fi
  
  _log_scaffold_message "mkdir" "$dir_path"
  SCAFFOLD_CREATED_DIRS+=("$dir_path")
  return 0
}

# create_file_safe() - Create a file with transaction tracking
# Usage: create_file_safe "$path" "$content" [permissions]
# Arguments:
#   path: File path to create
#   content: Content to write to file
#   permissions: Optional permissions (default: 644)
# Returns: 0 on success, 1 on failure
create_file_safe() {
  local file_path="$1"
  local content="$2"
  local perms="${3:-644}"
  
  # Create parent directory if needed
  local parent_dir
  parent_dir="$(dirname "$file_path")"
  
  if [ ! -d "$parent_dir" ]; then
    create_directory_safe "$parent_dir" || return 1
  fi
  
  # Skip if file already exists
  if [ -f "$file_path" ]; then
    _log_scaffold_message "skip" "File already exists: $file_path"
    return 0
  fi
  
  # Write file
  if ! echo "$content" > "$file_path" 2>/dev/null; then
    _log_scaffold_message "error" "Failed to create file: $file_path"
    return 1
  fi
  
  # Set permissions
  if ! chmod "$perms" "$file_path" 2>/dev/null; then
    _log_scaffold_message "warn" "Failed to set permissions $perms on $file_path"
  fi
  
  # Log operation in transaction
  if [ "$TRANSACTION_ACTIVE" -eq 1 ]; then
    transaction_log_operation "touch" "$file_path" "$perms" || return 1
    transaction_record_file_rollback "$file_path" || return 1
  fi
  
  _log_scaffold_message "create" "$file_path"
  SCAFFOLD_CREATED_FILES+=("$file_path")
  return 0
}

# ============================================================================
# SCAFFOLD GENERATION CORE LOGIC (T059-T062)
# ============================================================================

# scaffold_parent_directories() - Create parent directories from config
# Usage: scaffold_parent_directories "$config_file" "$base_path"
# Implements T060: parent directory creation with robust YAML parsing
# Arguments:
#   config_file: Path to YAML config file
#   base_path: Base path where directories will be created
# Returns: 0 on success, 1 on failure
scaffold_parent_directories() {
  local config_file="$1"
  local base_path="$2"
  local parent_count=0
  local failed_count=0
  
  _log_scaffold_message "info" "Creating parent directories..."
  
  # Load config and extract parent directories section
  local parent_dirs_section
  parent_dirs_section=$(load_config "$config_file" | grep -A 200 "parent_directories:" || true)
  
  if [ -z "$parent_dirs_section" ]; then
    _log_scaffold_message "warn" "No parent directories in config"
    return 0
  fi
  
  # Parse YAML structure for parent directories
  # Format:
  # parent_directories:
  #   - name: "directory_name"
  #     description: "Purpose"
  #     integrity: true|false
  #     project_scope: "world"|"project"
  
  local dir_name=""
  local dir_description=""
  local dir_integrity="false"
  local in_parent_section=0
  
  while IFS= read -r line; do
    # Exit parent_directories section when we hit next top-level key
    if [[ "$line" =~ ^[a-zA-Z_]+: ]] && [[ ! "$line" =~ ^[[:space:]] ]]; then
      if [ "$in_parent_section" -eq 1 ] && [ -n "$dir_name" ]; then
        # Process last directory entry
        local dir_path="${base_path}/${dir_name}"
        if create_directory_safe "$dir_path"; then
          ((parent_count++))
        else
          _log_scaffold_message "error" "Failed to create parent directory: $dir_name"
          ((failed_count++))
        fi
      fi
      break
    fi
    
    # Skip comments and empty lines
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ -z "${line// }" ]] && continue
    
    # Detect parent_directories section start
    if [[ "$line" =~ ^parent_directories: ]]; then
      in_parent_section=1
      continue
    fi
    
    # Skip if not in parent section
    [ "$in_parent_section" -eq 0 ] && continue
    
    # Parse directory entries (2-space indented items)
    if [[ "$line" =~ ^[[:space:]]{2}-[[:space:]]+name:[[:space:]]+\"?([^\"]+)\"? ]]; then
      # First, process previous directory if exists
      if [ -n "$dir_name" ]; then
        local dir_path="${base_path}/${dir_name}"
        if create_directory_safe "$dir_path"; then
          ((parent_count++))
        else
          _log_scaffold_message "error" "Failed to create parent directory: $dir_name"
          ((failed_count++))
        fi
      fi
      
      # Start new directory entry
      dir_name="${BASH_REMATCH[1]}"
      dir_description=""
      dir_integrity="false"
    
    # Parse description field
    elif [[ "$line" =~ ^[[:space:]]{4}description:[[:space:]]+\"?(.+?)\"?$ ]]; then
      dir_description="${BASH_REMATCH[1]}"
    
    # Parse integrity flag
    elif [[ "$line" =~ ^[[:space:]]{4}integrity:[[:space:]]+(true|false) ]]; then
      dir_integrity="${BASH_REMATCH[1]}"
    fi
  done <<< "$parent_dirs_section"
  
  # Process the last directory entry if exists
  if [ -n "$dir_name" ]; then
    local dir_path="${base_path}/${dir_name}"
    if create_directory_safe "$dir_path"; then
      ((parent_count++))
    else
      _log_scaffold_message "error" "Failed to create parent directory: $dir_name"
      ((failed_count++))
    fi
  fi
  
  # Report results
  if [ "$failed_count" -gt 0 ]; then
    _log_scaffold_message "error" "Parent directory creation: $parent_count succeeded, $failed_count failed"
    return 1
  fi
  
  _log_scaffold_message "info" "Parent directories created: $parent_count"
  return 0
}

# scaffold_subdirectories() - Create subdirectories with nesting support
# Usage: scaffold_subdirectories "$config_file" "$base_path"
# Implements T061: subdirectory creation with nesting
# Implements T062: children directory traversal
# Arguments:
#   config_file: Path to YAML config file
#   base_path: Base path where directories will be created
# Returns: 0 on success, 1 on failure
scaffold_subdirectories() {
  local config_file="$1"
  local base_path="$2"
  local subdir_count=0
  local failed_count=0
  
  _log_scaffold_message "info" "Creating subdirectories with nesting..."
  
  # Load config and extract subdirectories section
  local subdirs_section
  subdirs_section=$(load_config "$config_file" | grep -A 500 "subdirectories:" || true)
  
  if [ -z "$subdirs_section" ]; then
    _log_scaffold_message "warn" "No subdirectories in config"
    return 0
  fi
  
  # Parse YAML structure for subdirectories
  # Format:
  # subdirectories:
  #   - parent: "parent_dir_name"
  #     description: "Description"
  #     structure:
  #       - name: "subdir_name"
  #         type: "folder"
  #         description: "Purpose"
  #         children:
  #           - name: "nested_dir"
  #             description: "Nested purpose"
  
  local parent_dir=""
  local current_subdir=""
  local current_level=0
  local subdir_count=0
  
  # Helper function to process a directory entry recursively
  # Arguments: parent_path, directory_name, indent_level
  _create_nested_dir() {
    local parent_path="$1"
    local dir_name="$2"
    local indent_level="${3:-0}"
    
    local full_path="${parent_path}/${dir_name}"
    
    # Create the directory
    if ! create_directory_safe "$full_path"; then
      _log_scaffold_message "error" "Failed to create subdirectory: $dir_name at $parent_path"
      return 1
    fi
    
    ((subdir_count++))
    return 0
  }
  
  # Parse subdirectories section line by line
  while IFS= read -r line; do
    # Exit subdirectories section when we hit next top-level key
    if [[ "$line" =~ ^[a-zA-Z_]+: ]] && [[ ! "$line" =~ ^[[:space:]] ]]; then
      break
    fi
    
    # Skip comments and empty lines
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ -z "${line// }" ]] && continue
    
    # Skip the section header line
    [[ "$line" =~ ^subdirectories: ]] && continue
    
    # Parse parent directory
    if [[ "$line" =~ ^[[:space:]]{2}-[[:space:]]+parent:[[:space:]]+\"?([^\"]+)\"? ]]; then
      parent_dir="${BASH_REMATCH[1]}"
      current_subdir=""
      continue
    fi
    
    # Parse subdirectory names at level 1 (structure items)
    if [[ "$line" =~ ^[[:space:]]{6}-[[:space:]]+name:[[:space:]]+\"?([^\"]+)\"? ]]; then
      current_subdir="${BASH_REMATCH[1]}"
      
      if [ -n "$parent_dir" ] && [ -n "$current_subdir" ]; then
        local subdir_path="${base_path}/${parent_dir}/${current_subdir}"
        if _create_nested_dir "${base_path}/${parent_dir}" "$current_subdir" "1"; then
          # Successfully created, continue to process potential children
          true
        else
          ((failed_count++))
        fi
      fi
      continue
    fi
    
    # Parse children directories (nested under current subdirectory)
    # This handles the "children:" section with items indented further
    if [[ "$line" =~ ^[[:space:]]{10}-[[:space:]]+name:[[:space:]]+\"?([^\"]+)\"? ]]; then
      local child_name="${BASH_REMATCH[1]}"
      
      if [ -n "$parent_dir" ] && [ -n "$current_subdir" ] && [ -n "$child_name" ]; then
        local child_path="${base_path}/${parent_dir}/${current_subdir}/${child_name}"
        if _create_nested_dir "${base_path}/${parent_dir}/${current_subdir}" "$child_name" "2"; then
          # Successfully created child directory
          true
        else
          ((failed_count++))
        fi
      fi
      continue
    fi
    
    # Parse deeply nested children (3+ levels of nesting)
    if [[ "$line" =~ ^[[:space:]]{14}-[[:space:]]+name:[[:space:]]+\"?([^\"]+)\"? ]]; then
      local nested_child_name="${BASH_REMATCH[1]}"
      
      if [ -n "$parent_dir" ] && [ -n "$current_subdir" ]; then
        # For very deep nesting, construct the full path
        local nested_path="${base_path}/${parent_dir}/${current_subdir}/${nested_child_name}"
        # Note: This is a simplified implementation that handles 3+ levels
        # A more complete implementation would track the nesting hierarchy
        if _create_nested_dir "${base_path}/${parent_dir}/${current_subdir}" "$nested_child_name" "3"; then
          true
        else
          ((failed_count++))
        fi
      fi
      continue
    fi
  done <<< "$subdirs_section"
  
  # Report results
  if [ "$failed_count" -gt 0 ]; then
    _log_scaffold_message "error" "Subdirectory creation: $subdir_count succeeded, $failed_count failed"
    return 1
  fi
  
  _log_scaffold_message "info" "Subdirectories created: $subdir_count"
  return 0
}

# scaffold_integrity_directories() - Create .integrity/ directories at required levels
# Part of metadata generation (related to T064-T068)
# Usage: scaffold_integrity_directories "$base_path" "$level"
# Arguments:
#   base_path: Base path for .integrity/ directory
#   level: Level of integrity dir (workspace, world, project, study)
# Returns: 0 on success, 1 on failure
scaffold_integrity_directories() {
  local base_path="$1"
  local level="${2:-workspace}"
  
  local integrity_path="${base_path}/.integrity"
  
  # Create .integrity directory with restricted permissions (700)
  if ! mkdir -p "$integrity_path" 2>/dev/null; then
    _log_scaffold_message "error" "Failed to create .integrity directory"
    return 1
  fi
  
  # Set restricted permissions: 700 (rwx------)
  if ! chmod 700 "$integrity_path" 2>/dev/null; then
    _log_scaffold_message "warn" "Failed to set permissions 700 on .integrity"
  fi
  
  # Log operation in transaction
  if [ "$TRANSACTION_ACTIVE" -eq 1 ]; then
    transaction_log_operation "mkdir" "$integrity_path" "700" || return 1
    transaction_record_mkdir_rollback "$integrity_path" || return 1
  fi
  
  _log_scaffold_message "mkdir" "$integrity_path (integrity - 700)"
  return 0
}

# ============================================================================
# METADATA GENERATION (T064-T068)
# ============================================================================

# generate_metadata_file() - Generate a metadata file in .integrity/ directory
# Part of T064-T068: Metadata generation at different levels
# Usage: generate_metadata_file "$integrity_path" "$filename" "$metadata_content"
# Arguments:
#   integrity_path: Path to .integrity/ directory
#   filename: Name of metadata file (e.g., "workspace.yaml")
#   metadata_content: YAML content for metadata
# Returns: 0 on success, 1 on failure
generate_metadata_file() {
  local integrity_path="$1"
  local filename="$2"
  local metadata_content="$3"
  
  local metadata_file="${integrity_path}/${filename}"
  
  # Create metadata file with restricted permissions (600)
  if ! echo "$metadata_content" > "$metadata_file" 2>/dev/null; then
    _log_scaffold_message "error" "Failed to create metadata file: $filename"
    return 1
  fi
  
  # Set restricted permissions: 600 (rw-------)
  if ! chmod 600 "$metadata_file" 2>/dev/null; then
    _log_scaffold_message "warn" "Failed to set permissions 600 on $filename"
  fi
  
  # Log operation in transaction
  if [ "$TRANSACTION_ACTIVE" -eq 1 ]; then
    transaction_log_operation "touch" "$metadata_file" "600" || return 1
    transaction_record_file_rollback "$metadata_file" || return 1
  fi
  
  _log_scaffold_message "create" "$metadata_file (metadata - 600)"
  return 0
}

# ============================================================================
# PERMISSIONS MANAGEMENT (T069-T073)
# ============================================================================

# set_permissions() - Set directory and file permissions for scaffold
# Implements T069-T073: Permission inheritance and restriction
# Usage: set_permissions "$base_path" ["restrict_integrity"]
# Arguments:
#   base_path: Base path to set permissions on
#   restrict_integrity: If "true", ensure .integrity/ is 700/600
# Returns: 0 on success, 1 on failure
set_permissions() {
  local base_path="$1"
  local restrict_integrity="${2:-true}"
  
  _log_scaffold_message "info" "Setting permissions..."
  
  # Set directory permissions to 755 (rwxr-xr-x) by default
  if ! find "$base_path" -type d -not -path "*/.integrity*" -exec chmod 755 {} + 2>/dev/null; then
    _log_scaffold_message "warn" "Failed to set directory permissions"
  else
    _log_scaffold_message "mkdir" "Set directory permissions: 755 (default)"
  fi
  
  # Set file permissions to 644 (rw-r--r--) by default
  if ! find "$base_path" -type f -not -path "*/.integrity*" -exec chmod 644 {} + 2>/dev/null; then
    _log_scaffold_message "warn" "Failed to set file permissions"
  else
    _log_scaffold_message "create" "Set file permissions: 644 (default)"
  fi
  
  # Restrict .integrity/ directories to 700 and files to 600
  if [ "$restrict_integrity" = "true" ]; then
    if find "$base_path" -path "*/.integrity" -type d -exec chmod 700 {} + 2>/dev/null; then
      _log_scaffold_message "mkdir" "Set .integrity/ directory permissions: 700"
    fi
    
    if find "$base_path" -path "*/.integrity/*" -type f -exec chmod 600 {} + 2>/dev/null; then
      _log_scaffold_message "create" "Set .integrity/ file permissions: 600"
    fi
  fi
  
  return 0
}

# ============================================================================
# ATOMIC COMMIT VALIDATION (T063)
# ============================================================================

# validate_scaffold_plan() - Validate scaffold operations before committing
# Implements T063: Atomic commit validation and pre-flight checks
# Usage: validate_scaffold_plan "$config_file" "$base_path"
# Performs pre-flight validation to ensure atomicity:
#   - Verifies base path is writable
#   - Validates config schema before any operations
#   - Checks for permission conflicts
#   - Ensures parent directories exist or can be created
#   - Validates transaction state is ready
# Arguments:
#   config_file: Path to YAML config file
#   base_path: Base path for scaffold creation
# Returns: 0 if validation passes, 1 if validation fails
validate_scaffold_plan() {
  local config_file="$1"
  local base_path="$2"
  
  # Validation Step 1: Config file exists and is readable
  if [ ! -f "$config_file" ]; then
    _log_scaffold_message "error" "Config file not readable: $config_file"
    return 1
  fi
  
  # Validation Step 2: Config schema is valid
  if ! validate_config_schema "$config_file" 2>/dev/null; then
    _log_scaffold_message "error" "Config schema validation failed: $config_file"
    return 1
  fi
  
  # Validation Step 3: Base path parent directory exists and is writable
  local base_parent
  base_parent="$(dirname "$base_path")"
  
  if [ ! -d "$base_parent" ]; then
    _log_scaffold_message "error" "Base parent directory does not exist: $base_parent"
    return 1
  fi
  
  if [ ! -w "$base_parent" ]; then
    _log_scaffold_message "error" "Base parent directory is not writable: $base_parent"
    return 1
  fi
  
  # Validation Step 4: If base path exists, it must be a directory and writable
  if [ -e "$base_path" ]; then
    if [ ! -d "$base_path" ]; then
      _log_scaffold_message "error" "Base path exists but is not a directory: $base_path"
      return 1
    fi
    if [ ! -w "$base_path" ]; then
      _log_scaffold_message "error" "Base path directory is not writable: $base_path"
      return 1
    fi
  fi
  
  # Validation Step 5: Check if .integrity path would cause conflicts
  local integrity_path="${base_path}/.integrity"
  if [ -e "$integrity_path" ] && [ ! -d "$integrity_path" ]; then
    _log_scaffold_message "error" ".integrity path exists but is not a directory: $integrity_path"
    return 1
  fi
  
  # Validation Step 6: Verify transaction system is available
  if ! transaction_init 2>/dev/null; then
    _log_scaffold_message "error" "Failed to initialize transaction system"
    return 1
  fi
  
  _log_scaffold_message "info" "Scaffold plan validation passed"
  return 0
}

# ============================================================================
# MAIN SCAFFOLD GENERATOR FUNCTION
# ============================================================================

# scaffold_generator() - Main scaffold generation function with atomic transaction support
# Implements T059-T063: Complete scaffold generation with atomicity
# Usage: scaffold_generator "$config_file" "$base_path" [--verbose]
# Arguments:
#   config_file: Path to YAML configuration file
#   base_path: Base path where to create scaffold
#   --verbose: Optional verbose output
# Returns: 0 on success, 1 on failure (with automatic rollback)
scaffold_generator() {
  local config_file="$1"
  local base_path="$2"
  local verbose="${3:-}"
  
  # Validate arguments
  if [ -z "$config_file" ] || [ -z "$base_path" ]; then
    _log_scaffold_message "error" "Missing required arguments: config_file and base_path"
    return 1
  fi
  
  # Store global state
  SCAFFOLD_CONFIG_FILE="$config_file"
  SCAFFOLD_BASE_PATH="$base_path"
  SCAFFOLD_CREATED_DIRS=()
  SCAFFOLD_CREATED_FILES=()
  
  # ATOMIC COMMIT VALIDATION (T063)
  # Pre-flight checks to ensure atomicity before any operations
  if ! validate_scaffold_plan "$config_file" "$base_path"; then
    _log_scaffold_message "error" "Scaffold plan validation failed - aborting"
    return 1
  fi
  
  # Begin atomic transaction
  if ! transaction_begin "scaffold_$(basename "$config_file" .yaml)" 2>/dev/null; then
    _log_scaffold_message "error" "Failed to initialize transaction"
    return 1
  fi
  
  # Execute scaffold generation steps
  _log_scaffold_message "info" "Generating scaffold for: $(basename "$config_file")"
  
  # Step 1: Create parent directories (T060)
  if ! scaffold_parent_directories "$config_file" "$base_path"; then
    _log_scaffold_message "error" "Parent directory creation failed - rolling back"
    transaction_rollback true 2>/dev/null || true
    return 1
  fi
  
  # Step 2: Create subdirectories with nesting (T061-T062)
  if ! scaffold_subdirectories "$config_file" "$base_path"; then
    _log_scaffold_message "error" "Subdirectory creation failed - rolling back"
    transaction_rollback true 2>/dev/null || true
    return 1
  fi
  
  # Step 3: Create .integrity/ directories (metadata prep)
  if ! scaffold_integrity_directories "$base_path" "world"; then
    _log_scaffold_message "error" "Integrity directory creation failed - rolling back"
    transaction_rollback true 2>/dev/null || true
    return 1
  fi
  
  # Step 4: Set permissions (T069-T073)
  if ! set_permissions "$base_path" "true"; then
    _log_scaffold_message "error" "Permission setting failed - rolling back"
    transaction_rollback true 2>/dev/null || true
    return 1
  fi
  
  # Step 5: Commit transaction atomically (T063)
  if ! transaction_commit true 2>/dev/null; then
    _log_scaffold_message "error" "Transaction commit failed - rolling back"
    transaction_rollback true 2>/dev/null || true
    return 1
  fi
  
  _log_scaffold_message "info" "Scaffold generation completed successfully"
  
  if [ -n "$verbose" ]; then
    echo ""
    echo "Scaffold Summary:"
    echo "  Base path: $base_path"
    echo "  Config file: $(basename "$config_file")"
    echo "  Directories created: ${#SCAFFOLD_CREATED_DIRS[@]}"
    echo "  Files created: ${#SCAFFOLD_CREATED_FILES[@]}"
  fi
  
  return 0
}

# ============================================================================
# PUBLIC API EXPORTS
# ============================================================================

# Export main function
export -f scaffold_generator
export -f validate_scaffold_plan
export -f create_directory_safe
export -f create_file_safe
export -f scaffold_parent_directories
export -f scaffold_subdirectories
export -f scaffold_integrity_directories
export -f generate_metadata_file
export -f set_permissions

# Export global variables
export SCAFFOLD_CREATED_DIRS
export SCAFFOLD_CREATED_FILES
export SCAFFOLD_BASE_PATH
export SCAFFOLD_CONFIG_FILE
