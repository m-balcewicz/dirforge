# Version Management

This document explains how to update version numbers throughout the DirForge repository.

## Quick Start

To update all version references:

```bash
./scripts/update-versions.sh <new-version>
```

Example:
```bash
./scripts/update-versions.sh 1.2.0
```

## Features

- Auto-detect: Automatically finds current version in all files
- Dry-run mode: Preview changes without modifying files (--dry-run)
- Simple confirmation: One-time prompt before updating
- Skip confirmation: Automatically update with -y flag

## Usage Examples

### Preview Changes
```bash
./scripts/update-versions.sh --dry-run 1.2.0
```

### Update Without Confirmation (CI/CD)
```bash
./scripts/update-versions.sh -y 1.2.0
```

### Standard Interactive Update
```bash
./scripts/update-versions.sh 1.2.0
```

## What Gets Updated

The script updates version references in:

- dirforge.sh - Main VERSION variable
- All YAML files (excluding .specify/)
- All Markdown files (excluding .specify/)

## Files Updated

The script automatically detects and updates version references in:

1. dirforge.sh - Main version constant
2. world-configs/*.yaml - World configuration files
3. README.md - Project documentation
4. CHANGELOG.md - Version history
5. All other .md and .yaml files

## Notes

- Creates backup files with .bak extension before updating
- Skips the .specify/ directory (contains configuration)
- Excludes node_modules/ directories
- Version format: X.Y.Z (e.g., 1.2.0)

## Current Version

Run ./scripts/update-versions.sh --dry-run <version> to see what would be updated.
