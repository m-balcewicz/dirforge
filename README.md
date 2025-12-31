# dirforge — workspace scaffolder (DirForge)

This repository contains a small Bash-first CLI, `dirforge`, which scaffolds standardized directory structures according to the DirForge Constitution v1.1.0.

> **⚡ New in v1.1.0**: Clear separation between workspace setup (`dirforge init`) and entity creation (`dirforge create <entity>`). Backward compatibility maintained with helpful migration guidance.

## Key Features
- **Clear Command Structure**: Separate workspace initialization (`dirforge init`) from entity creation (`dirforge create <entity>`)
- **Complete workspace initialization**: Create all 7 world types at once
- **Individual entity creation**: Research, lecture, coding (with multi-language support), journal, office, private projects
- **Backward compatibility**: Deprecated syntax still works with helpful migration guidance
- **Safe project updates**: Upgrade existing projects with additive-only migrations
- **Flexible path specification**: Use `--here`, `--path=`, or positional arguments to specify targets
- **Subdirectory-aware**: Run update from any location within project hierarchy; automatically finds project root
- **Interactive and automated modes**: Prompts or automatic creation with flags; safe handling of unknown versions
- **Dry-run preview**: See what will be created or updated before making changes
- **JSON output**: Machine-readable plans for automation
- **YAML-based configuration system** (v1.1.0+): Define custom world structures using declarative YAML configs
- **Atomic operations**: All-or-nothing scaffold generation with automatic rollback on error
- **Constitution compliance**: All structures follow DirForge Constitution v1.1.0

## Installation

DirForge provides multiple installation methods for different use cases. The **Installation Wizard** is recommended for new users.

### Quick Installation (Recommended)

For the best experience, use the interactive installation wizard:

```bash
# Clone the repository
git clone https://github.com/m-balcewicz/dirforge.git
cd dirforge

# Run the installation wizard
./scripts/install_dirforge.sh --wizard
```

The wizard will:
- Guide you through installation options
- Detect your system configuration
- Set up PATH automatically
- Run tests to verify installation
- Provide clear feedback and next steps

### Installation Modes

The `install_dirforge.sh` script supports three modes:

```bash
# Interactive wizard mode (recommended)
bash scripts/install_dirforge.sh --wizard

# Local installation (recommended, no sudo required)
bash scripts/install_dirforge.sh --local

# System-wide installation (requires sudo)
sudo bash scripts/install_dirforge.sh --system
```

### Installation Options

- **Local Installation** (`~/bin`): Available only to your user, no admin rights needed
- **System Installation** (`/usr/local/bin`): Available to all users, requires sudo

### Uninstallation

To remove DirForge from your system:

```bash
# Interactive uninstallation
./scripts/uninstall_dirforge.sh

# Remove local installation only
./scripts/uninstall_dirforge.sh --local

# Remove system installation (requires sudo)
sudo ./scripts/uninstall_dirforge.sh --system

# Remove all installations
sudo ./scripts/uninstall_dirforge.sh --all
```

### Requirements

- **bash** (version 4.0 or later recommended)
- **Standard Unix tools**: `cp`, `chmod`, `mkdir`, `grep`, `tr`
- **macOS** or **Linux** (other Unix-like systems may work)

### Post-Installation

After installation, verify everything works:

```bash
# Check installation
dirforge --version

# Run tests
bash tests/run_tests.sh

# Get help
dirforge --help
```

## Command Structure

DirForge v1.1.0 uses a clear separation between workspace setup and entity creation:

```bash
# Workspace initialization (creates all world directories)
dirforge init [path] [options]

# Entity creation within existing workspace
dirforge create <entity-type> [entity-options] [global-options]

# Workspace-only entities (office, private)
dirforge init <world-type> [options]
```

### Entity Types
- **research** - Academic research projects with study organization
- **lecture** - Educational content and course management
- **coding** - Programming projects with multi-language support
- **journal** - Academic paper authorship and review workflows
- **office** - Administrative and business document organization (workspace-only)
- **private** - Personal projects and archives (workspace-only)

### Backward Compatibility

Deprecated `dirforge init <entity>` syntax still works but shows helpful warnings:

```bash
# Deprecated (still works with warning)
dirforge init research --name "Project"

# Shows: ⚠️ DEPRECATION WARNING: Use 'dirforge create research' instead

# Current recommended syntax  
dirforge create research --name "Project"

# Suppress warnings if needed
DIRFORGE_SUPPRESS_DEPRECATION=1 dirforge init research --name "Project"
```

## Help System

The `dirforge` tool includes a comprehensive help system with progressive disclosure:

```bash
# Global help - tool overview and constitution reference
dirforge --help

# Command-specific help
dirforge init --help              # Workspace initialization help
dirforge create --help            # Entity creation help

# Entity-specific help - detailed structure and examples
dirforge create research --help
dirforge create lecture --help
dirforge create coding --help
dirforge create journal --help
dirforge init office --help       # Office and private are workspace-only
dirforge init private --help

# Version information with constitution version
dirforge --version
```

## YAML Configuration System

DirForge v1.1.0 introduces a declarative YAML-based configuration system for defining custom workspace structures. Instead of hard-coded directory layouts, you can now create reusable configuration files that define your workspace organization.

### Quick Start

**1. Initialize workspace:**
```bash
# Initialize complete workspace with all world directories
dirforge init

# Initialize workspace in specific directory
dirforge init /path/to/workspace --auto
```

**2. Create projects within workspace:**
```bash
# Create research project with study
dirforge create research --project myproject --study mystudy
```

**3. List available configurations:**
```bash
dirforge list-configs
```

**3. Validate a configuration:**
```bash
dirforge validate-config templates/world-configs/coding.world.yaml
```

### Built-in World Types

DirForge provides 7 pre-configured world types:

| World Type | Purpose | Command | Metadata Levels |
|-----------|---------|---------|-----------------|
| **CODING_WORLD** | Programming language projects | `dirforge create coding` | Workspace, World, Project |
| **RESEARCH_WORLD** | Academic research with studies | `dirforge create research` | Workspace, World, Project, Study |
| **JOURNAL_WORLD** | Paper authorship and reviews | `dirforge create journal` | Workspace, World, Project |
| **LECTURE_WORLD** | Course materials and grading | `dirforge create lecture` | Workspace, World, Project |
| **OFFICE_WORLD** | Administrative and business docs | `dirforge init office` | Workspace, World, Project |
| **PRIVATE_WORLD** | Personal projects and archives | `dirforge init private` | Workspace, World, Project |
| **LITERATURE_WORLD** | Extensible template | `dirforge create literature` | Workspace, World, Project |

### Creating Custom Configurations

Create your own world configuration as a YAML file:

```yaml
world:
  type: MYWORLD_TYPE
  description: "My custom workspace structure"

metadata:
  version: "1.0.0"
  constitution_version: "1.1.0"
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
```

Then use it:
```bash
# Validate custom config
dirforge validate-config my-world.yaml

# Initialize with custom config
dirforge init --config my-world.yaml
```

### Features

- **Variable Expansion**: Use `${USER}` and `${DATE}` in configs for dynamic values
- **Schema Validation**: Automatic validation of config structure and types
- **Metadata Tracking**: Creation info, user, timestamp stored in `.integrity/` directories
- **Atomic Operations**: All-or-nothing scaffold generation with automatic rollback on error
- **Permission Management**: Automatic handling of file permissions with sensible defaults
- **Caching**: Configuration caching for improved performance (30-minute TTL)

### Documentation

For detailed information about the YAML configuration system:

- **Getting Started**: [`docs/yaml-config-user-guide.md`](docs/yaml-config-user-guide.md)
- **API Reference**: 
  - [`docs/yaml-parsing-api.md`](docs/yaml-parsing-api.md) - Configuration loading and YAML parsing
  - [`docs/scaffold-generation-api.md`](docs/scaffold-generation-api.md) - Scaffold generation and transactions
- **System Design**: [`docs/010-yaml-configuration-system.md`](docs/010-yaml-configuration-system.md)
- **Schema Details**: [`templates/world-configs/SCHEMA.md`](templates/world-configs/SCHEMA.md)
- **Troubleshooting**: [`docs/yaml-config-troubleshooting.md`](docs/yaml-config-troubleshooting.md)
- **Migration Guide**: [`docs/migration-to-yaml-configs.md`](docs/migration-to-yaml-configs.md)

---

Help System

The `dirforge` tool includes a comprehensive help system with progressive disclosure:
- **Progressive disclosure**: More detailed help as you specify context
- **ANSI color formatting**: Enhanced readability with terminal color support
- **Constitution compliance**: Direct references to DirForge Constitution v1.1.0
- **Directory structure previews**: ASCII tree views of generated structures
- **Copy-pasteable examples**: Real-world usage patterns for each world type
- **Terminal adaptation**: Automatic paging for long content, NO_COLOR support


## Update Existing Projects

The `dirforge update` command upgrades an existing DirForge project structure to the latest constitution version. It is safe, additive-only (never deletes or overwrites), and supports preview, backup, and automation modes.

### Syntax
```bash
# Update current directory to latest version
dirforge update

# Update from project subdirectory to project root
dirforge update --here

# Update specific directory
dirforge update /path/to/project
dirforge update --path=/path/to/project

# Preview changes without making modifications
dirforge update --dry-run

# Output machine-readable JSON summary
dirforge update --json

# Create a timestamped backup before updating
dirforge update --backup

# Update all nested subprojects recursively
dirforge update [path] [options]
```

### Path Specification

The update command supports multiple ways to specify the target directory:

- **Default (no path)**: Updates current directory if it's a valid project root, or walks up directory tree to find the project root
- **`--here`**: Explicitly use current directory; finds project root if in subdirectory (recommended for subdirectory updates)
- **`--path=PATH`**: Specify target directory explicitly
- **Positional argument**: `dirforge update /path/to/project` updates that directory

All four methods support recursive subproject updates and work from any location in the project hierarchy.

### Options
- `--dry-run`: Preview changes without making modifications
- `--json`: Output machine-readable JSON summary of planned changes
- `--backup`: Create a timestamped backup before updating
- `--force`: Override version/world detection errors (use with caution)
- `--here`: Explicitly use current directory; finds project root if in subdirectory
- `--path=PATH`: Specify target directory with explicit flag

### Behavior
- Only adds missing directories/files (never deletes or overwrites)
- Validates structure before and after update
- Supports nested subprojects (recursively updates all detected projects)
- Provides clear user messaging and error handling
- Intelligently finds project root when called from subdirectories
- Handles unknown versions/world-types with interactive prompting (TTY) or safe defaults (non-TTY)

### Examples
```bash
# Update current directory
dirforge update

# Update with dry-run preview
dirforge update --dry-run

# Update from project subdirectory
cd RESEARCH_WORLD/2025_my_project/01_project_management
dirforge update --here

# Update specific path
dirforge update /path/to/project
dirforge update --path=/path/to/project

# Backup before updating
dirforge update --backup

# Get JSON summary for automation
dirforge update --json

# Combine flags
dirforge update --here --dry-run
dirforge update /path --backup --dry-run
```

### Migration Notes
- Manual migration steps may be required for some world types/versions.
- See the migration guide in `docs/` for details.

---
## Usage

### Command Structure

DirForge uses a clear separation between workspace setup and entity creation:

#### Syntax
```bash
# Complete workspace initialization (creates all world directories)
dirforge init [path] [options]

# Individual entity creation within existing workspace
dirforge create <entity-type> [entity-specific-options] [global-options]

# Workspace-only world types (office, private)
dirforge init <world-type> [options]
```

### Workspace Initialization

The `dirforge init` command creates complete workspaces with all world directories.

#### Global Options
- `--dry-run`, `--preview`: Preview changes without creating files
- `--json`: Output machine-readable JSON plan (requires --dry-run)
- `--force`: Overwrite existing directories without prompting
- `--backup`: Create timestamped backups before overwriting
- `--yes`, `-y`: Skip interactive prompts and proceed
- `--help`, `-h`: Show help information
- `--quiet`, `-q`: Suppress non-error output
- `--verbose`, `-v`: Show detailed progress information

#### Workspace Initialization Options
- `--auto`: Create automatically without prompts (same as `--yes`)
- `--here`: Explicitly use current directory
- `--path=PATH`: Specify target directory with explicit flag

#### World Types
- `research`: Academic research projects with data management
- `lecture`: Educational content with grading workflows  
- `coding`: Software development projects
- `journal`: Journal-related activities (submissions, reviews, editorial work)
- `office`: Administrative and business documents
- `private`: Personal projects with privacy controls

### Workspace Initialization

Create a complete DirForge workspace with all world types:

```bash
# Initialize complete workspace in current directory
dirforge init
dirforge init --here

# Initialize workspace in specific directory
dirforge init /path/to/my/workspace
dirforge init ~/my-projects
dirforge init --path=/opt/workspaces/team1

# Automated creation without prompts
dirforge init ~/new-workspace --auto
dirforge init --here --yes

# Preview workspace creation without making changes
dirforge init ~/test-workspace --dry-run
dirforge init . --dry-run --verbose

# Get machine-readable output for automation
dirforge init test-workspace --dry-run --json
dirforge init ~/workspace --dry-run --json --quiet

# Create with backup of existing content
dirforge init existing-workspace --backup
dirforge init --here --backup --force

# Force overwrite existing directories
dirforge init ~/workspace --force --auto
```

**Workspace Structure Created:**
```
workspace/
├── CODING_WORLD/
├── JOURNAL_WORLD/
├── LECTURE_WORLD/
├── OFFICE_WORLD/
│   ├── 00_admin/
│   ├── 01_finance/
│   ├── 02_hr_administration/
│   ├── 03_faculty/
│   ├── 04_inventory_equipment/
│   ├── 05_software_licenses/
│   ├── 06_public_relations/
│   └── 90_archive/
├── PRIVATE_WORLD/
│   ├── 00_admin/
│   ├── 01_credentials/
│   ├── 02_id_contracts/
│   ├── 03_finance/
│   ├── 04_documents/
│   ├── 05_photos/
│   ├── 06_movies/
│   ├── 07_hiking/
│   ├── 09_installers/
│   └── 90_archive/
└── RESEARCH_WORLD/
	├── <PROJECT_ID>/
	│   ├── 00_admin/
	│   ├── 01_project_management/
	│   │   ├── 01_proposal/
	│   │   │   ├── 01_draft/
	│   │   │   ├── 02_submission/
	│   │   │   ├── 03_review/
	│   │   │   └── 04_final/
	│   │   ├── 02_finance/
	│   │   ├── 03_reports/
	│   │   └── 04_presentations/
	│   ├── 02_studies/
	│   │   ├── <study_name>/
	│   │   │   ├── 00_protocols/
	│   │   │   ├── 01_code/
	│   │   │   ├── 02_data/
	│   │   │   ├── 03_outputs/
	│   │   │   ├── 04_publication/
	│   │   │   ├── 05_presentations/
	│   │   │   └── .integrity/
	│   └── .integrity/
```

### Entity Creation

Create specific projects within existing world directories:

```bash
# Research projects (within RESEARCH_WORLD/)
# Create project with study-based structure
dirforge create research --name "Thermal Model Analysis"
dirforge create research --name "ML Study" --python 3.12
dirforge create research --name "Theory Work" --no-conda

# Create project with first study in one command
dirforge create research --name "Digital Rock Physics" --study "Porosity Analysis"

# Add studies to existing projects
dirforge create research --project 2025_thermal_model_analysis --study "Heat Transfer Model"
dirforge create research --project 2025_thermal_model_analysis --study "Validation Experiments"

# Lecture projects (within LECTURE_WORLD/)  
dirforge create lecture --name "Digital Rock Physics"
dirforge create lecture --name "Physics 101" --backup
dirforge create lecture --name "Advanced Course" --force

# Coding projects (within CODING_WORLD/)
dirforge create coding --language python --project ml_toolkit
dirforge create coding --language matlab --project functions
dirforge create coding --project my_tool --dry-run

# Journal projects (within JOURNAL_WORLD/) - Role-Based Organization
# Primary authorship (lead author projects)
dirforge create journal --name "thermal_analysis" --first
dirforge create journal --name "seismic_modeling_study" --first --year 2024

# Co-author collaboration (joint projects)
dirforge create journal --name "2021_elastic_properties" --coauthor
dirforge create journal --name "international_consortium" --coauthor

# Journal service (reviews, editorial work)
dirforge create journal --name "Geophysics" --id "GEO-2025-0451" --service
dirforge create journal --name "Nature Geoscience" --id "REVIEWER_2024_Q4" --service

# Office and private world structures (workspace-only)
dirforge init office    # Creates OFFICE_WORLD/ with standard directories
dirforge init private   # Creates PRIVATE_WORLD/ with standard directories
```

### World-Specific Options

Each world type has additional options for customization:

#### Research Projects
- `--name "Project Name"`: Human-readable project name (required for new projects)
- `--project "project_id"`: Existing project ID to add study to (use with `--study`)
- `--study "Study Name"`: Create project with initial study or add study to existing project
- `--python VERSION`: Python version for conda environment (default: 3.11)
- `--no-conda`: Skip conda environment creation
- `--conda-packages "pkg1 pkg2"`: Additional packages beyond base set

**Note:** Project IDs are automatically generated as `YEAR_snake_case_title` (e.g., `2025_thermal_model_analysis` for "Thermal Model Analysis" created in 2025).

#### Research Studies
Research projects use a study-based organization where each project can contain multiple independent studies. Studies are created within the project's `02_studies/` directory:

```bash
# Create a study in an existing project
dirforge create research --project "2025_thermal_model_analysis" --study "Heat Transfer Model"

# Study names are automatically converted to lower_snake_case
# "Heat Transfer Model" becomes "heat_transfer_model"
```

Each study contains its own complete research workflow:
- `00_protocols/`: Experimental protocols and methodologies
- `01_code/`: Analysis scripts, notebooks, and software
- `02_data/`: Raw and processed datasets with metadata.yaml
- `03_outputs/`: Results, figures, and processed data
- `04_publication/`: Manuscripts and supplementary materials
- `05_presentations/`: Slides and presentation materials

#### Project Management (01_project_management)
Project-level administrative and management artifacts live in `01_project_management/`. The scaffolder creates a small, opinionated subtree to capture the proposal lifecycle, budgets, reports, and presentation assets:

```
RESEARCH_WORLD/<PROJECT_ID>/01_project_management/
├── README.md
├── 01_proposal/
│   ├── 01_draft/
│   ├── 02_submission/
│   ├── 03_review/
│   └── 04_final/
├── 02_finance/
├── 03_reports/
└── 04_presentations/  (kept flat for easier previews/exports)
```

Use descriptive filenames (e.g., `2025-09-01_budget_v1.xlsx`, `proposal_final.pdf`) and avoid committing secrets. The scaffolder renders README templates into these folders with `{{PROJECT_NAME}}` and `{{PROJECT_ID}}` populated from the `--name` you provide.

#### Lecture Projects  
- `--name "Course Name"`: Lecture/course name (required)
- `--no-conda`: Skip conda environment creation

#### Coding Projects
- `--project "project-name"`: Project name (required)
- `--language LANG`: Programming language (python, javascript, etc.)
- `--no-conda`: Skip conda environment creation (for Python projects)

#### Journal Projects (Role-Based Organization)
- `--name "Name"`: Paper name (for --first/--coauthor) or journal name (for --service)
- `--first`: Primary authorship role (lead author projects)
- `--coauthor`: Co-author collaboration role (joint projects)  
- `--service`: Journal service role (reviews, editorial work)
- `--year YYYY`: Explicit year for authorship projects (default: current year or extracted from name)
- `--id "MANUSCRIPT_ID"`: Manuscript/reviewer ID (required with --service)

**Role-based structure**: Projects are organized by role (admin, primary authorship, co-author, service) rather than journal name. Use `dirforge create journal --help` for complete examples and migration guidance.

### Command Line Options

**Global Options (work with all commands):**
- `--dry-run`, `--preview`: Preview changes without creating files
- `--json`: Output machine-readable JSON plan (requires --dry-run)
- `--force`: Overwrite existing directories without prompting
- `--backup`: Create timestamped backups before overwriting
- `--yes`, `-y`: Skip interactive prompts and proceed
- `--help`, `-h`: Show help information
- `--quiet`, `-q`: Suppress non-error output
- `--verbose`, `-v`: Show detailed progress information

**Workspace Initialization Options:**
- `--auto`: Create automatically without prompts (alias for `--yes`)
- `--here`: Explicitly use current directory
- `--path=PATH`: Specify target directory with explicit flag

### Advanced Usage Examples

**Safety and Preview:**
```bash
# Always preview before creating
dirforge init ~/important-workspace --dry-run

# Create with backup for safety
dirforge init existing-workspace --backup

# Get JSON output for automation/CI
dirforge init workspace --dry-run --json | jq .directories[]
```

**Automation and Scripting:**
```bash
# Non-interactive creation for scripts
dirforge init /opt/workspaces/team1 --auto --force

# Quiet mode for clean script output
dirforge init ~/workspace --auto --quiet

# Verbose mode for debugging
dirforge init ~/workspace --verbose --dry-run
```

**Error Recovery:**
```bash
# Force overwrite if something went wrong
dirforge init ~/workspace --force

# Create backup before fixing
dirforge init ~/workspace --backup --force
```

## Developer Commands
- Install yq (strict YAML validation): `brew install yq`
- Lint shell scripts: `scripts/lint_shell.sh`
- Run full test suite: `bash tests/run_tests.sh`
- Validate help system content: `scripts/validate_help_content.sh`
- Test help system performance: `tests/help/test_performance.sh`
- Validate a manifest: `./tools/manifest.sh path/to/your.manifest.yaml`

**Help System Architecture:**
- Progressive disclosure: `dirforge --help` → `dirforge create --help` → `dirforge create <entity> --help`
- Terminal adaptation: Auto-detects color support, terminal width, paging capability
- **Constitution integration**: Dynamic references to DirForge Constitution v1.1.0
- Performance optimization: Cached content generation for repeated calls (<200ms target)

Notes & future directions
- The current tool is intentionally simple and Bash-first and lives in `tools/` for now.
- We can later migrate to a `bin/` layout, add a `src/` Python module for richer features, or convert into a packaged CLI (`pyproject.toml`) when the codebase grows.
- The installer is deliberately idempotent and conservative — it copies the script, it does not remove or modify other files.

Contributing
- If you want to add features (journal init, extra templates, tests), keep helper scripts in `tools/`, templates in `templates/`, and example projects in `examples/`.
- Help system templates are stored in `templates/help/` for reference and testing.
- Help system libraries are in `lib/`: `help.sh` (content formatting), `colors.sh` (ANSI color management), `terminal.sh` (capability detection).
- Project configuration templates use `.template` extension in `templates/`.

**Help System Development:**
- Run help content validation: `scripts/validate_help_content.sh`
- Test help system performance: `tests/help/test_performance.sh`
- Validate constitution references: `tests/help/test_constitution_refs.sh`
- Test accessibility features: `tests/help/test_accessibility.sh`