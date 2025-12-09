# dirforge — workspace scaffolder (DirForge)

This repository contains a small Bash-first CLI, `dirforge`, which scaffolds standardized directory structures according to the DirForge Constitution.

Overview
- CLI script: `tools/dirforge` (Bash)
- Templates: `templates/` (project.yaml.template, CONSTITUTION_CHECK.md)
- Installer helper: `scripts/install_dirforge.sh`

Install (recommended, user-local)
1. Make sure `~/bin` is on your PATH (for zsh):

```bash
mkdir -p ~/bin
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

2. Run the installer (copies `tools/dirforge` into `~/bin`):

```bash
bash scripts/install_dirforge.sh
```

Or install system-wide (requires sudo):

```bash
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

Notes & future directions
- The current tool is intentionally simple and Bash-first and lives in `tools/` for now.
- We can later migrate to a `bin/` layout, add a `src/` Python module for richer features, or convert into a packaged CLI (`pyproject.toml`) when the codebase grows.
- The installer is deliberately idempotent and conservative — it copies the script, it does not remove or modify other files.

Contributing
- If you want to add features (journal init, extra templates, tests), keep helper scripts in `tools/` and templates in `templates/`.

License & governance
- Follow the `.specify/memory/constitution.md` rules for project IDs, manifests, and no-plaintext-credentials.
