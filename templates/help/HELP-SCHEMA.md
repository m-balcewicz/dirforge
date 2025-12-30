# Help System YAML Schema

**Version:** 1.0.22  
**Status:** Active  
**Last Updated:** 2025-12-30

---

## Overview

This document defines the YAML schema for help files in the DirForge help system. Help files are stored in `templates/help/` with `.yaml` extension and are dynamically parsed by `lib/help_yaml_parser.sh`.

---

## File Naming Conventions

Help files follow this naming pattern:

```
<command-name>.yaml          # For specific commands
<topic-name>.yaml            # For broader topics
```

**Examples:**
- `validate-config.yaml` - Help for `dirforge validate-config` command
- `list-configs.yaml` - Help for `dirforge list-configs` command
- `yaml-config-system.yaml` - Help for YAML configuration system overview
- `custom-world.yaml` - Help for creating custom world configurations

---

## Top-Level Structure

```yaml
# Root element: command or topic identifier
command: <command-name>      # Required: unique command identifier
description: <brief>         # Required: one-line description
type: <type>                 # Required: command or topic
category: <category>         # Required: YAML, scaffold, etc.

# Content sections
syntax: { ... }              # Required: command syntax and arguments
usage: { ... }               # Optional: usage patterns and flags
examples: [ ... ]            # Required: practical examples
output: { ... }              # Optional: output format description
related: [ ... ]             # Optional: related commands
see_also: [ ... ]            # Optional: documentation links

# Help variants
short_help: { ... }          # Required: concise essential help
long_help: { ... }           # Required: complete detailed help
```

---

## Detailed Field Definitions

### Root Fields

#### `command` (Required String)
Unique identifier for the command or topic. Used for lookups and caching.

**Format:** Lowercase with hyphens, no spaces  
**Example:** `validate-config`, `list-configs`, `yaml-config-system`

**Usage in dirforge:**
```bash
dirforge help validate-config    # Looks up help for "validate-config"
dirforge help yaml-config-system # Looks up help for "yaml-config-system"
```

#### `description` (Required String)
One-line description of the command or topic. Used in listings and summary help.

**Format:** Complete sentence with period  
**Example:** `"Validate a YAML configuration file."`

#### `type` (Required String)
Categorizes the help content type.

**Allowed Values:**
- `command` - Help for a CLI command
- `topic` - Help for a broader topic or feature

#### `category` (Required String)
Identifies the functional area for organization.

**Suggested Values:**
- `yaml` - YAML configuration system related
- `scaffold` - Scaffold generation related
- `general` - General dirforge commands
- `init` - Initialization related

#### `syntax` (Required Object)
Formal syntax specification of the command.

```yaml
syntax:
  usage: "<command-form>"                # Required: canonical usage form
  arguments: [ ... ]                     # Optional: positional arguments
  options: [ ... ]                       # Optional: flags and options
  variants: [ ... ]                      # Optional: alternative forms
```

**Example:**
```yaml
syntax:
  usage: "dirforge validate-config <config-file>"
  arguments:
    - name: config-file
      description: "Path to .yaml configuration file"
      required: true
  options:
    - flag: --quiet
      description: "Suppress output"
    - flag: --json
      description: "Output validation errors as JSON"
  variants:
    - "dirforge validate-config --help"
```

#### `usage` (Optional Object)
Usage patterns, common workflows, and best practices.

```yaml
usage:
  patterns:
    - name: <pattern-name>
      description: <description>
      command: <command-example>
  common_workflows:
    - name: <workflow-name>
      description: <description>
      steps: [ ... ]
```

#### `examples` (Required Array)
Practical examples showing command usage. Minimum 2 examples required.

```yaml
examples:
  - title: "Validate a built-in config"
    command: "dirforge validate-config templates/world-configs/coding.yaml"
    description: "Check if the CODING_WORLD configuration is valid"
    output: |
      ✓ Config validation passed
        - world.type: CODING_WORLD
        - All required fields present

  - title: "Validate custom world config"
    command: "dirforge validate-config ~/my-world.yaml"
    description: "Validate a custom world configuration file"
    
  - title: "Check validation errors"
    command: "dirforge validate-config --json invalid.yaml"
    description: "View validation errors in JSON format"
```

**Required Fields per Example:**
- `title` - Short descriptive title
- `command` - Exact command to run
- `description` - What the example demonstrates

**Optional Fields:**
- `output` - Expected output (for illustration)
- `expected_exit_code` - Exit code if notable

#### `output` (Optional Object)
Description of command output format and structure.

```yaml
output:
  format: <format-type>                   # text, table, json, etc.
  description: <description>
  columns: [ ... ]                        # For table output
  schema: <schema-description>            # For structured output
  example: |
    <sample output>
```

**Example:**
```yaml
output:
  format: table
  description: "Displays all available world configurations in a table"
  columns:
    - name: "World Type"
      description: "Configuration identifier (CODING_WORLD, RESEARCH_WORLD, etc.)"
    - name: "Config File"
      description: "Path to the .yaml configuration file"
  example: |
    CODING_WORLD      templates/world-configs/coding.yaml
    RESEARCH_WORLD    templates/world-configs/research.yaml
```

#### `related` (Optional Array)
Related commands that may be useful in conjunction with this command.

```yaml
related:
  - command: list-configs
    reason: "See all available configurations before validating"
  - command: init --config
    reason: "Use a validated config to create a workspace"
```

**Fields:**
- `command` - Related command name
- `reason` - Why it's related

#### `see_also` (Optional Array)
Links to documentation and help topics.

```yaml
see_also:
  - title: "YAML Configuration System"
    link: "yaml-config-system"
    type: "help-topic"
  
  - title: "Custom World Configuration Guide"
    link: "custom-world"
    type: "help-topic"
  
  - title: "Configuration Schema"
    link: "docs/010-yaml-configuration-system.md"
    type: "documentation"
```

---

## Help Variants

### `short_help` (Required Object)

Concise help for quick reference. Displayed with `<command> --help`.

```yaml
short_help:
  summary: "<one-line summary>"           # Required: single sentence
  synopsis: "<brief syntax>"              # Required: command form
  quick_options: [ ... ]                  # Required: most common options (2-3 max)
  hint: "<helpful tip>"                   # Optional: usage suggestion
```

**Example:**
```yaml
short_help:
  summary: "Validate a YAML configuration file"
  synopsis: "dirforge validate-config <config-file>"
  quick_options:
    - flag: --quiet
      description: "Suppress output"
    - flag: --json
      description: "Output as JSON"
  hint: "Validate before using config with 'dirforge init --config'"
```

### `long_help` (Required Object)

Complete detailed help. Displayed with `dirforge help <command>`.

```yaml
long_help:
  summary: "<comprehensive description>"  # Required: 3-5 sentences
  details: "<additional information>"     # Optional: deeper explanation
  important_notes: [ ... ]                # Optional: critical information
  all_options: [ ... ]                    # Required: complete option list
  see_also: [ ... ]                       # Optional: related items (repeated)
```

**Example:**
```yaml
long_help:
  summary: |
    The validate-config command checks if a YAML configuration file is valid
    according to the DirForge configuration schema. It verifies all required
    fields are present, checks field types, and validates nested structures.
    Use this before deploying a custom world configuration.
    
  details: |
    Configuration files must follow the structure defined in the HELP-SCHEMA.
    This command performs comprehensive validation including required fields,
    type checking, and nested structure validation.
    
  important_notes:
    - "Configuration files must have .yaml extension"
    - "All required fields must be present"
    - "Schema validation is strict (no extra fields allowed)"
    
  all_options:
    - flag: --quiet, -q
      description: "Suppress all output (exit code indicates result)"
    - flag: --json
      description: "Output validation errors as JSON for automation"
    - flag: --verbose, -v
      description: "Show detailed validation trace"
```

---

## Required vs. Optional Fields

### Minimum Required for Any Help File

- ✅ `command` - Unique identifier
- ✅ `description` - One-line description
- ✅ `type` - command or topic
- ✅ `category` - Functional area
- ✅ `syntax` - Command syntax with usage, arguments, options
- ✅ `examples` - At least 2 practical examples
- ✅ `short_help` - Quick reference help
- ✅ `long_help` - Complete detailed help

### Optional But Recommended

- ℹ️ `usage` - Usage patterns and workflows
- ℹ️ `output` - Output format description
- ℹ️ `related` - Related commands
- ℹ️ `see_also` - Documentation links

---

## Schema Validation Rules

Help files are validated against these rules:

1. **File Format:** Must be valid YAML
2. **Required Fields:** All marked "Required" above must be present
3. **Field Types:** Fields must match declared types (string, array, object)
4. **String Lengths:**
   - `description`: 1-100 characters
   - `short_help.summary`: 1-80 characters
   - `short_help.synopsis`: 1-100 characters
5. **Example Count:** At least 2 examples required
6. **Option Descriptions:** All options must have descriptions
7. **Command Naming:** Command names must be lowercase with hyphens

---

## Example: Complete Help File

Here's a complete example of a well-formed help YAML file:

```yaml
command: validate-config
description: "Validate a YAML configuration file against the configuration schema"
type: command
category: yaml

syntax:
  usage: "dirforge validate-config <config-file>"
  arguments:
    - name: config-file
      description: "Path to YAML configuration file (.yaml extension)"
      required: true
  options:
    - flag: --quiet, -q
      description: "Suppress output; use exit code to check result"
    - flag: --json
      description: "Output validation errors as JSON"
    - flag: --verbose, -v
      description: "Show detailed validation trace"
  variants:
    - "dirforge validate-config ~/custom.yaml"
    - "dirforge validate-config --json templates/world-configs/coding.yaml"

usage:
  patterns:
    - name: quick-check
      description: "Quick validation with minimal output"
      command: "dirforge validate-config config.yaml"
    
    - name: detailed-validation
      description: "Full validation trace for debugging"
      command: "dirforge validate-config --verbose config.yaml"
    
    - name: automation
      description: "JSON output for use in scripts"
      command: "dirforge validate-config --json config.yaml | jq ."
  
  common_workflows:
    - name: "Validate before using"
      description: "Always validate a custom config before using with dirforge init"
      steps:
        - "Create custom world configuration file"
        - "Run validate-config to check for errors"
        - "Fix any reported issues"
        - "Use config with 'dirforge init --config custom.yaml'"

examples:
  - title: "Validate built-in CODING_WORLD config"
    command: "dirforge validate-config templates/world-configs/coding.yaml"
    description: "Check if the standard CODING_WORLD configuration is valid"
    output: |
      ✓ Config validation passed
        - world.type: CODING_WORLD
        - metadata.version: 1.0.0
        - 8 parent directories configured
        - All required fields present

  - title: "Validate custom configuration with JSON output"
    command: "dirforge validate-config --json ~/my-world.yaml"
    description: "Validate with JSON output for automated processing"
    expected_exit_code: 0

  - title: "Validate with verbose trace for debugging"
    command: "dirforge validate-config --verbose ~/problematic.yaml"
    description: "Get detailed validation trace to diagnose issues"

output:
  format: text
  description: "Validation results with status indicator and details"
  example: |
    ✓ Config validation passed
      - world.type: CODING_WORLD
      - metadata.version: 1.0.0
      - parent_directories: 8
      - All required fields present

related:
  - command: list-configs
    reason: "See available configurations before validating"
  
  - command: init --config
    reason: "Use a validated configuration to create workspace"
  
  - command: help yaml-config-system
    reason: "Learn about the YAML configuration system"

see_also:
  - title: "YAML Configuration System"
    link: "yaml-config-system"
    type: help-topic
  
  - title: "Custom World Configuration Guide"
    link: "custom-world"
    type: help-topic
  
  - title: "Configuration Schema"
    link: "templates/world-configs/SCHEMA.md"
    type: documentation

short_help:
  summary: "Validate a YAML configuration file"
  synopsis: "dirforge validate-config <config-file>"
  quick_options:
    - flag: --quiet
      description: "Suppress output"
    - flag: --json
      description: "Output as JSON"
  hint: "Always validate custom configs before using with 'dirforge init --config'"

long_help:
  summary: |
    The validate-config command checks whether a YAML configuration file is valid
    according to the DirForge configuration schema. It verifies that all required
    fields are present, checks that field types are correct, and validates nested
    structures. Use this command before deploying a custom world configuration to
    ensure it will work correctly with dirforge init.
  
  details: |
    Configuration files must follow the structure defined in templates/world-configs/SCHEMA.md.
    Validation is strict and will reject files with missing required fields or
    incorrect field types. Detailed error messages help you fix validation issues.
  
  important_notes:
    - "Configuration files must have .yaml extension"
    - "All required fields must be present and correctly typed"
    - "Validation is strict; extra fields will cause errors"
    - "Invalid configs cannot be used with 'dirforge init --config'"
  
  all_options:
    - flag: --quiet, -q
      description: "Suppress all output; check exit code for result (0=valid, 1=invalid)"
    - flag: --json
      description: "Output validation errors as JSON for use in automation and scripts"
    - flag: --verbose, -v
      description: "Show detailed validation trace and intermediate steps"
    - flag: --help, -h
      description: "Display this help message"
```

---

## Help File Organization

Help files should be organized by topic:

```
templates/help/
├── HELP-SCHEMA.md                    # This file
├── validate-config.yaml              # Command-specific help
├── list-configs.yaml                 # Command-specific help
├── init-config.yaml                  # Command-specific help
├── yaml-config-system.yaml           # Topic help
└── custom-world.yaml                 # Topic help
```

---

## Dynamic Parsing

Help files are parsed dynamically by `lib/help_yaml_parser.sh`:

```bash
# Load help for a command
load_help_yaml "validate-config"

# Get specific section
get_help_section "validate-config" "examples"

# Get command-specific help (short)
get_command_help "validate-config"

# Get full help (long)
get_command_help "validate-config" "long"

# Format and display help
format_help_output "validate-config" "short"
```

---

## Progressive Disclosure Pattern

The help system implements progressive disclosure:

```bash
# Global help - lists available commands
dirforge --help

# Command-specific short help (essential info)
dirforge validate-config --help

# Command-specific long help (complete details)
dirforge help validate-config

# Topic help (system features)
dirforge help yaml-config-system
```

---

## Validation and Testing

All help YAML files are validated:

1. **YAML Syntax:** Must parse as valid YAML
2. **Schema Compliance:** Must match HELP-SCHEMA requirements
3. **Content Quality:** Descriptions must be clear and complete
4. **Example Accuracy:** Examples must be tested and correct
5. **Link Validity:** All cross-references must be resolvable

Help validation is performed by: `tests/test-functions/test_help_yaml_parser.sh`

---

**Schema Version:** 1.0.22  
**Last Updated:** 2025-12-30  
**Status:** Active
