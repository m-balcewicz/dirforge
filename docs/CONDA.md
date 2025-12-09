# Conda usage and DirForge

This document describes how `dirforge` handles Conda environments and recommendations for working on macOS and CI.

Principles
- Manifests and project templates must never contain plaintext credentials.
- `dirforge` may optionally create a Conda environment when scaffolding a project; this is disabled with `--no-conda`.

Local usage
- To create a Conda environment locally run `dirforge` without `--no-conda` and follow prompts.
- If you prefer not to create environments on macOS or CI, use `--no-conda`.

Scaffolder behavior
- When Conda env creation is enabled, `dirforge` will write an `environment.yml` template into the project root.
- The scaffolder does not automatically `conda env create` in CI; this is intentional to avoid side effects. CI jobs should install dependencies using `conda` only where necessary.

Testing and CI
- Tests that run the scaffolder should avoid creating real Conda environments. The test harness uses `--no-conda` or restricts `PATH` to prevent accidental `conda` invocation.
- CI can install `conda` if you want to test environment creation; otherwise prefer running `dirforge --no-conda` in CI.

Notes for maintainers
- Add a short example in `specs` showing how to export `environment.yml` and how to reproduce locally.
