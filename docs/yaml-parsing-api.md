# YAML Parsing & Loading API Reference

**Version:** 1.0.22  
**Component:** lib/yaml_utils.sh, lib/config_utils.sh  
**Last Updated:** 2025-12-30

---

## Table of Contents

1. [Configuration Loading API](#configuration-loading-api)
2. [YAML Parsing API](#yaml-parsing-api)
3. [Variable Expansion API](#variable-expansion-api)
4. [Error Handling](#error-handling)
5. [Usage Examples](#usage-examples)
6. [Performance Notes](#performance-notes)

---

## Configuration Loading API

### load_config()

Load a world configuration from file or by inferring from world-type.

**Signature:**
```bash
load_config(config_path_or_world_type) → exit_code
```

**Parameters:**
- `config_path_or_world_type` (string): Either:
  - Explicit path: `/path/to/config.yaml`
  - World type: `CODING_WORLD`, `RESEARCH_WORLD`, etc.
  - Short name: `coding`, `research`, etc.

**Returns:**
- Exit code 0: Success, config loaded and cached
- Exit code 1: File not found or invalid YAML

**Behavior:**
- Searches standard locations if world-type provided
- Caches result for 30 minutes (TTL)
- Expands variables (${USER}, ${DATE})
- Sets environment variables for config fields

**Example:**
```bash
source "${REPO_ROOT}/lib/config_utils.sh"

# Load by world type (auto-infers path)
load_config "CODING_WORLD"
echo "Config loaded successfully"

# Load by explicit path
load_config "/path/to/custom.yaml"

# Load by short name
load_config "research"
```

### infer_config_path()

Map a world-type to its config file path.

**Signature:**
```bash
infer_config_path(world_type) → config_path
```

**Parameters:**
- `world_type` (string): World type identifier
  - `CODING_WORLD` → `coding.world.yaml`
  - `RESEARCH_WORLD` → `research.world.yaml`
  - Short forms also accepted: `coding`, `research`

**Returns:**
- Absolute path to config file

**Behavior:**
- Converts uppercase to lowercase
- Adds `.world.yaml` extension
- Searches in `templates/world-configs/`
- Returns full path (not relative)

**Example:**
```bash
source "${REPO_ROOT}/lib/config_utils.sh"

config_path=$(infer_config_path "CODING_WORLD")
echo "Config location: $config_path"
# Output: /path/to/templates/world-configs/coding.world.yaml

config_path=$(infer_config_path "coding")
# Same result
```

### resolve_config_path()

Resolve config path, handling both explicit paths and type inference.

**Signature:**
```bash
resolve_config_path(path_or_type) → config_path
```

**Parameters:**
- `path_or_type` (string): Either:
  - `/path/to/config.yaml` (explicit path)
  - `CODING_WORLD` (world type)

**Returns:**
- Absolute path to config file

**Behavior:**
- If argument contains `/`, treats as explicit path
- Otherwise, infers path from world-type
- Validates file exists

**Example:**
```bash
# Both work the same way
resolve_config_path "CODING_WORLD"
resolve_config_path "/path/to/coding.world.yaml"
```

### find_config_file()

Search for a config file by name in standard locations.

**Signature:**
```bash
find_config_file(config_name) → config_path
```

**Parameters:**
- `config_name` (string): Filename (with or without extension)
  - `coding.world.yaml`
  - `coding.yaml`
  - `coding`

**Returns:**
- Absolute path if found, empty string if not found

**Search Locations:**
1. `${REPO_ROOT}/templates/world-configs/`
2. `${PWD}` (current directory)
3. `${DIRFORGE_CONFIG_PATH}` (if set)

**Example:**
```bash
config=$(find_config_file "coding.world.yaml")
[[ -n "$config" ]] && echo "Found: $config"
```

### list_available_configs()

List all available world configurations.

**Signature:**
```bash
list_available_configs() → config_list
```

**Returns:**
- Space-separated list of config file paths

**Behavior:**
- Scans `templates/world-configs/`
- Finds all `*.world.yaml` files
- Sorted by filename

**Example:**
```bash
configs=$(list_available_configs)
for config in $configs; do
  echo "Available: $(basename "$config")"
done
```

---

## YAML Parsing API

### parse_yaml()

Extract a value from a YAML file using dot notation.

**Signature:**
```bash
parse_yaml(yaml_file, field_path) → field_value
```

**Parameters:**
- `yaml_file` (string): Path to YAML file
- `field_path` (string): Field path in dot notation
  - `world.type` → `config['world']['type']`
  - `metadata.version` → `config['metadata']['version']`
  - `parent_directories` → all parent directories

**Returns:**
- Field value (printed to stdout)
- Empty string if field not found

**Exit Code:**
- 0: Success
- 1: File not found, invalid YAML, or field missing

**Example:**
```bash
source "${REPO_ROOT}/lib/yaml_utils.sh"

world_type=$(parse_yaml "config.yaml" "world.type")
echo "World type: $world_type"
# Output: World type: CODING_WORLD

version=$(parse_yaml "config.yaml" "metadata.version")
echo "Version: $version"
# Output: Version: 1.0.22
```

### Nested Field Access

**Dot Notation Examples:**

```bash
# Top-level field
parse_yaml config.yaml "world"

# Nested field
parse_yaml config.yaml "world.type"

# Array access (if supported)
parse_yaml config.yaml "parent_directories.python"

# Deep nesting
parse_yaml config.yaml "metadata.created_by"
```

---

## Variable Expansion API

### expand_variables()

Expand template variables in a string.

**Signature:**
```bash
expand_variables(text) → expanded_text
```

**Parameters:**
- `text` (string): Text containing variables

**Supported Variables:**
- `${USER}` → Current Unix user
- `${DATE}` → ISO 8601 UTC timestamp

**Returns:**
- String with variables replaced

**Example:**
```bash
source "${REPO_ROOT}/lib/yaml_utils.sh"

text="Created by ${USER} at ${DATE}"
expanded=$(expand_variables "$text")
echo "$expanded"
# Output: Created by martin at 2025-12-30T21:35:00Z
```

### Variable Expansion Details

**${USER} Expansion:**
- Replaced with output of `whoami`
- Always lowercase
- Matches Unix user conventions

**${DATE} Expansion:**
- ISO 8601 format: YYYY-MM-DDTHH:MM:SSZ
- Always UTC timezone
- Timestamp when expansion occurs

**Escaping Variables:**
- Use `\${VAR}` to prevent expansion
- Backslash removed after expansion
- Literal `${VAR}` becomes `${VAR}` in output

**Example:**
```bash
# Variable expanded
expand_variables "User: ${USER}"
# Output: User: martin

# Variable escaped
expand_variables "User: \${USER}"
# Output: User: ${USER}

# Both can be used
expand_variables "User: ${USER} at \${DATE}"
# Output: User: martin at ${DATE}
```

---

## Error Handling

### handle_yaml_error()

Report YAML parse errors with context.

**Signature:**
```bash
handle_yaml_error(file, line, message) → void
```

**Parameters:**
- `file` (string): File path
- `line` (number): Line number (1-indexed)
- `message` (string): Error description

**Behavior:**
- Prints formatted error message
- Includes file path and line number
- Prints surrounding context (±2 lines)
- Uses color coding if available

**Example:**
```bash
source "${REPO_ROOT}/lib/config_error.sh"

handle_yaml_error "config.yaml" 15 "Invalid indentation"
# Output:
#   config.yaml:15: Invalid indentation
#   13 |   version: "1.0.22"
#   14 |   created_by: "${USER}"
#   15 |   invalid yaml
#       ^
#   16 |   name: "test"
```

### report_schema_error()

Report schema validation errors.

**Signature:**
```bash
report_schema_error(file, field, message) → void
```

**Parameters:**
- `file` (string): Config file path
- `field` (string): Field name (dot notation)
- `message` (string): Error description

**Behavior:**
- Reports missing or invalid fields
- Includes field path
- Suggests expected type

**Example:**
```bash
source "${REPO_ROOT}/lib/config_error.sh"

report_schema_error "config.yaml" "world.type" \
  "Required field missing"
# Output:
#   config.yaml: Missing required field 'world.type'
#   Expected type: string
```

---

## Usage Examples

### Complete Config Loading Example

```bash
#!/bin/bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Source required libraries
source "${REPO_ROOT}/lib/config_utils.sh"
source "${REPO_ROOT}/lib/config_schema.sh"
source "${REPO_ROOT}/lib/config_error.sh"

# Load config by world type
world_type="CODING_WORLD"
if ! load_config "$world_type"; then
    echo "Failed to load config for $world_type" >&2
    exit 1
fi

# Validate schema
config_path=$(infer_config_path "$world_type")
if ! validate_config_schema "$config_path"; then
    report_schema_error "$config_path" "root" "Invalid schema"
    exit 1
fi

# Extract configuration values
version=$(parse_yaml "$config_path" "metadata.version")
description=$(parse_yaml "$config_path" "world.description")

echo "Loaded: $description (v$version)"
```

### Variable Expansion Example

```bash
#!/bin/bash

source "${REPO_ROOT}/lib/yaml_utils.sh"

# Expand variables in template
template='Created by ${USER} at ${DATE}'
result=$(expand_variables "$template")

echo "$result"
# Output: Created by martin at 2025-12-30T21:35:00Z

# Use in metadata
metadata="workspace_id: test
created_by: ${USER}
created_at: ${DATE}"

expanded=$(expand_variables "$metadata")
echo "$expanded"
```

### Config Validation Example

```bash
#!/bin/bash

source "${REPO_ROOT}/lib/config_utils.sh"
source "${REPO_ROOT}/lib/config_schema.sh"
source "${REPO_ROOT}/lib/config_error.sh"

validate_world_config() {
    local world_type="$1"
    
    # Infer config path
    local config_path=$(infer_config_path "$world_type")
    
    if [[ ! -f "$config_path" ]]; then
        echo "Config not found: $config_path" >&2
        return 1
    fi
    
    # Validate schema
    if ! validate_config_schema "$config_path"; then
        echo "Schema validation failed" >&2
        return 1
    fi
    
    # Load config
    if ! load_config "$world_type"; then
        echo "Failed to load config" >&2
        return 1
    fi
    
    echo "Config valid and loaded successfully"
    return 0
}

# Test all world types
for world in CODING RESEARCH JOURNAL LECTURE OFFICE PRIVATE LITERATURE; do
    validate_world_config "${world}_WORLD"
done
```

---

## Performance Notes

### Caching

**Configuration Caching:**
- First load: Full YAML parsing, ~50ms
- Cached loads: Instant (in-memory)
- Cache TTL: 30 minutes
- Cache invalidation: Automatic

**Environment Override:**
```bash
# Disable cache for testing
DIRFORGE_CACHE_DISABLE=1 load_config "CODING_WORLD"
```

### Variable Expansion Timing

- Variables expanded at scaffold generation time
- Not expanded when config is loaded
- Each scaffold generation gets fresh timestamp
- Enables per-user customization

### Optimization Tips

1. **Batch Operations**
   - Load config once, use multiple times
   - Leverage caching

2. **Error Handling**
   - Validate early to fail fast
   - Catch errors before filesystem operations

3. **Variable Expansion**
   - Use variables for dynamic content
   - Timing is automatic at generation

---

## Environment Variables

### DIRFORGE_CONFIG_PATH

Override default config search path.

```bash
export DIRFORGE_CONFIG_PATH="/custom/config/path"
load_config "CODING_WORLD"
# Searches DIRFORGE_CONFIG_PATH first
```

### DIRFORGE_CACHE_DISABLE

Disable configuration caching (testing only).

```bash
export DIRFORGE_CACHE_DISABLE=1
load_config "CODING_WORLD"  # No caching
```

### DIRFORGE_USER

Override user for ${USER} expansion.

```bash
export DIRFORGE_USER="testuser"
expand_variables "Created by ${USER}"
# Output: Created by testuser
```

---

**Document:** yaml-parsing-api.md  
**Created:** 2025-12-30  
**Status:** Complete  
**References:** lib/config_utils.sh, lib/yaml_utils.sh, lib/config_error.sh
