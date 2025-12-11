# Migration Guide: Journal Structure v1.0.20 → v1.0.21

## Overview

DirForge Constitution v1.0.21 introduces a **breaking change** to journal project organization. Journal projects now use a **role-based structure** where projects are organized by academic role rather than journal name, improving workflow clarity and collaboration tracking.

**Migration Timeline**: This is a breaking change. Existing journal projects must be migrated manually.

## What Changed

### Before (v1.0.20): Journal-Name Organization
```
JOURNAL_WORLD/
├── GEOPHYSICS/
│   ├── manuscript_2024_001/
│   │   ├── 01_manuscript/
│   │   ├── 02_reviews/
│   │   └── 03_correspondence/
│   └── reviewer_2024_q3/
├── NATURE_GEOSCIENCE/
│   └── editorial_board_2024/
└── JGR_SOLID_EARTH/
    └── assoc_editor_position/
```

**Command Format (Old)**:
```bash
dirforge init journal --journal "Geophysics" --id "manuscript_2024_001"
dirforge init journal --journal "Nature Geoscience" --id "editorial_board_2024"
```

### After (v1.0.21): Role-Based Organization
```
JOURNAL_WORLD/
├── 00_admin/                    # Manual organization only
│   ├── subscriptions/
│   └── memberships/
├── 01_primary_authorship/       # Lead author projects
│   ├── 2024_thermal_analysis/
│   └── 2025_seismic_modeling/
├── 02_coauthor_invites/         # Collaborative projects
│   ├── 2021_elastic_properties/
│   └── 2024_consortium_study/
└── 03_journal_service/          # Reviews & editorial work
    ├── geophysics/
    │   └── GEO-2024-001/
    └── nature_geoscience/
        └── REVIEWER_2024_Q4/
```

**Command Format (New)**:
```bash
# Primary authorship (lead author)
dirforge init journal --name "thermal_analysis" --first
dirforge init journal --name "seismic_modeling" --first --year 2025

# Co-author collaboration
dirforge init journal --name "2021_elastic_properties" --coauthor
dirforge init journal --name "consortium_study" --coauthor

# Journal service (reviews, editorial)
dirforge init journal --name "Geophysics" --id "GEO-2024-001" --service
dirforge init journal --name "Nature Geoscience" --id "REVIEWER_2024_Q4" --service
```

## Breaking Changes

### 1. Command Interface
- **Removed**: `--journal` flag → **Replaced**: `--name` flag (universal)
- **Added**: Role flags: `--first`, `--coauthor`, `--service`
- **Enhanced**: `--year` flag with automatic extraction from paper names
- **Required**: `--id` flag only with `--service` (not with authorship roles)

### 2. Directory Structure
- **Old**: Projects grouped by journal name (`JOURNAL_WORLD/JOURNAL_NAME/ID/`)
- **New**: Projects grouped by academic role (`JOURNAL_WORLD/ROLE_DIRECTORY/PROJECT/`)
- **Benefit**: Clearer separation of different academic responsibilities

### 3. File Organization
- **Unchanged**: Standard subdirectories (`01_manuscript/`, `02_reviews/`, `03_correspondence/`)
- **Enhanced**: Role-based context makes finding relevant projects easier

## Migration Process

### Step 1: Assessment
1. **Backup existing structure**:
   ```bash
   cp -r JOURNAL_WORLD/ JOURNAL_WORLD_BACKUP_$(date +%Y%m%d)
   ```

2. **Inventory existing projects** and categorize by role:
   - **Lead author projects** → will go to `01_primary_authorship/`
   - **Collaborative projects** → will go to `02_coauthor_invites/`
   - **Review/editorial work** → will go to `03_journal_service/`
   - **Administrative content** → will go to `00_admin/` (manual organization)

### Step 2: Create New Structure
1. **Initialize role-based structure** (creates all role directories):
   ```bash
   # This will create the 4-role directory structure
   dirforge init journal --name "migration_test" --first
   ```

2. **Remove test project**:
   ```bash
   rm -rf JOURNAL_WORLD/01_primary_authorship/*migration_test*
   ```

### Step 3: Migrate Content by Role

#### For Primary Authorship Projects
```bash
# Example: Old structure JOURNAL_WORLD/GEOPHYSICS/thermal_study_2024/
# → New structure: JOURNAL_WORLD/01_primary_authorship/2024_thermal_study/

# Create new project structure
dirforge init journal --name "thermal_study" --first --year 2024

# Move content from old location
mv JOURNAL_WORLD_BACKUP/GEOPHYSICS/thermal_study_2024/01_manuscript/* \
   JOURNAL_WORLD/01_primary_authorship/2024_thermal_study/01_manuscript/

mv JOURNAL_WORLD_BACKUP/GEOPHYSICS/thermal_study_2024/02_reviews/* \
   JOURNAL_WORLD/01_primary_authorship/2024_thermal_study/02_reviews/

mv JOURNAL_WORLD_BACKUP/GEOPHYSICS/thermal_study_2024/03_correspondence/* \
   JOURNAL_WORLD/01_primary_authorship/2024_thermal_study/03_correspondence/
```

#### For Co-author Projects
```bash
# Example: Old structure JOURNAL_WORLD/NATURE_GEOSCIENCE/international_collab/
# → New structure: JOURNAL_WORLD/02_coauthor_invites/2024_international_collab/

# Create new project structure
dirforge init journal --name "international_collab" --coauthor

# Move content (same pattern as above)
```

#### For Journal Service Projects
```bash
# Example: Old structure JOURNAL_WORLD/GEOPHYSICS/reviewer_2024_q3/
# → New structure: JOURNAL_WORLD/03_journal_service/geophysics/REVIEWER_2024_Q3/

# Create new project structure
dirforge init journal --name "Geophysics" --id "REVIEWER_2024_Q3" --service

# Move content (same pattern as above)
```

### Step 4: Administrative Content
```bash
# Create admin structure manually
mkdir -p JOURNAL_WORLD/00_admin/{subscriptions,memberships,general}

# Move any administrative content
mv JOURNAL_WORLD_BACKUP/admin_content/* JOURNAL_WORLD/00_admin/general/
```

### Step 5: Validation
1. **Verify all content migrated**:
   ```bash
   # Check that backup and new structure have equivalent content
   find JOURNAL_WORLD_BACKUP -name "*.pdf" | wc -l
   find JOURNAL_WORLD -name "*.pdf" | wc -l
   ```

2. **Test new commands**:
   ```bash
   # Verify you can create new projects with new syntax
   dirforge init journal --name "test_migration" --first --dry-run
   dirforge init journal --name "Test Journal" --id "TEST-001" --service --dry-run
   ```

3. **Clean up old structure** (only after verification):
   ```bash
   # Remove old journal directories that were successfully migrated
   rm -rf JOURNAL_WORLD/GEOPHYSICS JOURNAL_WORLD/NATURE_GEOSCIENCE
   ```

## Common Migration Scenarios

### Scenario 1: Mixed Role Projects in Same Journal
**Old**: Multiple projects in same journal directory with different purposes
```
JOURNAL_WORLD/GEOPHYSICS/
├── my_manuscript_2024/     # Your lead-author work
├── collab_project_2023/    # Co-author project  
└── reviewer_assignment/    # Review work
```

**Migration**: Split by role into different directories
```bash
# Lead author project → primary authorship
dirforge init journal --name "my_manuscript" --first --year 2024

# Collaborative project → co-author role  
dirforge init journal --name "2023_collab_project" --coauthor

# Review work → service role
dirforge init journal --name "Geophysics" --id "REVIEWER_ASSIGNMENT" --service
```

### Scenario 2: Year Embedded in Project Names
**Old**: `JOURNAL_WORLD/NATURE/2021_elastic_properties_study/`
**New**: Use `--coauthor` with embedded year (auto-extracted)
```bash
dirforge init journal --name "2021_elastic_properties_study" --coauthor
# Results in: JOURNAL_WORLD/02_coauthor_invites/2021_elastic_properties_study/
```

### Scenario 3: Editorial Board/Long-term Positions
**Old**: `JOURNAL_WORLD/JGR/editorial_board_member/`
**New**: Use service role with descriptive ID
```bash
dirforge init journal --name "JGR Solid Earth" --id "EDITORIAL_BOARD_2024" --service
# Results in: JOURNAL_WORLD/03_journal_service/jgr_solid_earth/EDITORIAL_BOARD_2024/
```

## Troubleshooting

### Issue: Command Not Found After Migration
**Symptoms**: Old commands no longer work
```bash
dirforge init journal --journal "Nature" --id "123"  # FAILS
```

**Solution**: Use new role-based syntax
```bash
dirforge init journal --name "Nature Geoscience" --id "NGS-123" --service
```

### Issue: Directory Conflicts
**Symptoms**: Migration creates conflicting directory names
**Solution**: Use backup and careful naming
```bash
# If conflict detected, rename manually before migration
mv JOURNAL_WORLD/conflicting_dir JOURNAL_WORLD_BACKUP/conflicting_dir_old
```

### Issue: Lost Content During Migration
**Symptoms**: Files missing after migration
**Solution**: Restore from backup and retry with careful validation
```bash
# Restore from backup
rm -rf JOURNAL_WORLD
cp -r JOURNAL_WORLD_BACKUP_20241211 JOURNAL_WORLD
# Retry migration with step-by-step validation
```

### Issue: Year Detection Not Working
**Symptoms**: Projects end up with current year instead of intended year
**Solution**: Use explicit `--year` flag for authorship projects
```bash
# Instead of relying on name parsing
dirforge init journal --name "historical_project" --first --year 2020
```

## Validation Checklist

### Pre-Migration
- [ ] Complete backup of JOURNAL_WORLD created
- [ ] All projects categorized by role (primary/coauthor/service)
- [ ] Migration plan documented for each project
- [ ] Test environment prepared

### Post-Migration
- [ ] All content successfully moved to new structure
- [ ] File counts match between backup and migrated structure
- [ ] New commands work correctly (`dirforge init journal --name "test" --first --dry-run`)
- [ ] Old directory structure removed (after verification)
- [ ] Documentation updated with new command syntax

## Getting Help

### Migration Support
For complex migration scenarios or issues:
- Use `dirforge init journal --help` for complete command reference
- Check constitution version: `dirforge --version`
- Always maintain backups during migration process
- Migration is one-way; plan carefully before executing

### Command Reference
```bash
# Help and examples
dirforge init journal --help          # Role-based help with examples
dirforge init journal --help-long     # Comprehensive migration guidance

# Version information
dirforge --version                     # Shows constitution v1.0.21

# Testing new commands (safe)
dirforge init journal --name "test" --first --dry-run
dirforge init journal --name "journal" --id "ID" --service --dry-run
```

## Summary

The v1.0.21 journal structure migration provides:
- **Clearer organization** by academic role rather than journal name
- **Better workflow separation** between lead authorship, collaboration, and service
- **Consistent command interface** with unified `--name` flag across all roles
- **Enhanced functionality** with automatic year extraction and improved validation

While this is a breaking change requiring manual migration, the improved organization and clearer role separation provide significant long-term benefits for managing academic journal activities.