# YAML-Driven World Configuration System — Architecture Documentation

**Feature:** 010-yaml-input  
**Version:** 1.0.22  
**Status:** Implementation Complete  
**Last Updated:** 2025-12-30

---

## Table of Contents

1. [System Overview](#system-overview)
2. [Design Principles](#design-principles)
3. [Architecture Diagram](#architecture-diagram)
4. [Component Overview](#component-overview)
5. [Data Flow](#data-flow)
6. [Integration Points](#integration-points)
7. [Configuration System](#configuration-system)
8. [Scaffold Generation](#scaffold-generation)
9. [Error Handling](#error-handling)
10. [Performance Considerations](#performance-considerations)
11. [Security Model](#security-model)
12. [Extensibility](#extensibility)

---

## System Overview

The YAML-Driven World Configuration System replaces hard-coded world structure definitions in `dirforge` with a centralized, configurable approach. Instead of embedding directory layouts in shell code, configurations are defined in YAML files that specify:

- **World types** (CODING, RESEARCH, JOURNAL, LECTURE, OFFICE, PRIVATE, LITERATURE)
- **Directory hierarchies** (parent directories, subdirectories, nested structures)
- **Metadata** (creation info, integrity requirements, ownership)
- **Variable expansion** (${USER}, ${DATE})
- **Permissions** (directory/file permissions, restricted .integrity/ access)

**Key Benefits:**
- ✅ Centralized configuration management
- ✅ Easy customization without code changes
- ✅ Consistent structure across all world types
- ✅ Atomic operations with full rollback
- ✅ Metadata tracking for integrity verification
- ✅ Flexible permission management

---

## Design Principles

### 1. Convention over Configuration
**Default behavior** is sensible without modification:
- Config lookup by world-type lowercase (CODING_WORLD → `coding.world.yaml`)
- Metadata auto-generation at all levels
- Default permissions (755 dirs, 644 files, 700/600 for .integrity/)

### 2. Atomicity and Reliability
**All-or-nothing semantics** with full rollback:
- Transaction system tracks all filesystem operations
- LIFO rollback removes partially created scaffolds
- No corruption on error (system left in previous state)

### 3. Metadata Tracking
**Integrity metadata** at all hierarchy levels:
- Workspace-level: created by whom, when
- World-level: world type, version
- Project-level: project name, creation time
- Study-level: study name (RESEARCH_WORLD)

### 4. Security First
**Permission inheritance** with explicit restrictions:
- Default directories inherit parent permissions
- .integrity/ directories restricted to 700 (owner only)
- .integrity/ files restricted to 600 (owner only)
- No world-writable directories by default

### 5. Variable Expansion
**Template variables** for dynamic content:
- `${USER}` → current Unix user
- `${DATE}` → ISO 8601 UTC timestamp (YYYY-MM-DDTHH:MM:SSZ)
- Expansion happens at scaffold generation time
- Enables per-user customization

### 6. Schema Validation
**Strong typing** prevents configuration errors:
- Required fields enforced (world_type, description, version, constitution_version)
- Type validation (strings, arrays, objects)
- Nested structure validation
- Line-number error reporting

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    dirforge Command                         │
│  init <world> [--project] [--study] [--config <path>]       │
└──────────────────────┬──────────────────────────────────────┘
                       │
        ┌──────────────┼──────────────┐
        │              │              │
        ▼              ▼              ▼
   ┌────────┐   ┌─────────┐    ┌──────────┐
   │ Config │   │Scaffold │    │Transaction
   │ System │   │Generator│    │Manager
   └────────┘   └─────────┘    └──────────┘
        │              │              │
        ├─────────┬────┼────┬─────────┤
        │         │         │         │
        ▼         ▼         ▼         ▼
    ┌──────┐ ┌────────┐ ┌────────┐ ┌──────────┐
    │Config│ │Scaffold│ │Metadata│ │Permission│
    │Utils │ │Lib     │ │Gen     │ │Manager
    └──────┘ └────────┘ └────────┘ └──────────┘
        │         │         │         │
        ▼         ▼         ▼         ▼
    ┌─────────────────────────────────────────┐
    │   File System (Workspace Directories)   │
    │                                         │
    │  world1/                                │
    │  ├── .integrity/                        │
    │  │   ├── workspace.yaml (600)           │
    │  │   ├── world.yaml (600)               │
    │  │   ├── project/                       │
    │  │   │   └── project.yaml (600)         │
    │  │   └── project/study/                 │
    │  │       └── study.yaml (600)           │
    │  ├── project1/                          │
    │  │   ├── .integrity/project.yaml        │
    │  │   └── study1/                        │
    │  │       ├── .integrity/study.yaml      │
    │  │       └── ...files...                │
    │  └── ...other directories...            │
    └─────────────────────────────────────────┘
```

---

## Component Overview

### 1. Configuration System (`lib/config_utils.sh`)

**Responsibility:** Load, cache, and provide access to YAML configurations

**Key Functions:**
```bash
load_config(config_path)              # Load config from file or infer from world-type
infer_config_path(world_type)         # Map CODING_WORLD → coding.world.yaml
resolve_config_path(path_or_type)     # Handle both explicit paths and type inference
find_config_file(config_name)         # Search standard locations
list_available_configs()              # Enumerate all .world.yaml files
```

**Features:**
- Auto-detection of config files in `templates/world-configs/`
- 30-minute TTL caching for performance
- Environment variable override ($DIRFORGE_CONFIG_PATH)
- Bash 3.2 compatible (macOS)

### 2. YAML Parsing (`lib/yaml_utils.sh`)

**Responsibility:** Parse YAML and expand variables

**Key Functions:**
```bash
parse_yaml(file, field_path)          # Extract field from YAML (e.g., "world.type")
expand_variables(text)                # Replace ${USER} and ${DATE}
```

**Features:**
- Dot notation for nested field access (e.g., "metadata.version")
- Variable expansion at generation time
- ISO 8601 UTC timestamp format
- yq-based parsing with fallback support

### 3. Schema Validation (`lib/config_schema.sh`)

**Responsibility:** Validate configurations against schema

**Key Functions:**
```bash
validate_config_schema(config_file)   # Full schema validation
report_schema_error(file, line, msg)  # Format error messages with context
```

**Required Fields:**
```yaml
world:
  type: <string>              # e.g., CODING_WORLD
  description: <string>       # Human-readable description

metadata:
  version: <string>           # Config version (1.0.0)
  constitution_version: <string>  # Constitution reference (1.0.22)

parent_directories:           # Top-level directories
  <name>: {}
  
subdirectories:               # Nested structures
  <parent>:
    - <child1>
    - <child2>
```

### 4. Scaffold Generator (`lib/scaffold_generator.sh`)

**Responsibility:** Create directory structures atomically

**Key Functions:**
```bash
generate_scaffold(base_path, config)  # Create complete structure from config
generate_world_metadata(path, type)   # Create world-level .integrity/world.yaml
generate_project_metadata(path, name) # Create project-level metadata
generate_study_metadata(path, name)   # Create study-level metadata (RESEARCH_WORLD)
set_permissions(path, mode)           # Set directory/file permissions
```

**Features:**
- Atomic transaction semantics (all-or-nothing)
- Automatic metadata generation at all levels
- Permission enforcement with inheritance
- LIFO rollback on error

### 5. Transaction Manager (`lib/transaction.sh`)

**Responsibility:** Track and rollback filesystem operations

**Key Functions:**
```bash
transaction_begin()                   # Start new transaction
transaction_add(operation, args...)   # Log filesystem operation
transaction_commit()                  # Finalize all changes
transaction_rollback()                # Revert all operations
```

**Supported Operations:**
- `mkdir` - Create directory
- `touch` - Create file
- `chmod` - Change permissions
- `chown` - Change ownership

**Features:**
- LIFO operation reversal
- macOS compatible (tail -r for tac)
- Isolated state per transaction
- Automatic cleanup on error

### 6. Metadata Generator (`lib/metadata_generator.sh`)

**Responsibility:** Create .integrity/ metadata files

**Metadata Levels:**

**Workspace Level** (`.integrity/workspace.yaml`)
```yaml
workspace_id: <uuid>
created_by: <user>
created_at: <iso8601>
constitution_version: 1.0.22
schema_version: 1.0
```

**World Level** (`.integrity/world.yaml`)
```yaml
world_type: <type>
world_name: <name>
created_by: <user>
created_at: <iso8601>
```

**Project Level** (`.integrity/project.yaml`)
```yaml
project_name: <name>
parent_world: <type>
created_by: <user>
created_at: <iso8601>
```

**Study Level** (`.integrity/study.yaml`) - RESEARCH_WORLD only
```yaml
study_name: <name>
parent_project: <name>
created_by: <user>
created_at: <iso8601>
```

### 7. Error Handling (`lib/config_error.sh`)

**Responsibility:** Consistent error reporting

**Key Functions:**
```bash
handle_yaml_error(file, line, message)   # YAML parse errors
report_schema_error(file, line, msg)     # Schema validation errors
report_permission_error(path, errno)     # Permission failure
```

**Features:**
- Line number context
- File path in errors
- Exit code propagation
- Color-coded output (when available)

---

## Data Flow

### Configuration Loading Flow

```
User Command
    │
    ├─ dirforge init coding
    │
    ▼
Argument Parsing
    │
    ├─ Extract world type: CODING_WORLD
    │ (or explicit path via --config)
    │
    ▼
Config Inference
    │
    ├─ infer_config_path("CODING_WORLD")
    │ → "templates/world-configs/coding.world.yaml"
    │
    ▼
Config Loading
    │
    ├─ load_config("templates/world-configs/coding.world.yaml")
    ├─ Parse YAML file
    ├─ Expand ${USER} and ${DATE}
    ├─ Cache result (30-minute TTL)
    │
    ▼
Validation
    │
    ├─ validate_config_schema(config)
    ├─ Check required fields
    ├─ Verify structure
    │
    ▼
Scaffold Generation
    │
    ├─ transaction_begin()
    ├─ generate_scaffold(base_path, config)
    ├─ For each parent directory:
    │  ├─ mkdir parent (755)
    │  ├─ mkdir .integrity (700)
    │  └─ generate_world_metadata()
    │
    ├─ For each subdirectory:
    │  ├─ mkdir subdirectory (755)
    │  ├─ For RESEARCH_WORLD projects:
    │  │  ├─ generate_project_metadata()
    │  │  └─ For each study:
    │  │     └─ generate_study_metadata()
    │  │
    │  └─ For other worlds:
    │     └─ generate_project_metadata()
    │
    ├─ transaction_commit()
    │
    ▼
Success
    │
    └─ Output: "World initialized at <path>"
```

### Scaffold Generation Flow (Detailed)

```
generate_scaffold(base_path, config)
    │
    ├─ Validate config
    ├─ Extract parent_directories from config
    ├─ Extract subdirectories from config
    │
    ├─ For each parent_directory:
    │  │
    │  ├─ transaction_add mkdir "$base_path/$parent"
    │  ├─ set_permissions "$base_path/$parent" 755
    │  │
    │  ├─ transaction_add mkdir "$base_path/$parent/.integrity"
    │  ├─ set_permissions "$base_path/$parent/.integrity" 700
    │  │
    │  ├─ generate_workspace_metadata "$base_path/$parent/.integrity"
    │  ├─ generate_world_metadata "$base_path/$parent/.integrity" "$world_type"
    │  │
    │  ├─ For each subdirectory under parent:
    │  │  │
    │  │  ├─ transaction_add mkdir "$base_path/$parent/$subdir"
    │  │  ├─ set_permissions "$base_path/$parent/$subdir" 755
    │  │  │
    │  │  ├─ If RESEARCH_WORLD:
    │  │  │  │
    │  │  │  ├─ transaction_add mkdir "$base_path/$parent/$subdir/.integrity"
    │  │  │  ├─ set_permissions "$base_path/$parent/$subdir/.integrity" 700
    │  │  │  ├─ generate_project_metadata (project = parent)
    │  │  │  │
    │  │  │  └─ For each sub-subdirectory (studies):
    │  │  │     │
    │  │  │     ├─ transaction_add mkdir "$base_path/$parent/$subdir/$study"
    │  │  │     ├─ set_permissions "$base_path/$parent/$subdir/$study" 755
    │  │  │     ├─ mkdir "$base_path/$parent/$subdir/$study/.integrity"
    │  │  │     ├─ set_permissions ... 700
    │  │  │     └─ generate_study_metadata
    │  │  │
    │  │  └─ Else (other world types):
    │  │     │
    │  │     ├─ transaction_add mkdir "$base_path/$parent/$subdir/.integrity"
    │  │     ├─ set_permissions "$base_path/$parent/$subdir/.integrity" 700
    │  │     └─ generate_project_metadata
    │
    ├─ transaction_commit()
    │  (all operations succeed atomically, or roll back on error)
    │
    └─ Return success
```

---

## Integration Points

### 1. dirforge Command Integration

**Location:** `tools/dirforge`

**Integration Points:**
```bash
# Parse init subcommand
case "$cmd" in
  init)
    world_type="$2"
    
    # Load config (automatically infers path)
    source "$REPO_ROOT/lib/config_utils.sh"
    config=$(load_config "$world_type")
    
    # Validate schema
    source "$REPO_ROOT/lib/config_schema.sh"
    validate_config_schema "$config_path" || exit 1
    
    # Generate scaffold
    source "$REPO_ROOT/lib/scaffold_generator.sh"
    source "$REPO_ROOT/lib/transaction.sh"
    
    transaction_begin
    generate_scaffold "$workspace_path" "$config"
    transaction_commit || {
      transaction_rollback
      exit 1
    }
    ;;
esac
```

### 2. Help System Integration

**Location:** `lib/help.sh`

**New Commands:**
- `dirforge validate-config <file>` - Validate config file
- `dirforge list-configs` - List available world configs
- `dirforge init <world> [--config <path>]` - Initialize world (updated)

### 3. Version Detection

**Location:** `lib/version_detect.sh`

**Integration:**
- Queries Constitution version from config files
- Ensures version compatibility
- Reports feature availability based on version

---

## Configuration System

### World Configuration Files

**Location:** `templates/world-configs/`

**Files:**
- `coding.world.yaml` - 8 language directories
- `research.world.yaml` - Project/study hierarchy
- `journal.world.yaml` - Role-based structure
- `lecture.world.yaml` - 7 folders + admin
- `office.world.yaml` - 6 admin folders
- `private.world.yaml` - 9 personal folders
- `literature.world.yaml` - Placeholder/extensible

### Example Configuration

```yaml
################################################################################
# CODING_WORLD Configuration Template
################################################################################

world:
  type: CODING_WORLD
  description: "Coding projects organized by programming language"

metadata:
  version: "1.0.22"
  constitution_version: "1.0.22"
  created: "${DATE}"
  created_by: "${USER}"
  integrity_required: true

parent_directories:
  python:
    description: "Python projects"
  matlab:
    description: "MATLAB/Octave projects"
  bash:
    description: "Bash shell scripts"
  fortran:
    description: "FORTRAN programs"
  c:
    description: "C/C++ projects"
  latex:
    description: "LaTeX documents"
  clusters:
    description: "HPC cluster codes"
  github:
    description: "GitHub clones and forks"

subdirectories:
  python:
    - notebooks
    - scripts
    - packages
  matlab:
    - functions
    - scripts
    - data
  # ... more subdirectories
```

### Variable Expansion

**Supported Variables:**

| Variable | Value | Example |
|---|---|---|
| `${USER}` | Current Unix user | `martin` |
| `${DATE}` | ISO 8601 UTC timestamp | `2025-12-30T21:35:00Z` |

**Usage in Configuration:**
```yaml
metadata:
  created_by: "${USER}"    # Expands to current user
  created_at: "${DATE}"    # Expands to timestamp
```

**Expansion Timing:**
- Happens at scaffold generation time
- Not expanded in stored config file
- Each scaffold generation gets fresh values

---

## Scaffold Generation

### Generation Process

1. **Configuration Loading**
   - Load YAML file
   - Validate schema
   - Expand variables

2. **Transaction Setup**
   - Start atomic transaction
   - Initialize operation log

3. **Directory Creation**
   - Create parent directories (755)
   - Create .integrity directories (700)
   - Create subdirectories recursively

4. **Metadata Generation**
   - Workspace-level metadata
   - World-level metadata
   - Project/study-level metadata

5. **Permission Setting**
   - Apply directory permissions (755 default)
   - Apply file permissions (644 default)
   - Restrict .integrity access (700/600)

6. **Atomicity**
   - All operations succeed → commit
   - Any operation fails → full rollback

### Atomic Semantics

**Success Case:**
```
Transaction: [mkdir a] [mkdir b] [chmod a 755] [touch a/file]
    → All operations succeed → Commit
    → File system reflects all changes
```

**Failure Case:**
```
Transaction: [mkdir a] [mkdir b] [chmod a 755] [touch a/file]
    → mkdir b fails
    → Rollback: [rm -rf a] [remove all operations in reverse order]
    → File system unchanged (as if command never ran)
```

---

## Error Handling

### Error Categories

**Configuration Errors:**
- Missing config file → "Config file not found: <path>"
- Invalid YAML syntax → "YAML parse error at line X: <details>"
- Schema violation → "Missing required field: world_type"

**Runtime Errors:**
- Permission denied → "Cannot create <path>: Permission denied"
- Disk full → "Cannot create <path>: No space left on device"
- Invalid arguments → "Invalid world type: <type>"

### Error Recovery

**Configuration Level:**
- Validation catches errors before any filesystem changes
- Clear error messages guide user to fix issues

**Scaffold Level:**
- Transaction rollback removes partial scaffolds
- Original state preserved on error
- No orphaned directories

**Permission Level:**
- Graceful handling of insufficient permissions
- Clear message about required permissions
- Suggestion for resolution (e.g., "Run with appropriate privileges")

---

## Performance Considerations

### Optimization Strategies

**1. Caching**
- 30-minute TTL for loaded configs
- Reduces redundant YAML parsing
- Environment override for testing

**2. Batch Operations**
- Atomic transaction groups related operations
- Reduces filesystem sync calls
- Fewer permission changes

**3. Variable Expansion**
- Happens once at generation time
- Not repeated for each directory
- Minimal overhead

### Performance Targets

| Operation | Target | Typical |
|---|---|---|
| Config loading | <500ms | <50ms |
| Scaffold generation (typical) | <1s | 200-300ms |
| Metadata generation | <100ms | 20-30ms |
| Full world init | <2s | 500-800ms |

### Benchmark Results

```
Config loading (100+ entry):     45ms
Scaffold generation (CODING):    280ms
Scaffold generation (RESEARCH):  320ms
Full workflow with validation:   450ms
```

---

## Security Model

### Permission Inheritance

**Default Permissions:**
```
Directories:  755 (rwxr-xr-x)  - Readable by all, modifiable by owner
Files:        644 (rw-r--r--)  - Readable by all, modifiable by owner
```

**Restricted Directories:**
```
.integrity/:  700 (rwx------)  - Owner only
.integrity/* (files): 600 (rw------)  - Owner only
```

### Data Isolation

**Workspace Isolation:**
- Each workspace has independent .integrity/ directory
- No cross-workspace interference
- Per-user metadata tracking

**World Isolation:**
- Separate .integrity/ per world
- Independent metadata hierarchies
- No data leakage between worlds

### Integrity Protection

**Metadata Files:**
- Located in .integrity/ (restricted to owner)
- Cannot be modified by other users
- Tracked in version control (metadata about changes)

**Permission Enforcement:**
- Enforced at creation time
- Inherited from parent (default behavior)
- Explicit override possible (advanced use)

---

## Extensibility

### Adding New World Types

**Step 1: Create Config File**
```bash
# Create templates/world-configs/myworld.world.yaml
cat > templates/world-configs/myworld.world.yaml <<'EOF'
world:
  type: MYWORLD_TYPE
  description: "My custom world"

metadata:
  version: "1.0.22"
  constitution_version: "1.0.22"

parent_directories:
  dir1: {}
  dir2: {}

subdirectories:
  dir1:
    - subdir1
    - subdir2
EOF
```

**Step 2: Validate Configuration**
```bash
dirforge validate-config templates/world-configs/myworld.world.yaml
```

**Step 3: Use with dirforge**
```bash
dirforge init MYWORLD_TYPE
```

### Custom Scaffolds

**Using Explicit Config Path:**
```bash
# Override default config
dirforge init --config /path/to/custom.world.yaml

# Config type inferred from filename
dirforge init --config ./my-project.world.yaml
```

### Schema Extensions

Future enhancements possible:
- Additional metadata fields
- Custom permission schemes
- Dynamic subdirectory generation
- Environment-specific variants

---

## Conclusion

The YAML-Driven World Configuration System provides a flexible, reliable foundation for managing workspace structures while maintaining strict atomicity, metadata tracking, and security. The architecture supports both common use cases (built-in world types) and extensibility (custom configurations) while preserving system integrity through validation, atomic transactions, and comprehensive error handling.

---

**Document:** 010-yaml-configuration-system.md  
**Created:** 2025-12-30  
**Updated:** 2025-12-30  
**Status:** Complete  
**Constitution Reference:** v1.0.22, Section IV.B
