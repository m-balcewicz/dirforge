# Backup a directory to a timestamped path
dirforge_backup() {
  local src_dir="$1"
  
  # Validate source directory exists
  if [[ ! -d "$src_dir" ]]; then
    echo "Error: Source directory '$src_dir' does not exist" >&2
    return 1
  fi
  
  local ts
  ts=$(date +%Y%m%d-%H%M%S)
  local backup_path="${src_dir%/}_backup_$ts"
  
  # Create backup
  if cp -a "$src_dir" "$backup_path"; then
    echo "$backup_path"
    return 0
  else
    echo "Error: Failed to create backup" >&2
    return 1
  fi
}

# Restore a directory from a backup path (overwrites target)
dirforge_restore() {
  local backup_path="$1"
  local target_dir="$2"
  
  # Validate backup exists
  if [[ ! -d "$backup_path" ]]; then
    echo "Error: Backup directory '$backup_path' does not exist" >&2
    return 1
  fi
  
  # Convert to absolute paths to avoid confusion
  backup_path=$(cd "$backup_path" && pwd)
  target_dir=$(cd "$target_dir" && pwd)
  
  # Create target directory if it doesn't exist
  if [[ ! -d "$target_dir" ]]; then
    mkdir -p "$target_dir" || {
      echo "Error: Failed to create target directory '$target_dir'" >&2
      return 1
    }
  fi
  
  # Clear the target directory safely, excluding backup directories
  find "$target_dir" -mindepth 1 -maxdepth 1 \
    -not -path "*_backup_*" \
    -exec rm -rf {} + 2>/dev/null || true
  
  # Copy backup contents to target location using absolute paths
  (cd "$backup_path" && cp -a ./* "$target_dir"/ 2>/dev/null || true)
  (cd "$backup_path" && cp -a ./.[^.]* "$target_dir"/ 2>/dev/null || true)
  
  return 0
}
#!/usr/bin/env bash
# lib/migrate.sh
# Migration step engine for dirforge update with .integrity system support (v1.0.22)

# Adds missing directories/files for a given world type and version
# Usage: migrate_additive <target_dir> <world_type> <from_version> <to_version> <dry_run>
migrate_additive() {
  local dir="$1"
  local world="$2"
  local from_ver="$3"
  local to_ver="$4"
  local dry_run="$5"
  
  # Initialize changes array
  local changes
  changes=()

  # JOURNAL_WORLD migrations
  # v1.0.20 -> v1.0.21 (add role directories)
  if [[ "$world" == "JOURNAL_WORLD" && "$from_ver" == "1.0.20" ]]; then
    for role in 00_admin 01_primary_authorship 02_coauthor_invites 03_journal_service; do
      if [[ ! -d "$dir/$role" ]]; then
        changes+=("ADD $role/")
        if [[ "$dry_run" != "1" ]]; then
          mkdir -p "$dir/$role"
        fi
      fi
    done
  fi
  
  # v1.0.21 -> v1.0.22 (add .integrity structure)
  if [[ "$world" == "JOURNAL_WORLD" && "$from_ver" == "1.0.21" && "$to_ver" == "1.0.22" ]]; then
    if [[ "$dry_run" != "1" ]]; then
      mkdir -p "$dir/.integrity/checksums" "$dir/.integrity/manifests"
    fi
    changes+=("ADD .integrity/")
    changes+=("ADD .integrity/checksums/")
    changes+=("ADD .integrity/manifests/")
  fi

  # RESEARCH_WORLD migrations
  # v1.0.16 -> v1.0.17+ (add 02_studies/)
  if [[ "$world" == "RESEARCH_WORLD" && "$from_ver" == "1.0.16" ]]; then
    if [[ ! -d "$dir/02_studies" ]]; then
      changes+=("ADD 02_studies/")
      if [[ "$dry_run" != "1" ]]; then
        mkdir -p "$dir/02_studies"
      fi
    fi
  fi
  
  # v1.0.17 -> v1.0.22 (add .integrity structure and 05_supervision/ with subdirectories)
  if [[ "$world" == "RESEARCH_WORLD" && "$from_ver" == "1.0.17" && "$to_ver" == "1.0.22" ]]; then
    if [[ "$dry_run" != "1" ]]; then
      mkdir -p "$dir/.integrity/checksums" "$dir/.integrity/manifests"
      # Add 05_supervision/ with subdirectories if project management exists
      if [[ -d "$dir/01_project_management" && ! -d "$dir/01_project_management/05_supervision" ]]; then
        mkdir -p "$dir/01_project_management/05_supervision/BSc_Thesis"
        mkdir -p "$dir/01_project_management/05_supervision/MSc_Thesis"
        mkdir -p "$dir/01_project_management/05_supervision/PhD_Supervision"
      fi
    fi
    changes+=("ADD .integrity/")
    changes+=("ADD .integrity/checksums/")
    changes+=("ADD .integrity/manifests/")
    if [[ -d "$dir/01_project_management" && ! -d "$dir/01_project_management/05_supervision" ]]; then
      changes+=("ADD 01_project_management/05_supervision/BSc_Thesis/")
      changes+=("ADD 01_project_management/05_supervision/MSc_Thesis/")
      changes+=("ADD 01_project_management/05_supervision/PhD_Supervision/")
    fi
  fi

  # OFFICE_WORLD v1.0.10 -> v1.0.11+ (add 05_meetings/)
  if [[ "$world" == "OFFICE_WORLD" && "$from_ver" == "1.0.10" ]]; then
    if [[ ! -d "$dir/05_meetings" ]]; then
      changes+=("ADD 05_meetings/")
      if [[ "$dry_run" != "1" ]]; then
        mkdir -p "$dir/05_meetings"
      fi
    fi
  fi
  
  # v1.0.11 -> v1.0.22 (add .integrity structure)
  if [[ "$world" == "OFFICE_WORLD" && "$from_ver" == "1.0.11" && "$to_ver" == "1.0.22" ]]; then
    if [[ "$dry_run" != "1" ]]; then
      mkdir -p "$dir/.integrity/checksums" "$dir/.integrity/manifests"
    fi
    changes+=("ADD .integrity/")
    changes+=("ADD .integrity/checksums/")
    changes+=("ADD .integrity/manifests/")
  fi

  # Generic .integrity structure for any world type upgrading to v1.0.22
  if [[ "$to_ver" == "1.0.22" && ! -d "$dir/.integrity" ]]; then
    if [[ "$dry_run" != "1" ]]; then
      mkdir -p "$dir/.integrity/checksums" "$dir/.integrity/manifests"
    fi
    if ! echo "${changes[@]:-}" | grep -q "ADD .integrity"; then
      changes+=("ADD .integrity/")
      changes+=("ADD .integrity/checksums/")
      changes+=("ADD .integrity/manifests/")
    fi
  fi

  # RESEARCH_WORLD v1.0.22 additive: ensure 05_supervision/ with subdirectories exists (for non-v1.0.17 migrations)
  if [[ "$world" == "RESEARCH_WORLD" && "$to_ver" == "1.0.22" ]]; then
    # Skip if already running as part of v1.0.17 migration above
    if [[ "$from_ver" != "1.0.17" ]] && [[ -d "$dir/01_project_management" && ! -d "$dir/01_project_management/05_supervision" ]]; then
      if [[ "$dry_run" != "1" ]]; then
        mkdir -p "$dir/01_project_management/05_supervision/BSc_Thesis"
        mkdir -p "$dir/01_project_management/05_supervision/MSc_Thesis"
        mkdir -p "$dir/01_project_management/05_supervision/PhD_Supervision"
      fi
      changes+=("ADD 01_project_management/05_supervision/BSc_Thesis/")
      changes+=("ADD 01_project_management/05_supervision/MSc_Thesis/")
      changes+=("ADD 01_project_management/05_supervision/PhD_Supervision/")
    fi
  fi

  # Workspace-level updates (multi-world entity)
  if [[ "$world" == "workspace" && "$to_ver" == "1.0.22" ]]; then
    # Create workspace metadata if it doesn't exist
    if [[ ! -f "$dir/.integrity/workspace.yaml" ]]; then
      if [[ "$dry_run" != "1" ]]; then
        mkdir -p "$dir/.integrity/checksums" "$dir/.integrity/manifests"
        cat > "$dir/.integrity/workspace.yaml" << EOF
workspace: "true"
version: "$to_ver"
created: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
updated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
EOF
      fi
      changes+=("ADD .integrity/workspace.yaml")
    fi
  fi

  # Output summary
  if [[ ${#changes[@]} -gt 0 ]]; then
    for c in "${changes[@]}"; do
      echo "$c"
    done
  fi
  
  return 0
}
