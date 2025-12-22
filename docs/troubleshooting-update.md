# DirForge Update Command - Troubleshooting Guide

## Common Issues and Solutions

### Detection & Version Issues

#### Issue: "Unknown version detected"

**Symptoms:**
```
ERROR: Could not determine current constitution version
Current version: unknown
Aborting: cannot determine migration path
```

**Root Cause:**
- Missing `project.yaml` in the directory
- Malformed `project.yaml` with missing version field
- Running update in wrong directory

**Solutions:**

**Option 1: Check directory structure**
```bash
# Verify you're in a valid project directory
pwd
ls -la | head -20

# Look for project.yaml
find . -maxdepth 1 -name "project.yaml" -o -name ".integrity"
```

**Option 2: Create minimal project.yaml**
```bash
# If completely missing, create one
cat > project.yaml << 'EOF'
world_type: RESEARCH_WORLD
project_id: my_project
name: My Project
version: 1.0.20
EOF

dirforge update --dry-run
```

**Option 3: Use --force flag**
```bash
# Override detection with defaults
dirforge update --force --dry-run

# This assumes:
# - world_type: RESEARCH_WORLD
# - version: 1.0.20 (migration to 1.0.22)
```

---

#### Issue: "Unknown world type detected"

**Symptoms:**
```
ERROR: Could not determine world type
World type: unknown
Aborting: cannot determine structure
```

**Root Cause:**
- Directory doesn't match expected world structure
- Missing characteristic subdirectories (00_admin, etc.)
- World type detection heuristics didn't match

**Solutions:**

**Option 1: Manually specify world type**
```bash
# Edit project.yaml
cat >> project.yaml << 'EOF'
world_type: RESEARCH_WORLD
EOF

dirforge update --dry-run
```

**Option 2: Create expected directory structure**
```bash
# For RESEARCH_WORLD
mkdir -p 00_admin 01_project_management 02_studies

# For CODING_WORLD
mkdir -p 00_admin 01_projects

# For JOURNAL_WORLD
mkdir -p 00_admin 01_primary_authorship

dirforge update --force --dry-run
```

**Option 3: Check detection logic**
```bash
# See what detection functions see
dirforge update --dry-run 2>&1 | head -20

# This shows:
# - Detected files/directories
# - Heuristics that were evaluated
# - Final world type determination
```

---

### Permission Issues

#### Issue: "Permission denied" creating .integrity/

**Symptoms:**
```
ERROR: Permission denied writing to .integrity/
Failed to create directory structure
```

**Root Cause:**
- Parent directory owned by different user
- Read-only filesystem or mounted directory
- SELinux or AppArmor restrictions

**Solutions:**

**Option 1: Check directory permissions**
```bash
# View current permissions
ls -la .

# Grant write permission
chmod u+w .

# Recursive fix if needed
chmod u+w -R .
```

**Option 2: Change to parent directory**
```bash
# If individual project is locked, try parent
cd ..
dirforge update --dry-run

# This scans all projects in the parent
```

**Option 3: Use elevated privileges (carefully)**
```bash
# Only if you own the directory
sudo dirforge update --dry-run

# Reset ownership after
sudo chown -R $USER:$USER .
```

**Option 4: Verify filesystem**
```bash
# Check if filesystem is mounted read-only
mount | grep "$(pwd)" | grep ro

# Check available space
df -h .
```

---

### Backup & Recovery Issues

#### Issue: Backup directory already exists

**Symptoms:**
```
ERROR: Backup directory already exists
Cannot create backup: /path/to/workspace.backup.20251222_120000
```

**Root Cause:**
- Previous backup from same date
- Backup directory not cleaned up
- Multiple update attempts

**Solutions:**

**Option 1: Remove old backup**
```bash
# List existing backups
ls -lta | grep backup

# Remove conflicting backup
rm -rf workspace.backup.20251222_120000

# Try backup again
dirforge update --backup
```

**Option 2: Use different backup location**
```bash
# Manual backup with unique name
cp -r . ../backup.$(date +%s)

# Then update
dirforge update
```

**Option 3: Skip backup and use manual copy**
```bash
# Create manual backup first
cp -r . ../my_project.backup

# Update without --backup flag
dirforge update
```

---

#### Issue: Cannot restore from backup

**Symptoms:**
```
ERROR: Backup file corrupted or incomplete
Restoration failed at step X
```

**Root Cause:**
- Incomplete backup (disk full during backup)
- Backup directory deleted or moved
- Corruption from unexpected interruption

**Solutions:**

**Option 1: Verify backup integrity**
```bash
# Check backup size
du -sh workspace.backup.*

# Verify critical files exist
ls -la workspace.backup.*/project.yaml

# List all backup files
find workspace.backup.* -type f | head -20
```

**Option 2: Manual restoration**
```bash
# If automatic restoration fails
# 1. Clear current directory
cd ..
rm -rf my_project

# 2. Copy from backup
cp -r my_project.backup my_project

# 3. Verify restoration
cd my_project
ls -la
```

**Option 3: Partial restoration**
```bash
# If backup is incomplete, restore what you can
# Copy data files
cp -r workspace.backup.*/01_projects/* ./01_projects/

# Copy admin files
cp -r workspace.backup.*/00_admin/* ./00_admin/

# Restore project.yaml
cp workspace.backup.*/project.yaml ./
```

---

### Update Process Issues

#### Issue: Update appears to hang

**Symptoms:**
```
# Update command started but no output for > 30 seconds
dirforge update
# (no response)
```

**Root Cause:**
- Very large workspace (1000+ projects)
- Slow filesystem (network drive, USB)
- Memory constraints
- I/O bottleneck

**Solutions:**

**Option 1: Check what's happening**
```bash
# In another terminal, monitor the process
ps aux | grep dirforge

# Check disk I/O
iotop

# Check memory usage
top
```

**Option 2: Let it finish (with timeout)**
```bash
# Set a timeout of 30 seconds
timeout 30 dirforge update

# If it timeout, try with --dry-run first
dirforge update --dry-run --json
```

**Option 3: Test on smaller subset**
```bash
# Try updating a single project first
cd 00_admin  # or first subdirectory
dirforge update --dry-run

# Then try full update
cd ..
dirforge update --dry-run
```

**Option 4: Use JSON output (faster)**
```bash
# JSON mode has minimal formatting overhead
dirforge update --json --dry-run

# Redirect to file to see progress
dirforge update --json > update.log 2>&1 &
tail -f update.log
```

---

#### Issue: Update failed mid-operation

**Symptoms:**
```
ERROR: Partial update - some directories were created
.integrity/ may be incomplete
Run again to complete or use --dry-run to check
```

**Root Cause:**
- Network interruption
- Out of disk space mid-update
- Process killed during execution
- Permissions revoked mid-operation

**Solutions:**

**Option 1: Check what was created**
```bash
# See what's in .integrity/
ls -la .integrity/

# Check if critical files exist
ls -la .integrity/project.yaml
```

**Option 2: Complete the partial update**
```bash
# Restore from backup first
cp -r workspace.backup.*/* .

# Try update again
dirforge update --dry-run

# If successful, apply
dirforge update
```

**Option 3: Clean and retry**
```bash
# Remove incomplete .integrity/
rm -rf .integrity/

# Retry the update
dirforge update --dry-run
```

---

### Performance Issues

#### Issue: Update is too slow

**Symptoms:**
```
# Update taking > 5 seconds
# For small workspace this is abnormal

time dirforge update --dry-run
# real    0m12.345s    # Should be < 1s for small workspaces
```

**Root Cause:**
- Very large workspace (100+ projects)
- Slow disk (network drive, USB)
- Many subdirectories (deep nesting)
- File permission checks taking time

**Solutions:**

**Option 1: Use --json flag (faster parsing)**
```bash
# JSON mode is faster than text output
time dirforge update --dry-run --json
# Should be notably faster
```

**Option 2: Profile the operation**
```bash
# Run with bash debugging
bash -x $(which dirforge) update --dry-run 2>&1 | tail -100

# Look for slowest operations:
# - find commands
# - grep operations
# - external tool calls
```

**Option 3: Check filesystem performance**
```bash
# Test disk speed
time dd if=/dev/zero of=testfile bs=1M count=100
rm testfile

# Check if on network drive
mount | grep "$(pwd)"

# Check directory size
find . -type d | wc -l  # Number of directories
find . -type f | wc -l  # Number of files
```

**Option 4: Reduce update scope**
```bash
# Update individual projects instead of all at once
cd project1 && dirforge update
cd ../project2 && dirforge update

# Or update workspace level only
dirforge update --here  # Only current directory
```

---

### Validation Issues

#### Issue: "Structure validation failed"

**Symptoms:**
```
ERROR: Structure validation failed
Expected files/dirs missing:
- .integrity/
- .integrity/project.yaml
- .integrity/checksums/
```

**Root Cause:**
- Update created incomplete structure
- Files deleted after update
- Permissions prevent reading created files
- Disk full during structure verification

**Solutions:**

**Option 1: Re-run update**
```bash
# Sometimes trying again completes the operation
dirforge update

# With more output
dirforge update 2>&1 | tee update.log
```

**Option 2: Verify what exists**
```bash
# Check each critical component
[[ -d .integrity ]] && echo "✓ .integrity exists"
[[ -f .integrity/project.yaml ]] && echo "✓ project.yaml exists"
[[ -d .integrity/checksums ]] && echo "✓ checksums/ exists"

# List what's actually there
find .integrity -type f -o -type d | sort
```

**Option 3: Manually create missing pieces**
```bash
# If only some parts are missing
mkdir -p .integrity/checksums
mkdir -p .integrity/manifests

# Restore project.yaml if missing
if [[ ! -f .integrity/project.yaml ]]; then
  cp project.yaml .integrity/project.yaml
fi

# Run validation again
dirforge update --dry-run
```

---

### Flag & Parameter Issues

#### Issue: --force flag doesn't override detection

**Symptoms:**
```
# Even with --force, shows detection failure
dirforge update --force --dry-run
ERROR: Could not detect version
```

**Root Cause:**
- Flag passed after command name
- Global FORCE variable not passed through
- Flag order matters

**Solutions:**

**Option 1: Try flag before command**
```bash
# May not work depending on command structure
dirforge --force update --dry-run
```

**Option 2: Create project.yaml first**
```bash
# --force still needs some basic metadata
cat > project.yaml << 'EOF'
world_type: RESEARCH_WORLD
version: 1.0.20
EOF

dirforge update --force --dry-run
```

**Option 3: Export FORCE variable**
```bash
# Explicitly set the environment variable
export FORCE=true
dirforge update --dry-run

unset FORCE
```

---

#### Issue: --dry-run and --json together show different results

**Symptoms:**
```
# Text output says:
dirforge update --dry-run
"Changes: 3 items to add"

# JSON output says:
dirforge update --dry-run --json | jq '.changes | length'
5
```

**Root Cause:**
- Different formatting in text vs. JSON
- Text output counts directories as single items
- JSON lists individual files

**Solutions:**

**Option 1: Use JSON for accurate counts**
```bash
# JSON is more precise
dirforge update --dry-run --json | jq '.changes'

# Verify count
dirforge update --dry-run --json | jq '.changes | length'
```

**Option 2: Compare outputs**
```bash
# Save both for comparison
dirforge update --dry-run > text_output.txt
dirforge update --dry-run --json > json_output.json

# Review differences
diff -u text_output.txt json_output.json | head -50
```

---

### Help System Issues

#### Issue: --help shows nothing or is truncated

**Symptoms:**
```
dirforge update --help
# No output, or only partial help
```

**Root Cause:**
- Help system not loaded
- Terminal too narrow (text wrapping issues)
- Pager issue (more/less not available)

**Solutions:**

**Option 1: Check without pager**
```bash
# Force no pager
dirforge update --help | cat

# Or directly read help file
grep -A 100 "update command" /path/to/help.sh
```

**Option 2: Widen terminal**
```bash
# Resize terminal to 120+ columns
# Help text is formatted for 100+ column width

# Or use JSON output which has no formatting
dirforge update --dry-run --json | jq '.help_text' 2>/dev/null || echo "Help in JSON not available"
```

**Option 3: Check help file directly**
```bash
# Help system is in lib/help.sh
grep -B 5 -A 50 "show_update_command_help" lib/help.sh
```

---

## Quick Reference: Solution Matrix

| Issue | Quick Fix | Next Step |
|-------|-----------|-----------|
| Unknown version | Create project.yaml | Set version: 1.0.20 |
| Unknown world type | Use --force flag | Or mkdir 00_admin |
| Permission denied | chmod u+w . | Check filesystem |
| Backup exists | Remove old backup | Or use different location |
| Update hangs | Check with ps aux | Try --json flag |
| Too slow | Use --json | Profile with bash -x |
| Validation fails | Re-run update | Check disk space |
| --force ineffective | Create project.yaml | Or use export FORCE=true |

---

## Getting Additional Help

**Built-in Help:**
```bash
dirforge update --help

# Or for the whole dirforge system
dirforge --help
```

**Debug Mode:**
```bash
# Run with bash debugging
bash -x $(which dirforge) update --dry-run 2>&1 | head -100

# This shows:
# - All variable assignments
# - Function calls
# - Conditional branches taken
```

**Test Files (for examples):**
```bash
# Located in tests/ directory
tests/test_update_force_override.sh      # --force flag examples
tests/test_update_help_integration.sh    # Help system examples
tests/test_update_performance.sh         # Performance test cases
tests/test_update_dry_run_backup.sh      # Backup/dry-run examples
```

**Report Issues:**
Create a test case showing:
1. Directory structure
2. Current project.yaml content
3. Command executed
4. Full error output
5. Terminal environment (bash version, OS)

---

**Last Updated:** 2025-12-22  
**Guide Version:** 1.0  
**Covers:** dirforge update command v1.0.22
