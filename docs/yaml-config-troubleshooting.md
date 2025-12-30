# YAML Configuration System — Troubleshooting Guide

**Version:** 1.0.22  
**Last Updated:** 2025-12-30

---

## Table of Contents

1. [Quick Diagnostics](#quick-diagnostics)
2. [Validation Errors](#validation-errors)
3. [File and Path Issues](#file-and-path-issues)
4. [Permission Problems](#permission-problems)
5. [Initialization Failures](#initialization-failures)
6. [Variable Expansion Issues](#variable-expansion-issues)
7. [Performance Problems](#performance-problems)
8. [Metadata Issues](#metadata-issues)
9. [Debugging Tools](#debugging-tools)
10. [Getting Help](#getting-help)

---

## Quick Diagnostics

### Diagnostic Checklist

```bash
# 1. Check dirforge installation
which dirforge

# 2. Check repository structure
ls templates/world-configs/

# 3. Validate a config
dirforge validate-config templates/world-configs/coding.world.yaml

# 4. List available configs
dirforge list-configs

# 5. Check permissions on repo
ls -ld templates/
ls -ld templates/world-configs/

# 6. Check disk space
df -h

# 7. Check system resources
free -h
```

### Enable Debug Mode

```bash
# Set debug environment variable
export DEBUG_YAML_CONFIG=1

# Run command with debug output
dirforge init CODING_WORLD

# Disable when done
unset DEBUG_YAML_CONFIG
```

---

## Validation Errors

### Error: "Config validation failed"

**Message:**
```
✗ Config validation failed
  Schema check: Missing required field
```

**Cause:** Configuration file missing required fields

**Solution:**
```bash
# 1. Check which field is missing
dirforge validate-config config.yaml

# 2. Look at working example
cat templates/world-configs/coding.world.yaml | head -20

# 3. Add missing field:
# Must have:
# - world.type
# - world.description  
# - metadata.version
# - metadata.constitution_version
# - metadata.created_by
# - metadata.created_at
# - parent_directories (at least one)

# 4. Validate again
dirforge validate-config config.yaml
```

### Error: "Invalid YAML syntax"

**Message:**
```
YAML parse error at line 5: mapping values are not allowed here
```

**Cause:** YAML indentation or syntax error

**Solution:**
```bash
# 1. Check indentation (must be 2 spaces, no tabs)
cat -A config.yaml | head -20

# 2. Validate YAML syntax
python3 -c "import yaml; yaml.safe_load(open('config.yaml'))"

# 3. Common issues:
# - Tabs instead of spaces
# - Inconsistent indentation
# - Missing quotes around strings with special chars
# - Colons in values need quotes

# Example fix:
# BAD:  key: value: with: colons
# GOOD: key: "value: with: colons"

# 4. Revalidate
dirforge validate-config config.yaml
```

### Error: "Schema validation failed"

**Message:**
```
Schema validation failed
  - world.type: Not in allowed values (CODING_WORLD, RESEARCH_WORLD, ...)
  - metadata.version: Must match pattern ^\d+\.\d+\.\d+$
```

**Cause:** Field value doesn't match schema requirements

**Solution:**
```bash
# 1. Check world.type
# Must be one of:
# - CODING_WORLD
# - RESEARCH_WORLD
# - JOURNAL_WORLD
# - LECTURE_WORLD
# - OFFICE_WORLD
# - PRIVATE_WORLD
# - LITERATURE_WORLD

# 2. Check metadata.version
# Must be in format: X.Y.Z (semver)
# Valid: 1.0.0, 2.1.3
# Invalid: 1, 1.0, v1.0.0

# 3. Check constitution_version
# Must be 1.0.22 for current system

# 4. Fix and revalidate
dirforge validate-config config.yaml
```

### Error: "Field type mismatch"

**Message:**
```
Field 'parent_directories' must be object, got string
```

**Cause:** Wrong data type for field

**Solution:**
```bash
# Check schema documentation
cat templates/world-configs/SCHEMA.md

# parent_directories must be an object (dictionary):
# BAD:
# parent_directories: "projects,resources"

# GOOD:
# parent_directories:
#   projects:
#     description: "My projects"
#   resources:
#     description: "My resources"

# Revalidate
dirforge validate-config config.yaml
```

---

## File and Path Issues

### Error: "Config file not found"

**Message:**
```
Config file not found: templates/world-configs/coding.world.yaml
```

**Cause:** File doesn't exist or path is wrong

**Solution:**
```bash
# 1. Check file exists
ls templates/world-configs/coding.world.yaml

# 2. List available configs
ls templates/world-configs/

# 3. Use correct path
# If in repo root:
dirforge validate-config templates/world-configs/coding.world.yaml

# If in subdirectory:
dirforge validate-config ../../templates/world-configs/coding.world.yaml

# Or use absolute path:
dirforge validate-config $(pwd)/templates/world-configs/coding.world.yaml

# 4. Try list-configs
dirforge list-configs
```

### Error: "No such file or directory"

**Message:**
```
bash: line 10: templates/world-configs/coding.world.yaml: No such file or directory
```

**Cause:** Working directory is wrong or relative path is incorrect

**Solution:**
```bash
# 1. Check current directory
pwd

# 2. Check if repo structure exists
ls templates/

# 3. Navigate to repo root
cd /Users/martin/Documents/CODING_WORLD/bash/dirforge

# 4. Then run command
dirforge init CODING_WORLD

# 5. Or use absolute paths
dirforge init --config /Users/martin/Documents/CODING_WORLD/bash/dirforge/templates/world-configs/coding.world.yaml
```

### Error: "DIRFORGE_CONFIG_PATH not set"

**Message:**
```
Config path environment variable not set
```

**Cause:** Custom config location not specified

**Solution:**
```bash
# Option 1: Use explicit --config flag
dirforge init --config ~/custom.world.yaml

# Option 2: Set environment variable
export DIRFORGE_CONFIG_PATH=~/custom.world.yaml
dirforge init CODING_WORLD

# Option 3: Use standard location
# Templates are auto-discovered in templates/world-configs/
dirforge init CODING_WORLD
```

---

## Permission Problems

### Error: "Permission denied" on Config Read

**Message:**
```
Config file: Permission denied (read)
```

**Cause:** Config file not readable

**Solution:**
```bash
# 1. Check file permissions
ls -l templates/world-configs/coding.world.yaml

# 2. Make readable
chmod 644 templates/world-configs/coding.world.yaml

# 3. Verify
ls -l templates/world-configs/coding.world.yaml

# 4. Retry command
dirforge validate-config templates/world-configs/coding.world.yaml
```

### Error: "Permission denied" on Directory Creation

**Message:**
```
Cannot create directory: Permission denied
```

**Cause:** No write permission in target directory

**Solution:**
```bash
# 1. Check target directory permissions
ls -ld ~/coding_workspace/

# 2. Check if directory exists
[ -d ~/coding_workspace/ ] && echo "exists" || echo "not found"

# 3. Fix permissions
# If you own it:
chmod 755 ~/coding_workspace/

# If you don't own it:
sudo chown $USER ~/coding_workspace/
chmod 755 ~/coding_workspace/

# 4. Or create in different location
dirforge init CODING_WORLD ~/myworkspace

# 5. Check parent directory
ls -ld ~
ls -ld ~/coding_workspace
```

### Error: ".integrity/ files read-only"

**Message:**
```
Cannot modify .integrity/workspace.yaml: Permission denied
```

**Cause:** .integrity/ directories are protected (600 permissions)

**Solution:**
```bash
# 1. Understand: .integrity/ is intentionally read-only
# This protects metadata from accidental modification

# 2. To view metadata:
cat ~/coding_workspace/.integrity/workspace.yaml

# 3. To view all metadata:
find ~/coding_workspace -name ".integrity" -type d -exec ls -la {} \;

# 4. To modify only if absolutely necessary:
# WARNING: This breaks metadata integrity!
sudo chmod 644 ~/coding_workspace/.integrity/workspace.yaml
# ... make changes ...
sudo chmod 600 ~/coding_workspace/.integrity/workspace.yaml

# 5. Or recreate with new config:
rm -rf ~/coding_workspace
dirforge init CODING_WORLD
```

---

## Initialization Failures

### Error: "Scaffold generation failed"

**Message:**
```
Scaffold generation failed at step 3/7
Unable to create directory: coding/python
```

**Cause:** Configuration is invalid or filesystem issue

**Solution:**
```bash
# 1. Validate config first
dirforge validate-config config.yaml

# 2. Check disk space
df -h

# 3. Check if workspace exists
[ -d ~/coding_workspace ] && echo "exists" || echo "not found"

# 4. Clean up partial creation
rm -rf ~/coding_workspace

# 5. Retry initialization
dirforge init CODING_WORLD

# 6. Check if creation succeeded
ls -la ~/coding_workspace/
```

### Error: "Partial scaffold created, transaction rolled back"

**Message:**
```
Error during scaffold generation
Transaction rolled back automatically
Workspace cleaned up
```

**Cause:** Error occurred during creation, automatic rollback triggered

**Solution:**
```bash
# 1. This is expected behavior! 
# The system automatically cleans up on error

# 2. Verify clean state
ls ~/coding_workspace/
# Should be empty or non-existent

# 3. Check what went wrong (enable debug)
DEBUG_YAML_CONFIG=1 dirforge init CODING_WORLD

# 4. Fix the issue
# (Check disk space, permissions, config validity)

# 5. Retry
dirforge init CODING_WORLD
```

### Error: "Multiple workspace versions detected"

**Message:**
```
Workspace contains multiple incompatible metadata versions
```

**Cause:** Workspace created with different config format

**Solution:**
```bash
# 1. Check metadata
cat ~/coding_workspace/.integrity/workspace.yaml | grep constitution_version

# 2. If old version (< 1.0.22):
# Must upgrade, see migration guide
# docs/migration-to-yaml-configs.md

# 3. If mixed versions:
# Backup and recreate
cp -r ~/coding_workspace ~/coding_workspace.backup
rm -rf ~/coding_workspace
dirforge init CODING_WORLD

# 4. Migrate data from backup if needed
cp -r ~/coding_workspace.backup/python/* ~/coding_workspace/python/
```

---

## Variable Expansion Issues

### Error: "${USER} not expanded"

**Message:**
```
created_by: "${USER}"  # Should be your username
```

**Cause:** Variable expansion not working

**Solution:**
```bash
# 1. Check if variable is set
echo $USER

# 2. Supported variables:
# - ${USER}     → current user
# - ${DATE}     → ISO 8601 UTC timestamp
# - ${...}      → any other is an error

# 3. For custom variables, modify config:
# Instead of: ${MYVAR}
# Use: hardcoded value or script

# 4. Check variable syntax
# Must be: ${VARIABLE_NAME}
# Not: $VARIABLE_NAME or {$VARIABLE_NAME}

# 5. Validate config
dirforge validate-config config.yaml
```

### Error: "Date format invalid"

**Message:**
```
created_at: invalid date format
```

**Cause:** ${DATE} not properly formatted

**Solution:**
```bash
# 1. ${DATE} is automatically formatted
# You don't need to format it manually

# 2. Valid usage:
# created_at: "${DATE}"

# 3. Result is ISO 8601 UTC:
# 2025-12-30T21:35:00Z

# 4. Don't add extra formatting:
# BAD: "${DATE}" formatted as "%Y-%m-%d"
# GOOD: "${DATE}"

# 5. Validate
dirforge validate-config config.yaml
```

### Error: "Escaped variables in output"

**Message:**
```
created_by: "${USER}"  # Literal string, not expanded
```

**Cause:** Variable needs escaping or was in quotes

**Solution:**
```bash
# 1. Check YAML escaping
# These need quotes if they contain special chars:
created_by: "${USER}"    # GOOD - will expand
created_at: "${DATE}"    # GOOD - will expand

# 2. To use literal ${USER}:
created_by: "\${USER}"   # Escapes the variable
# Result: ${USER} (literal)

# 3. Or use different syntax
created_by: "john.doe"   # Hardcoded

# 4. Validate and check result
dirforge validate-config config.yaml
cat config.yaml | grep created_by
```

---

## Performance Problems

### Issue: "Initialization very slow"

**Symptom:** `dirforge init` takes >5 seconds

**Solution:**
```bash
# 1. Check system resources
free -h      # Check memory
df -h        # Check disk I/O
ps aux       # Check other processes

# 2. Check config size
wc -l templates/world-configs/coding.world.yaml

# 3. Check if caching is enabled
echo $DIRFORGE_CACHE_DISABLE
# Should be empty (caching enabled)

# 4. Verify fast path
# First init: ~1-2 seconds (cache building)
# Second init: ~0.5 seconds (from cache)

# 5. If consistently slow:
# - Check disk health: diskutil info /
# - Check for background processes
# - Try on different machine if possible
```

### Issue: "Config validation takes too long"

**Symptom:** `dirforge validate-config` >2 seconds

**Solution:**
```bash
# 1. Schema validation targets:
# - Small configs (<1 MB): <500ms
# - Large configs (<10 MB): <2s

# 2. Check file size
ls -lh templates/world-configs/coding.world.yaml

# 3. Check for large YAML in config
grep -c "description:" config.yaml
# Large number of entries can slow validation

# 4. Disable heavy validation if needed
# (Not recommended, but possible)
# Set: DIRFORGE_VALIDATE_SKIP_EXPENSIVE=1

# 5. Consider splitting large configs
# Create separate files for different world types
```

### Issue: "Memory usage high"

**Symptom:** dirforge uses significant memory

**Solution:**
```bash
# 1. Check memory usage
ps aux | grep dirforge

# 2. Large configs use more memory
# Check config size
du -h templates/world-configs/

# 3. Clear cache if it grows too large
# (Cache auto-expires after 30 minutes)
rm -rf ~/.dirforge/cache/

# 4. If memory still high:
# May indicate memory leak - report issue
# For now, restart shell session
exec zsh
```

---

## Metadata Issues

### Issue: "Metadata corrupted"

**Symptom:** Metadata files unreadable or invalid

**Solution:**
```bash
# 1. Check metadata
cat ~/coding_workspace/.integrity/workspace.yaml

# 2. If unreadable, try recovery
# Metadata is read-only, so corruption is rare

# 3. To recreate workspace:
rm -rf ~/coding_workspace
dirforge init CODING_WORLD

# 4. Restore data from backups
cp -r ~/backup/coding_workspace/* ~/coding_workspace/
# (Don't copy .integrity/ - it will be wrong)
```

### Issue: "Metadata timestamps wrong"

**Symptom:** Created timestamps don't match actual creation

**Cause:** System clock was wrong when workspace created

**Solution:**
```bash
# 1. Check timestamp
cat ~/coding_workspace/.integrity/workspace.yaml | grep created_at

# 2. This is informational only
# Doesn't affect functionality

# 3. To fix timestamp:
# Must recreate workspace
rm -rf ~/coding_workspace
# Fix system clock if needed
date  # Check current date
dirforge init CODING_WORLD
```

### Issue: "Workspace UUID is duplicated"

**Symptom:** Multiple workspaces with same ID

**Cause:** Bug or manual creation

**Solution:**
```bash
# 1. This shouldn't happen (IDs are unique)
# If found, indicates problem

# 2. Workaround: recreate one workspace
rm -rf ~/second_workspace
dirforge init CODING_WORLD ~/second_workspace

# 3. Report as bug if reproducible
```

---

## Debugging Tools

### Enable Verbose Output

```bash
# 1. Debug environment variable
export DEBUG_YAML_CONFIG=1

# 2. Run command (will show detailed output)
dirforge init CODING_WORLD

# 3. Capture output
dirforge init CODING_WORLD 2>&1 | tee /tmp/dirforge-debug.log

# 4. Disable when done
unset DEBUG_YAML_CONFIG
```

### Manual Validation Script

```bash
#!/bin/bash
# Manual validation of config file

CONFIG="${1:?Config file required}"

echo "=== Diagnostic Report for $CONFIG ==="
echo

echo "1. File exists:"
[ -f "$CONFIG" ] && echo "   ✓ File exists" || echo "   ✗ File not found"
echo

echo "2. File readable:"
[ -r "$CONFIG" ] && echo "   ✓ Readable" || echo "   ✗ Not readable"
echo

echo "3. File size:"
ls -lh "$CONFIG" | awk '{print "   " $5}'
echo

echo "4. First 20 lines:"
head -20 "$CONFIG" | sed 's/^/   /'
echo

echo "5. YAML valid:"
python3 -c "import yaml; yaml.safe_load(open('$CONFIG'))" 2>&1 | sed 's/^/   /'
echo

echo "6. Formal validation:"
dirforge validate-config "$CONFIG"
```

### Check System Configuration

```bash
# Check environment
env | grep -i dirforge

# Check installed tools
which dirforge
which python3
which bash

# Check versions
dirforge --version 2>/dev/null || echo "dirforge version unknown"
python3 --version
bash --version | head -1
```

---

## Getting Help

### Where to Find Answers

1. **Quick Help**
   ```bash
   dirforge --help
   dirforge init --help
   dirforge validate-config --help
   ```

2. **Documentation Files**
   - **Quick Start:** `docs/yaml-config-user-guide.md`
   - **API Reference:** `docs/yaml-parsing-api.md`
   - **System Design:** `docs/010-yaml-configuration-system.md`
   - **Schema Details:** `templates/world-configs/SCHEMA.md`

3. **Configuration Examples**
   ```bash
   # View working examples
   ls templates/world-configs/
   cat templates/world-configs/coding.world.yaml
   ```

4. **Check Logs**
   ```bash
   # Enable debug mode
   DEBUG_YAML_CONFIG=1 dirforge init 2>&1 | tee debug.log
   
   # Examine log
   cat debug.log
   ```

5. **Test with Sample Config**
   ```bash
   # Try a known-working config
   dirforge validate-config templates/world-configs/coding.world.yaml
   dirforge init CODING_WORLD ~/test_workspace
   ```

### Reporting Issues

When reporting problems, include:

1. **What you did:**
   ```bash
   dirforge init CODING_WORLD
   ```

2. **What you expected:**
   ```
   Workspace created at ~/coding_workspace
   ```

3. **What happened instead:**
   ```
   Error: Permission denied
   ```

4. **Debug output:**
   ```bash
   DEBUG_YAML_CONFIG=1 dirforge init CODING_WORLD 2>&1
   ```

5. **System information:**
   ```bash
   # Collect diagnostics
   echo "=== System ===" && uname -a
   echo "=== Shell ===" && bash --version | head -1
   echo "=== Dirforge ===" && which dirforge
   echo "=== Environment ===" && env | grep -i dirforge
   ```

---

**Document:** yaml-config-troubleshooting.md  
**Created:** 2025-12-30  
**Status:** Complete  
**Sections:** 10 major trouble areas covered  
**Target Audience:** Users debugging configuration issues
