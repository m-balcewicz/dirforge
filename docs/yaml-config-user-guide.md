# YAML Configuration System — User Guide & Quick-Start

**Version:** 1.0.22  
**Last Updated:** 2025-12-30

---

## Table of Contents

1. [Quick-Start Guide](#quick-start-guide)
2. [Basic Usage](#basic-usage)
3. [Command Reference](#command-reference)
4. [Configuration Files](#configuration-files)
5. [Creating Custom Worlds](#creating-custom-worlds)
6. [Best Practices](#best-practices)
7. [Troubleshooting](#troubleshooting)
8. [FAQ](#faq)

---

## Quick-Start Guide

### 5-Minute Setup

**1. Initialize a Coding Workspace**
```bash
dirforge init CODING_WORLD
cd ~/coding_workspace
```

**2. List Available Worlds**
```bash
dirforge list-configs
```

Output:
```
CODING_WORLD      coding.world.yaml
RESEARCH_WORLD    research.world.yaml
JOURNAL_WORLD     journal.world.yaml
LECTURE_WORLD     lecture.world.yaml
OFFICE_WORLD      office.world.yaml
PRIVATE_WORLD     private.world.yaml
LITERATURE_WORLD  literature.world.yaml
```

**3. Validate a Configuration**
```bash
dirforge validate-config templates/world-configs/coding.world.yaml
```

Output:
```
✓ Config validation passed
  - world.type: CODING_WORLD
  - metadata.version: 1.0.22
  - parent_directories: 8
  - All required fields present
```

**4. Initialize Different World Types**
```bash
# Research workspace
dirforge init RESEARCH_WORLD --project my_research

# Journal workspace
dirforge init JOURNAL_WORLD

# Lecture workspace  
dirforge init LECTURE_WORLD
```

**5. Explore Generated Structure**
```bash
# See what was created
ls -la ~/coding_workspace/
cd ~/coding_workspace/python
ls -la .integrity/  # View metadata
```

---

## Basic Usage

### Initialize Worlds

**Default Initialization (Inferred Config):**
```bash
# Automatically finds templates/world-configs/coding.world.yaml
dirforge init CODING_WORLD

# Creates:
# ~/coding_workspace/
# ├── python/
# ├── matlab/
# ├── bash/
# ├── fortran/
# ├── c/
# ├── latex/
# ├── clusters/
# └── github/
```

**RESEARCH_WORLD with Project:**
```bash
# Create project structure
dirforge init RESEARCH_WORLD --project myproject

# Creates:
# ~/research_workspace/
# └── myproject/
#     ├── .integrity/project.yaml
#     └── (project subdirectories)
```

**RESEARCH_WORLD with Project and Study:**
```bash
# Create project and study
dirforge init RESEARCH_WORLD \
    --project myproject \
    --study mystudy

# Creates study-level structure with metadata
```

### Explicit Config Path

**Using Custom Configuration:**
```bash
# Use specific config file
dirforge init --config /path/to/custom.world.yaml

# Use config in current directory
dirforge init --config ./myworld.yaml
```

### Validation Before Initialization

**Check Config Validity:**
```bash
# Validate config before using
dirforge validate-config ~/custom.world.yaml

# Fix any issues reported
# Then use with dirforge init
```

---

## Command Reference

### dirforge init

Initialize a new world workspace.

**Syntax:**
```bash
dirforge init <WORLD_TYPE> [OPTIONS]

WORLD_TYPE: One of:
  - CODING_WORLD
  - RESEARCH_WORLD
  - JOURNAL_WORLD
  - LECTURE_WORLD
  - OFFICE_WORLD
  - PRIVATE_WORLD
  - LITERATURE_WORLD

OPTIONS:
  --config <PATH>       Use explicit config file
  --project <NAME>      Specify project name (RESEARCH_WORLD)
  --study <NAME>        Specify study name (RESEARCH_WORLD)
```

**Examples:**
```bash
# Basic initialization
dirforge init CODING_WORLD

# With explicit config
dirforge init --config templates/world-configs/coding.world.yaml

# Research with project
dirforge init RESEARCH_WORLD --project data_analysis

# Research with project and study
dirforge init RESEARCH_WORLD \
    --project data_analysis \
    --study preprocessing
```

### dirforge validate-config

Validate a configuration file.

**Syntax:**
```bash
dirforge validate-config <CONFIG_FILE>

CONFIG_FILE: Path to .world.yaml file

EXIT CODES:
  0: Config valid
  1: Config invalid
```

**Examples:**
```bash
# Validate built-in config
dirforge validate-config templates/world-configs/coding.world.yaml

# Validate custom config
dirforge validate-config ~/my-custom-world.yaml

# Use in scripts
if dirforge validate-config config.yaml; then
    dirforge init --config config.yaml
else
    echo "Config validation failed"
fi
```

### dirforge list-configs

List all available configurations.

**Syntax:**
```bash
dirforge list-configs

OUTPUT:
  World Type         Config File
  ─────────────────  ──────────────────────
  CODING_WORLD       coding.world.yaml
  RESEARCH_WORLD     research.world.yaml
  ... (all 7 worlds)
```

**Examples:**
```bash
# List all available worlds
dirforge list-configs

# Use in scripts
configs=$(dirforge list-configs)
for config in $configs; do
    echo "Available: $config"
done
```

---

## Configuration Files

### Built-In World Types

**CODING_WORLD** - Programming Language Directories
```
coding/
├── python/      (Python projects)
├── matlab/      (MATLAB/Octave)
├── bash/        (Shell scripts)
├── fortran/     (FORTRAN)
├── c/           (C/C++)
├── latex/       (LaTeX documents)
├── clusters/    (HPC cluster codes)
└── github/      (GitHub clones)
```

**RESEARCH_WORLD** - Project/Study Structure
```
research/
├── project1/
│   ├── study1/
│   ├── study2/
│   └── ...
├── project2/
│   ├── study1/
│   └── ...
└── ...
```

**JOURNAL_WORLD** - Role-Based Directories
```
journal/
├── admin/
├── archive/
├── papers/
├── ...
```

**LECTURE_WORLD** - Course Structure
```
lectures/
├── lectures/
├── solutions/
├── exams/
├── grading/
├── resources/
├── admin/
└── recordings/
```

**OFFICE_WORLD** - Administrative Directories
```
office/
├── correspondence/
├── contracts/
├── finance/
├── personnel/
├── reports/
└── meetings/
```

**PRIVATE_WORLD** - Personal Organization
```
private/
├── 00_admin/
├── 10_personal/
├── 20_health/
├── 30_finance/
├── 40_travel/
├── 50_projects/
├── 60_learning/
├── 70_entertainment/
└── 90_archive/
```

**LITERATURE_WORLD** - Extensible Template
```
literature/
├── (user-defined structure)
```

### Metadata in .integrity/

Each level creates a `.integrity/` directory with metadata:

**Workspace Level:**
```yaml
# .integrity/workspace.yaml (600 permissions)
workspace_id: f47ac10b-58cc-4372-a567-0e02b2c3d479
created_by: martin
created_at: 2025-12-30T21:35:00Z
constitution_version: 1.0.22
schema_version: 1.0
```

**World Level:**
```yaml
# coding/.integrity/world.yaml (600 permissions)
world_type: CODING_WORLD
world_name: coding
created_by: martin
created_at: 2025-12-30T21:35:00Z
```

**Project Level:**
```yaml
# coding/python/.integrity/project.yaml (600 permissions)
project_name: python
parent_world: CODING_WORLD
created_by: martin
created_at: 2025-12-30T21:35:00Z
```

---

## Creating Custom Worlds

### Step 1: Create Config File

Create a new `.world.yaml` file:

```bash
cat > my-custom-world.yaml <<'EOF'
world:
  type: MYWORLD_TYPE
  description: "My custom world structure"

metadata:
  version: "1.0.0"
  constitution_version: "1.0.22"
  created_by: "${USER}"
  created_at: "${DATE}"

parent_directories:
  projects:
    description: "My projects"
  resources:
    description: "Reference materials"
  archive:
    description: "Old projects"

subdirectories:
  projects:
    - active
    - completed
    - archived
  resources:
    - documentation
    - templates
    - tools
EOF
```

### Step 2: Validate Configuration

```bash
dirforge validate-config my-custom-world.yaml
```

Output:
```
✓ Config validation passed
  - world.type: MYWORLD_TYPE
  - metadata.version: 1.0.0
  - parent_directories: 3
  - subdirectories: 6
  - All required fields present
```

### Step 3: Use Configuration

```bash
# Use with explicit path
dirforge init --config ./my-custom-world.yaml

# Or move to standard location
cp my-custom-world.yaml templates/world-configs/myworld.world.yaml
dirforge init MYWORLD_TYPE
```

### Step 4: Distribute Configuration

```bash
# Share with team
cp my-custom-world.yaml team-shared-config.yaml

# Others can use
dirforge init --config team-shared-config.yaml
```

---

## Best Practices

### 1. Validate Before Using

**Always validate custom configs:**
```bash
dirforge validate-config config.yaml || exit 1
dirforge init --config config.yaml
```

### 2. Use Appropriate World Types

- **Code projects** → CODING_WORLD
- **Research data** → RESEARCH_WORLD
- **Daily notes** → JOURNAL_WORLD
- **Courses** → LECTURE_WORLD
- **Business** → OFFICE_WORLD
- **Personal** → PRIVATE_WORLD

### 3. Consistent Naming

- Use lowercase for directory names: `my_project` not `MY_PROJECT`
- Use underscores for spaces: `data_analysis` not `data analysis`
- Keep names short and descriptive

### 4. Metadata Tracking

- `.integrity/` files track creation info
- Do NOT modify or delete metadata
- Use for auditing and structure verification

### 5. Permission Respect

- Don't modify `.integrity/` permissions (700/600)
- Use `chmod` for other directories if needed
- Default 755/644 usually appropriate

### 6. Configuration Management

- Version control config files
- Comment complex structures
- Document custom world purposes

---

## Troubleshooting

### Config Validation Fails

**Problem:** `dirforge validate-config` reports errors

**Solution:**
```bash
# Check exact error
dirforge validate-config config.yaml

# Common issues:
# 1. Missing required field (world.type, metadata.version)
# 2. Invalid YAML syntax (check indentation)
# 3. Wrong field type (should be string, not number)

# Fix and retry
dirforge validate-config config.yaml
```

### Config File Not Found

**Problem:** `Config file not found: templates/world-configs/...`

**Solution:**
```bash
# Check file exists
ls templates/world-configs/

# Use explicit path if needed
dirforge init --config /full/path/to/config.yaml

# Check environment
echo $DIRFORGE_CONFIG_PATH
```

### Permission Denied on Init

**Problem:** `Cannot create directory: Permission denied`

**Solution:**
```bash
# Check permissions on workspace
ls -ld ~/coding_workspace/

# Ensure you own the directory or have write permission
sudo chown $USER ~/coding_workspace

# Or create in different location
dirforge init CODING_WORLD ~/myworkspace
```

### Partial Scaffold Created

**Problem:** Workspace partially created on error

**Solution:**
```bash
# Transaction system automatically rolls back
# No manual cleanup needed

# Check if workspace directory exists
ls ~/coding_workspace/
# Should either be empty or not exist

# If partial files remain, manually clean:
rm -rf ~/coding_workspace/
dirforge init CODING_WORLD ~/coding_workspace
```

### Disk Space Issues

**Problem:** `No space left on device`

**Solution:**
```bash
# Check available space
df -h

# Free up space
# Then retry initialization
dirforge init CODING_WORLD ~/coding_workspace
```

---

## FAQ

### Q: Can I modify the world config after initialization?

**A:** Metadata is read-only, but you can:
- Add new subdirectories manually
- Move projects between directories
- Create additional projects

The metadata tracks what was initially created.

### Q: What happens if init fails?

**A:** The system automatically rolls back:
- All created directories removed
- All created files deleted
- Filesystem returns to original state
- No orphaned files

Just run the command again.

### Q: Can I use the same config for different workspaces?

**A:** Yes! Each initialization creates new metadata with fresh timestamps:
```bash
dirforge init CODING_WORLD ~/workspace1
dirforge init CODING_WORLD ~/workspace2
# Different timestamps, same structure
```

### Q: How do I back up my configuration?

**A:** Config files are in version control:
```bash
# Add to git
git add templates/world-configs/
git commit -m "Add custom world configs"

# Or manually copy
cp templates/world-configs/*.yaml ~/backup/
```

### Q: Can I share configs with colleagues?

**A:** Yes, they're just YAML files:
```bash
# Email or copy
scp my-world.yaml colleague:~/

# They can use
dirforge validate-config ~/my-world.yaml
dirforge init --config ~/my-world.yaml
```

### Q: What's the difference between validate-config and init?

**A:**
- `validate-config`: Just checks if config is valid (no changes)
- `init`: Validates + creates the actual workspace structure

Always validate before init to catch errors early.

### Q: Can I have nested projects in RESEARCH_WORLD?

**A:** Currently one level deep (project → study). For deeper nesting:
- Create custom world config
- Or manually create subdirectories after init

### Q: How do I recover deleted workspace?

**A:** Workspaces created by dirforge:
- No automatic backup
- Can recreate with `dirforge init`
- Metadata regenerated (different timestamps)

Keep important data in version control.

### Q: Can I change workspace permissions?

**A:** Yes, after initialization:
```bash
# Change world directory permissions
chmod 750 ~/coding_workspace/python

# .integrity remains protected (700/600)
chmod 700 ~/coding_workspace/python/.integrity
```

### Q: How do I list my projects in RESEARCH_WORLD?

**A:**
```bash
ls ~/research_workspace/
# Shows all projects

for project in ~/research_workspace/*; do
    echo "Project: $(basename "$project")"
    ls "$project"  # List studies
done
```

---

**Document:** yaml-config-user-guide.md  
**Created:** 2025-12-30  
**Status:** Complete  
**Target Audience:** All dirforge users
