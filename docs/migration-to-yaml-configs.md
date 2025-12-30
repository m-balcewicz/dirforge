# Migration to YAML Configuration System (v1.0.22)

**Version:** 1.0.22  
**Last Updated:** 2025-12-30  
**Migration Path:** v1.0.21 → v1.0.22

---

## Overview

DirForge v1.0.22 introduces a **declarative YAML-based configuration system** that replaces hard-coded directory structures. This guide helps you understand the changes and migrate existing workspaces.

### Key Changes

| Aspect | v1.0.21 | v1.0.22 |
|--------|---------|---------|
| **Configuration** | Hard-coded in Bash | Declarative YAML files |
| **Customization** | Limited (requires code changes) | Easy (edit YAML config) |
| **Reproducibility** | Per-command flags | Version-controlled configs |
| **Reusability** | Create new code per variant | Share config files |
| **Metadata** | Minimal | Comprehensive in `.integrity/` |

### Breaking Changes

⚠️ **Important**: v1.0.22 is **backward compatible** with existing workspaces, but:

1. **New command names**: `dirforge init` replaces positional world-type arguments
2. **New config flags**: Use `--config` or explicit world-type (CODING_WORLD, not "coding")
3. **New metadata structure**: `.integrity/` directories track creation details
4. **Config file location**: Configs in `templates/world-configs/` (not elsewhere)

---

## What Changed for Users

### v1.0.21 Usage

```bash
# Old command style (still works)
dirforge research
dirforge coding --language python
dirforge journal --first
```

### v1.0.22 Usage

```bash
# New command style (recommended)
dirforge init RESEARCH_WORLD --project myproject --study mystudy
dirforge init CODING_WORLD
dirforge init JOURNAL_WORLD --name "my_paper" --first
```

### Configuration Files

**v1.0.21**: No configuration files (everything hard-coded)

**v1.0.22**: Configuration files in `templates/world-configs/`
```
templates/world-configs/
├── coding.world.yaml
├── research.world.yaml
├── journal.world.yaml
├── lecture.world.yaml
├── office.world.yaml
├── private.world.yaml
├── literature.world.yaml
└── SCHEMA.md
```

### Metadata Tracking

**v1.0.21**: No metadata stored

**v1.0.22**: Creation information stored in `.integrity/` directories
```
workspace/
├── CODING_WORLD/
│   └── .integrity/
│       └── world.yaml        # Metadata for CODING_WORLD
├── RESEARCH_WORLD/
│   ├── .integrity/
│   │   └── workspace.yaml    # Metadata for workspace
│   └── myproject/
│       ├── .integrity/
│       │   └── project.yaml  # Metadata for project
│       └── mystudy/
│           └── .integrity/
│               └── study.yaml  # Metadata for study
```

---

## Migration Paths

### Scenario 1: Update Existing Workspace

**Question**: Do you have workspaces created with v1.0.21?

**Answer**: You don't need to do anything immediately. Workspaces are backward compatible.

**To upgrade**, use the `dirforge update` command:

```bash
# Update workspace to v1.0.22
cd ~/coding_workspace
dirforge update

# Or update from anywhere
dirforge update ~/coding_workspace

# Preview what will change
dirforge update ~/coding_workspace --dry-run
```

**What `dirforge update` does:**
- Adds new `.integrity/` metadata directories
- Creates updated metadata files
- Never deletes or overwrites existing content
- Additive-only changes (safe)

**Example output:**
```
Updating ~/coding_workspace from v1.0.21 to v1.0.22...

Changes:
  + Add CODING_WORLD/.integrity/world.yaml
  + Add CODING_WORLD/.integrity/project.yaml (for each project)
  + Add .integrity/workspace.yaml

No directories or files will be deleted.
Backup recommended before proceeding.
```

### Scenario 2: Create New Workspace with v1.0.22

```bash
# Use YAML config system
dirforge init CODING_WORLD ~/new_workspace

# Check generated structure
ls -la ~/new_workspace/
cat ~/new_workspace/CODING_WORLD/.integrity/world.yaml
```

### Scenario 3: Migrate from v1.0.21 to Custom Config

**Goal**: Replace hard-coded structure with reusable YAML config

**Steps:**

1. **Export current structure** (optional, for documentation):
```bash
# Document current layout
tree ~/coding_workspace/ > structure-backup.txt
```

2. **Create custom YAML config** based on your structure:
```yaml
world:
  type: MYWORLD
  description: "My organization structure"

metadata:
  version: "1.0.0"
  constitution_version: "1.0.22"
  created_by: "${USER}"
  created_at: "${DATE}"

parent_directories:
  projects:
    description: "My projects"
  archived:
    description: "Completed work"

subdirectories:
  projects:
    - active
    - in_review
    - completed
```

3. **Validate config**:
```bash
dirforge validate-config my-world.yaml
```

4. **Create new workspace with config**:
```bash
dirforge init --config my-world.yaml ~/new_workspace
```

5. **Copy data from old workspace** (if needed):
```bash
# Copy project files, exclude metadata
cp -r ~/old_workspace/projects/* ~/new_workspace/projects/

# Verify
ls -la ~/new_workspace/projects/
```

### Scenario 4: Share Custom Config with Team

**Goal**: Distribute standardized workspace configuration

**Steps:**

1. **Create and test config**:
```bash
cat > team-world.yaml <<'EOF'
world:
  type: TEAM_WORLD
  description: "Standard team workspace"

metadata:
  version: "1.0.0"
  constitution_version: "1.0.22"
  created_by: "${USER}"
  created_at: "${DATE}"

parent_directories:
  projects:
    description: "Team projects"
  shared:
    description: "Shared resources"
  archive:
    description: "Archived projects"

subdirectories:
  projects:
    - active
    - completed
  shared:
    - templates
    - documentation
    - tools
  archive:
    - 2024
    - 2023
EOF

# Validate
dirforge validate-config team-world.yaml
```

2. **Add to version control**:
```bash
git add team-world.yaml
git commit -m "Add team workspace config"
```

3. **Share with team**:
```bash
# Team members can use
dirforge validate-config team-world.yaml
dirforge init --config team-world.yaml ~/team_workspace
```

---

## Breaking Changes and Compatibility

### Backward Compatibility

✅ **v1.0.22 still supports v1.0.21 workspaces**

```bash
# Old workspaces still exist and work
ls ~/coding_workspace/python/

# But lack new metadata
ls ~/coding_workspace/.integrity/  # May not exist in old workspaces
```

### Forward Compatibility

❌ **v1.0.21 cannot understand v1.0.22 configs**

If you share a v1.0.22 workspace with someone using v1.0.21:
- They cannot modify it with their version
- Recommendation: Update your team to v1.0.22

### Version Detection

The system detects workspace versions automatically:

```bash
# Automatic version detection
dirforge update ~/workspace
# Detects: v1.0.21
# Upgrades to: v1.0.22

# Check version (stored in metadata)
cat ~/workspace/.integrity/workspace.yaml | grep constitution_version
# constitution_version: "1.0.22"
```

---

## Command Mapping (v1.0.21 → v1.0.22)

### Initialization Commands

| v1.0.21 | v1.0.22 | Notes |
|---------|---------|-------|
| `dirforge research` | `dirforge init RESEARCH_WORLD` | World-type now explicit |
| `dirforge coding` | `dirforge init CODING_WORLD` | World-type now explicit |
| `dirforge journal --first` | `dirforge init JOURNAL_WORLD --name "paper" --first` | Enhanced options |
| `dirforge lecture` | `dirforge init LECTURE_WORLD` | World-type now explicit |

### Configuration Commands (NEW in v1.0.22)

| Command | Purpose | Example |
|---------|---------|---------|
| `dirforge list-configs` | List available configs | `dirforge list-configs` |
| `dirforge validate-config` | Validate config file | `dirforge validate-config my.yaml` |
| `dirforge init --config` | Use explicit config | `dirforge init --config my.yaml` |

---

## Testing Your Migration

### Pre-Migration Checklist

- [ ] Backup existing workspaces
- [ ] Backup configuration files
- [ ] Document current directory structure
- [ ] Plan downtime if needed

### Migration Verification

```bash
#!/bin/bash
# Verify migration was successful

echo "=== Before Update ==="
ls -la ~/workspace/.integrity/ 2>/dev/null || echo "No .integrity/ found (v1.0.21)"

echo -e "\n=== Running Update ==="
dirforge update ~/workspace --dry-run

echo -e "\n=== After Update ==="
dirforge update ~/workspace
ls -la ~/workspace/.integrity/

echo -e "\n=== Verify Metadata ==="
cat ~/workspace/.integrity/workspace.yaml
cat ~/workspace/CODING_WORLD/.integrity/world.yaml

echo -e "\n=== Verify Data Integrity ==="
# Check that your files still exist
ls ~/workspace/CODING_WORLD/python/
ls ~/workspace/RESEARCH_WORLD/*/  2>/dev/null || echo "(No research projects)"

echo -e "\n✓ Migration complete"
```

### Rollback Plan

If something goes wrong:

```bash
# 1. Restore from backup
cp -r ~/workspace.backup ~/workspace

# 2. Or remove only metadata (keep data)
rm -rf ~/workspace/.integrity/
rm -rf ~/workspace/**/.integrity/

# 3. Retry migration
dirforge update ~/workspace --dry-run
dirforge update ~/workspace
```

---

## Troubleshooting Migration

### Issue: "Multiple constitution versions detected"

**Problem:**
```
Error: Workspace contains mixed constitution versions
```

**Cause:** Partial update or corrupted metadata

**Solution:**
```bash
# Option 1: Force clean update
dirforge update ~/workspace --force

# Option 2: Remove mixed metadata
find ~/workspace -name ".integrity" -type d
# Check for mixed versions, remove problematic ones

# Option 3: Full reset
rm -rf ~/workspace
dirforge init CODING_WORLD ~/workspace
# Then copy data back from backup
```

### Issue: "Metadata creation failed"

**Problem:**
```
Cannot create .integrity/workspace.yaml: Permission denied
```

**Cause:** Permission issue on workspace directory

**Solution:**
```bash
# Fix permissions
chmod 755 ~/workspace
chmod 755 ~/workspace/*

# Retry update
dirforge update ~/workspace
```

### Issue: "Config file format incompatible"

**Problem:**
```
Config validation failed: Incompatible schema version
```

**Cause:** Config created with different YAML schema

**Solution:**
```bash
# Update config to v1.0.22 schema
# Key required fields:
# - world.type
# - world.description
# - metadata.version
# - metadata.constitution_version: "1.0.22"
# - metadata.created_by: "${USER}"
# - metadata.created_at: "${DATE}"

dirforge validate-config your-config.yaml
```

---

## FAQ

### Q: Do I need to migrate my workspace right away?

**A:** No. v1.0.22 is backward compatible with v1.0.21 workspaces. You can migrate on your schedule.

### Q: What happens if I don't update?

**A:** Your existing workspaces continue to work. But you won't get new features:
- Configuration-based structure (reproducible)
- Metadata tracking (audit trail)
- Custom world types (via YAML)

### Q: Can I downgrade from v1.0.22 to v1.0.21?

**A:** Not recommended. While workspaces are compatible, v1.0.21 doesn't understand `.integrity/` metadata. It just ignores them.

**If you must downgrade:**
1. Backup v1.0.22 workspaces
2. Remove `.integrity/` directories (optional)
3. Use v1.0.21
4. Restore backups and upgrade when ready

### Q: How do I migrate a team workspace?

**A:** Use `dirforge update` on the shared workspace:

```bash
# Shared location
dirforge update /shared/team_workspace

# All users get updated structure
# Recommend: Coordinate timing to avoid conflicts
```

### Q: Are there any data loss risks?

**A:** No. `dirforge update` is additive-only:
- ✅ Adds metadata
- ✅ Adds new directories
- ❌ Never deletes files
- ❌ Never overwrites files

### Q: How do I verify migration success?

**A:** Check metadata creation:

```bash
# Should exist and be readable
cat ~/workspace/.integrity/workspace.yaml

# Should contain constitution_version
grep constitution_version ~/workspace/.integrity/workspace.yaml
# Output: constitution_version: "1.0.22"
```

### Q: What if I created custom world structures?

**A:** Define them in YAML configs:

1. Create `.yaml` file documenting your structure
2. Validate with `dirforge validate-config`
3. Share config for reproducibility
4. Use `--config` flag to initialize new workspaces

See **Scenario 3** above.

---

## Performance Impact

### Migration Time

- Small workspace (< 100 files): < 1 second
- Large workspace (> 10,000 files): < 5 seconds
- Metadata creation: < 100ms

### Storage Impact

Metadata adds minimal storage:
- `.integrity/` directory: ~2KB per level
- Total overhead: ~10KB per workspace (negligible)

### No Performance Degradation

Operations remain fast:
- Initialization: ~0.5-2s (same as v1.0.21)
- Updates: ~0.1-0.5s (same as v1.0.21)
- Config validation: ~500ms (new, acceptable)

---

## Getting Help

If you encounter issues during migration:

1. **Check Troubleshooting Guide**:
   - [`docs/yaml-config-troubleshooting.md`](yaml-config-troubleshooting.md)

2. **Review Configuration Schema**:
   - [`templates/world-configs/SCHEMA.md`](../templates/world-configs/SCHEMA.md)

3. **Enable Debug Mode**:
   ```bash
   DEBUG_YAML_CONFIG=1 dirforge update ~/workspace
   ```

4. **Verify Installation**:
   ```bash
   dirforge --version
   dirforge list-configs
   dirforge validate-config templates/world-configs/coding.world.yaml
   ```

---

**Document:** migration-to-yaml-configs.md  
**Created:** 2025-12-30  
**Status:** Complete  
**Target Audience:** Users upgrading from v1.0.21  
**Related Documents:** 
- User guide: `docs/yaml-config-user-guide.md`
- Troubleshooting: `docs/yaml-config-troubleshooting.md`
- Architecture: `docs/010-yaml-configuration-system.md`
