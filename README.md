# dirforge — workspace scaffolder (DirForge)

This repository contains a small Bash-first CLI, `dirforge`, which scaffolds standardized directory structures according to the DirForge Constitution.

Overview
- CLI script: `tools/dirforge` (Bash)
- Templates: `templates/` (project.yaml.template, lecture project templates)
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

Usage examples

```bash
# Create a research project
dirforge init research --title "Thermal Model Analysis"

# Create a lecture project
dirforge init lecture --name "Digital Rock Physics"

# Create a coding project (python)
dirforge init coding --language python --project ml_toolkit
```

Developer commands
- Install yq (strict YAML validation): `brew install yq`
- Lint shell scripts: `scripts/lint_shell.sh`
- Run full test suite: `bash tests/run_tests.sh`
- Validate a manifest: `./tools/manifest.sh path/to/your.manifest.yaml`

Notes & future directions
- The current tool is intentionally simple and Bash-first and lives in `tools/` for now.
- We can later migrate to a `bin/` layout, add a `src/` Python module for richer features, or convert into a packaged CLI (`pyproject.toml`) when the codebase grows.
- The installer is deliberately idempotent and conservative — it copies the script, it does not remove or modify other files.

Contributing
- If you want to add features (journal init, extra templates, tests), keep helper scripts in `tools/` and templates in `templates/`.