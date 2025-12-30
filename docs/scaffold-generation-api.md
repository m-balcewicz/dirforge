# Scaffold Generation API Reference

**Version:** 1.0.22  
**Components:** lib/scaffold_generator.sh, lib/metadata_generator.sh, lib/transaction.sh  
**Last Updated:** 2025-12-30

---

## Table of Contents

1. [Scaffold Generator API](#scaffold-generator-api)
2. [Metadata Generator API](#metadata-generator-api)
3. [Transaction Manager API](#transaction-manager-api)
4. [Permission Management](#permission-management)
5. [Error Handling](#error-handling)
6. [Usage Examples](#usage-examples)
7. [Atomicity Guarantees](#atomicity-guarantees)

---

## Scaffold Generator API

### generate_scaffold()

Create a complete directory structure from a configuration.

**Signature:**
```bash
generate_scaffold(base_path, config_file) → exit_code
```

**Parameters:**
- `base_path` (string): Root directory path for scaffold
- `config_file` (string): YAML configuration file path

**Returns:**
- Exit code 0: Success
- Exit code 1: Error (partially created directories rolled back)

**Behavior:**
- Validates configuration
- Creates parent directories
- Creates subdirectories recursively
- Generates metadata at all levels
- Sets permissions (755 dirs, 644 files, 700/600 .integrity/)
- Uses atomic transactions (all-or-nothing)

**Example:**
```bash
source "${REPO_ROOT}/lib/scaffold_generator.sh"

# Generate CODING_WORLD scaffold
if generate_scaffold "/workspace/coding" \
    "templates/world-configs/coding.world.yaml"; then
    echo "Scaffold created successfully"
else
    echo "Scaffold generation failed (rolled back)" >&2
    exit 1
fi
```

### generate_workspace_metadata()

Create workspace-level .integrity/workspace.yaml.

**Signature:**
```bash
generate_workspace_metadata(integrity_dir) → exit_code
```

**Parameters:**
- `integrity_dir` (string): Path to .integrity/ directory

**Generates:**
```yaml
workspace_id: <uuid>
created_by: ${USER}
created_at: ${DATE}
constitution_version: 1.0.22
schema_version: 1.0
```

**Returns:**
- Exit code 0: Success
- Exit code 1: Error (permission denied, disk full, etc.)

**File Location:**
```
workspace/
└── .integrity/
    └── workspace.yaml (600)
```

**Example:**
```bash
source "${REPO_ROOT}/lib/metadata_generator.sh"

mkdir -p /workspace/.integrity
chmod 700 /workspace/.integrity

if generate_workspace_metadata "/workspace/.integrity"; then
    echo "Workspace metadata created"
else
    echo "Failed to create metadata" >&2
    exit 1
fi
```

### generate_world_metadata()

Create world-level .integrity/world.yaml.

**Signature:**
```bash
generate_world_metadata(integrity_dir, world_name, world_type) → exit_code
```

**Parameters:**
- `integrity_dir` (string): Path to .integrity/ directory
- `world_name` (string): Name of world (usually matches directory)
- `world_type` (string): Type (CODING_WORLD, RESEARCH_WORLD, etc.)

**Generates:**
```yaml
world_type: ${world_type}
world_name: ${world_name}
created_by: ${USER}
created_at: ${DATE}
```

**Returns:**
- Exit code 0: Success
- Exit code 1: Error

**File Location:**
```
workspace/coding/
├── .integrity/
│   └── world.yaml (600)
└── ...directories...
```

**Example:**
```bash
generate_world_metadata "/workspace/coding/.integrity" \
    "coding" "CODING_WORLD"
```

### generate_project_metadata()

Create project-level .integrity/project.yaml.

**Signature:**
```bash
generate_project_metadata(integrity_dir, project_name) → exit_code
```

**Parameters:**
- `integrity_dir` (string): Path to project/.integrity/ directory
- `project_name` (string): Name of project

**Generates:**
```yaml
project_name: ${project_name}
parent_world: <world_type>
created_by: ${USER}
created_at: ${DATE}
```

**Returns:**
- Exit code 0: Success
- Exit code 1: Error

**File Location:**
```
workspace/coding/project1/
├── .integrity/
│   └── project.yaml (600)
└── ...files...
```

**Example:**
```bash
generate_project_metadata "/workspace/coding/python/.integrity" \
    "python"
```

### generate_study_metadata()

Create study-level .integrity/study.yaml (RESEARCH_WORLD only).

**Signature:**
```bash
generate_study_metadata(integrity_dir, study_name, project_name) → exit_code
```

**Parameters:**
- `integrity_dir` (string): Path to study/.integrity/ directory
- `study_name` (string): Name of study
- `project_name` (string): Name of parent project

**Generates:**
```yaml
study_name: ${study_name}
parent_project: ${project_name}
created_by: ${USER}
created_at: ${DATE}
```

**Returns:**
- Exit code 0: Success
- Exit code 1: Error

**File Location:**
```
workspace/research/project1/study1/
├── .integrity/
│   └── study.yaml (600)
└── ...files...
```

**Example:**
```bash
generate_study_metadata "/workspace/research/proj1/study1/.integrity" \
    "study1" "proj1"
```

---

## Metadata Generator API

### Metadata File Format

**All metadata files are YAML with restricted permissions (600):**

**Workspace Metadata:**
```yaml
workspace_id: f47ac10b-58cc-4372-a567-0e02b2c3d479
created_by: martin
created_at: 2025-12-30T21:35:00Z
constitution_version: 1.0.22
schema_version: 1.0
```

**World Metadata:**
```yaml
world_type: CODING_WORLD
world_name: coding
created_by: martin
created_at: 2025-12-30T21:35:00Z
```

**Project Metadata:**
```yaml
project_name: python
parent_world: CODING_WORLD
created_by: martin
created_at: 2025-12-30T21:35:00Z
```

**Study Metadata:**
```yaml
study_name: study1
parent_project: research_project
created_by: martin
created_at: 2025-12-30T21:35:00Z
```

### Metadata Hierarchy

```
Workspace Level:
  workspace/.integrity/workspace.yaml

World Level:
  workspace/world_name/.integrity/world.yaml

Project Level:
  workspace/world_name/project_name/.integrity/project.yaml

Study Level (RESEARCH_WORLD only):
  workspace/world_name/project_name/study_name/.integrity/study.yaml
```

---

## Transaction Manager API

### transaction_begin()

Start a new transaction.

**Signature:**
```bash
transaction_begin() → exit_code
```

**Returns:**
- Exit code 0: Success

**Behavior:**
- Initializes transaction state
- Creates empty operation log
- Prepares for rollback support

**Example:**
```bash
source "${REPO_ROOT}/lib/transaction.sh"

transaction_begin
# Perform operations
mkdir /workspace/test
transaction_commit
```

### transaction_add()

Log a filesystem operation for potential rollback.

**Signature:**
```bash
transaction_add(operation, args...) → exit_code
```

**Parameters:**
- `operation` (string): Type of operation
  - `mkdir` - Create directory
  - `touch` - Create file
  - `chmod` - Change permissions
  - `chown` - Change ownership
- `args...` (strings): Operation-specific arguments

**Returns:**
- Exit code 0: Operation logged
- Exit code 1: Invalid operation

**Supported Operations:**

```bash
# Create directory
transaction_add mkdir "/path/to/dir"

# Create file
transaction_add touch "/path/to/file"

# Change permissions
transaction_add chmod "755" "/path/to/dir"

# Change ownership
transaction_add chown "user:group" "/path/to/dir"
```

**Example:**
```bash
transaction_begin

# Log operations (don't execute yet)
transaction_add mkdir "/workspace/test"
transaction_add touch "/workspace/test/file"
transaction_add chmod "755" "/workspace/test"

# Execute all
transaction_commit
```

### transaction_commit()

Execute all logged operations atomically.

**Signature:**
```bash
transaction_commit() → exit_code
```

**Returns:**
- Exit code 0: All operations succeeded
- Exit code 1: Operation failed (transaction rolled back)

**Behavior:**
- Executes all logged operations
- On any failure, rolls back all changes
- Leaves filesystem in original state on error
- All-or-nothing semantics

**Example:**
```bash
transaction_begin
transaction_add mkdir "/workspace/a"
transaction_add mkdir "/workspace/b"
transaction_add mkdir "/workspace/c"

if ! transaction_commit; then
    echo "Transaction failed - all changes rolled back"
    exit 1
fi

echo "All directories created successfully"
```

### transaction_rollback()

Manually rollback all logged operations.

**Signature:**
```bash
transaction_rollback() → exit_code
```

**Returns:**
- Exit code 0: Rollback succeeded
- Exit code 1: Rollback partial (some files couldn't be removed)

**Behavior:**
- Reverses all operations in LIFO order
- Removes created directories and files
- Restores original permissions
- Called automatically on commit failure

**Example:**
```bash
transaction_begin
transaction_add mkdir "/workspace/test"

# Something went wrong - undo everything
transaction_rollback

# Filesystem unchanged
```

---

## Permission Management

### set_permissions()

Set directory and file permissions.

**Signature:**
```bash
set_permissions(path, mode) → exit_code
```

**Parameters:**
- `path` (string): Directory or file path
- `mode` (string): Octal permission mode (755, 644, 700, 600)

**Returns:**
- Exit code 0: Success
- Exit code 1: Permission denied or invalid path

**Behavior:**
- Uses `chmod` to set permissions
- Validates mode is octal
- Handles symbolic modes (not recommended)

**Default Modes:**
```bash
set_permissions "/workspace/coding" 755        # rwxr-xr-x
set_permissions "/workspace/coding/.integrity" 700  # rwx------
set_permissions "/workspace/file.txt" 644      # rw-r--r--
set_permissions "/workspace/secret" 600        # rw-------
```

**Example:**
```bash
# Create directory with permissions
mkdir /workspace/coding
set_permissions /workspace/coding 755

# Create .integrity with restricted permissions
mkdir /workspace/coding/.integrity
set_permissions /workspace/coding/.integrity 700
```

### Permission Inheritance

**Default Behavior:**
```
Parent directory: 755 (rwxr-xr-x)
  ↓
Child directory: 755 (rwxr-xr-x) - inherited
  ↓
.integrity/: 700 (rwx------) - explicit override
```

**Override Example:**
```bash
# Create with default permission
mkdir /workspace/test
set_permissions /workspace/test 755  # Default

# Override to more restrictive
set_permissions /workspace/test 700  # Owner only
```

---

## Error Handling

### Common Errors

**Permission Denied:**
```
Error: Cannot create /workspace/test: Permission denied
Cause: Insufficient permissions on parent directory
Fix: Check parent directory permissions or run with sudo
```

**No Space Left:**
```
Error: Cannot create /workspace/test: No space left on device
Cause: Disk full
Fix: Free up disk space and retry
```

**Invalid Configuration:**
```
Error: Invalid configuration: Missing required field 'world.type'
Cause: Config file doesn't conform to schema
Fix: Run 'dirforge validate-config <file>' for details
```

**Transaction Rollback:**
```
Error: mkdir /workspace/b failed: File exists
Rolling back all operations...
Cause: Unexpected state or concurrent modification
Fix: Check for conflicting operations or concurrent access
```

### Error Recovery

**Automatic Rollback:**
```bash
transaction_begin
transaction_add mkdir "/workspace/a"
transaction_add mkdir "/workspace/a"  # Duplicate - will fail

if ! transaction_commit; then
    echo "Transaction failed"
    # Both mkdir operations rolled back
    # Filesystem unchanged
fi
```

**Manual Recovery:**
```bash
transaction_begin

# Do some operations
transaction_add mkdir "/workspace/test"

# Error handling
if some_error; then
    transaction_rollback  # Manual rollback
    exit 1
fi

transaction_commit
```

---

## Usage Examples

### Simple Scaffold Generation

```bash
#!/bin/bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

source "${REPO_ROOT}/lib/scaffold_generator.sh"
source "${REPO_ROOT}/lib/config_utils.sh"

# Load config
if ! load_config "CODING_WORLD"; then
    echo "Failed to load config" >&2
    exit 1
fi

# Generate scaffold
config_path=$(infer_config_path "CODING_WORLD")
if ! generate_scaffold "/workspace" "$config_path"; then
    echo "Failed to generate scaffold" >&2
    exit 1
fi

echo "Scaffold created at /workspace"
```

### Transaction with Manual Control

```bash
#!/bin/bash

source "${REPO_ROOT}/lib/transaction.sh"

transaction_begin

# Log operations
transaction_add mkdir "/workspace/a"
transaction_add mkdir "/workspace/b"
transaction_add mkdir "/workspace/c"
transaction_add chmod "755" "/workspace/a"

# Execute atomically
if ! transaction_commit; then
    echo "Failed to create directories" >&2
    # All rolled back automatically
    exit 1
fi

echo "All directories created successfully"
```

### Metadata Generation

```bash
#!/bin/bash

source "${REPO_ROOT}/lib/metadata_generator.sh"
source "${REPO_ROOT}/lib/transaction.sh"

# Create workspace
mkdir -p /workspace/.integrity
chmod 700 /workspace/.integrity

# Generate all metadata
transaction_begin

if ! generate_workspace_metadata "/workspace/.integrity"; then
    transaction_rollback
    exit 1
fi

if ! generate_world_metadata "/workspace/coding/.integrity" \
        "coding" "CODING_WORLD"; then
    transaction_rollback
    exit 1
fi

if ! transaction_commit; then
    echo "Failed to generate metadata" >&2
    exit 1
fi

echo "Metadata created successfully"
```

### Complete Scaffold with Error Handling

```bash
#!/bin/bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

source "${REPO_ROOT}/lib/scaffold_generator.sh"
source "${REPO_ROOT}/lib/config_utils.sh"
source "${REPO_ROOT}/lib/config_schema.sh"
source "${REPO_ROOT}/lib/transaction.sh"

world_type="$1"
workspace_path="$2"

# Validate config
config_path=$(infer_config_path "$world_type")
if ! validate_config_schema "$config_path"; then
    echo "Config validation failed" >&2
    exit 1
fi

# Load config
if ! load_config "$world_type"; then
    echo "Failed to load config" >&2
    exit 1
fi

# Create base directory
if [[ -e "$workspace_path" ]]; then
    echo "Workspace already exists: $workspace_path" >&2
    exit 1
fi

mkdir -p "$workspace_path"

# Generate scaffold with rollback on error
transaction_begin

if ! generate_scaffold "$workspace_path" "$config_path"; then
    echo "Failed to generate scaffold - rolling back" >&2
    transaction_rollback
    rmdir "$workspace_path" 2>/dev/null || true
    exit 1
fi

if ! transaction_commit; then
    echo "Failed to complete scaffold - rolled back" >&2
    rmdir "$workspace_path" 2>/dev/null || true
    exit 1
fi

echo "Workspace created successfully at $workspace_path"
```

---

## Atomicity Guarantees

### All-or-Nothing Semantics

**Success Case:**
```
Command: generate_scaffold "/workspace" "config.yaml"
Operations: [mkdir a] [mkdir a/.integrity] [chmod 755 a] [touch metadata]
Result: All succeed → All written to disk
Effect: Workspace fully initialized
```

**Failure Case:**
```
Command: generate_scaffold "/workspace" "config.yaml"
Operations: [mkdir a] [mkdir a/.integrity] [mkdir a/b] [FAIL - disk full]
Result: Failure detected → All operations rolled back
Effect: Workspace unchanged (as if command never ran)
```

### LIFO Rollback

Operations reversed in Last-In-First-Out order:

```
Logged Operations:
  1. mkdir a
  2. mkdir a/b
  3. mkdir a/b/c
  4. chmod 755 a

Rollback Order:
  1. (undo chmod 755 a)
  2. rmdir a/b/c
  3. rmdir a/b
  4. rmdir a
```

### Isolation

- Transactions are per-process
- No interference with concurrent operations
- Safe for parallel scaffold generation in different workspaces

---

**Document:** scaffold-generation-api.md  
**Created:** 2025-12-30  
**Status:** Complete  
**References:** lib/scaffold_generator.sh, lib/metadata_generator.sh, lib/transaction.sh
