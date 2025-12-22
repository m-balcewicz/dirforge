# Migration Guide: DirForge Constitution v1.0.20+ → v1.0.22

## Overview

This migration guide explains how to safely update DirForge workspaces from older constitution versions (v1.0.16 through v1.0.21) to the latest version (v1.0.22). The v1.0.22 update introduces the centralized `.integrity/` metadata system for enhanced structure validation and consistency checking.

The `dirforge update` command automates the migration process, but understanding the changes helps you validate the results.

**Key Features of v1.0.22:**
- Centralized `.integrity/` directory for metadata
- Hierarchical YAML metadata (workspace.yaml, project.yaml, etc.)
- Structure validation and checksums
- Support for all world types (RESEARCH_WORLD, JOURNAL_WORLD, CODING_WORLD, etc.)
- Backward compatibility with legacy project.yaml files

## General Migration Principles

- **Additive Only**: The update process only adds missing directories and files. No user data is deleted or overwritten.
- **Backup First**: Always create a backup before updating. Use `dirforge update --backup` to create an automated timestamped backup.
- **Preview Changes**: Use `dirforge update --dry-run` to preview what will be changed before applying updates.
- **Automatic Migration**: The legacy `project.yaml` file is automatically migrated to `.integrity/project.yaml`.
- **Legacy Compatibility**: The old `project.yaml` file remains intact for backward compatibility.

## Before You Migrate

### Requirements

- Bash 4.0 or later
- Standard Unix tools (find, grep, etc.)
- Read and write access to your workspace directory
- ~5 MB free disk space (for .integrity/ directory and backups)

### Backup Your Workspace

Create a backup before starting the migration:

```bash
# Automated backup (recommended)
dirforge update --backup

# Manual backup
cp -r <your_workspace> <your_workspace>.backup.$(date +%Y%m%d_%H%M%S)
```

## Migration Steps

### Step 1: Preview the Changes

Always preview first to understand what will be changed:

```bash
# Preview changes without making them
dirforge update --dry-run

# View in JSON format for automation/parsing
dirforge update --dry-run --json
```

This shows you:
- Current detected version
- Target version (v1.0.22)
- Detected world type
- List of directories/files that will be added
- Any warnings or issues

### Step 2: Create a Backup

If you haven't already:

```bash
dirforge update --backup
```

This creates a timestamped backup directory before making changes.

### Step 3: Apply the Update

```bash
# Simple update
dirforge update

# Update specific directory
dirforge update /path/to/project

# Update with explicit path
dirforge update --path=/path/to/workspace
```

The command will:
1. Detect the current structure version
2. Identify the world type
3. Create the `.integrity/` directory structure
4. Migrate metadata from legacy `project.yaml`
5. Create version-specific YAML files
6. Validate the updated structure
7. Display a summary of changes

### Step 4: Verify the Update

After the update completes:

```bash
# Check the .integrity directory was created
ls -la <project_dir>/.integrity/

# View migrated metadata
cat <project_dir>/.integrity/project.yaml

# Verify structure with dry-run (should show "already up to date")
dirforge update --dry-run
```

## What Gets Created/Changed

### New Directories

The `.integrity/` directory structure is created with:

```
.integrity/
├── project.yaml          # Migrated from legacy project.yaml
├── workspace.yaml        # Workspace-level metadata (if applicable)
├── checksums/            # Directory for integrity checksums
└── manifests/            # Directory for file manifests
```

### Metadata Files

Each metadata file contains version information:

**`.integrity/project.yaml` format:**
```yaml
project_id: your_project_id
name: Your Project Name
version: 1.0.22                # Updated to latest
world_type: RESEARCH_WORLD     # Detected from structure
creation_date: 2025-12-15
constitution_version: 1.0.22   # Latest constitution
```

### What Stays the Same

- All your project data and files remain **untouched**
- Existing `project.yaml` remains intact
- Directory structure from older versions is preserved
- All subdirectories and their contents are preserved

## World-Type Specific Information

### RESEARCH_WORLD

**Structure at v1.0.22:**
```
RESEARCH_WORLD/
└── project_name/
    ├── .integrity/              # NEW
    │   ├── project.yaml
    │   ├── checksums/
    │   └── manifests/
    ├── project.yaml             # (kept for compatibility)
    ├── 00_admin/
    ├── 01_project_management/
    └── 02_studies/
```

**Migration:**
- ✅ Automatic: Legacy `project.yaml` is migrated to `.integrity/project.yaml`
- ✅ Automatic: `.integrity/` directories are created
- ℹ️ Manual: Reorganize study files if needed (optional, structure is additive)

### JOURNAL_WORLD

**Structure at v1.0.22:**
```
JOURNAL_WORLD/
└── journal_project/
    ├── .integrity/              # NEW
    │   ├── project.yaml
    │   ├── checksums/
    │   └── manifests/
    ├── project.yaml             # (kept for compatibility)
    ├── 00_admin/
    └── 01_primary_authorship/
        ├── 02_coauthor_invites/
        └── 03_journal_service/
```

**Migration:**
- ✅ Automatic: Metadata migration
- ✅ Automatic: Missing role directories added if needed
- ℹ️ Note: If migrating from v1.0.20, ensure journal projects are organized by role

### CODING_WORLD

**Structure at v1.0.22:**
```
CODING_WORLD/
└── project_name/
    ├── .integrity/              # NEW
    │   ├── project.yaml
    │   ├── checksums/
    │   └── manifests/
    ├── project.yaml             # (kept for compatibility)
    ├── 00_admin/
    └── 01_projects/
        ├── project_subdir1/
        ├── project_subdir2/
        └── ...
```

**Migration:**
- ✅ Automatic: All migration steps are automatic
- ✅ No breaking changes for CODING_WORLD

### LECTURE_WORLD

**Structure at v1.0.22:**
```
LECTURE_WORLD/
└── course_name/
    ├── .integrity/              # NEW
    ├── project.yaml
    ├── 00_admin/
    ├── 01_courses/
    └── ...
```

**Migration:**
- ✅ Automatic: All migration steps are automatic

## Troubleshooting

### Problem: "Could not detect world type"

**Cause:** The script couldn't determine if this is a RESEARCH_WORLD, CODING_WORLD, etc.

**Solutions:**

1. **Check directory structure:**
   ```bash
   # Verify you're in a valid world or project directory
   ls -la  # Should see world type directories (00_admin, 01_projects, etc.)
   ```

2. **Use --force flag:**
   ```bash
   # Override detection and use defaults
   dirforge update --force --dry-run
   ```

3. **Create project.yaml with world_type:**
   ```bash
   cat > project.yaml << EOF
   world_type: RESEARCH_WORLD
   project_id: my_project
   name: My Project
   version: 1.0.20
   EOF
   dirforge update --dry-run
   ```

### Problem: "Permission denied" when creating .integrity/

**Cause:** The directory lacks write permissions.

**Solutions:**

1. **Check permissions:**
   ```bash
   ls -la .integrity/
   chmod u+w .
   ```

2. **Run with appropriate privileges:**
   ```bash
   sudo dirforge update
   ```

3. **Update parent directory only:**
   ```bash
   # If individual project lacks permissions, try workspace level
   cd ..
   dirforge update --dry-run
   ```

### Problem: Migration failed midway

**Cause:** An error occurred during migration.

**Solutions:**

1. **Restore from backup:**
   ```bash
   cp -r <workspace>.backup.<timestamp>/* <workspace>/
   ```

2. **Check error details:**
   ```bash
   dirforge update --dry-run  # Shows what failed
   ```

3. **Retry with verbose output:**
   ```bash
   dirforge update 2>&1 | tee migration.log
   ```

### Problem: "Already up to date" but .integrity doesn't exist

**Cause:** Mixed version states or detection issue.

**Solutions:**

1. **Check actual structure:**
   ```bash
   find . -name ".integrity" -type d
   ls -la .integrity/  # Should exist
   ```

2. **Force re-scan:**
   ```bash
   rm -rf .integrity/  # Remove if corrupted
   dirforge update --force --dry-run
   ```

3. **Update with explicit flags:**
   ```bash
   dirforge update --force --dry-run
   ```

## Using JSON Output for Automation

The `--json` flag is useful for scripting and CI/CD:

```bash
# Get migration plan as JSON
dirforge update --dry-run --json | jq .

# Parse specific information
dirforge update --dry-run --json | jq '.changes | length'

# Check if update is needed
dirforge update --dry-run --json | jq '.already_up_to_date'
```

**JSON Output Structure:**
```json
{
  "ok": true,
  "current_version": "1.0.20",
  "target_version": "1.0.22",
  "world_type": "RESEARCH_WORLD",
  "dry_run": true,
  "already_up_to_date": false,
  "changes": [
    "ADD .integrity/",
    "ADD .integrity/checksums/",
    "ADD .integrity/project.yaml"
  ]
}
```

## Verifying a Successful Migration

After migration completes, verify:

```bash
# 1. Check .integrity directory exists
test -d .integrity && echo "✓ .integrity directory created"

# 2. Check metadata file exists
test -f .integrity/project.yaml && echo "✓ project.yaml migrated"

# 3. Verify version was updated
grep "version:" .integrity/project.yaml | grep "1.0.22" && echo "✓ Version updated to 1.0.22"

# 4. Run another dry-run (should show "already up to date")
dirforge update --dry-run | grep -i "already up to date" && echo "✓ Structure validated"
```

## Rollback Instructions

If you need to revert to the previous version:

```bash
# Restore from backup (if you used --backup)
cp -r <workspace>.backup.<timestamp>/* <workspace>/

# Or manually:
rm -rf .integrity/
# Legacy project.yaml is preserved automatically
```

## Performance Notes

- Single project update: ~65ms
- Medium workspace (10 projects): ~75ms
- Large workspace (60 projects): ~166ms
- All operations well under 5 second requirement

See `specs/009-update-command/performance-analysis.txt` for detailed benchmarks.

## Getting Help

If you encounter issues not covered here:

1. **Check the help system:**
   ```bash
   dirforge update --help
   ```

2. **Review test files:**
   - `tests/test_update_migration_v1.0.22.sh` - Migration scenarios
   - `tests/test_update_integration_v1.0.22.sh` - Integration tests
   - `tests/test_update_force_override.sh` - Force flag examples

3. **Enable debug output:**
   ```bash
   dirforge update --dry-run 2>&1 | head -50
   ```

## Migration Summary

| Aspect | Details |
|--------|---------|
| **Duration** | < 1 second for typical workspace |
| **Risk Level** | Very Low (additive only, with automatic backup) |
| **Data Loss** | None (preserves all user data) |
| **Reversibility** | Fully reversible (backup restoration) |
| **World Types** | All supported (RESEARCH, JOURNAL, CODING, LECTURE, OFFICE, PRIVATE, LITERATURE) |
| **Breaking Changes** | None at v1.0.22 (v1.0.21→v1.0.22 is additive only) |

---

**Last Updated:** 2025-12-22  
**DirForge Constitution Version:** v1.0.22  
**Migration Tool:** dirforge v1.0.22
