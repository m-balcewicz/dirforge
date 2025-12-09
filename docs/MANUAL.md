# DirForge Manual

Version: 1.0 | Constitution: v1.0.16

## Table of Contents

1. [Overview](#overview)
2. [Installation](#installation)
3. [Basic Usage](#basic-usage)
4. [Command Reference](#command-reference)
5. [Global Flags](#global-flags)
6. [Project Types](#project-types)
7. [Examples](#examples)
8. [Troubleshooting](#troubleshooting)

---

## Overview

DirForge is a workspace scaffolder that creates standardized, constitution-compliant directory structures for research, lecture, coding, and journal projects. It enforces data integrity best practices through automated manifest validation and `.integrity/` directories for checksums and manifests.

**Key Features:**
- Constitution-compliant project scaffolding
- Automated `.integrity/` directories for data validation
- Dry-run preview mode with JSON output
- Safe overwrite protection with backup capabilities
- Conda environment integration (optional)
- YAML manifest validation

---

## Installation

### Quick Install

```bash
# Clone repository
git clone https://github.com/m-balcewicz/dirforge.git
cd dirforge

# Make dirforge executable
chmod +x tools/dirforge

# Add to PATH (optional)
export PATH="$PATH:$(pwd)/tools"
```

### Dependencies

**Required:**
- Bash 4.0+ (macOS ships with 3.2, consider `brew install bash`)

**Optional:**
- `yq` v4+ — for strict YAML manifest validation (`brew install yq`)
- `conda` — for automated environment creation

---

## Basic Usage

### Create a Research Project

```bash
# Simple research project
./tools/dirforge init research --title "Digital Rock Physics"

# Without conda environment
./tools/dirforge init research --title "My Project" --no-conda

# Preview before creating (dry-run)
./tools/dirforge --dry-run init research --title "My Project"
```

### Create a Lecture Project

```bash
# Simple lecture project
./tools/dirforge init lecture --name "Computational Geophysics"

# Without conda environment
./tools/dirforge init lecture --name "Physics 101" --no-conda
```

### Preview with JSON Output

```bash
# Machine-readable preview
./tools/dirforge --dry-run --json init research --title "Test" | jq .
```

---

## Command Reference

### `dirforge init <type>`

Create a new project scaffold.

**Types:**
- `research` — Research project with numbered folders (01-08) and `.integrity/`
- `lecture` — Lecture project with grading workflow and `.integrity/`
- `coding` — Coding project (language-specific)
- `journal` — Journal manuscript submission project

**Common Options:**
- `--title <name>` — Project title (for research)
- `--name <name>` — Lecture name (for lecture)
- `--no-conda` — Skip conda environment creation
- `--python <version>` — Python version for conda env (default: 3.11)
- `--conda-packages "<pkgs>"` — Additional conda packages

---

## Global Flags

### Preview & Planning

#### `--dry-run` / `--preview`
Preview what will be created without writing to disk.

```bash
./tools/dirforge --dry-run init research --title "Test"
```

**Output:**
```
DRY RUN: would create directory: RESEARCH_WORLD/2025_test
DRY RUN: mkdir -p RESEARCH_WORLD/2025_test/01_project_management
DRY RUN: mkdir -p RESEARCH_WORLD/2025_test/02_admin
...
DRY RUN: would write file: RESEARCH_WORLD/2025_test/README.md
DRY RUN: would write file: RESEARCH_WORLD/2025_test/project.yaml
```

#### `--json`
Output machine-readable JSON plan (requires `--dry-run`).

```bash
./tools/dirforge --dry-run --json init research --title "Test"
```

**Output:**
```json
{
  "dry_run": true,
  "directories": [
    "RESEARCH_WORLD/2025_test",
    "RESEARCH_WORLD/2025_test/01_project_management",
    "RESEARCH_WORLD/2025_test/.integrity/checksums"
  ],
  "files": [
    "RESEARCH_WORLD/2025_test/README.md",
    "RESEARCH_WORLD/2025_test/project.yaml"
  ]
}
```

**Use cases:**
- CI/CD validation
- Scripting and automation
- Preview before deployment

---

### Overwrite Protection

DirForge prevents accidental overwrites by default. If a project already exists, you must explicitly choose how to handle it.

#### Default Behavior (No Flags)

```bash
./tools/dirforge init research --title "Existing Project"
```

**Error:**
```
Project '2025_existing_project' already exists at RESEARCH_WORLD/2025_existing_project
Use --force to overwrite or --backup to create a backup before overwriting
```

#### `--backup`
**Creates a timestamped backup before overwriting.**

```bash
./tools/dirforge --backup init research --title "Existing Project"
```

**What happens:**
1. Interactive prompt asks: `Overwrite existing project? [y/N]`
2. If you answer `y`:
   - Creates backup: `RESEARCH_WORLD/2025_existing_project.backup-20251209-204019/`
   - Removes original directory
   - Creates fresh project structure

**Backup naming format:** `<project-dir>.backup-YYYYMMDD-HHMMSS`

**Example:**
```
Original:  RESEARCH_WORLD/2025_digital_rock_physics/
Backup:    RESEARCH_WORLD/2025_digital_rock_physics.backup-20251209-143052/
New:       RESEARCH_WORLD/2025_digital_rock_physics/
```

**What's in the backup:**
- Complete copy of all files and directories
- Preserves all subdirectories (01_project_management, 04_data, .integrity/, etc.)
- Preserves all your work, data, analysis, manuscripts

**When to use `--backup`:**
- You've made changes but want to start fresh with a clean structure
- You're updating to a new constitution version
- You want to reorganize but keep the old version
- Safety-first approach: you can always restore from backup

#### `--force`
**Overwrites WITHOUT creating a backup.**

```bash
./tools/dirforge --force init research --title "Existing Project"
```

**What happens:**
1. Interactive prompt asks: `Overwrite existing project? [y/N]`
2. If you answer `y`:
   - **Deletes original directory permanently**
   - Creates fresh project structure
   - **No backup created — data loss risk!**

**When to use `--force`:**
- Empty test projects you don't need
- Initial project setup testing
- You have external backups (Git, Time Machine, etc.)
- You're certain you don't need the old version

**⚠️ Warning:** This permanently deletes the existing project. Use with caution!

#### `--yes` / `-y`
**Skips interactive confirmation prompts.**

```bash
./tools/dirforge --backup --yes init research --title "Existing Project"
```

**What happens:**
- No prompt shown
- Proceeds automatically with backup/overwrite
- Useful for scripts and automation

**Common combinations:**
```bash
# Backup without prompt (safe automation)
./tools/dirforge --backup --yes init research --title "Project"

# Force overwrite without prompt (dangerous!)
./tools/dirforge --force --yes init research --title "Project"
```

---

### Comparison: `--backup` vs `--force`

| Feature | `--backup` | `--force` |
|---------|-----------|-----------|
| Creates backup | ✅ Yes | ❌ No |
| Data safety | ✅ Safe | ⚠️ Risky |
| Disk space | Uses 2x space temporarily | Minimal |
| Recovery | ✅ Can restore | ❌ Permanent loss |
| Use case | Production work | Testing/empty projects |
| Recommended | ✅ Default choice | Use with caution |

**Best practice:** Always use `--backup` unless you're absolutely certain you don't need the old version.

---

## Project Types

### Research Projects

**Structure:**
```
RESEARCH_WORLD/<YYYY_project_id>/
├── README.md
├── project.yaml
├── 01_project_management/
├── 02_admin/
├── 03_design_protocols/
├── 04_data/
├── 05_data_analysis/
├── 06_data_outputs/
├── 07_publication/
├── 08_documentation/
└── .integrity/
    ├── checksums/
    └── manifests/
```

**Features:**
- Constitution v1.0.16 compliant
- Numbered folder convention (01-08)
- `.integrity/` for data validation
- Automatic project ID with year prefix

**Example:**
```bash
./tools/dirforge init research --title "Thermal Modeling Study"
# Creates: RESEARCH_WORLD/2025_thermal_modeling_study/
```

---

### Lecture Projects

**Structure:**
```
LECTURE_WORLD/<lecture_id>/
├── README.md
├── project.yaml
├── 00_admin/
├── 01_code/
├── 02_data/
│   ├── experimental_recordings/
│   └── reference/
├── 03_slides/
├── 04_manuscript/
├── 05_exercises/
│   ├── problems/
│   ├── solutions/
│   ├── submissions/
│   └── graded/
├── 06_exams/
│   ├── problems/
│   ├── solutions/
│   ├── submissions/
│   └── graded/
├── 07_grades/
└── .integrity/
    ├── checksums/
    └── manifests/
```

**Features:**
- Grading workflow (problems/solutions/submissions/graded)
- Recording manifest support
- Reference figure metadata tracking
- Name → `lecture_id` conversion

**Example:**
```bash
./tools/dirforge init lecture --name "Digital Rock Physics"
# Creates: LECTURE_WORLD/digital_rock_physics/
```

---

## Examples

### Complete Research Workflow

```bash
# 1. Preview the structure
./tools/dirforge --dry-run init research --title "Pore Pressure Study"

# 2. Create the project
./tools/dirforge init research --title "Pore Pressure Study"

# 3. Add your data to 04_data/
cp ~/raw_data/*.dat RESEARCH_WORLD/2025_pore_pressure_study/04_data/

# 4. Generate checksums
cd RESEARCH_WORLD/2025_pore_pressure_study
shasum -a 256 04_data/*.dat > .integrity/checksums/raw_data.sha256

# 5. Create manifest for external datasets
cat > 04_data/xct_scans.manifest.yaml <<EOF
storage_location: "smb://nas.lab.edu/xct_archive"
server_or_nas: "nas.lab.edu"
path_on_store: "/archive/2025/pore_pressure/xct_scans"
naming: "sample_<ID>_<timestamp>.raw"
checksum: ".integrity/checksums/xct_scans.sha256"
access: "Contact Dr. Smith for NAS credentials"
EOF

# 6. Validate manifest
../../tools/manifest.sh 04_data/xct_scans.manifest.yaml
```

### Updating an Existing Project

```bash
# You made changes and want to update to new constitution version
# Create backup first!
./tools/dirforge --backup --yes init research --title "My Project"

# If something goes wrong, restore from backup:
# rm -rf RESEARCH_WORLD/2025_my_project
# mv RESEARCH_WORLD/2025_my_project.backup-20251209-143052 RESEARCH_WORLD/2025_my_project
```

### Automated Testing Setup

```bash
# CI/CD script to verify structure
./tools/dirforge --dry-run --json init research --title "CI Test" | \
  jq -e '.directories | contains(["RESEARCH_WORLD/2025_ci_test/.integrity/checksums"])'
```

---

## Troubleshooting

### "Project already exists" Error

**Problem:**
```
Project '2025_my_project' already exists at RESEARCH_WORLD/2025_my_project
Use --force to overwrite or --backup to create a backup before overwriting
```

**Solution:**
Choose your approach based on whether you need to keep the existing data:

```bash
# Safe: Create backup before overwriting
./tools/dirforge --backup init research --title "My Project"

# Risky: Overwrite without backup
./tools/dirforge --force --yes init research --title "My Project"
```

### "WARNING: 'yq' not found"

**Problem:**
Manifest validator works in fallback mode without full YAML validation.

**Solution:**
```bash
# Install yq for strict mode
brew install yq

# Verify installation
yq --version
```

### Conda Environment Not Created

**Problem:**
`--no-conda` was specified or conda is not installed.

**Solution:**
```bash
# Without --no-conda flag
./tools/dirforge init research --title "My Project"

# Or install conda first
brew install --cask miniconda
```

### Interactive Prompt Hangs in Scripts

**Problem:**
Script waits for user input when project exists.

**Solution:**
```bash
# Use --yes to skip prompts
./tools/dirforge --backup --yes init research --title "My Project"
```

---

## Related Documentation

- **Constitution**: `.specify/memory/constitution.md` — Governance rules (v1.0.16)
- **Conda Guide**: `docs/CONDA.md` — Conda environment management
- **Examples**: `examples/README.md` — Example scaffolds
- **Manifest Validator**: `tools/manifest.sh --help` — YAML validation

---

## Quick Reference

### Most Common Commands

```bash
# Create research project
./tools/dirforge init research --title "My Project" --no-conda

# Create lecture
./tools/dirforge init lecture --name "My Course" --no-conda

# Preview first
./tools/dirforge --dry-run init research --title "My Project"

# Update existing (with backup)
./tools/dirforge --backup --yes init research --title "My Project"

# Validate manifest
./tools/manifest.sh path/to/dataset.manifest.yaml
```

### Flag Cheat Sheet

| Flag | Purpose | Safe? |
|------|---------|-------|
| `--dry-run` | Preview only | ✅ |
| `--json` | Machine output | ✅ |
| `--backup` | Backup before overwrite | ✅ |
| `--force` | Delete and overwrite | ⚠️ |
| `--yes` | Skip prompts | ⚠️ |
| `--no-conda` | Skip conda env | ✅ |

---

**Need Help?** Check `examples/README.md` for working examples or run `./tools/dirforge --help` for usage information.
