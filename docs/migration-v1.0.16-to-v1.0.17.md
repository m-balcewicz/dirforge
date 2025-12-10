# Migration Guide: DirForge Constitution v1.0.16 → v1.0.17

## Overview

DirForge Constitution v1.0.17 introduces a **breaking change** to research project organization. Research projects now use a **study-based structure** where individual studies are contained within projects, replacing the previous flat project organization.

**Migration Timeline:** This is a breaking change. Existing research projects must be migrated manually.

## What Changed

### Before (v1.0.16)
```
RESEARCH_WORLD/
├── 00_admin/
├── 01_projects/
│   ├── project_a/
│   │   ├── 00_protocols/
│   │   ├── 01_code/
│   │   ├── 02_data/
│   │   ├── 03_outputs/
│   │   ├── 04_publication/
│   │   └── 05_presentations/
│   └── project_b/
│       └── ...
└── 90_archive/
```

### After (v1.0.17)
```
RESEARCH_WORLD/
├── <project_id>/
│   ├── 00_admin/           # Project-level admin (contracts, ethics, etc.)
│   ├── 01_project_management/  # Project-level management (proposals, budgets, etc.)
│   ├── 02_studies/         # Container for individual studies
│   │   ├── study_name_a/
│   │   │   ├── 00_protocols/
│   │   │   ├── 01_code/
│   │   │   ├── 02_data/
│   │   │   ├── 03_outputs/
│   │   │   ├── 04_publication/
│   │   │   └── 05_presentations/
│   │   └── study_name_b/
│   │       └── ...
│   └── .integrity/         # Project-level integrity files
```

## Breaking Changes

1. **Directory Structure**: Projects now have `00_admin/`, `01_project_management/`, `02_studies/` at the top level
2. **Study Organization**: Individual studies are now contained within `02_studies/` subdirectory
3. **Project ID**: Projects are created as `RESEARCH_WORLD/<project_id>/` instead of `RESEARCH_WORLD/01_projects/<project_id>/`
4. **No More 03-08 Directories**: Old numbered directories (03_analysis, 04_results, etc.) are removed

## Migration Steps

### Step 1: Backup Your Data
```bash
# Create timestamped backup
cp -r RESEARCH_WORLD RESEARCH_WORLD.backup.$(date +%Y%m%d_%H%M%S)
```

### Step 2: Create New Project Structure
For each existing project in `RESEARCH_WORLD/01_projects/`:

```bash
# Example migration for "thermal_model_analysis" project
cd RESEARCH_WORLD

# Create new project structure
mkdir -p thermal_model_analysis/{00_admin,01_project_management,02_studies,.integrity/checksums,.integrity/manifests}

# Move project-level files
mv 01_projects/thermal_model_analysis/project.yaml thermal_model_analysis/
mv 01_projects/thermal_model_analysis/README.md thermal_model_analysis/

# Move admin documents to 00_admin/
mv 01_projects/thermal_model_analysis/00_admin/* thermal_model_analysis/00_admin/ 2>/dev/null || true

# Move management documents to 01_project_management/
mv 01_projects/thermal_model_analysis/01_project_management/* thermal_model_analysis/01_project_management/ 2>/dev/null || true
```

### Step 3: Convert Old Studies to New Structure
Each old project becomes a single study within the new project:

```bash
# Convert old project to study structure
cd RESEARCH_WORLD/thermal_model_analysis

# Create study directory (use descriptive name)
mkdir -p 02_studies/thermal_model_analysis

# Move existing content
mv ../01_projects/thermal_model_analysis/00_protocols 02_studies/thermal_model_analysis/
mv ../01_projects/thermal_model_analysis/01_code 02_studies/thermal_model_analysis/
mv ../01_projects/thermal_model_analysis/02_data 02_studies/thermal_model_analysis/
mv ../01_projects/thermal_model_analysis/03_outputs 02_studies/thermal_model_analysis/
mv ../01_projects/thermal_model_analysis/04_publication 02_studies/thermal_model_analysis/
mv ../01_projects/thermal_model_analysis/05_presentations 02_studies/thermal_model_analysis/

# Create study integrity directories
mkdir -p 02_studies/thermal_model_analysis/.integrity/{checksums,manifests}
```

### Step 4: Update Project Metadata
Update the `project.yaml` file to reference studies:

```yaml
# Before
owner: "Research Team"
contact: "team@example.edu"

# After
owner: "Research Team"
contact: "team@example.edu"
studies:
  - id: "thermal_model_analysis"
    name: "Thermal Model Analysis"
    description: "Complete thermal modeling study"
    status: "active"
```

### Step 5: Update README.md
Update project README to reflect new structure:

```markdown
# Thermal Model Analysis Project

## Studies
- `02_studies/thermal_model_analysis/` - Complete thermal modeling workflow
```

### Step 6: Clean Up
```bash
# Remove old project directory
rm -rf RESEARCH_WORLD/01_projects/thermal_model_analysis

# Remove old 01_projects if empty
rmdir RESEARCH_WORLD/01_projects 2>/dev/null || true
```

## Automated Migration Script

Save this script as `migrate_v1.0.17.sh` and run it from your workspace root:

```bash
#!/bin/bash
set -e

# Migration script: DirForge v1.0.16 → v1.0.17
# Run from workspace root containing RESEARCH_WORLD/

if [ ! -d "RESEARCH_WORLD/01_projects" ]; then
    echo "No old projects found - already migrated or no projects exist"
    exit 0
fi

echo "Starting migration from v1.0.16 to v1.0.17..."

for old_project in RESEARCH_WORLD/01_projects/*/; do
    if [ ! -d "$old_project" ]; then continue; fi

    project_name=$(basename "$old_project")
    echo "Migrating project: $project_name"

    # Create new structure
    mkdir -p "RESEARCH_WORLD/$project_name/{00_admin,01_project_management,02_studies,.integrity/checksums,.integrity/manifests}"

    # Move project files
    [ -f "$old_project/project.yaml" ] && mv "$old_project/project.yaml" "RESEARCH_WORLD/$project_name/"
    [ -f "$old_project/README.md" ] && mv "$old_project/README.md" "RESEARCH_WORLD/$project_name/"

    # Move admin content
    [ -d "$old_project/00_admin" ] && mv "$old_project/00_admin"/* "RESEARCH_WORLD/$project_name/00_admin/" 2>/dev/null || true

    # Move management content
    [ -d "$old_project/01_project_management" ] && mv "$old_project/01_project_management"/* "RESEARCH_WORLD/$project_name/01_project_management/" 2>/dev/null || true

    # Convert project to study
    mkdir -p "RESEARCH_WORLD/$project_name/02_studies/$project_name/.integrity/{checksums,manifests}"

    for dir in 00_protocols 01_code 02_data 03_outputs 04_publication 05_presentations; do
        [ -d "$old_project/$dir" ] && mv "$old_project/$dir" "RESEARCH_WORLD/$project_name/02_studies/$project_name/"
    done

    # Update project.yaml
    if [ -f "RESEARCH_WORLD/$project_name/project.yaml" ]; then
        cat >> "RESEARCH_WORLD/$project_name/project.yaml" << EOF

# Added during v1.0.17 migration
studies:
  - id: "$project_name"
    name: "$project_name"
    description: "Migrated from v1.0.16 structure"
    status: "active"
EOF
    fi

    # Remove old project
    rm -rf "$old_project"
done

# Clean up empty directories
rmdir RESEARCH_WORLD/01_projects 2>/dev/null || true

echo "Migration complete! Please verify your data integrity."
```

## Verification Checklist

After migration, verify:

- [ ] All project files moved to correct locations
- [ ] Study content accessible in `02_studies/<study_name>/`
- [ ] Checksums and manifests preserved
- [ ] Project.yaml updated with study references
- [ ] README.md updated to reflect new structure
- [ ] No broken file references in scripts/notebooks

## Troubleshooting

### Issue: Missing Files
**Symptom:** Files not found after migration
**Solution:** Check backup and restore from `RESEARCH_WORLD.backup.*`

### Issue: Broken Symlinks
**Symptom:** Symlinks point to old paths
**Solution:** Update symlinks to new `02_studies/<study_name>/` paths

### Issue: Script Errors
**Symptom:** Analysis scripts fail with path errors
**Solution:** Update hardcoded paths to reflect new structure:
```python
# Old
data_path = "../02_data/"

# New
data_path = "../02_studies/thermal_model_analysis/02_data/"
```

## Getting Help

If you encounter issues:
1. Check this migration guide
2. Review the DirForge Constitution v1.0.17
3. Test with `dirforge init research --dry-run` to see new structure
4. File an issue with migration details

## Related Documentation

- [DirForge Constitution v1.0.17](../constitution.md)
- [Research Project Examples](../examples/RESEARCH_WORLD/)
- [Study-Based Organization Guide](study-organization.md)