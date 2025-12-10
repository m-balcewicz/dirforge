# dirforge — workspace scaffolder (DirForge)

This repository contains a small Bash-first CLI, `dirforge`, which scaffolds standardized directory structures according to the DirForge Constitution.

## Key Features
- **Complete workspace initialization**: Create all 6 world types at once
- **Individual world creation**: Research, lecture, coding, journal, office, private projects
- **Interactive and automated modes**: Prompts or automatic creation with flags
- **Dry-run preview**: See what will be created before making changes
- **JSON output**: Machine-readable plans for automation
- **Constitution compliance**: All structures follow DirForge Constitution v1.0.16

## Constitutional Compliance

DirForge now includes built-in validation and automated tests to ensure generated
workspaces strictly follow the authoritative DirForge Constitution (v1.0.16).

- Run the comprehensive compliance test suite:

```bash
# Run the repo-level integration tests (includes constitution checks)
bash tests/run_tests.sh

# Run the dedicated constitutional compliance checks
bash tests/test_constitution_compliance.sh
```

The `dirforge` CLI reports the constitution version and supports a dry-run JSON
mode for automation and CI integration.

Overview
- CLI script: `tools/dirforge` (Bash)
- Help system libraries: `lib/` (terminal detection, color formatting, help content)
- Templates: `templates/` (project templates, help examples, configuration templates)
- Installer helper: `scripts/install_dirforge.sh`

Install (recommended, user-local)
1) Make sure `~/bin` is on your PATH (zsh):
```bash
mkdir -p ~/bin
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

2) Install dirforge (local default; system-wide requires sudo):
```bash
# Local (default)
bash scripts/install_dirforge.sh

# Explicit local
bash scripts/install_dirforge.sh --local

# System-wide
sudo bash scripts/install_dirforge.sh --system
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
- **Constitution compliance**: Direct references to DirForge Constitution v1.0.16
- **Directory structure previews**: ASCII tree views of generated structures
- **Copy-pasteable examples**: Real-world usage patterns for each world type
- **Terminal adaptation**: Automatic paging for long content, NO_COLOR support

## Usage examples

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
│   ├── 00_admin/
│   ├── 01_projects/
│   └── 90_archive/
├── JOURNAL_WORLD/
│   ├── 00_admin/
│   ├── 01_daily/
│   ├── 02_weekly/
│   ├── 03_monthly/
│   ├── 04_yearly/
│   └── 90_archive/
├── LECTURE_WORLD/
│   ├── 00_admin/
│   ├── 01_courses/
│   └── 90_archive/
├── OFFICE_WORLD/
│   ├── 00_admin/
│   ├── 01_finance/
│   ├── 04_inventory_equipment/
│   ├── 05_software_licenses/
│   ├── 06_public_relations/
│   └── 90_archive/
├── PRIVATE_WORLD/
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
    ├── 00_admin/
    ├── 01_projects/
    └── 90_archive/
```

### Individual World Projects

Create specific projects within existing world directories:

```bash
# Research projects (within RESEARCH_WORLD/)
dirforge init research --title "Thermal Model Analysis"
dirforge init research --title "ML Study" --python 3.12
dirforge init research --title "Theory Work" --no-conda
dirforge init research --title "Existing Project" --backup

# Lecture projects (within LECTURE_WORLD/)  
dirforge init lecture --name "Digital Rock Physics"
dirforge init lecture --name "Physics 101" --backup
dirforge init lecture --name "Advanced Course" --force

# Coding projects (within CODING_WORLD/)
dirforge init coding --language python --project ml_toolkit
dirforge init coding --language javascript --project web_app
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
- `--title "Project Title"`: Human-readable project title (required)
- `--python VERSION`: Python version for conda environment (default: 3.11)
- `--no-conda`: Skip conda environment creation
- `--conda-packages "pkg1 pkg2"`: Additional packages beyond base set

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
- Constitution integration: Dynamic references to DirForge Constitution v1.0.16
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