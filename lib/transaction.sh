#!/usr/bin/env bash
# Transaction Manager for DirForge Scaffold Generation (T056-T058)
# 
# Provides atomic transaction support for filesystem operations with full rollback capability.
# Implements transaction tracking (T057) and rollback mechanism (T058).
#
# Usage:
#   source lib/transaction.sh
#   transaction_begin "my_operation"
#   # Perform operations...
#   transaction_commit || transaction_rollback
#
# Exit Code: 0 on success, 1 on failure
#
# Constitution v1.0.22 Section IV.C: Scaffold Generation & Integration

set -euo pipefail

# ============================================================================
# TRANSACTION STATE MANAGEMENT
# ============================================================================

# Global transaction state variables
TRANSACTION_ACTIVE=0
TRANSACTION_ID=""
TRANSACTION_LOG_DIR=""
TRANSACTION_OPS_FILE=""
TRANSACTION_ROLLBACK_FILE=""
TRANSACTION_OP_COUNT=0

# ============================================================================
# TRANSACTION INITIALIZATION
# ============================================================================

# Initialize transaction system
# Usage: transaction_init
# Returns: 0 on success, 1 on failure
transaction_init() {
  # Set up transaction log directory if not already set
  if [ -z "$TRANSACTION_LOG_DIR" ]; then
    TRANSACTION_LOG_DIR="/tmp/dirforge_transactions_$$"
    mkdir -p "$TRANSACTION_LOG_DIR" || return 1
  fi
  return 0
}

# Begin a new transaction
# Usage: transaction_begin [transaction_name]
# Arguments:
#   transaction_name: Optional name for transaction (default: "default")
# Returns: 0 on success, 1 if transaction already active
transaction_begin() {
  local tx_name="${1:-default}"
  
  # Check if transaction already active
  if [ "$TRANSACTION_ACTIVE" -eq 1 ]; then
    echo "Error: Transaction already active (ID: $TRANSACTION_ID)" >&2
    return 1
  fi
  
  # Initialize transaction system
  transaction_init || return 1
  
  # Generate unique transaction ID
  TRANSACTION_ID="tx_${tx_name}_$$_$(date +%s%N)"
  TRANSACTION_OPS_FILE="$TRANSACTION_LOG_DIR/${TRANSACTION_ID}.ops"
  TRANSACTION_ROLLBACK_FILE="$TRANSACTION_LOG_DIR/${TRANSACTION_ID}.rollback"
  TRANSACTION_OP_COUNT=0
  TRANSACTION_ACTIVE=1
  
  # Create empty operation files
  touch "$TRANSACTION_OPS_FILE" "$TRANSACTION_ROLLBACK_FILE" || return 1
  
  return 0
}

# ============================================================================
# OPERATION TRACKING (T057)
# ============================================================================

# Log a filesystem operation for tracking
# Usage: transaction_log_operation "mkdir" "/path/to/dir"
# Arguments:
#   operation_type: Type of operation (mkdir, touch, write, chown, chmod, etc.)
#   target_path: Path to the resource being operated on
#   [additional_args]: Optional additional arguments for the operation
# Returns: 0 on success, 1 on failure
transaction_log_operation() {
  [ "$TRANSACTION_ACTIVE" -eq 1 ] || return 1
  
  local op_type="$1"
  local target_path="$2"
  shift 2
  local additional_args="$*"
  
  # Format: TYPE|PATH|ARGS|TIMESTAMP
  {
    echo "${op_type}|${target_path}|${additional_args}|$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
  } >> "$TRANSACTION_OPS_FILE" || return 1
  
  ((TRANSACTION_OP_COUNT++))
  return 0
}

# Record a rollback action for a mkdir operation
# Usage: transaction_record_mkdir_rollback "/path/to/dir"
# Returns: 0 on success
transaction_record_mkdir_rollback() {
  [ "$TRANSACTION_ACTIVE" -eq 1 ] || return 1
  
  local dir_path="$1"
  
  # Rollback action: rm -rf (remove directory and contents)
  echo "rm_rf|${dir_path}|" >> "$TRANSACTION_ROLLBACK_FILE" || return 1
  
  return 0
}

# Record a rollback action for a file write operation
# Usage: transaction_record_file_rollback "/path/to/file"
# Returns: 0 on success
transaction_record_file_rollback() {
  [ "$TRANSACTION_ACTIVE" -eq 1 ] || return 1
  
  local file_path="$1"
  
  # Rollback action: rm (remove file)
  echo "rm|${file_path}|" >> "$TRANSACTION_ROLLBACK_FILE" || return 1
  
  return 0
}

# Record a rollback action for a permission change
# Usage: transaction_record_chmod_rollback "/path/to/target" "original_perms"
# Returns: 0 on success
transaction_record_chmod_rollback() {
  [ "$TRANSACTION_ACTIVE" -eq 1 ] || return 1
  
  local target_path="$1"
  local original_perms="$2"
  
  # Rollback action: chmod to original permissions
  echo "chmod|${target_path}|${original_perms}" >> "$TRANSACTION_ROLLBACK_FILE" || return 1
  
  return 0
}

# Record a rollback action for an owner change
# Usage: transaction_record_chown_rollback "/path/to/target" "original_owner"
# Returns: 0 on success
transaction_record_chown_rollback() {
  [ "$TRANSACTION_ACTIVE" -eq 1 ] || return 1
  
  local target_path="$1"
  local original_owner="$2"
  
  # Rollback action: chown to original owner
  echo "chown|${target_path}|${original_owner}" >> "$TRANSACTION_ROLLBACK_FILE" || return 1
  
  return 0
}

# Get the current transaction operation count
# Usage: transaction_get_op_count
# Returns: Number of operations logged in current transaction
transaction_get_op_count() {
  echo "$TRANSACTION_OP_COUNT"
}

# Get the current transaction ID
# Usage: transaction_get_id
# Returns: Current transaction ID, empty if no active transaction
transaction_get_id() {
  [ "$TRANSACTION_ACTIVE" -eq 1 ] && echo "$TRANSACTION_ID" || echo ""
}

# ============================================================================
# TRANSACTION ROLLBACK (T058)
# ============================================================================

# Perform a complete rollback of all transaction operations
# Usage: transaction_rollback [verbose]
# Arguments:
#   verbose: Optional flag to show rollback details (default: false)
# Returns: 0 on success, 1 on failure
transaction_rollback() {
  [ "$TRANSACTION_ACTIVE" -eq 1 ] || {
    echo "Error: No active transaction to rollback" >&2
    return 1
  }
  
  local verbose="${1:-false}"
  local rollback_failed=0
  
  # Ensure rollback file exists
  [ -f "$TRANSACTION_ROLLBACK_FILE" ] || {
    echo "Error: Rollback file not found" >&2
    TRANSACTION_ACTIVE=0
    return 1
  }
  
  # Execute rollback actions in reverse order (LIFO)
  # Read operations and execute them backwards to undo changes
  if [ -s "$TRANSACTION_ROLLBACK_FILE" ]; then
    # Reverse the order of operations for proper rollback
    local -a rollback_ops
    while IFS= read -r line; do
      rollback_ops+=("$line")
    done < <(tail -r "$TRANSACTION_ROLLBACK_FILE" 2>/dev/null || sed '1!G;h;$!d' "$TRANSACTION_ROLLBACK_FILE")
    
    # Execute rollback operations
    for op_line in "${rollback_ops[@]}"; do
      IFS='|' read -r op_type op_path op_args <<< "$op_line"
      
      [ "$verbose" = "true" ] && echo "Rolling back: $op_type $op_path" >&2
      
      case "$op_type" in
        rm_rf)
          # Remove directory and contents
          if [ -e "$op_path" ]; then
            rm -rf "$op_path" || {
              echo "Warning: Failed to remove directory: $op_path" >&2
              rollback_failed=1
            }
          fi
          ;;
        rm)
          # Remove file
          if [ -e "$op_path" ]; then
            rm -f "$op_path" || {
              echo "Warning: Failed to remove file: $op_path" >&2
              rollback_failed=1
            }
          fi
          ;;
        chmod)
          # Restore permissions
          if [ -e "$op_path" ]; then
            chmod "$op_args" "$op_path" || {
              echo "Warning: Failed to restore permissions on: $op_path" >&2
              rollback_failed=1
            }
          fi
          ;;
        chown)
          # Restore owner
          if [ -e "$op_path" ]; then
            chown "$op_args" "$op_path" || {
              echo "Warning: Failed to restore owner on: $op_path" >&2
              rollback_failed=1
            }
          fi
          ;;
        *)
          echo "Warning: Unknown rollback operation: $op_type" >&2
          ;;
      esac
    done
  fi
  
  # Clean up transaction files
  rm -f "$TRANSACTION_OPS_FILE" "$TRANSACTION_ROLLBACK_FILE" || true
  
  # Reset transaction state
  TRANSACTION_ACTIVE=0
  TRANSACTION_ID=""
  TRANSACTION_OP_COUNT=0
  
  return $rollback_failed
}

# ============================================================================
# TRANSACTION COMMIT
# ============================================================================

# Validate transaction and commit (mark as complete)
# Usage: transaction_validate
# Returns: 0 if transaction is valid, 1 if validation fails
transaction_validate() {
  [ "$TRANSACTION_ACTIVE" -eq 1 ] || {
    echo "Error: No active transaction to validate" >&2
    return 1
  }
  
  # Check that operation and rollback files exist
  [ -f "$TRANSACTION_OPS_FILE" ] || {
    echo "Error: Transaction operation file not found" >&2
    return 1
  }
  
  [ -f "$TRANSACTION_ROLLBACK_FILE" ] || {
    echo "Error: Transaction rollback file not found" >&2
    return 1
  }
  
  return 0
}

# Commit transaction (finalize, no rollback possible after this)
# Usage: transaction_commit [verbose]
# Arguments:
#   verbose: Optional flag to show commit details (default: false)
# Returns: 0 on success, 1 on failure
transaction_commit() {
  [ "$TRANSACTION_ACTIVE" -eq 1 ] || {
    echo "Error: No active transaction to commit" >&2
    return 1
  }
  
  local verbose="${1:-false}"
  
  # Validate before committing
  transaction_validate || return 1
  
  # Log commit timestamp
  [ "$verbose" = "true" ] && echo "Committing transaction: $TRANSACTION_ID (${TRANSACTION_OP_COUNT} ops)" >&2
  
  # Clean up transaction files to mark as committed
  rm -f "$TRANSACTION_OPS_FILE" "$TRANSACTION_ROLLBACK_FILE" || return 1
  
  # Reset transaction state
  TRANSACTION_ACTIVE=0
  TRANSACTION_ID=""
  TRANSACTION_OP_COUNT=0
  
  return 0
}

# Abort transaction (cleanup without committing)
# Usage: transaction_abort [verbose]
# Arguments:
#   verbose: Optional flag to show abort details (default: false)
# Returns: 0 on success
transaction_abort() {
  local verbose="${1:-false}"
  
  [ "$verbose" = "true" ] && echo "Aborting transaction: $TRANSACTION_ID" >&2
  
  # Remove transaction files without executing rollback actions
  rm -f "$TRANSACTION_OPS_FILE" "$TRANSACTION_ROLLBACK_FILE" || true
  
  # Reset transaction state
  TRANSACTION_ACTIVE=0
  TRANSACTION_ID=""
  TRANSACTION_OP_COUNT=0
  
  return 0
}

# ============================================================================
# TRANSACTION STATUS & INSPECTION
# ============================================================================

# Check if a transaction is currently active
# Usage: transaction_is_active
# Returns: 0 if transaction active, 1 if not
transaction_is_active() {
  [ "$TRANSACTION_ACTIVE" -eq 1 ] && return 0 || return 1
}

# Get detailed transaction status
# Usage: transaction_get_status
# Returns: Transaction status as JSON-like format (for inspection)
transaction_get_status() {
  if [ "$TRANSACTION_ACTIVE" -eq 1 ]; then
    cat <<EOF
{
  "active": true,
  "id": "$TRANSACTION_ID",
  "operations": $TRANSACTION_OP_COUNT,
  "ops_file": "$TRANSACTION_OPS_FILE",
  "rollback_file": "$TRANSACTION_ROLLBACK_FILE"
}
EOF
  else
    cat <<EOF
{
  "active": false,
  "id": "",
  "operations": 0
}
EOF
  fi
}

# Display transaction log (debugging)
# Usage: transaction_show_log
# Returns: 0 if log displayed, 1 if no active transaction
transaction_show_log() {
  [ "$TRANSACTION_ACTIVE" -eq 1 ] || {
    echo "No active transaction" >&2
    return 1
  }
  
  echo "=== Transaction Operations Log ===" >&2
  echo "Transaction ID: $TRANSACTION_ID" >&2
  echo "Operations: $TRANSACTION_OP_COUNT" >&2
  echo "" >&2
  
  if [ -s "$TRANSACTION_OPS_FILE" ]; then
    cat "$TRANSACTION_OPS_FILE" >&2
  else
    echo "(no operations)" >&2
  fi
  
  return 0
}

# Display rollback plan (debugging)
# Usage: transaction_show_rollback_plan
# Returns: 0 if plan displayed, 1 if no active transaction
transaction_show_rollback_plan() {
  [ "$TRANSACTION_ACTIVE" -eq 1 ] || {
    echo "No active transaction" >&2
    return 1
  }
  
  echo "=== Transaction Rollback Plan ===" >&2
  echo "Transaction ID: $TRANSACTION_ID" >&2
  echo "" >&2
  
  if [ -s "$TRANSACTION_ROLLBACK_FILE" ]; then
    cat "$TRANSACTION_ROLLBACK_FILE" >&2
  else
    echo "(no rollback actions)" >&2
  fi
  
  return 0
}

# ============================================================================
# CLEANUP & UTILITIES
# ============================================================================

# Clean up all transaction temporary files
# Usage: transaction_cleanup_all
# Returns: 0 on success
transaction_cleanup_all() {
  if [ -n "$TRANSACTION_LOG_DIR" ] && [ -d "$TRANSACTION_LOG_DIR" ]; then
    rm -rf "$TRANSACTION_LOG_DIR" || true
  fi
  
  TRANSACTION_ACTIVE=0
  TRANSACTION_ID=""
  TRANSACTION_LOG_DIR=""
  TRANSACTION_OPS_FILE=""
  TRANSACTION_ROLLBACK_FILE=""
  TRANSACTION_OP_COUNT=0
  
  return 0
}

# Register cleanup trap for script exit
# Usage: transaction_register_cleanup_trap
# Ensures rollback occurs if script exits unexpectedly
transaction_register_cleanup_trap() {
  trap 'transaction_is_active && transaction_rollback true' EXIT
}

# ============================================================================
# COMPATIBILITY & INITIALIZATION
# ============================================================================

# Initialize transaction system on library load
transaction_init || true

# Export functions for use in other scripts
export -f transaction_init
export -f transaction_begin
export -f transaction_log_operation
export -f transaction_record_mkdir_rollback
export -f transaction_record_file_rollback
export -f transaction_record_chmod_rollback
export -f transaction_record_chown_rollback
export -f transaction_get_op_count
export -f transaction_get_id
export -f transaction_rollback
export -f transaction_validate
export -f transaction_commit
export -f transaction_abort
export -f transaction_is_active
export -f transaction_get_status
export -f transaction_show_log
export -f transaction_show_rollback_plan
export -f transaction_cleanup_all
export -f transaction_register_cleanup_trap
