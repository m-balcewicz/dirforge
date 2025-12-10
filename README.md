# dirforge — workspace scaffolder (DirForge)

This repository contains a small Bash-first CLI, `dirforge`, which scaffolds standardized directory structures according to the DirForge Constitution.

## Key Features
- **Complete workspace initialization**: Create all 6 world types at once
- **Individual world creation**: Research, lecture, coding (with multi-language support), journal, office, private projects
- **Interactive and automated modes**: Prompts or automatic creation with flags
- **Dry-run preview**: See what will be created before making changes
- **JSON output**: Machine-readable plans for automation
- **Constitution compliance**: All structures follow DirForge Constitution v1.0.17

## Installation

DirForge provides multiple installation methods for different use cases. The **Installation Wizard** is recommended for new users.

### Quick Installation (Recommended)

For the best experience, use the interactive installation wizard:

```bash
# Clone the repository
git clone https://github.com/m-balcewicz/dirforge.git
cd dirforge

# Run the installation wizard
./scripts/dirforge_install_wizard.sh
```

The wizard will:
- Guide you through installation options
- Detect your system configuration
- Set up PATH automatically
- Run tests to verify installation
- Provide clear feedback and next steps

### Manual Installation

If you prefer manual installation, use the traditional script:

```bash
# Local installation (recommended, no sudo required)
bash scripts/install_dirforge.sh

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

Help System

The `dirforge` tool includes a comprehensive help system with progressive disclosure:

```bash
# Global help - tool overview and constitution reference
dirforge --help

# Command-specific help - available world types
dirforge init --help

# World-type specific help - detailed structure and examples
dirforge init research --help
dirforge init lecture --help
dirforge init coding --help
dirforge init journal --help
dirforge init office --help
dirforge init private --help

# Version information with constitution version
dirforge --version
```

**Help System Features:**
- **Progressive disclosure**: More detailed help as you specify context
- **ANSI color formatting**: Enhanced readability with terminal color support
- **Constitution compliance**: Direct references to DirForge Constitution v1.0.17
- **Directory structure previews**: ASCII tree views of generated structures
- **Copy-pasteable examples**: Real-world usage patterns for each world type
- **Terminal adaptation**: Automatic paging for long content, NO_COLOR support

## Usage

### Complete Workspace Initialization

The `dirforge init` command can create a complete workspace with all world types or individual projects within specific worlds.

#### Syntax
```bash
# Complete workspace initialization
dirforge init [path] [options]

# Individual world project creation  
dirforge init <world-type> [world-specific-options] [global-options]
```

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
```

### Individual World Projects

Create specific projects within existing world directories:

```bash
# Research projects (within RESEARCH_WORLD/)
# Create project with study-based structure
dirforge init research --title "Thermal Model Analysis"
dirforge init research --title "ML Study" --python 3.12
dirforge init research --title "Theory Work" --no-conda

# Create project with first study in one command
dirforge init research --title "Digital Rock Physics" --study "Porosity Analysis"

# Add studies to existing projects
dirforge init research --project 2025_thermal_model_analysis --study "Heat Transfer Model"
dirforge init research --project 2025_thermal_model_analysis --study "Validation Experiments"

# Lecture projects (within LECTURE_WORLD/)  
dirforge init lecture --name "Digital Rock Physics"
dirforge init lecture --name "Physics 101" --backup
dirforge init lecture --name "Advanced Course" --force

# Coding projects (within CODING_WORLD/)
dirforge init coding --language python --project ml_toolkit
dirforge init coding --language matlab --project functions
dirforge init coding --project my_tool --dry-run

# Journal projects (within JOURNAL_WORLD/)
dirforge init journal --journal "Geophysics" --id "GEO-2025-0451"
dirforge init journal --journal "Nature Geoscience" --id "REVIEWER_2024_Q4" 
dirforge init journal --journal "JGR Solid Earth" --id "ASSOC_EDITOR_2024"

# Office and private world structures
dirforge init office    # Creates OFFICE_WORLD/ with standard directories
dirforge init private   # Creates PRIVATE_WORLD/ with standard directories
```

### World-Specific Options

Each world type has additional options for customization:

#### Research Projects
- `--title "Project Title"`: Human-readable project title (required for new projects)
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
dirforge init research --project "2025_thermal_model_analysis" --study "Heat Transfer Model"

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

#### Lecture Projects  
- `--name "Course Name"`: Lecture/course name (required)
- `--no-conda`: Skip conda environment creation

#### Coding Projects
- `--project "project-name"`: Project name (required)
- `--language LANG`: Programming language (python, javascript, etc.)
- `--no-conda`: Skip conda environment creation (for Python projects)

#### Journal Projects
- `--journal "Journal Name"`: Target journal name (required)
- `--id "MANUSCRIPT_ID"`: Manuscript or reviewer ID (required)

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

Developer commands
- Install yq (strict YAML validation): `brew install yq`
- Lint shell scripts: `scripts/lint_shell.sh`
- Run full test suite: `bash tests/run_tests.sh`
- Validate help system content: `scripts/validate_help_content.sh`
- Test help system performance: `tests/help/test_performance.sh`
- Validate a manifest: `./tools/manifest.sh path/to/your.manifest.yaml`

**Help System Architecture:**
- Progressive disclosure: `dirforge --help` → `dirforge init --help` → `dirforge init <world> --help`
- Terminal adaptation: Auto-detects color support, terminal width, paging capability
- Constitution integration: Dynamic references to DirForge Constitution v1.0.17
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