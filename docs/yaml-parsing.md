# YAML Parsing API Reference

**Part of:** Feature 010: YAML-Driven World Configuration System  
**Version:** 1.0.22  
**Last Updated:** 2025-12-29

---

## Table of Contents

1. [Overview](#overview)
2. [Core Functions](#core-functions)
   - [parse_yaml()](#parse_yaml)
   - [load_config()](#load_config)
   - [expand_variables()](#expand_variables)
3. [Variable Expansion](#variable-expansion)
4. [Error Handling](#error-handling)
5. [Examples](#examples)
   - [Basic Usage](#basic-usage)
   - [All World Types](#all-world-types)
   - [Advanced Usage](#advanced-usage)
6. [Troubleshooting](#troubleshooting)

---

## Overview

The YAML Parsing API provides a complete system for loading, parsing, and manipulating YAML configuration files. It includes:

- **YAML Parsing** with support for nested fields and dot notation
- **Config Loading** with automatic variable expansion
- **Variable Expansion** for user, date, and timestamp placeholders
- **Error Handling** with helpful error messages and context display
- **Bash 3.2 Compatibility** for macOS and legacy systems

### Supported World Types

The system manages configuration for 7 world types:

| World Type | Config File | Description |
|-----------|------------|-------------|
| CODING_WORLD | `coding.world.yaml` | Programming languages and clusters |
| RESEARCH_WORLD | `research.world.yaml` | Research projects and studies |
| JOURNAL_WORLD | `journal.world.yaml` | Personal journal with roles |
| LECTURE_WORLD | `lecture.world.yaml` | Educational lectures and courses |
| OFFICE_WORLD | `office.world.yaml` | Administrative documents |
| PRIVATE_WORLD | `private.world.yaml` | Personal files (admin through archive) |
| LITERATURE_WORLD | `literature.world.yaml` | Literature references and notes |

---

## Core Functions

### parse_yaml()

Extracts a value from a YAML file using dot notation for nested fields.

**Signature:**
```bash
parse_yaml <yaml_file> <field_path>
```

**Parameters:**
- `yaml_file` - Path to the YAML configuration file
- `field_path` - Field path using dot notation (e.g., `world.type`, `world.parent_directories[0].name`)

**Returns:**
- The field value on stdout

**Exit Code:**
- `0` - Success, field found and extracted
- `1` - Error (file not found, field not found, invalid YAML)

**Example:**
```bash
parse_yaml templates/world-configs/coding.world.yaml "world.type"
# Output: CODING_WORLD

parse_yaml templates/world-configs/research.world.yaml "world.description"
# Output: Research world for managing scientific projects and studies
```

### load_config()

Loads a complete YAML configuration and exports all fields as shell variables with `CONFIG_` prefix.

**Signature:**
```bash
load_config <world_type|config_file>
```

**Parameters:**
- `world_type` - World type name (e.g., `CODING_WORLD`) OR
- `config_file` - Absolute path to a `.world.yaml` file

**Exports:**
All configuration fields are exported as `CONFIG_FIELDNAME` variables, with nested paths flattened using underscores:
```bash
CONFIG_WORLD_TYPE          # Root world type
CONFIG_WORLD_DESCRIPTION   # World description
CONFIG_WORLD_VERSION       # Config version
CONFIG_METADATA_*          # Metadata fields
CONFIG_PARENT_DIRECTORIES_* # Array elements
# etc.
```

**Exit Code:**
- `0` - Success
- `1` - Error (config not found, invalid YAML, parsing error)

**Example:**
```bash
load_config CODING_WORLD
echo "$CONFIG_WORLD_TYPE"        # Output: CODING_WORLD
echo "$CONFIG_WORLD_DESCRIPTION" # Output: Description text

# Or with a specific file path:
load_config /path/to/research.world.yaml
echo "$CONFIG_WORLD_TYPE"        # Output: RESEARCH_WORLD
```

### expand_variables()

Expands variable placeholders in YAML content (${USER}, ${DATE}, ${TIMESTAMP}).

**Signature:**
```bash
expand_variables <input_file> [output_file]
```

**Parameters:**
- `input_file` - Path to file with variable placeholders
- `output_file` - (Optional) Output file path. If omitted or `-`, writes to stdout

**Supported Variables:**
- `${USER}` - Current Unix username (e.g., `martin`)
- `${DATE}` - Current date in ISO 8601 UTC format (e.g., `2025-12-29T19:48:53Z`)
- `${TIMESTAMP}` - Unix epoch seconds (e.g., `1767037733`)

**Exit Code:**
- `0` - Success
- `1` - Error (input file not found)

**Example:**
```bash
# Expand variables to stdout
expand_variables templates/my-template.yaml

# Expand variables and save to file
expand_variables templates/my-template.yaml output/expanded.yaml

# Input file content:
# owner: ${USER}
# created: ${DATE}
# epoch: ${TIMESTAMP}
#
# Output:
# owner: martin
# created: 2025-12-29T19:48:53Z
# epoch: 1767037733
```

---

## Variable Expansion

Variables are expanded at load time and can be used in configuration templates.

### Variable Reference

| Variable | Format | Example |
|----------|--------|---------|
| `${USER}` | Unix username | `martin` |
| `${DATE}` | ISO 8601 UTC | `2025-12-29T19:48:53Z` |
| `${TIMESTAMP}` | Unix epoch | `1767037733` |

### Date Format Details

The `${DATE}` variable uses ISO 8601 UTC format:
- **Format:** `YYYY-MM-DDTHH:MM:SSZ`
- **Example:** `2025-12-29T19:48:53Z`
- **Timezone:** Always UTC (Z suffix indicates Zulu time)
- **Precision:** Seconds

This format is:
- Machine-readable and sortable
- International standard (ISO 8601)
- Timezone-aware
- Compatible with date parsing in most programming languages

---

## Error Handling

### handle_yaml_error()

Reports YAML parsing errors with context and file information.

**Signature:**
```bash
handle_yaml_error <error_message> <yaml_file> [line_number] [field_path]
```

**Parameters:**
- `error_message` - Description of the error
- `yaml_file` - Path to the problematic YAML file
- `line_number` - (Optional) Line number where error occurred
- `field_path` - (Optional) Field path being accessed

**Example:**
```bash
handle_yaml_error "Invalid field type" "coding.world.yaml" 15 "world.type"
# Output:
# YAML Parse Error:
#   Message: Invalid field type
#   File: coding.world.yaml
#   Line: 15
#   Field: world.type
#
# Context:
#   13: world:
#   14:   type: CODING_WORLD
#   15:   invalid: data
```

### Error Exit Codes

The system uses standardized error codes:

| Code | Name | Description |
|------|------|-------------|
| 101 | ERR_CONFIG_NOT_FOUND | Configuration file not found |
| 102 | ERR_INVALID_YAML | YAML syntax error |
| 103 | ERR_SCHEMA_VALIDATION | Schema validation failed |
| 104 | ERR_FIELD_NOT_FOUND | Requested field not found |
| 105 | ERR_FIELD_TYPE_MISMATCH | Field value type mismatch |
| 109 | ERR_YAML_PARSE_ERROR | General YAML parse error |

---

## Examples

### Basic Usage

#### Load a Configuration

```bash
#!/usr/bin/env bash

# Source the config library
source lib/config_utils.sh

# Load a configuration by world type
load_config RESEARCH_WORLD

# Access exported variables
echo "World Type: $CONFIG_WORLD_TYPE"
echo "Description: $CONFIG_WORLD_DESCRIPTION"
```

#### Extract a Specific Field

```bash
#!/usr/bin/env bash

source lib/yaml_utils.sh

# Get the world type
type=$(parse_yaml templates/world-configs/journal.world.yaml "world.type")
echo "Loaded: $type"

# Get nested field
description=$(parse_yaml templates/world-configs/coding.world.yaml "world.description")
echo "Description: $description"
```

#### Expand Variables in Templates

```bash
#!/usr/bin/env bash

source lib/yaml_utils.sh

# Create a template
cat > my-config.yaml << 'EOF'
owner: ${USER}
created_at: ${DATE}
metadata:
  user: ${USER}
  timestamp: ${TIMESTAMP}
EOF

# Expand variables
expand_variables my-config.yaml > expanded-config.yaml

# View results
cat expanded-config.yaml
```

### All World Types

Here's how to work with each world type:

#### CODING_WORLD

```bash
source lib/config_utils.sh
load_config CODING_WORLD

# Contains programming languages: python, matlab, bash, fortran, c, latex, clusters, github
echo "Languages: ${CONFIG_WORLD_PARENT_DIRECTORIES_0_NAME:-python}"
```

#### RESEARCH_WORLD

```bash
source lib/config_utils.sh
load_config RESEARCH_WORLD

# Contains project hierarchy and study structure
echo "Type: $CONFIG_WORLD_TYPE"  # RESEARCH_WORLD
```

#### JOURNAL_WORLD

```bash
source lib/config_utils.sh
load_config JOURNAL_WORLD

# Contains role-based parent directories
echo "Journal Type: $CONFIG_WORLD_TYPE"  # JOURNAL_WORLD
```

#### LECTURE_WORLD

```bash
source lib/config_utils.sh
load_config LECTURE_WORLD

# Contains 7 mandatory folders and admin structure
echo "Lecture World: $CONFIG_WORLD_TYPE"  # LECTURE_WORLD
```

#### OFFICE_WORLD

```bash
source lib/config_utils.sh
load_config OFFICE_WORLD

# Contains 6 administrative folders
echo "Office: $CONFIG_WORLD_TYPE"  # OFFICE_WORLD
```

#### PRIVATE_WORLD

```bash
source lib/config_utils.sh
load_config PRIVATE_WORLD

# Contains 9 personal folders (00_admin through 90_archive)
echo "Private: $CONFIG_WORLD_TYPE"  # PRIVATE_WORLD
```

#### LITERATURE_WORLD

```bash
source lib/config_utils.sh
load_config LITERATURE_WORLD

# Placeholder for future expansion
echo "Literature: $CONFIG_WORLD_TYPE"  # LITERATURE_WORLD
```

### Advanced Usage

#### Error Handling

```bash
#!/usr/bin/env bash

source lib/config_utils.sh
source lib/config_error.sh

# Load with error handling
if ! load_config "RESEARCH_WORLD"; then
    echo "Failed to load configuration"
    exit 1
fi

# Check specific fields with error handling
if ! value=$(parse_yaml "templates/world-configs/research.world.yaml" "world.type" 2>/dev/null); then
    handle_yaml_error "Failed to extract world.type" "research.world.yaml" "" "world.type"
    exit 1
fi

echo "World type: $value"
```

#### Custom Configuration Processing

```bash
#!/usr/bin/env bash

# Load all 7 world configs and process them
for world_type in CODING RESEARCH JOURNAL LECTURE OFFICE PRIVATE LITERATURE; do
    world="${world_type}_WORLD"
    
    source lib/config_utils.sh
    
    if load_config "$world" 2>/dev/null; then
        echo "✓ Loaded $world"
        echo "  Description: ${CONFIG_WORLD_DESCRIPTION:0:50}..."
    else
        echo "✗ Failed to load $world"
    fi
done
```

#### Template Processing Pipeline

```bash
#!/usr/bin/env bash

source lib/yaml_utils.sh

# 1. Load template
template_file="templates/scaffold-template.yaml"

# 2. Expand variables
expanded=$(expand_variables "$template_file")

# 3. Parse configuration
while IFS= read -r line; do
    # Process each line of expanded YAML
    if [[ $line =~ ^([a-z_]+):\ *(.*)$ ]]; then
        key="${BASH_REMATCH[1]}"
        value="${BASH_REMATCH[2]}"
        echo "Processing: $key = $value"
    fi
done <<< "$expanded"
```

---

## Troubleshooting

### Common Issues

#### Issue: "Config file not found"

**Cause:** The configuration file doesn't exist at the specified path.

**Solution:**
```bash
# Verify the file exists
ls -l templates/world-configs/*.world.yaml

# Check the current working directory
pwd

# Use absolute paths
load_config /full/path/to/coding.world.yaml
```

#### Issue: "Field not found"

**Cause:** The field path doesn't exist in the YAML file.

**Solution:**
```bash
# Check available fields
parse_yaml templates/world-configs/coding.yaml.yaml "world" | head

# Verify exact field name
# Use: world.type (not world.World_Type)
parse_yaml templates/world-configs/coding.world.yaml "world.type"
```

#### Issue: "Invalid YAML syntax"

**Cause:** The YAML file has indentation or syntax errors.

**Solution:**
```bash
# Validate YAML with yq
yq eval '.' templates/world-configs/coding.world.yaml

# Or with Python
python3 -c "import yaml; yaml.safe_load(open('templates/world-configs/coding.world.yaml'))"
```

#### Issue: Variables Not Expanded

**Cause:** Variable expansion requires using `expand_variables()` or `load_config()` with special handling.

**Solution:**
```bash
# Use expand_variables for template files
expand_variables my-template.yaml

# Or use get_yaml_variable for individual variables
source lib/yaml_utils.sh
get_yaml_variable "USER"      # martin
get_yaml_variable "DATE"      # 2025-12-29T19:48:53Z
```

### Performance Tips

1. **Caching:** Configurations are cached in `/tmp` for 30 minutes
2. **Batch Operations:** Load config once, use exported variables multiple times
3. **Minimal Parsing:** Use `parse_yaml()` only for fields you need
4. **Error Suppression:** Use `2>/dev/null` to suppress error messages in scripts

---

## Integration with dirforge

The YAML Parsing API is integrated into the main `dirforge` tool:

```bash
# List all available configurations
dirforge list-configs

# Validate a configuration
dirforge validate-config templates/world-configs/coding.world.yaml

# Use configuration in scaffold generation
dirforge init CODING_WORLD my-project/
```

---

## References

- **YAML Specification:** [yaml.org](https://yaml.org/)
- **ISO 8601 Standard:** Date and time representation
- **Configuration Schema:** See `templates/world-configs/SCHEMA.md`
- **Template Examples:** See `templates/world-configs/TEMPLATE-EXAMPLES.md`
- **Test Suite:** `tests/test-functions/test_*` files

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.22 | 2025-12-29 | Initial API documentation with all 7 world types |

---

## Contact & Support

For issues, questions, or contributions:
- Check the test files: `tests/test-functions/`
- Review error messages with context
- Validate YAML files before use
