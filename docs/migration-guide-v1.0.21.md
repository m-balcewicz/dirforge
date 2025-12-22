# Migration Guide: DirForge Constitution v1.0.16+ → v1.0.21

## Overview

This migration guide explains how to safely update DirForge workspaces from older constitution versions (v1.0.16 and later) to the latest version (v1.0.21). The `dirforge update` command automates most additive migrations, but some world types and versions require manual steps. Always back up your workspace before migrating.

## General Migration Principles
- **Additive Only**: The update process only adds missing directories/files. No user data is deleted or overwritten.
- **Backup First**: Use `dirforge update --backup` or manually back up your workspace before updating.
- **Preview**: Use `dirforge update --dry-run` to preview planned changes.
- **Manual Steps**: Some breaking changes require manual reorganization. See world-type sections below.

## Migration Steps

### 1. Backup Your Workspace
```bash
cp -r <your_workspace> <your_workspace>.backup.$(date +%Y%m%d_%H%M%S)
# Or use:
dirforge update --backup
```

### 2. Preview Planned Changes
```bash
dirforge update --dry-run
```

### 3. Apply the Update
```bash
dirforge update
```

### 4. Review Output and Manual Steps
- Review the summary and any warnings after update.
- If manual migration is required, see the relevant section below.

---

## World-Type Specific Migration Notes

### Research World: v1.0.16 → v1.0.17+
- **Breaking Change**: Projects now use a study-based structure (`02_studies/` per project).
- **Manual Migration Required**: Move existing projects from `RESEARCH_WORLD/01_projects/` to new per-project directories, and reorganize studies under `02_studies/`.
- See `docs/migration-v1.0.16-to-v1.0.17.md` for detailed steps and examples.

### Journal World: v1.0.20 → v1.0.21
- **Breaking Change**: Projects are now organized by academic role (primary authorship, coauthor, service) instead of journal name.
- **Manual Migration Required**: Move projects to the new role-based directories (`01_primary_authorship/`, `02_coauthor_invites/`, `03_journal_service/`).
- See `docs/journal-migration-v1.0.21.md` for detailed steps and examples.

### Other Worlds
- For coding, lecture, office, and private worlds, updates are additive and automated. No manual migration is required.

---

## Troubleshooting
- **Version Not Detected**: Use `--force` to override, but review output carefully.
- **Permission Errors**: Ensure you have write access to all directories.
- **Already Up to Date**: No changes will be made if your workspace matches the latest constitution.
- **Corrupted or Missing `project.yaml`**: Restore from backup or reinitialize as needed.

---

## Additional Resources
- [DirForge README](../README.md)
- [Research World Migration v1.0.16→v1.0.17](migration-v1.0.16-to-v1.0.17.md)
- [Journal World Migration v1.0.21](journal-migration-v1.0.21.md)
- Use `dirforge --help` and `dirforge update --help` for command-line guidance.

---

**If you have questions or encounter issues, please open an issue on GitHub or consult the help system.**
