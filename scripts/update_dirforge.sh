#!/usr/bin/env bash
set -euo pipefail

# update_dirforge.sh
# Update the installed dirforge tool and/or apply workspace structure updates
#
# Usage:
#   ./scripts/update_dirforge.sh                  # interactive: preview then prompt per WORLD
#   ./scripts/update_dirforge.sh --dry-run         # preview only, no changes
#   ./scripts/update_dirforge.sh --force           # apply all without prompting
#   ./scripts/update_dirforge.sh --tool-only       # update installed tool only
#   ./scripts/update_dirforge.sh --workspace-only  # update workspace structures only
#   ./scripts/update_dirforge.sh --backup          # create backups before applying changes
#   ./scripts/update_dirforge.sh --bootstrap        # stamp current template_version on all projects (no structural changes)
#   ./scripts/update_dirforge.sh --help            # show this help
#
# Environment:
#   DIRFORGE_WORKSPACE_ROOT   Path containing *_WORLD directories (default: ~/Documents)

# ============================================================================
# CONSTANTS
# ============================================================================

readonly KNOWN_WORLDS=(
    CODING_WORLD
    JOURNAL_WORLD
    LECTURE_WORLD
    LITERATURE_WORLD
    OFFICE_WORLD
    PRIVATE_WORLD
    RESEARCH_WORLD
)

# ============================================================================
# COLOR CODES
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

print_header() {
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC} ${CYAN}                      DirForge Update${NC} ${BLUE}                                       ║${NC}"
    echo -e "${BLUE}║${NC} ${PURPLE}            Update tool installation & workspace structures${NC} ${BLUE}                 ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo
}

print_section() {
    local title="$1"
    echo
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  $title${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_success() {
    echo -e "  ${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "  ${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "  ${RED}✗${NC} $1"
}

print_info() {
    echo -e "  ${BLUE}ℹ${NC} $1"
}

print_item() {
    echo -e "  ${CYAN}→${NC} $1"
}

# Get user confirmation
confirm() {
    local prompt="$1"
    local default="${2:-n}"
    local response

    if [[ "$default" == "y" ]]; then
        echo -ne "  $prompt [Y/n]: "
    else
        echo -ne "  $prompt [y/N]: "
    fi

    if read -r response; then
        response=${response:-$default}
    else
        response="$default"
    fi

    case "$response" in
        [Yy]|[Yy][Ee][Ss]) return 0 ;;
        *) return 1 ;;
    esac
}

# Check if running as root
is_root() {
    [[ $EUID -eq 0 ]]
}

# ============================================================================
# TEMPLATE VERSION HELPERS
# ============================================================================

# Read a template_version for a given world type from the manifest file.
# Arguments: manifest_file, world_type
# Outputs: version string (e.g., "1.0.0") or "unknown"
get_manifest_template_version() {
    local manifest="$1"
    local world_type="$2"

    if [[ ! -f "$manifest" ]]; then
        echo "unknown"
        return 1
    fi

    local in_block=false
    while IFS= read -r line; do
        # Detect world type header (e.g., "  RESEARCH_WORLD:")
        if [[ "$line" =~ ^[[:space:]]+${world_type}:[[:space:]]*$ ]]; then
            in_block=true
            continue
        fi
        if [[ "$in_block" == true ]]; then
            if [[ "$line" =~ ^[[:space:]]+template_version:[[:space:]]+\"?([^\"]+)\"? ]]; then
                echo "${BASH_REMATCH[1]}"
                return 0
            fi
            # Next world type block → stop
            if [[ "$line" =~ ^[[:space:]]{2}[A-Z_]+:[[:space:]]*$ ]]; then
                break
            fi
        fi
    done < "$manifest"

    echo "unknown"
    return 1
}

# Read the config_file name for a given world type from the manifest.
# Arguments: manifest_file, world_type
# Outputs: config filename (e.g., "research.world.yaml")
get_manifest_config_file() {
    local manifest="$1"
    local world_type="$2"

    if [[ ! -f "$manifest" ]]; then
        echo ""
        return 1
    fi

    local in_block=false
    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]+${world_type}:[[:space:]]*$ ]]; then
            in_block=true
            continue
        fi
        if [[ "$in_block" == true ]]; then
            if [[ "$line" =~ ^[[:space:]]+config_file:[[:space:]]+\"?([^\"]+)\"? ]]; then
                echo "${BASH_REMATCH[1]}"
                return 0
            fi
            if [[ "$line" =~ ^[[:space:]]{2}[A-Z_]+:[[:space:]]*$ ]]; then
                break
            fi
        fi
    done < "$manifest"

    echo ""
    return 1
}

# Read the deployed template_version from a WORLD's .integrity/world.yaml.
# Arguments: world_integrity_yaml path
# Outputs: version string or "unknown"
get_deployed_template_version() {
    local yaml_file="$1"

    if [[ ! -f "$yaml_file" ]]; then
        echo "unknown"
        return 0
    fi

    local version
    version=$(grep -E '^\s*template_version:' "$yaml_file" 2>/dev/null \
        | head -n1 \
        | sed 's/.*template_version:[[:space:]]*//' \
        | tr -d '"' \
        | tr -d "'" \
        | tr -d '[:space:]')

    if [[ -n "$version" ]]; then
        echo "$version"
    else
        echo "unknown"
    fi
}

# Check if a version bump is structural (minor or major change).
# Patch-only bumps (e.g., 1.0.0 → 1.0.1) are cosmetic/description only.
# Arguments: old_version, new_version
# Returns: 0 if structural (needs migration), 1 if patch-only or unchanged
is_structural_bump() {
    local old_ver="$1"
    local new_ver="$2"

    if [[ "$old_ver" == "$new_ver" ]]; then
        return 1
    fi

    # If old is unknown, treat as structural
    if [[ "$old_ver" == "unknown" ]]; then
        return 0
    fi

    local IFS='.'
    read -ra old_parts <<< "$old_ver"
    read -ra new_parts <<< "$new_ver"

    local old_major="${old_parts[0]:-0}"
    local old_minor="${old_parts[1]:-0}"
    local new_major="${new_parts[0]:-0}"
    local new_minor="${new_parts[1]:-0}"

    # Major or minor difference → structural
    if (( new_major != old_major || new_minor != old_minor )); then
        return 0
    fi

    # Only patch differs → cosmetic
    return 1
}

# Stamp the template_version into a WORLD's .integrity/world.yaml.
# Arguments: world_integrity_yaml, template_version
stamp_template_version() {
    local yaml_file="$1"
    local version="$2"

    if [[ ! -f "$yaml_file" ]]; then
        return 1
    fi

    if grep -q 'template_version:' "$yaml_file" 2>/dev/null; then
        # Update existing field
        if [[ "$(uname)" == "Darwin" ]]; then
            sed -i '' "s/template_version:.*/template_version: \"$version\"/" "$yaml_file"
        else
            sed -i "s/template_version:.*/template_version: \"$version\"/" "$yaml_file"
        fi
    else
        # Append after schema_version line, or at end
        if grep -q 'schema_version:' "$yaml_file" 2>/dev/null; then
            if [[ "$(uname)" == "Darwin" ]]; then
                sed -i '' "/schema_version:/a\\\
  template_version: \"$version\"\
" "$yaml_file"
            else
                sed -i "/schema_version:/a\\  template_version: \"$version\"" "$yaml_file"
            fi
        else
            echo "  template_version: \"$version\"" >> "$yaml_file"
        fi
    fi
}

# ============================================================================
# TEMPLATE-DRIVEN SCAFFOLD (ADDITIVE ONLY)
# ============================================================================

# Re-read a world config YAML and create any missing directories.
# Existing directories are safely skipped (mkdir -p is idempotent).
# Arguments: config_file, project_path, dry_run
# Outputs: ADD lines for each directory that would be/was created
scaffold_from_template() {
    local config_file="$1"
    local project_path="$2"
    local dry_run="$3"

    if [[ ! -f "$config_file" || ! -d "$project_path" ]]; then
        return 0
    fi

    local config_content
    config_content=$(cat "$config_file")

    # NOTE: parent_directories are WORLD-level folders (project roots),
    # not project-internal structure — intentionally skipped here.

    # --- Parse subdirectories ---
    local in_subdirs=false
    local subdir_parent=""
    local current_subdir=""
    while IFS= read -r line; do
        if [[ "$line" =~ ^subdirectories: ]]; then
            in_subdirs=true
            continue
        fi
        if [[ "$in_subdirs" == true ]]; then
            if [[ "$line" =~ ^[a-zA-Z_]+: ]] && [[ ! "$line" =~ ^[[:space:]] ]]; then
                break
            fi
            # Parse parent
            if [[ "$line" =~ ^[[:space:]]{2}-[[:space:]]+parent:[[:space:]]+\"?([^\"]+)\"? ]]; then
                subdir_parent="${BASH_REMATCH[1]}"
                current_subdir=""
                continue
            fi
            # Structure items (6-space indent)
            if [[ "$line" =~ ^[[:space:]]{6}-[[:space:]]+name:[[:space:]]+\"?([^\"]+)\"? ]]; then
                current_subdir="${BASH_REMATCH[1]}"
                if [[ -n "$subdir_parent" ]]; then
                    local sd_path="${project_path}/${subdir_parent}/${current_subdir}"
                    if [[ ! -d "$sd_path" ]]; then
                        if [[ "$dry_run" == true ]]; then
                            echo "ADD ${subdir_parent}/${current_subdir}/"
                        else
                            mkdir -p "$sd_path"
                            echo "ADD ${subdir_parent}/${current_subdir}/"
                        fi
                    fi
                fi
                continue
            fi
            # Children (10-space indent)
            if [[ "$line" =~ ^[[:space:]]{10}-[[:space:]]+name:[[:space:]]+\"?([^\"]+)\"? ]]; then
                local child_name="${BASH_REMATCH[1]}"
                if [[ -n "$subdir_parent" && -n "$current_subdir" ]]; then
                    local child_path="${project_path}/${subdir_parent}/${current_subdir}/${child_name}"
                    if [[ ! -d "$child_path" ]]; then
                        if [[ "$dry_run" == true ]]; then
                            echo "ADD ${subdir_parent}/${current_subdir}/${child_name}/"
                        else
                            mkdir -p "$child_path"
                            echo "ADD ${subdir_parent}/${current_subdir}/${child_name}/"
                        fi
                    fi
                fi
                continue
            fi
        fi
    done <<< "$config_content"

    # --- Parse study_subdirectories (RESEARCH_WORLD) ---
    local in_studies=false
    while IFS= read -r line; do
        if [[ "$line" =~ ^study_subdirectories: ]]; then
            in_studies=true
            continue
        fi
        if [[ "$in_studies" == true ]]; then
            if [[ "$line" =~ ^[a-zA-Z_]+: ]] && [[ ! "$line" =~ ^[[:space:]] ]]; then
                break
            fi
            if [[ "$line" =~ ^[[:space:]]*-[[:space:]]+name:[[:space:]]+\"?([^\"]+)\"? ]]; then
                local study_subdir="${BASH_REMATCH[1]}"
                if [[ -d "${project_path}/02_studies" ]]; then
                    for study_dir in "${project_path}/02_studies"/*/; do
                        if [[ -d "$study_dir" ]]; then
                            local study_sub_path="${study_dir}${study_subdir}"
                            if [[ ! -d "$study_sub_path" ]]; then
                                if [[ "$dry_run" == true ]]; then
                                    echo "ADD 02_studies/$(basename "$study_dir")/${study_subdir}/"
                                else
                                    mkdir -p "$study_sub_path"
                                    echo "ADD 02_studies/$(basename "$study_dir")/${study_subdir}/"
                                fi
                            fi
                        fi
                    done
                fi
            fi
        fi
    done <<< "$config_content"

    return 0
}

# ============================================================================
# PHASE 1: INSTALLATION DETECTION & TOOL UPDATE
# ============================================================================

# Detect the current dirforge installation type and paths.
# Sets global variables: INSTALL_MODE, INSTALLED_BIN, INSTALLED_LIB
detect_installation() {
    INSTALL_MODE=""
    INSTALLED_BIN=""
    INSTALLED_LIB=""

    # Check local installation first (preferred)
    if [[ -f "$HOME/bin/dirforge" ]]; then
        INSTALL_MODE="local"
        INSTALLED_BIN="$HOME/bin/dirforge"
        INSTALLED_LIB="$HOME/.local/lib/dirforge"
        return 0
    fi

    # Check system-wide installation
    if [[ -f "/usr/local/bin/dirforge" ]]; then
        INSTALL_MODE="system"
        INSTALLED_BIN="/usr/local/bin/dirforge"
        INSTALLED_LIB="/usr/local/lib/dirforge"
        return 0
    fi

    return 1
}

# Get the version string from a dirforge binary.
# Arguments: path to binary
get_version_from_binary() {
    local bin_path="$1"
    if [[ -x "$bin_path" ]]; then
        "$bin_path" --version 2>/dev/null | head -n1 || echo "unknown"
    else
        echo "unknown"
    fi
}

# Get the version from the repo source (grep CONSTITUTION_VERSION).
get_version_from_repo() {
    local repo_src="$1"
    grep -m1 'CONSTITUTION_VERSION=' "$repo_src" 2>/dev/null \
        | sed 's/.*CONSTITUTION_VERSION="//' \
        | sed 's/".*//' \
        || echo "unknown"
}

# Compare installed files against repo source.
# Returns 0 if files differ (update needed), 1 if identical.
check_files_changed() {
    local repo_root="$1"

    # Compare main binary
    if ! diff -q "$INSTALLED_BIN" "$repo_root/tools/dirforge" >/dev/null 2>&1; then
        return 0
    fi

    # Compare lib files
    if [[ -d "$INSTALLED_LIB" && -d "$repo_root/lib" ]]; then
        for lib_file in "$repo_root"/lib/*.sh; do
            local basename
            basename=$(basename "$lib_file")
            if ! diff -q "$INSTALLED_LIB/$basename" "$lib_file" >/dev/null 2>&1; then
                return 0
            fi
        done
    fi

    # Compare template files
    if [[ -d "$INSTALLED_LIB/templates" && -d "$repo_root/templates" ]]; then
        local diff_output
        diff_output=$(diff -rq "$INSTALLED_LIB/templates" "$repo_root/templates" 2>/dev/null || true)
        if [[ -n "$diff_output" ]]; then
            return 0
        fi
    fi

    return 1
}

# List which files have changed between installed and repo.
list_changed_files() {
    local repo_root="$1"
    local changes=()

    # Check main binary
    if ! diff -q "$INSTALLED_BIN" "$repo_root/tools/dirforge" >/dev/null 2>&1; then
        changes+=("tools/dirforge")
    fi

    # Check lib files
    if [[ -d "$repo_root/lib" ]]; then
        for lib_file in "$repo_root"/lib/*.sh; do
            local basename
            basename=$(basename "$lib_file")
            if ! diff -q "$INSTALLED_LIB/$basename" "$lib_file" >/dev/null 2>&1; then
                changes+=("lib/$basename")
            fi
        done
    fi

    # Check template files
    if [[ -d "$repo_root/templates" ]]; then
        local diff_output
        diff_output=$(diff -rq "$INSTALLED_LIB/templates" "$repo_root/templates" 2>/dev/null || true)
        if [[ -n "$diff_output" ]]; then
            # Extract just the filenames that differ
            while IFS= read -r line; do
                if [[ "$line" =~ "differ" ]] || [[ "$line" =~ "Only in" ]]; then
                    changes+=("templates: $line")
                fi
            done <<< "$diff_output"
        fi
    fi

    printf '%s\n' "${changes[@]}"
}

# Copy updated files to the installation directory.
# Arguments: repo_root
apply_tool_update() {
    local repo_root="$1"

    if [[ "$INSTALL_MODE" == "system" ]] && ! is_root; then
        print_error "System-wide update requires sudo. Re-run with: sudo $0"
        return 1
    fi

    # Copy main binary
    cp "$repo_root/tools/dirforge" "$INSTALLED_BIN"
    chmod 755 "$INSTALLED_BIN"

    # Copy libraries
    if [[ -d "$repo_root/lib" ]]; then
        mkdir -p "$INSTALLED_LIB"
        cp -r "$repo_root/lib"/* "$INSTALLED_LIB/"
        chmod 755 "$INSTALLED_LIB"/*.sh
    fi

    # Copy templates
    if [[ -d "$repo_root/templates" ]]; then
        # Remove old templates dir to avoid stale files
        if [[ -d "$INSTALLED_LIB/templates" ]]; then
            rm -rf "$INSTALLED_LIB/templates"
        fi
        cp -r "$repo_root/templates" "$INSTALLED_LIB/"
        chmod -R 755 "$INSTALLED_LIB/templates"/*.sh 2>/dev/null || true
    fi

    return 0
}

# Run Phase 1: detect installation, compare, and optionally update the tool.
# Arguments: repo_root, dry_run, force
# Returns: 0 on success/skip, 1 on hard error
phase_tool_update() {
    local repo_root="$1"
    local dry_run="$2"
    local force="$3"

    print_section "Phase 1: Tool Installation Check"

    # 1. Detect current installation
    if ! detect_installation; then
        print_error "No dirforge installation found."
        print_info "Install first with: bash ${repo_root}/scripts/install_dirforge.sh"
        return 1
    fi

    print_success "Installation detected (${INSTALL_MODE})"
    print_item "Binary: ${INSTALLED_BIN}"
    print_item "Libraries: ${INSTALLED_LIB}"

    # 2. Compare versions
    local installed_version repo_version
    installed_version=$(get_version_from_binary "$INSTALLED_BIN")
    repo_version=$(get_version_from_repo "$repo_root/tools/dirforge")

    print_item "Installed version: ${installed_version}"
    print_item "Repository version: ${repo_version}"

    # 3. Check for file-level changes
    if ! check_files_changed "$repo_root"; then
        print_success "Tool is already up to date — no file changes detected."
        return 0
    fi

    # 4. Show what changed
    echo
    print_info "Changed files:"
    while IFS= read -r changed; do
        print_item "$changed"
    done < <(list_changed_files "$repo_root")

    # 5. Apply or preview
    if [[ "$dry_run" == true ]]; then
        echo
        print_info "DRY RUN: Tool files would be updated (no changes made)."
        return 0
    fi

    if [[ "$force" != true ]]; then
        echo
        if ! confirm "Apply tool update?" "y"; then
            print_warning "Tool update skipped."
            return 0
        fi
    fi

    echo
    if apply_tool_update "$repo_root"; then
        local new_version
        new_version=$(get_version_from_binary "$INSTALLED_BIN")
        print_success "Tool updated successfully (${new_version})."
    else
        print_error "Tool update failed."
        return 1
    fi

    return 0
}

# ============================================================================
# PHASE 2: WORKSPACE DISCOVERY
# ============================================================================

# Resolve the workspace root directory.
# Uses $DIRFORGE_WORKSPACE_ROOT, falls back to ~/Documents.
resolve_workspace_root() {
    local root="${DIRFORGE_WORKSPACE_ROOT:-}"

    if [[ -n "$root" && -d "$root" ]]; then
        echo "$root"
        return 0
    fi

    # Fallback
    if [[ -d "$HOME/Documents" ]]; then
        echo "$HOME/Documents"
        return 0
    fi

    return 1
}

# Discover existing WORLD directories under the workspace root.
# Arguments: workspace_root
# Outputs: one line per found WORLD directory (full path)
discover_worlds() {
    local workspace_root="$1"
    local found=0

    for world_name in "${KNOWN_WORLDS[@]}"; do
        local world_path="${workspace_root}/${world_name}"
        if [[ -d "$world_path" ]]; then
            echo "$world_path"
            ((found++))
        fi
    done

    return $(( found == 0 ? 1 : 0 ))
}

# Run Phase 2: discover workspace and list WORLDs.
# Arguments: (none, uses resolve_workspace_root)
# Sets global: WORKSPACE_ROOT, WORLD_PATHS (array)
phase_discover_workspace() {
    print_section "Phase 2: Workspace Discovery"

    WORKSPACE_ROOT=""
    WORLD_PATHS=()

    WORKSPACE_ROOT=$(resolve_workspace_root) || {
        print_error "Cannot determine workspace root."
        print_info "Set \$DIRFORGE_WORKSPACE_ROOT or ensure ~/Documents exists."
        return 1
    }

    print_success "Workspace root: ${WORKSPACE_ROOT}"

    # Discover worlds
    local worlds_output
    worlds_output=$(discover_worlds "$WORKSPACE_ROOT") || {
        print_warning "No WORLD directories found under ${WORKSPACE_ROOT}"
        print_info "Known world types: ${KNOWN_WORLDS[*]}"
        return 0
    }

    while IFS= read -r world_path; do
        WORLD_PATHS+=("$world_path")
    done <<< "$worlds_output"

    echo
    print_info "Discovered ${#WORLD_PATHS[@]} WORLD(s):"
    for wp in "${WORLD_PATHS[@]}"; do
        print_item "$(basename "$wp")  →  ${wp}"
    done

    return 0
}

# ============================================================================
# PHASE 3 & 4: TEMPLATE-VERSION CHECK & APPLY
# ============================================================================

# Preview template-driven changes for a single WORLD directory.
# Compares manifest template_version against the WORLD-level .integrity/world.yaml.
# Then previews missing directories across all projects.
# Arguments: world_path, world_type, manifest_file, repo_root
# Returns: 0 if changes pending, 1 if up to date
preview_world_template_update() {
    local world_path="$1"
    local world_type="$2"
    local manifest_file="$3"
    local repo_root="$4"
    local world_name
    world_name=$(basename "$world_path")

    local manifest_version
    manifest_version=$(get_manifest_template_version "$manifest_file" "$world_type")

    if [[ "$manifest_version" == "unknown" ]]; then
        print_warning "${world_name}: no template_version in manifest — skipping."
        return 1
    fi

    # Read WORLD-level template_version
    local world_integrity="${world_path}/.integrity/world.yaml"
    local deployed_version="unknown"
    if [[ -f "$world_integrity" ]]; then
        deployed_version=$(get_deployed_template_version "$world_integrity")
    fi

    # Check if world is up to date
    if [[ "$deployed_version" == "$manifest_version" ]]; then
        local project_count=0
        for p in "$world_path"/*/; do [[ -d "$p" ]] && ((project_count++)); done
        if [[ $project_count -gt 0 ]]; then
            print_success "${world_name}: at template_version ${manifest_version} (${project_count} projects)."
        else
            print_info "${world_name}: at template_version ${manifest_version}, no projects."
        fi
        return 1
    fi

    local config_filename
    config_filename=$(get_manifest_config_file "$manifest_file" "$world_type")
    local config_path="${repo_root}/templates/world-configs/${config_filename}"

    if [[ ! -f "$config_path" ]]; then
        print_warning "${world_name}: config file not found (${config_filename}) — skipping."
        return 1
    fi

    echo -e "  ${BOLD}${world_name}:${NC} ${deployed_version} → ${manifest_version}"

    # Check for missing .integrity/world.yaml at WORLD level
    if [[ ! -f "$world_integrity" ]]; then
        echo "    ADD .integrity/world.yaml"
    fi

    # Preview structural changes if this is a minor/major bump
    if is_structural_bump "$deployed_version" "$manifest_version"; then
        local project_count=0
        local projects_with_changes=0

        for project_dir in "$world_path"/*/; do
            [[ -d "$project_dir" ]] || continue
            ((project_count++))

            local project_name
            project_name=$(basename "$project_dir")

            # Check for missing .integrity/project.yaml
            if [[ ! -f "${project_dir}.integrity/project.yaml" ]]; then
                echo "    ${project_name}: ADD .integrity/project.yaml"
                ((projects_with_changes++))
            fi

            # Preview directory scaffold
            local scaffold_preview
            scaffold_preview=$(scaffold_from_template "$config_path" "$project_dir" true 2>/dev/null || true)
            if [[ -n "$scaffold_preview" ]]; then
                echo "$scaffold_preview" | while IFS= read -r add_line; do
                    echo "    ${project_name}: $add_line"
                done
                ((projects_with_changes++))
            fi
        done

        if [[ $projects_with_changes -eq 0 && $project_count -gt 0 ]]; then
            echo "    (no missing directories detected across ${project_count} projects)"
        fi
    else
        echo "    (patch-only version bump — no structural changes)"
    fi

    echo
    return 0
}

# Apply template-driven updates for a single WORLD directory.
# Stamps WORLD-level .integrity/world.yaml, then scaffolds projects.
# Arguments: world_path, world_type, manifest_file, repo_root, backup_flag
apply_world_template_update() {
    local world_path="$1"
    local world_type="$2"
    local manifest_file="$3"
    local repo_root="$4"
    local backup_flag="$5"
    local world_name
    world_name=$(basename "$world_path")

    local manifest_version
    manifest_version=$(get_manifest_template_version "$manifest_file" "$world_type")

    local config_filename
    config_filename=$(get_manifest_config_file "$manifest_file" "$world_type")
    local config_path="${repo_root}/templates/world-configs/${config_filename}"

    # ── Ensure WORLD-level .integrity/world.yaml exists ──
    local world_integrity="${world_path}/.integrity/world.yaml"
    if [[ ! -f "$world_integrity" ]]; then
        mkdir -p "${world_path}/.integrity"
        cat > "$world_integrity" << EOF
# Auto-generated by update_dirforge.sh
world_type: "${world_type}"
template_version: "${manifest_version}"
created: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
EOF
        print_success "${world_name}: created .integrity/world.yaml"
    fi

    local updated_projects=0

    # ── Scaffold each project ──
    for project_dir in "$world_path"/*/; do
        [[ -d "$project_dir" ]] || continue

        local project_name
        project_name=$(basename "$project_dir")

        # Optional backup
        if [[ "$backup_flag" == true ]]; then
            local ts
            ts=$(date +%Y%m%d-%H%M%S)
            local backup_dest="${project_dir}.integrity/backup/backup_${ts}"
            mkdir -p "$(dirname "$backup_dest")"
            if cp -a "$project_dir" "$backup_dest" 2>/dev/null; then
                print_item "${project_name}: backup → ${backup_dest}"
            else
                print_warning "${project_name}: backup failed, continuing anyway."
            fi
        fi

        # Ensure project-level .integrity/project.yaml exists
        local project_integrity="${project_dir}.integrity/project.yaml"
        if [[ ! -f "$project_integrity" ]]; then
            mkdir -p "${project_dir}.integrity/checksums"
            mkdir -p "${project_dir}.integrity/manifests"
            cat > "$project_integrity" << EOF
name: "${project_name}"
world_type: "${world_type}"
version: "1.1.0"
created: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
updated: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
EOF
            print_item "${project_name}: created .integrity/project.yaml"
        fi

        # Apply structural changes if structural bump
        local deployed_version="unknown"
        if [[ -f "$world_integrity" ]]; then
            deployed_version=$(get_deployed_template_version "$world_integrity")
        fi

        if is_structural_bump "$deployed_version" "$manifest_version" && [[ -f "$config_path" ]]; then
            local scaffold_output
            scaffold_output=$(scaffold_from_template "$config_path" "$project_dir" false 2>/dev/null || true)
            if [[ -n "$scaffold_output" ]]; then
                echo "$scaffold_output" | while IFS= read -r add_line; do
                    print_item "${project_name}: ${add_line}"
                done
            fi
        fi

        # Also run dirforge update for metadata/integrity
        dirforge update "$project_dir" 2>/dev/null || true
        ((updated_projects++))
    done

    # ── Stamp the WORLD-level template_version ──
    stamp_template_version "$world_integrity" "$manifest_version"
    print_success "${world_name}: stamped template_version ${manifest_version}"

    if [[ $updated_projects -gt 0 ]]; then
        print_success "${world_name}: ${updated_projects} project(s) processed."
    fi

    return 0
}

# Bootstrap: stamp the current manifest template_version on every WORLD
# and ensure .integrity/ structure exists at both WORLD and project levels.
# No structural directory changes are made. Safe first-run for existing workspaces.
# Arguments: repo_root, force
phase_bootstrap() {
    local repo_root="$1"
    local force="$2"

    if [[ ${#WORLD_PATHS[@]} -eq 0 ]]; then
        print_info "No WORLD directories found."
        return 0
    fi

    # Locate manifest
    local manifest_file=""
    if [[ -f "${INSTALLED_LIB:-}/templates/template_versions.yaml" ]]; then
        manifest_file="${INSTALLED_LIB}/templates/template_versions.yaml"
    elif [[ -f "${repo_root}/templates/template_versions.yaml" ]]; then
        manifest_file="${repo_root}/templates/template_versions.yaml"
    fi

    if [[ -z "$manifest_file" || ! -f "$manifest_file" ]]; then
        print_error "No template_versions.yaml manifest found — cannot bootstrap."
        return 1
    fi

    print_section "Bootstrap: Initialize Integrity Metadata"
    print_info "Using manifest: ${manifest_file}"
    print_info "This will:"
    print_item "Create .integrity/world.yaml at each WORLD level (with template_version)"
    print_item "Create .integrity/project.yaml at each project level (if missing)"
    print_info "WITHOUT creating or modifying any project directories."
    echo

    if [[ "$force" != true ]]; then
        if ! confirm "Proceed with bootstrap?" "y"; then
            print_warning "Bootstrap cancelled."
            return 0
        fi
        echo
    fi

    local total_worlds_stamped=0
    local total_projects_created=0
    local total_projects_skipped=0

    for world_path in "${WORLD_PATHS[@]}"; do
        local world_type
        world_type=$(basename "$world_path")

        local manifest_version
        manifest_version=$(get_manifest_template_version "$manifest_file" "$world_type")

        if [[ "$manifest_version" == "unknown" ]]; then
            print_warning "${world_type}: not in manifest — skipping."
            continue
        fi

        # ── WORLD-level .integrity/world.yaml ──
        local world_integrity="${world_path}/.integrity/world.yaml"
        if [[ -f "$world_integrity" ]]; then
            local deployed
            deployed=$(get_deployed_template_version "$world_integrity")
            if [[ "$deployed" == "$manifest_version" ]]; then
                print_success "${world_type}: already at template_version ${manifest_version}."
            else
                stamp_template_version "$world_integrity" "$manifest_version"
                print_item "${world_type}: ${deployed} → ${manifest_version}"
                ((total_worlds_stamped++))
            fi
        else
            mkdir -p "${world_path}/.integrity"
            cat > "$world_integrity" << EOF
# Auto-generated by update_dirforge.sh --bootstrap
world_type: "${world_type}"
template_version: "${manifest_version}"
created: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
EOF
            print_success "${world_type}: created .integrity/world.yaml (${manifest_version})"
            ((total_worlds_stamped++))
        fi

        # ── Project-level .integrity/project.yaml ──
        for project_dir in "$world_path"/*/; do
            [[ -d "$project_dir" ]] || continue

            local project_name
            project_name=$(basename "$project_dir")
            local project_integrity="${project_dir}.integrity/project.yaml"

            if [[ -f "$project_integrity" ]]; then
                ((total_projects_skipped++))
                continue
            fi

            mkdir -p "${project_dir}.integrity/checksums"
            mkdir -p "${project_dir}.integrity/manifests"
            cat > "$project_integrity" << EOF
name: "${project_name}"
world_type: "${world_type}"
version: "1.1.0"
created: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
updated: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
EOF
            print_item "${world_type}/${project_name}: created .integrity/project.yaml"
            ((total_projects_created++))
        done
    done

    echo
    print_info "Bootstrap summary:"
    print_item "${total_worlds_stamped} WORLD(s) stamped with template_version"
    print_item "${total_projects_created} project(s) got new .integrity/project.yaml"
    print_item "${total_projects_skipped} project(s) already had .integrity/project.yaml"

    return 0
}

# Run Phase 3 (preview) and Phase 4 (apply) for all discovered WORLDs.
# Arguments: dry_run, force, backup, repo_root
phase_workspace_update() {
    local dry_run="$1"
    local force="$2"
    local backup="$3"
    local repo_root="$4"

    if [[ ${#WORLD_PATHS[@]} -eq 0 ]]; then
        print_info "No WORLD directories to update."
        return 0
    fi

    # Locate the template version manifest
    local manifest_file=""
    if [[ -f "${INSTALLED_LIB:-}/templates/template_versions.yaml" ]]; then
        manifest_file="${INSTALLED_LIB}/templates/template_versions.yaml"
    elif [[ -f "${repo_root}/templates/template_versions.yaml" ]]; then
        manifest_file="${repo_root}/templates/template_versions.yaml"
    fi

    if [[ -z "$manifest_file" || ! -f "$manifest_file" ]]; then
        print_warning "No template_versions.yaml manifest found."
        print_info "Falling back to dirforge update (version-based only)."
        _phase_workspace_update_legacy "$dry_run" "$force" "$backup"
        return $?
    fi

    print_info "Using manifest: ${manifest_file}"

    # ── Phase 3: Template-version preview ─────────────────────────────────────
    print_section "Phase 3: Template Version Check"
    print_info "Comparing deployed template_version against manifest..."
    echo

    local worlds_with_changes=()
    local worlds_up_to_date=()

    for world_path in "${WORLD_PATHS[@]}"; do
        local world_type
        world_type=$(basename "$world_path")

        if preview_world_template_update "$world_path" "$world_type" "$manifest_file" "$repo_root"; then
            worlds_with_changes+=("$world_path")
        else
            worlds_up_to_date+=("$world_path")
        fi
    done

    echo
    print_info "Preview summary:"
    print_item "${#worlds_with_changes[@]} WORLD(s) with pending changes"
    print_item "${#worlds_up_to_date[@]} WORLD(s) already up to date"

    # Dry-run stops here
    if [[ "$dry_run" == true ]]; then
        echo
        print_info "DRY RUN: No changes were made to any workspace structures."
        return 0
    fi

    if [[ ${#worlds_with_changes[@]} -eq 0 ]]; then
        echo
        print_success "All WORLD structures are up to date. Nothing to do."
        return 0
    fi

    # ── Phase 4: Apply ────────────────────────────────────────────────────────
    print_section "Phase 4: Apply Updates"

    local updated_count=0
    local skipped_count=0
    local failed_count=0

    for world_path in "${worlds_with_changes[@]}"; do
        local world_name world_type
        world_name=$(basename "$world_path")
        world_type="$world_name"

        if [[ "$force" != true ]]; then
            echo
            if ! confirm "Apply changes to ${world_name}?" "n"; then
                print_warning "${world_name}: skipped by user."
                ((skipped_count++))
                continue
            fi
        fi

        if apply_world_template_update "$world_path" "$world_type" "$manifest_file" "$repo_root" "$backup"; then
            ((updated_count++))
        else
            ((failed_count++))
        fi
    done

    echo
    print_info "Apply summary:"
    print_item "${updated_count} WORLD(s) updated"
    print_item "${skipped_count} WORLD(s) skipped"
    print_item "${failed_count} WORLD(s) failed"

    if [[ $failed_count -gt 0 ]]; then
        return 1
    fi
    return 0
}

# Legacy fallback: use dirforge update (version-based, no template comparison)
_phase_workspace_update_legacy() {
    local dry_run="$1"
    local force="$2"
    local backup="$3"

    print_section "Phase 3: Structure Preview (legacy)"
    print_info "Running dirforge update --dry-run for each WORLD..."

    local worlds_with_changes=()
    local worlds_up_to_date=()

    for world_path in "${WORLD_PATHS[@]}"; do
        local world_name
        world_name=$(basename "$world_path")
        local preview_output
        preview_output=$(dirforge update "$world_path" --dry-run 2>&1) || true

        if echo "$preview_output" | grep -q "already up to date"; then
            print_success "${world_name}: already up to date."
            worlds_up_to_date+=("$world_path")
        else
            echo
            echo -e "  ${BOLD}${world_name}:${NC}"
            echo "$preview_output" | while IFS= read -r line; do
                echo "    $line"
            done
            echo
            worlds_with_changes+=("$world_path")
        fi
    done

    echo
    print_info "Preview summary:"
    print_item "${#worlds_with_changes[@]} WORLD(s) with pending changes"
    print_item "${#worlds_up_to_date[@]} WORLD(s) already up to date"

    if [[ "$dry_run" == true ]]; then
        echo
        print_info "DRY RUN: No changes were made to any workspace structures."
        return 0
    fi

    if [[ ${#worlds_with_changes[@]} -eq 0 ]]; then
        echo
        print_success "All WORLD structures are up to date. Nothing to do."
        return 0
    fi

    print_section "Phase 4: Apply Updates (legacy)"

    local updated_count=0
    local skipped_count=0
    local failed_count=0

    for world_path in "${worlds_with_changes[@]}"; do
        local world_name
        world_name=$(basename "$world_path")

        if [[ "$force" != true ]]; then
            echo
            if ! confirm "Apply changes to ${world_name}?" "n"; then
                print_warning "${world_name}: skipped by user."
                ((skipped_count++))
                continue
            fi
        fi

        local args=("$world_path")
        [[ "$backup" == true ]] && args+=(--backup)

        if dirforge update "${args[@]}" 2>&1; then
            print_success "${world_name}: updated successfully."
            ((updated_count++))
        else
            print_error "${world_name}: update failed."
            ((failed_count++))
        fi
    done

    echo
    print_info "Apply summary:"
    print_item "${updated_count} WORLD(s) updated"
    print_item "${skipped_count} WORLD(s) skipped"
    print_item "${failed_count} WORLD(s) failed"

    [[ $failed_count -gt 0 ]] && return 1
    return 0
}

# ============================================================================
# PHASE 5: FINAL SUMMARY
# ============================================================================

print_summary() {
    local dry_run="$1"

    print_section "Summary"

    if [[ "$dry_run" == true ]]; then
        print_info "Mode: DRY RUN — no changes were made anywhere."
    else
        print_success "Update process complete."
    fi

    # Tool info
    if detect_installation; then
        local current_version
        current_version=$(get_version_from_binary "$INSTALLED_BIN")
        print_item "Installed version: ${current_version}"
        print_item "Install mode: ${INSTALL_MODE}"
    fi

    # Workspace info
    if [[ -n "${WORKSPACE_ROOT:-}" ]]; then
        print_item "Workspace root: ${WORKSPACE_ROOT}"
        print_item "WORLDs discovered: ${#WORLD_PATHS[@]}"
    fi

    echo
}

# ============================================================================
# MAIN ENTRY POINT
# ============================================================================

show_help() {
    echo "DirForge Update Script"
    echo
    echo "Update the installed dirforge tool and/or workspace directory structures."
    echo
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  --dry-run           Preview all changes without applying them"
    echo "  --force             Apply all changes without interactive prompts"
    echo "  --backup            Create timestamped backups before applying structure changes"
    echo "  --tool-only         Update the installed tool only (skip workspace updates)"
    echo "  --workspace-only    Update workspace structures only (skip tool update)"
    echo "  --bootstrap         Stamp current template_version on all projects (no structural changes)"
    echo "  --help, -h          Show this help message"
    echo
    echo "Environment:"
    echo "  DIRFORGE_WORKSPACE_ROOT   Path containing *_WORLD directories (default: ~/Documents)"
    echo
    echo "Template versioning:"
    echo "  The script reads templates/template_versions.yaml to compare template_version"
    echo "  values against what is deployed in each WORLD's .integrity/world.yaml."
    echo "  To trigger a migration after editing a world config template:"
    echo "    1. Edit the template in templates/world-configs/"
    echo "    2. Bump the template_version in templates/template_versions.yaml"
    echo "    3. Run: $0"
    echo
    echo "  Version semantics:"
    echo "    patch bump (1.0.0 → 1.0.1): description-only, no structural changes"
    echo "    minor bump (1.0.0 → 1.1.0): new directories/children, triggers scaffold"
    echo "    major bump (1.0.0 → 2.0.0): breaking changes, triggers scaffold"
    echo
    echo "Examples:"
    echo "  $0                        # Interactive: preview each WORLD, then prompt to apply"
    echo "  $0 --dry-run              # Preview only, no changes anywhere"
    echo "  $0 --force --backup       # Apply all updates with backups, no prompting"
    echo "  $0 --tool-only            # Only update the installed dirforge binary & libs"
    echo "  $0 --workspace-only       # Only update workspace structures"
    echo "  $0 --bootstrap            # Stamp version on all projects (safe first-run)"
    echo
}

main() {
    # ── Locate the repo root ─────────────────────────────────────────────────
    local script_dir
    if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
        script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    else
        script_dir="$(cd "$(dirname "$0")" && pwd)"
    fi
    local repo_root
    repo_root="$(cd "$script_dir/.." >/dev/null 2>&1 && pwd)"

    if [[ ! -f "$repo_root/tools/dirforge" ]]; then
        echo "ERROR: Cannot find dirforge source at $repo_root/tools/dirforge" >&2
        echo "Run this script from within the dirforge repository." >&2
        exit 1
    fi

    # ── Parse arguments ──────────────────────────────────────────────────────
    local dry_run=false
    local force=false
    local backup=false
    local tool_only=false
    local workspace_only=false
    local bootstrap=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)       dry_run=true; shift ;;
            --force)         force=true; shift ;;
            --backup)        backup=true; shift ;;
            --tool-only)     tool_only=true; shift ;;
            --workspace-only) workspace_only=true; shift ;;
            --bootstrap)     bootstrap=true; shift ;;
            --help|-h)       show_help; exit 0 ;;
            *)
                echo "ERROR: Unknown option: $1" >&2
                echo "Use --help for usage information." >&2
                exit 1
                ;;
        esac
    done

    # Validate conflicting flags
    if [[ "$tool_only" == true && "$workspace_only" == true ]]; then
        echo "ERROR: --tool-only and --workspace-only are mutually exclusive." >&2
        exit 1
    fi
    if [[ "$bootstrap" == true && "$tool_only" == true ]]; then
        echo "ERROR: --bootstrap and --tool-only are mutually exclusive." >&2
        exit 1
    fi

    # ── Header ───────────────────────────────────────────────────────────────
    print_header

    if [[ "$dry_run" == true ]]; then
        print_info "Mode: DRY RUN — no changes will be made."
        echo
    fi

    # ── Phase 1: Tool update ─────────────────────────────────────────────────
    if [[ "$workspace_only" != true ]]; then
        if ! phase_tool_update "$repo_root" "$dry_run" "$force"; then
            # Hard error in tool detection means we can't proceed
            exit 1
        fi
    fi

    # ── Phase 2 + 3 + 4: Workspace discovery & updates ──────────────────────
    if [[ "$tool_only" != true ]]; then
        if ! phase_discover_workspace; then
            # Hard error in workspace detection, but not fatal for tool-update
            print_error "Workspace discovery failed."
            exit 1
        fi

        if [[ "$bootstrap" == true ]]; then
            phase_bootstrap "$repo_root" "$force" || true
        else
            phase_workspace_update "$dry_run" "$force" "$backup" "$repo_root" || true
        fi
    fi

    # ── Phase 5: Summary ─────────────────────────────────────────────────────
    print_summary "$dry_run"
}

main "$@"
