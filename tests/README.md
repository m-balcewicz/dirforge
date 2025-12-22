# Tests — safe integration harness

This folder contains a minimal integration test harness for `dirforge` that runs the scaffolder in a temporary directory and avoids making system-wide changes.

How it works
- The test script `run_tests.sh` creates a temporary directory and runs `tools/dirforge` inside it.
- To prevent accidental creation of conda environments during tests, the script temporarily restricts `PATH` to `/bin:/usr/bin` so `conda` is not discovered. This keeps tests safe on developer machines.
- The script exercises: `init research --no-conda`, `init lecture --no-conda`, `init journal --journal --id`, `init office`, and `init private` and checks that expected folders are created.

Run the tests

```bash
bash tests/run_tests.sh
```

Notes and next steps
- These are lightweight, filesystem-only checks. They do not install software or create conda environments.
- For stronger isolation and reproducible CI, consider using Docker or a dedicated CI runner with an isolated conda installation.
- Future improvements:
  - Add unit tests (BATS) that assert file contents and templates.
  - Add a `--dry-run` mode to `dirforge` and test it.
  - Add a GitHub Actions workflow that runs `bash -n` and these tests on each PR.
