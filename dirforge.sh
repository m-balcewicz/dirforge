#!/usr/bin/env bash

set -euo pipefail

# --- Constants ---
WORLD_TYPES=("coding" "research" "office")
SUBDIR_TYPES=("journal" "recordings" "report")

VERSION="1.1.1"

# --- Helper Functions ---

usage() {
  cat <<EOF
Usage: dirforge <command> [options]

DirForge v$VERSION — workspace scaffolder

Commands:
  init [path] [--auto]
    Initialize a new world at <path> (default: current dir).

  create <type> --name <name> [--first]
    Create a new subdirectory of type <type>.
    Supported types: ${SUBDIR_TYPES[*]}

Options:
  --auto           Skip interactive prompts.
  --name <name>    Name of the subdirectory instance (required).
  --first          Mark this as the primary/default instance.

Examples:
  dirforge init              # Initialize workspace
  dirforge create coding     # Create coding project
  dirforge --version         # Show version

For more help: dirforge <command> --help
EOF
}

validate_world_type() {
  local type="$1"
  for t in "${WORLD_TYPES[@]}"; do
    [[ "$t" == "$type" ]] && return 0
  done
  echo "Error: Invalid world type '$type'. Supported: ${WORLD_TYPES[*]}" >&2
  exit 1
}

validate_subdir_type() {
  local type="$1"
  for t in "${SUBDIR_TYPES[@]}"; do
    [[ "$t" == "$type" ]] && return 0
  done
  echo "Error: Invalid subdir type '$type'. Supported: ${SUBDIR_TYPES[*]}" >&2
  exit 1
}

# --- `init` Command ---

cmd_init() {
  local path="${1:-.}"
  local auto=false

  shift || true
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --auto) auto=true; shift ;;
      *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
  done

  if [[ ! -d "$path" ]]; then
    mkdir -p "$path"
  fi

  cd "$path"

  if [[ ! -f "world.yaml" ]]; then
    echo "Which world type would you like to use? (coding/research/office)" >&2
    if [[ "$auto" == "true" ]]; then
      world_type="coding"
    else
      read -r world_type
    fi

    validate_world_type "$world_type"

    # Create minimal scaffolding for world.yaml
    cat > "world.yaml" <<EOF
type: $world_type
version: 1.0.0
instances: []
EOF

    # Create hidden config dir
    mkdir -p ".dirforge"
  else
    echo "World already initialized at '$path'" >&2
  fi
}

# --- `create` Command ---

cmd_create() {
  local subdir_type=""
  local name=""
  local first=false

  # Parse positional arg
  if [[ $# -lt 1 ]]; then
    echo "Error: Missing <subdir-type>" >&2
    usage
    exit 1
  fi
  subdir_type="$1"
  shift

  # Parse options
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --name)
        if [[ $# -lt 2 ]]; then
          echo "Error: --name requires an argument" >&2
          exit 1
        fi
        name="$2"
        shift 2
        ;;
      --first)
        first=true
        shift
        ;;
      *)
        echo "Unknown option: $1" >&2
        exit 1
        ;;
    esac
  done

  # Validate inputs
  validate_subdir_type "$subdir_type"
  if [[ -z "$name" ]]; then
    echo "Error: --name is required for subdir creation" >&2
    exit 1
  fi

  # Ensure world.yaml exists
  if [[ ! -f "world.yaml" ]]; then
    echo "Error: No world.yaml found. Run 'dirforge init' first." >&2
    exit 1
  fi

  # Determine template path (e.g., templates/coding/journal/)
  local world_type
  world_type=$(grep "^type:" world.yaml | awk '{print $2}')
  local template_dir="templates/$world_type/$subdir_type"

  if [[ ! -d "$template_dir" ]]; then
    echo "Error: Template for '$subdir_type' not found under '$world_type'" >&2
    exit 1
  fi

  # Create subdir and copy template contents
  local target_dir="$subdir_type/$name"
  mkdir -p "$target_dir"

  # Copy template files (simple version; could use rsync or cp -r)
  if [[ -f "$template_dir/template.yaml" ]]; then
    sed "s/\${name}/$name/g" "$template_dir/template.yaml" > "$target_dir/config.yaml"
  fi

  # Update world.yaml to register instance
  local yaml_entry="  - type: $subdir_type"
  if [[ "$first" == "true" ]]; then
    yaml_entry="$yaml_entry"
    # Prepend to list (naive approach)
    sed -i.bak "s/instances: \[\]/instances:\n  - type: $subdir_type\n    name: $name/" world.yaml
    rm -f "world.yaml.bak"
  else
    # Append to list
    if grep -q "^instances: \[\]" world.yaml; then
      sed -i.bak "s/instances: \[\]/instances:\n  - type: $subdir_type\n    name: $name/" world.yaml
      rm -f "world.yaml.bak"
    else
      echo "  - type: $subdir_type" >> world.yaml
      echo "    name: $name" >> world.yaml
    fi
  fi

  echo "Created $subdir_type instance '$name' at '$target_dir'"
}

# --- CLI Dispatcher ---

main() {
  if [[ $# -lt 1 ]]; then
    usage
    exit 1
  fi

  local cmd="$1"
  shift

  case "$cmd" in
    init)
      cmd_init "$@"
      ;;
    create)
      cmd_create "$@"
      ;;
    help|--help|-h)
      usage
      ;;
    version|--version|-v)
      echo "dirforge version $VERSION"
      ;;
    *)
      echo "Unknown command: $cmd" >&2
      usage
      exit 1
      ;;
  esac
}

main "$@"
