# dirforge — workspace scaffolder (DirForge)

This repository contains a small Bash-first CLI, `dirforge`, which scaffolds standardized directory structures according to the DirForge Constitution.

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

Usage examples

```bash
# Create a research project
dirforge init research --title "Thermal Model Analysis"

# Create a lecture project
dirforge init lecture --name "Digital Rock Physics"

# Create a coding project (python)
dirforge init coding --language python --project ml_toolkit

# Create journal project for your submission
dirforge init journal --journal "Geophysics" --id "GEO-2025-0451"

# Create journal project for reviewer work
dirforge init journal --journal "Nature Geoscience" --id "REVIEWER_2024_Q4"

# Create journal project for editorial duties
dirforge init journal --journal "JGR Solid Earth" --id "ASSOC_EDITOR_2024"
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