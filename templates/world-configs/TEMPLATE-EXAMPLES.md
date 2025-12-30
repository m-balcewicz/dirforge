# World Configuration Template Examples

**Version:** 1.0.22  
**Status:** Active  
**Date:** 2025-12-23  
**Reference:** Constitution v1.0.22

---

## Overview

This document provides copy-paste examples for creating custom world configurations. Whether you're creating a minimal world, customizing an existing type, or building a specialized variant, you'll find examples here.

---

## Example 1: Minimal World Configuration

The simplest valid world configuration with only required fields.

### Use Case
Creating a bare-bones custom world type with minimal structure. Perfect for testing or specialized single-purpose workspaces.

### File: `custom-minimal.world.yaml`

```yaml
################################################################################
# CUSTOM_MINIMAL World Configuration
#
# @schema-version: 1.0.22
# @template-version: 1.0
# @world-type: CUSTOM_MINIMAL
# @last-updated: 2025-12-23
#
# Minimal world configuration with only required fields.
#
################################################################################

world:
  type: CUSTOM_MINIMAL
  description: "Minimal custom world configuration for testing"

metadata:
  version: "1.0.22"
  constitution_version: "1.0.22"
  created: "${DATE}"
  author: "${USER}"
  creation_template: "world.yaml.template"
  integrity_required: false
  default_owner: "${USER}"

config:
  creation_method: "template"
  scaffold_type: "world"
  atomic_transactions: true
  rollback_on_failure: true

parent_directories:
  - name: "data"
    description: "Primary data storage"
    integrity: false
    project_scope: "world"

subdirectories: []

permissions:
  default_directory: 755
  default_file: 644
  integrity_directory: 700
  integrity_file: 600
```

### Creating This Example

1. Copy the YAML above
2. Save as `templates/world-configs/custom-minimal.world.yaml`
3. Replace `${DATE}` and `${USER}` will be auto-expanded during initialization
4. Verify syntax: `yq eval '.' templates/world-configs/custom-minimal.world.yaml`

---

## Example 2: Python-Specific Coding World

A specialized variant of CODING_WORLD focused only on Python projects.

### Use Case
Organizations or teams that primarily use Python. Creates a simplified coding environment with only Python-related folders and structure.

### File: `coding.world.python-specific.yaml`

```yaml
################################################################################
# CODING_WORLD (Python-Specific) Configuration Variant
#
# @schema-version: 1.0.22
# @template-version: 1.0
# @world-type: CODING_WORLD
# @variant: python-specific
# @last-updated: 2025-12-23
#
# Specialized CODING_WORLD variant focused on Python development.
# Reduced structure compared to standard CODING_WORLD.
#
################################################################################

world:
  type: CODING_WORLD
  description: "Python-focused coding workspace with minimal structure"

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

# Simplified to Python only
parent_directories:
  - name: "python"
    description: "Python projects and development (all versions)"
    integrity: true
    project_scope: "world"

subdirectories:
  - parent: "python"
    structure:
      - name: "3.11"
        type: "folder"
        description: "Python 3.11 projects"
      - name: "3.12"
        type: "folder"
        description: "Python 3.12 projects"
      - name: "scientific"
        type: "folder"
        description: "Scientific computing with NumPy, SciPy, etc."

permissions:
  default_directory: 755
  default_file: 644
  integrity_directory: 700
  integrity_file: 600
```

### Creating This Example

1. Copy the YAML above
2. Save as `templates/world-configs/coding.world.python-specific.yaml`
3. Use with: `dirforge init coding --config coding.world.python-specific.yaml`
4. Adjust subdirectories for your Python versions and focus areas

---

## Example 3: Data Science Project World

A specialized world for data science work with dedicated sections for data, notebooks, models, and results.

### Use Case
Data scientists and ML engineers who need organized structure for datasets, Jupyter notebooks, trained models, and experiment outputs.

### File: `datascience.world.yaml`

```yaml
################################################################################
# DATASCIENCE_WORLD Configuration
#
# @schema-version: 1.0.22
# @template-version: 1.0
# @world-type: DATASCIENCE_WORLD
# @last-updated: 2025-12-23
#
# Specialized world for data science projects with dedicated folders for
# data management, experimentation, model storage, and results tracking.
#
################################################################################

world:
  type: DATASCIENCE_WORLD
  description: "Data science workspace with dedicated structure for ML workflows"

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
    description: "Administrative files, notes, and metadata"
    integrity: true
    project_scope: "world"
  - name: "01_data"
    description: "Raw and processed datasets"
    integrity: true
    project_scope: "world"
  - name: "02_notebooks"
    description: "Jupyter notebooks for exploration and experimentation"
    integrity: true
    project_scope: "world"
  - name: "03_models"
    description: "Trained models and model artifacts"
    integrity: true
    project_scope: "world"
  - name: "04_results"
    description: "Experiment results and evaluation outputs"
    integrity: true
    project_scope: "world"

subdirectories:
  - parent: "01_data"
    structure:
      - name: "raw"
        type: "folder"
        description: "Original, immutable raw datasets"
      - name: "processed"
        type: "folder"
        description: "Cleaned and transformed datasets"
      - name: "external"
        type: "folder"
        description: "Third-party datasets"
  - parent: "02_notebooks"
    structure:
      - name: "exploratory"
        type: "folder"
        description: "EDA and data exploration notebooks"
      - name: "experimentation"
        type: "folder"
        description: "Model training and hyperparameter experimentation"
      - name: "reports"
        type: "folder"
        description: "Polished notebooks for presentation/publication"
  - parent: "03_models"
    structure:
      - name: "checkpoints"
        type: "folder"
        description: "Training checkpoints and intermediate models"
      - name: "final"
        type: "folder"
        description: "Final trained models ready for deployment"
      - name: "archived"
        type: "folder"
        description: "Previous model versions and experiments"
  - parent: "04_results"
    structure:
      - name: "metrics"
        type: "folder"
        description: "Performance metrics and evaluations"
      - name: "plots"
        type: "folder"
        description: "Visualizations and plots"
      - name: "reports"
        type: "folder"
        description: "Final result reports and summaries"

permissions:
  default_directory: 755
  default_file: 644
  integrity_directory: 700
  integrity_file: 600
```

### Creating This Example

1. Copy the YAML above
2. Save as `templates/world-configs/datascience.world.yaml`
3. Initialize: `dirforge init datascience`
4. Customize parent folder names if needed (e.g., rename "04_results" to "05_results")

---

## Example 4: Complete Template with All Fields

A fully documented template showing every possible field with explanations. Use this as a reference when creating your own custom world.

### File: `template.world.yaml.complete`

```yaml
################################################################################
# CUSTOM_WORLD Configuration Template (Complete Reference)
#
# @schema-version: 1.0.22
# @template-version: 1.0
# @world-type: CUSTOM_WORLD
# @last-updated: 2025-12-23
#
# This is a REFERENCE TEMPLATE showing all possible fields and options.
# For minimal examples, see Example 1 in TEMPLATE-EXAMPLES.md
#
# INSTRUCTIONS:
# 1. Copy this file: cp template.world.yaml.complete your-world.world.yaml
# 2. Replace CUSTOM_WORLD with your desired world type (UPPERCASE)
# 3. Update description, parent_directories, and subdirectories
# 4. Delete any sections you don't need (subdirectories can be empty)
# 5. Verify syntax: yq eval '.' your-world.world.yaml
# 6. Place in templates/world-configs/ directory
#
################################################################################

# SECTION 1: WORLD DEFINITION
# Identifies the world type and purpose
world:
  type: CUSTOM_WORLD                                    # Required: Your world type (UPPERCASE)
  description: "Description of your custom world type"  # Required: Human-readable purpose

# SECTION 2: METADATA
# Version, creation info, and initialization settings
metadata:
  version: "1.0.22"                        # Required: Schema version (typically matches Constitution version)
  constitution_version: "1.0.22"           # Required: Constitution version this config conforms to
  created: "${DATE}"                       # Required: Creation timestamp (will auto-expand to ISO 8601 UTC)
  author: "${USER}"                        # Required: Creator username (will auto-expand to current user)
  creation_template: "world.yaml.template" # Required: Template filename (always use this standard name)
  integrity_required: true                 # Required: Whether .integrity/ directories should be created
  default_owner: "${USER}"                 # Required: Default owner (will auto-expand to current user)

# SECTION 3: CONFIG
# Controls how scaffold generation behaves
config:
  creation_method: "template"      # Required: How this config was created (always "template")
  scaffold_type: "world"           # Required: Type of scaffold ("world", "project", "study")
  atomic_transactions: true        # Required: All-or-nothing creation (prevents partial scaffolds)
  rollback_on_failure: true        # Required: Whether to rollback on errors

# SECTION 4: PARENT DIRECTORIES
# Top-level folders that define the world structure
parent_directories:
  # Each item represents a major folder in your world
  - name: "your_folder_1"              # Required: Folder name (lowercase, underscore-separated)
    description: "Purpose of folder"   # Required: Human-readable description
    integrity: true                    # Optional: Create .integrity/ subdirectory (true/false, default: false)
    project_scope: "world"             # Optional: Scope level ("world" or "project", default: "world")
  
  - name: "your_folder_2"
    description: "Another folder"
    integrity: false
    project_scope: "world"

  # You can have as many parent directories as needed
  - name: "archive"
    description: "Archived or historical content"
    integrity: false
    project_scope: "world"

# SECTION 5: SUBDIRECTORIES
# Nested folder structures under parent directories
# This section can be empty [] if you don't need nesting
subdirectories:
  # Structure: parent_name -> list of subdirectories
  - parent: "your_folder_1"         # Which parent directory contains these subdirs
    structure:
      - name: "subfolder_a"         # Subfolder name
        type: "folder"              # Type (always "folder" for now)
        description: "Purpose"      # Description
      - name: "subfolder_b"
        type: "folder"
        description: "Another subdirectory"
  
  - parent: "your_folder_2"
    structure:
      - name: "data"
        type: "folder"
        description: "Data storage"
      - name: "results"
        type: "folder"
        description: "Results and outputs"

# SECTION 6: PERMISSIONS
# Default file/directory permissions
permissions:
  default_directory: 755           # Default for all directories (rwxr-xr-x)
  default_file: 644               # Default for all files (rw-r--r--)
  integrity_directory: 700         # .integrity/ directories (rwx------)
  integrity_file: 600             # .integrity/ files (rw-------)

################################################################################
# SCHEMA VALIDATION CHECKLIST
# 
# Before using your config, verify:
# - [ ] world.type is present and UPPERCASE
# - [ ] world.description is meaningful
# - [ ] metadata.version is "1.0.22"
# - [ ] metadata.constitution_version is "1.0.22"
# - [ ] metadata.created is "${DATE}" (will auto-expand)
# - [ ] metadata.author is "${USER}" (will auto-expand)
# - [ ] metadata.creation_template is "world.yaml.template"
# - [ ] metadata.integrity_required is true or false
# - [ ] metadata.default_owner is "${USER}"
# - [ ] config.creation_method is "template"
# - [ ] config.scaffold_type is "world", "project", or "study"
# - [ ] config.atomic_transactions is true
# - [ ] config.rollback_on_failure is true
# - [ ] parent_directories has at least 1 entry
# - [ ] Each parent has: name, description, integrity, project_scope
# - [ ] subdirectories is present (can be empty [])
# - [ ] permissions has all 4 fields with numeric values
# - [ ] YAML syntax is valid (yq eval '.' your-file.yaml)
#
################################################################################
```

### Using This Template

1. Copy the above as `your-custom.world.yaml`
2. Update the CUSTOM_WORLD type and description
3. Add/remove parent_directories and subdirectories as needed
4. Verify with: `yq eval '.' your-custom.world.yaml`
5. Place in `templates/world-configs/`

---

## Example 5: Custom Research World (Multi-Project)

A specialized research world for teams managing multiple concurrent projects with shared infrastructure.

### Use Case
Research groups managing multiple projects with shared datasets, shared code libraries, and individual project organization.

### File: `research.world.multi-project.yaml`

```yaml
################################################################################
# RESEARCH_WORLD (Multi-Project) Configuration Variant
#
# @schema-version: 1.0.22
# @template-version: 1.0
# @world-type: RESEARCH_WORLD
# @variant: multi-project
# @last-updated: 2025-12-23
#
# Specialized RESEARCH_WORLD variant for managing multiple concurrent
# research projects with shared resources.
#
################################################################################

world:
  type: RESEARCH_WORLD
  description: "Multi-project research workspace with shared infrastructure"

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
  - name: "00_shared_resources"
    description: "Shared code, libraries, and datasets used by all projects"
    integrity: true
    project_scope: "world"
  - name: "01_active_projects"
    description: "Currently active research projects"
    integrity: true
    project_scope: "world"
  - name: "02_archived_projects"
    description: "Completed or inactive projects"
    integrity: true
    project_scope: "world"

subdirectories:
  - parent: "00_shared_resources"
    structure:
      - name: "code_libraries"
        type: "folder"
        description: "Common code shared across projects"
      - name: "datasets"
        type: "folder"
        description: "Shared reference datasets"
      - name: "templates"
        type: "folder"
        description: "Standard templates and protocols"
  - parent: "01_active_projects"
    structure:
      - name: "project_a"
        type: "folder"
        description: "Project A workspace"
      - name: "project_b"
        type: "folder"
        description: "Project B workspace"
  - parent: "02_archived_projects"
    structure:
      - name: "completed"
        type: "folder"
        description: "Completed and published projects"

permissions:
  default_directory: 755
  default_file: 644
  integrity_directory: 700
  integrity_file: 600
```

---

## How to Create Your Own World Configuration

### Step-by-Step Guide

1. **Choose a world type name**
   ```
   CUSTOM_WORLD, MY_WORLD, ORGANIZATION_WORLD, etc.
   (Use UPPERCASE with underscores)
   ```

2. **Decide on parent directories**
   ```
   What are your main organizational sections?
   Examples: projects, data, results, archive
   ```

3. **Plan subdirectories (optional)**
   ```
   What nested structures do you need?
   Can be empty [] if not needed
   ```

4. **Select a template**
   ```
   - Example 1 for minimal needs
   - Example 2 for variants of existing types
   - Example 3-5 for specialized domains
   - Example 4 for complete reference
   ```

5. **Create your file**
   ```bash
   # Copy a template
   cp templates/world-configs/SCHEMA.md my-world.world.yaml
   
   # Edit and customize
   vim my-world.world.yaml
   ```

6. **Validate syntax**
   ```bash
   yq eval '.' my-world.world.yaml
   ```

7. **Move to correct location**
   ```bash
   mv my-world.world.yaml templates/world-configs/
   ```

8. **Test initialization (optional)**
   ```bash
   dirforge init my-world --config templates/world-configs/my-world.world.yaml
   ```

---

## Common Customization Patterns

### Pattern 1: Numbered Folder Organization

For strict hierarchical organization:

```yaml
parent_directories:
  - name: "00_admin"
    description: "Administrative section"
  - name: "01_data"
    description: "Data management section"
  - name: "02_processing"
    description: "Data processing section"
  - name: "03_results"
    description: "Results and outputs section"
  - name: "04_archive"
    description: "Archive and history section"
```

### Pattern 2: Functional Organization

For role or function-based structure:

```yaml
parent_directories:
  - name: "development"
    description: "Development and testing"
  - name: "production"
    description: "Production deployments"
  - name: "documentation"
    description: "Documentation and manuals"
```

### Pattern 3: Timeline-Based Organization

For time-series or project-phase organization:

```yaml
parent_directories:
  - name: "ongoing"
    description: "Currently active work"
  - name: "completed"
    description: "Finished and delivered"
  - name: "planned"
    description: "Planned future work"
```

---

## Quick Reference: Field Constraints

| Field | Constraints | Example |
|-------|-----------|---------|
| `world.type` | UPPERCASE, no spaces | `CUSTOM_WORLD` |
| `parent_directories[].name` | lowercase, underscore-separated | `my_project_data` |
| `parent_directories[].integrity` | `true` or `false` | `true` |
| `subdirectories[].parent` | Must match a parent directory name | `my_project_data` |
| `permissions.default_directory` | 3-digit octal (755 typical) | `755` |
| `${DATE}` | Will expand to ISO 8601 UTC | `2025-12-23T14:30:45Z` |
| `${USER}` | Will expand to current Unix user | `martin` |

---

## Validation Command

```bash
# Quick syntax check
yq eval '.' templates/world-configs/your-world.world.yaml

# Full schema validation (when validate-config command is ready)
dirforge validate-config templates/world-configs/your-world.world.yaml
```

---

## References

- **Full Schema:** `templates/world-configs/SCHEMA.md`
- **Constitution:** v1.0.22, Section IV.B
- **User Guide:** `docs/yaml-config-user-guide.md`

---

**Template Examples Version:** 1.0.22  
**Last Updated:** 2025-12-23  
**Status:** Active

