# World Configuration Schema Specification

**Version:** 1.0.22  
**Status:** Active  
**Date:** 2025-12-23  
**Reference:** Constitution v1.0.22

---

## Overview

This document specifies the complete schema for world configuration files (`.world.yaml`) in the dirforge YAML-Driven Configuration System. Each world configuration file defines the folder structure, metadata, and permissions for a specific world type.

---

## File Location & Naming

- **Location:** `templates/world-configs/`
- **Naming Convention:** `<world-type>.world.yaml`
- **Variants:** `<world-type>.world.<variant>.yaml` (for future use)
- **Example:** `research.world.yaml`, `coding.world.yaml`

---

## Complete Schema Definition

### Root Level

```yaml
world:            # Required: World definition section
metadata:         # Required: Metadata section
config:           # Required: Configuration section
parent_directories:  # Required: Parent folder definitions
subdirectories:   # Required: Nested folder definitions (can be empty)
permissions:      # Required: Permission defaults
```

---

## Section: `world`

Defines the world type and purpose.

### Fields

| Field | Type | Required | Description | Example |
|-------|------|----------|-------------|---------|
| `type` | string | Yes | World type identifier (UPPERCASE) | `RESEARCH_WORLD` |
| `description` | string | Yes | Human-readable description | `"Research and experimental work..."` |

### Example

```yaml
world:
  type: RESEARCH_WORLD
  description: "Research and experimental work workspace with project and study hierarchies"
```

---

## Section: `metadata`

Defines metadata and version information.

### Fields

| Field | Type | Required | Description | Format/Values |
|-------|------|----------|-------------|----------------|
| `version` | string | Yes | Constitution version | `"1.0.22"` |
| `constitution_version` | string | Yes | Constitution version this config conforms to | `"1.0.22"` |
| `created` | string | Yes | Creation timestamp (variable placeholder) | `"${DATE}"` (expands to ISO 8601 UTC) |
| `author` | string | Yes | Creator username (variable placeholder) | `"${USER}"` (expands to current user) |
| `creation_template` | string | Yes | Template filename (must be standard name) | `"world.yaml.template"` (not world-type-specific) |
| `integrity_required` | boolean | Yes | Whether `.integrity/` directories should be created | `true` or `false` |
| `default_owner` | string | Yes | Default owner username (variable placeholder) | `"${USER}"` (expands to current user) |

### Variable Expansion

- `${DATE}` → ISO 8601 UTC format: `YYYY-MM-DDTHH:MM:SSZ` (e.g., `2025-12-23T14:30:45Z`)
- `${USER}` → Current Unix username (e.g., `martin`)

### Example

```yaml
metadata:
  version: "1.0.22"
  constitution_version: "1.0.22"
  created: "${DATE}"
  author: "${USER}"
  creation_template: "world.yaml.template"
  integrity_required: true
  default_owner: "${USER}"
```

---

## Section: `config`

Defines configuration options and behavior.

### Fields

| Field | Type | Required | Description | Valid Values |
|-------|------|----------|-------------|--------------|
| `creation_method` | string | Yes | How the scaffold is created | `"template"` (currently only value) |
| `scaffold_type` | string | Yes | Type of scaffold being defined | `"world"` or `"project"` or `"study"` |
| `atomic_transactions` | boolean | Yes | Whether operations are atomic (all-or-nothing) | `true` or `false` |
| `rollback_on_failure` | boolean | Yes | Whether to rollback on any error | `true` or `false` |

### Example

```yaml
config:
  creation_method: "template"
  scaffold_type: "world"
  atomic_transactions: true
  rollback_on_failure: true
```

---

## Section: `parent_directories`

Defines the top-level folders for this world type. These are created immediately under the world name.

### Structure

```yaml
parent_directories:
  - name: "<folder_name>"
    description: "<purpose>"
    integrity: <true|false>
    project_scope: "<world|project>"
  - name: "<folder_name>"
    ...
```

### Fields for Each Entry

| Field | Type | Required | Description | Notes |
|-------|------|----------|-------------|-------|
| `name` | string | Yes | Folder name (no spaces) | Use `00_prefix` numbering for ordering |
| `description` | string | Yes | Purpose and contents | Human-readable explanation |
| `integrity` | boolean | Yes | Whether folder has `.integrity/` subdirectory | `true` = sensitive, `false` = general |
| `project_scope` | string | Yes | Scope of this folder | `"world"` = world-level, `"project"` = project-level |

### Naming Conventions

- **Numbered Folders:** Use `00_`, `01_`, etc. for ordering (preferred for multi-folder worlds)
- **Language/Category Folders:** Direct names without numbering (e.g., `python`, `matlab` for CODING_WORLD)
- **No Spaces:** Use underscores for multi-word names (e.g., `00_project_management`)

### Example

```yaml
parent_directories:
  - name: "00_admin"
    description: "Administrative materials, quick inbox, and project metadata"
    integrity: true
    project_scope: "project"
  - name: "01_project_management"
    description: "Planning documents, milestones, and timeline"
    integrity: true
    project_scope: "project"
  - name: "02_studies"
    description: "Individual study folders with their own complete workflows"
    integrity: true
    project_scope: "project"
```

---

## Section: `subdirectories`

Defines nested folder structures within parent directories. Can be empty list if no nesting is needed.

### Structure

```yaml
subdirectories:
  - parent: "<parent_folder_name>"
    description: "<purpose_of_structure>"
    structure:
      - name: "<subfolder_name>"
        type: "folder"
        description: "<purpose>"
      - name: "<subfolder_name>"
        type: "folder"
        description: "<purpose>"
        children:  # Optional: further nesting
          - name: "<child_folder>"
            type: "folder"
            description: "<purpose>"
```

### Fields for Each Subdirectory Entry

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `parent` | string | Yes | Name of the parent folder (must exist in `parent_directories`) |
| `description` | string | Yes | Purpose of this folder structure |
| `structure` | array | Yes | Array of folders to create under parent |

### Fields for Each Structure Item

| Field | Type | Required | Description | Notes |
|-------|------|----------|-------------|-------|
| `name` | string | Yes | Subfolder name | Relative to parent |
| `type` | string | Yes | Always `"folder"` | Reserved for future file types |
| `description` | string | Yes | Purpose of this subfolder | Human-readable |
| `children` | array | No | Nested structure (recursive) | For multi-level nesting |

### Empty Subdirectories

When a world type has no required nested structures, use an empty list:

```yaml
subdirectories: []
```

### Example: With Nested Structure

```yaml
subdirectories:
  - parent: "01_project_management"
    description: "Project management folder structure"
    structure:
      - name: "01_documents"
        type: "folder"
        description: "Planning and status documents"
      - name: "02_timeline"
        type: "folder"
        description: "Timeline and milestone tracking"
      - name: "03_meetings"
        type: "folder"
        description: "Meeting notes and decisions"

  - parent: "02_studies"
    description: "Per-study folder structure (repeated for each study)"
    structure:
      - name: "00_protocols"
        type: "folder"
        description: "Experimental protocols"
      - name: "01_code"
        type: "folder"
        description: "Analysis and processing code"
      - name: "02_data"
        type: "folder"
        description: "Raw and processed data"
        children:
          - name: "raw"
            type: "folder"
            description: "Unprocessed experimental data"
          - name: "processed"
            type: "folder"
            description: "Analysis-ready data"
```

### Example: Empty Subdirectories

```yaml
subdirectories: []
```

---

## Section: `permissions`

Defines default permission modes for created folders and files.

### Fields

| Field | Type | Description | Value | Notes |
|-------|------|-------------|-------|-------|
| `default_directory` | octal | Default permission for regular directories | `755` | `rwxr-xr-x` |
| `default_file` | octal | Default permission for regular files | `644` | `rw-r--r--` |
| `integrity_directory` | octal | Permission for `.integrity/` directories | `700` | `rwx------` (owner only) |
| `integrity_file` | octal | Permission for `.integrity/` files | `600` | `rw-------` (owner only) |

### Permission Model

- **Regular Directories:** `755` (rwxr-xr-x) — Owner can do anything, others can read/execute
- **Regular Files:** `644` (rw-r--r--) — Owner can read/write, others can read
- **.integrity/ Directories:** `700` (rwx------) — Owner only, full control
- **.integrity/ Files:** `600` (rw-------) — Owner only, read/write

### Example

```yaml
permissions:
  default_directory: 755
  default_file: 644
  integrity_directory: 700
  integrity_file: 600
```

---

## Complete Example: RESEARCH_WORLD

```yaml
################################################################################
# RESEARCH_WORLD Configuration Template
#
# @schema-version: 1.0.22
# @template-version: 1.0
# @world-type: RESEARCH_WORLD
# @last-updated: 2025-12-23
#
# Defines the complete research project structure with hierarchical organization.
# For schema documentation, see: templates/world-configs/SCHEMA.md
#
################################################################################

world:
  type: RESEARCH_WORLD
  description: "Research and experimental work workspace with project and study hierarchies"

metadata:
  version: "1.0.22"
  constitution_version: "1.0.22"
  created: "${DATE}"
  author: "${USER}"
  creation_template: "world.yaml.template"
  integrity_required: true
  default_owner: "${USER}"

config:
  creation_method: "template"
  scaffold_type: "world"
  atomic_transactions: true
  rollback_on_failure: true

parent_directories:
  - name: "00_admin"
    description: "Project administrative artifacts and metadata"
    integrity: true
    project_scope: "project"
  - name: "01_project_management"
    description: "Planning, timeline, and project documents"
    integrity: true
    project_scope: "project"
  - name: "02_studies"
    description: "Individual study folders with complete workflows"
    integrity: true
    project_scope: "project"

subdirectories:
  - parent: "01_project_management"
    description: "Project management folder structure"
    structure:
      - name: "01_documents"
        type: "folder"
        description: "Planning and status documents"
      - name: "02_timeline"
        type: "folder"
        description: "Timeline and milestone tracking"

  - parent: "02_studies"
    description: "Per-study folder structure"
    structure:
      - name: "00_protocols"
        type: "folder"
        description: "Experimental protocols"
      - name: "01_code"
        type: "folder"
        description: "Analysis and processing code"
      - name: "02_data"
        type: "folder"
        description: "Raw and processed data"
      - name: "03_outputs"
        type: "folder"
        description: "Analysis results and figures"

permissions:
  default_directory: 755
  default_file: 644
  integrity_directory: 700
  integrity_file: 600
```

---

## Validation Rules

### Required Fields (All Configs)

Every world configuration file MUST contain:
1. ✓ `world.type` — World type identifier
2. ✓ `world.description` — Human-readable description
3. ✓ `metadata.version` — Constitution version (must be "1.0.22")
4. ✓ `metadata.constitution_version` — Constitution version (must be "1.0.22")
5. ✓ `metadata.created` — Creation timestamp (use `${DATE}`)
6. ✓ `metadata.author` — Creator (use `${USER}`)
7. ✓ `metadata.creation_template` — Must be `"world.yaml.template"`
8. ✓ `metadata.integrity_required` — Boolean flag
9. ✓ `metadata.default_owner` — Owner (use `${USER}`)
10. ✓ `config.creation_method` — Must be `"template"`
11. ✓ `config.scaffold_type` — Must be `"world"`, `"project"`, or `"study"`
12. ✓ `config.atomic_transactions` — Boolean flag
13. ✓ `config.rollback_on_failure` — Boolean flag
14. ✓ `parent_directories` — Array (at least one entry)
15. ✓ `subdirectories` — Array (can be empty `[]`)
16. ✓ `permissions` — All four permission fields

### Parent Directories Rules

- ✓ Must have `name`, `description`, `integrity`, `project_scope`
- ✓ All names must be unique within the file
- ✓ `project_scope` must be `"world"` or `"project"`
- ✓ Names with numbers should use `00_`, `01_`, etc. format
- ✓ No spaces in folder names

### Subdirectories Rules

- ✓ If empty, must be `subdirectories: []`
- ✓ If populated, each entry must have `parent`, `description`, `structure`
- ✓ `parent` must reference an existing parent directory
- ✓ Each structure item must have `name`, `type` (always `"folder"`), `description`
- ✓ Optional `children` for further nesting

### Permission Rules

- ✓ Must specify all four permission fields
- ✓ Regular directories: `755`
- ✓ Regular files: `644`
- ✓ .integrity/ directories: `700`
- ✓ .integrity/ files: `600`

---

## File Format

- **Format:** YAML 1.2
- **Encoding:** UTF-8
- **Line Endings:** LF (Unix)
- **Indentation:** 2 spaces (not tabs)
- **Comments:** Use `#` for comments (preserved in metadata)

---

## Header Format (Standard for All Templates)

```yaml
################################################################################
# <WORLD>_WORLD Configuration Template
#
# @schema-version: 1.0.22
# @template-version: 1.0
# @world-type: <WORLD>_WORLD
# @last-updated: YYYY-MM-DD
#
# Brief description of purpose.
# For schema documentation, see: templates/world-configs/SCHEMA.md
#
################################################################################
```

---

## Variable Expansion

### Supported Variables

| Variable | Expands To | Format | Example |
|----------|-----------|--------|---------|
| `${USER}` | Current Unix username | String | `martin` |
| `${DATE}` | ISO 8601 UTC timestamp | `YYYY-MM-DDTHH:MM:SSZ` | `2025-12-23T14:30:45Z` |

### Variable Replacement Rules

- Variables are expanded **during scaffold generation**, not during parsing
- Variables must use exact syntax: `${VARIABLE_NAME}` (case-sensitive)
- Unknown variables are left as-is (not expanded)
- Only `${USER}` and `${DATE}` are currently supported

---

## World Types

### Supported World Types (v1.0.22)

| Type | File | Status | Parent Count | Notes |
|------|------|--------|--------------|-------|
| CODING_WORLD | `coding.world.yaml` | Active | 8 | Language-specific folders |
| RESEARCH_WORLD | `research.world.yaml` | Active | 3 | Projects + studies |
| JOURNAL_WORLD | `journal.world.yaml` | Active | 4 | Role-based organization |
| LECTURE_WORLD | `lecture.world.yaml` | Active | 8 | Course management |
| OFFICE_WORLD | `office.world.yaml` | Active | 7 | Administrative |
| PRIVATE_WORLD | `private.world.yaml` | Active | 10 | Personal (restricted) |
| LITERATURE_WORLD | `literature.world.yaml` | Placeholder | 2 | Knowledge management (future) |

---

## Conformance Testing

To validate a config file against this schema:

```bash
# Syntax validation (YAML only)
yq eval '.' templates/world-configs/research.world.yaml

# Schema conformance (manual or with validator)
dirforge validate-config templates/world-configs/research.world.yaml
```

---

## Template Examples for Custom Configurations

Creating custom world configurations is straightforward. See **`TEMPLATE-EXAMPLES.md`** for:

- **Example 1:** Minimal world config (required fields only)
- **Example 2:** Python-specific coding world variant
- **Example 3:** Data science project world (specialized domain)
- **Example 4:** Complete template with all possible fields
- **Example 5:** Multi-project research world variant

### Quick Start: Copy-Paste Template

The **Complete Template (Example 4)** in `TEMPLATE-EXAMPLES.md` contains every field with inline documentation. Copy it and customize for your needs:

```bash
# Copy template example
cp templates/world-configs/TEMPLATE-EXAMPLES.md my-custom.world.yaml

# Edit your custom config
vim my-custom.world.yaml

# Validate syntax
yq eval '.' my-custom.world.yaml

# Place in world-configs directory
mv my-custom.world.yaml templates/world-configs/

# Initialize your world
dirforge init my-custom
```

### Creating Custom Variants

You can create specialized variants of existing world types by adding variant identifiers:

```
coding.world.python-specific.yaml   # Python-only variant
research.world.multi-project.yaml   # Multi-project variant
journal.world.academic.yaml         # Academic-focused variant
```

See `TEMPLATE-EXAMPLES.md` for complete variant examples.

---

## References

- **Constitution:** v1.0.22, Section IV.B (World Configuration System)
- **Template Examples:** `templates/world-configs/TEMPLATE-EXAMPLES.md`
- **Related Files:**
  - Config Files: `templates/world-configs/*.world.yaml`
  - Parsing API: `docs/yaml-parsing-api.md`
  - User Guide: `docs/yaml-config-user-guide.md`

---

**Schema Version:** 1.0.22  
**Last Updated:** 2025-12-23  
**Status:** Active
