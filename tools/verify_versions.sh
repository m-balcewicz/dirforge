#!/usr/bin/env bash

set -euo pipefail

# --- Constants ---
VERSION="1.0"
TARGET_VERSION="1.1.1"

# --- Global Options ---
VERBOSE=false
REPORT_FORMAT="text"

# --- Helper Functions ---

usage() {
  cat <<EOF
Usage: verify_versions.sh [OPTIONS]

Verify that all version references are consistent throughout the repository

Options:
  -v, --verbose       Show detailed output
      --report <fmt>  Output format: text, json, or markdown
  -h, --help          Show help information

Examples:
  verify_versions.sh              # Verify versions with text output
  verify_versions.sh --verbose    # Show detailed verification
  verify_versions.sh --report json  # Output in JSON format

EOF
}

log_info() {
  if [[ "$VERBOSE" == "true" ]]; then
    echo "[INFO] $1"
  fi
}

log_error() {
  echo "[ERROR] $1" >&2
}

# --- Argument Parsing ---

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -v|--verbose)
        VERBOSE=true
        shift
        ;;
      --report)
        if [[ $# -lt 2 ]]; then
          log_error "--report requires an argument"
          exit 1
        fi
        REPORT_FORMAT="$2"
        shift 2
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        log_error "Unknown option: $1"
        usage
        exit 1
        ;;
    esac
  done
}

# --- Version Detection ---

detect_version_format() {
  local line_content="$1"
  
  if echo "$line_content" | grep -qE '(VERSION|DIRFORGE_VERSION)="?[0-9]+\.[0-9]+\.[0-9]+"?'; then
    echo "bash_constant"
  elif echo "$line_content" | grep -qE '(version|@schema-version|constitution_version):"?[0-9]+\.[0-9]+\.[0-9]+"?'; then
    echo "yaml_key"
  elif echo "$line_content" | grep -qE '(v|version\ *|DirForge\ v)[0-9]+\.[0-9]+\.[0-9]+'; then
    echo "markdown_text"
  elif echo "$line_content" | grep -qE '#.*(version|Version).*[0-9]+\.[0-9]+\.[0-9]+'; then
    echo "comment"
  else
    echo "unknown"
  fi
}

extract_version() {
  local line_content="$1"
  
  if [[ "$line_content" =~ VERSION=\"?([0-9]+\.[0-9]+\.[0-9]+)\"? ]]; then
    echo "${BASH_REMATCH[1]}"
  elif [[ "$line_content" =~ DIRFORGE_VERSION=([0-9]+\.[0-9]+\.[0-9]+) ]]; then
    echo "${BASH_REMATCH[1]}"
  elif [[ "$line_content" =~ version:\ *\"?([0-9]+\.[0-9]+\.[0-9]+)\"? ]]; then
    echo "${BASH_REMATCH[1]}"
  elif [[ "$line_content" =~ @schema-version:\ *([0-9]+\.[0-9]+\.[0-9]+) ]]; then
    echo "${BASH_REMATCH[1]}"
  elif [[ "$line_content" =~ constitution_version:\ *\"?([0-9]+\.[0-9]+\.[0-9]+)\"? ]]; then
    echo "${BASH_REMATCH[1]}"
  elif [[ "$line_content" =~ (v|version\ *|DirForge\ v)([0-9]+\.[0-9]+\.[0-9]+) ]]; then
    echo "${BASH_REMATCH[2]}"
  elif [[ "$line_content" =~ \#.*(version|Version).*([0-9]+\.[0-9]+\.[0-9]+) ]]; then
    echo "${BASH_REMATCH[2]}"
  else
    echo ""
  fi
}

should_exclude() {
  local file="$1"
  
  if [[ "$file" == *".git/"* ]]; then
    return 0
  fi
  
  if [[ "$file" == *"node_modules/"* ]]; then
    return 0
  fi
  
  if [[ "$file" == *"__pycache__/"* ]]; then
    return 0
  fi
  
  if file "$file" | grep -q "text"; then
    return 1
  else
    return 0
  fi
}

is_intentional() {
  local file="$1"
  
  if [[ "$file" == *"test_"*"_v1.0"* ]]; then
    return 0
  fi
  
  if [[ "$file" == *"migration"* ]]; then
    return 0
  fi
  
  if [[ "$file" == *"templates/example"* ]]; then
    return 0
  fi
  
  return 1
}

# --- Verification ---

verify_file() {
  local file="$1"
  local refs=0
  local outdated=0
  
  while IFS= read -r line; do
    local format=$(detect_version_format "$line")
    if [[ "$format" != "unknown" ]]; then
      refs=$((refs + 1))
      local version=$(extract_version "$line")
      if [[ -n "$version" && "$version" != "$TARGET_VERSION" ]]; then
        outdated=$((outdated + 1))
      fi
    fi
  done < "$file"
  
  echo "$refs:$outdated"
}

# --- Output Formats ---

output_text() {
  local total_files=0
  local consistent_refs=0
  local outdated_refs=0
  local skipped_count=0
  
  echo "Verifying version consistency..."
  
  while IFS= read -r file; do
    if should_exclude "$file"; then
      continue
    fi
    
    total_files=$((total_files + 1))
    
    local result=$(verify_file "$file")
    local refs=$(echo "$result" | cut -d: -f1)
    local outdated=$(echo "$result" | cut -d: -f2)
    
    consistent_refs=$((consistent_refs + refs))
    outdated_refs=$((outdated_refs + outdated))
  done < <(find . -type f ! -path "./.git/*" ! -path "./.specify/integrations/*")
  
  echo "Found $total_files files scanned"
  echo "Version references: $consistent_refs consistent ($TARGET_VERSION), $outdated_refs outdated"
  
  if [[ "$outdated_refs" -eq 0 ]]; then
    echo ""
    echo "Result: PASSED - All version references are consistent"
    return 0
  else
    echo ""
    echo "Result: FAILED - $outdated_refs outdated version references found"
    return 1
  fi
}

output_json() {
  local total_files=0
  local consistent_refs=0
  local outdated_refs=0
  
  while IFS= read -r file; do
    if should_exclude "$file"; then
      continue
    fi
    
    total_files=$((total_files + 1))
    
    local result=$(verify_file "$file")
    local refs=$(echo "$result" | cut -d: -f1)
    local outdated=$(echo "$result" | cut -d: -f2)
    
    consistent_refs=$((consistent_refs + refs))
    outdated_refs=$((outdated_refs + outdated))
  done < <(find . -type f ! -path "./.git/*" ! -path "./.specify/integrations/*")
  
  local status="PASSED"
  if [[ "$outdated_refs" -gt 0 ]]; then
    status="FAILED"
  fi
  
  cat <<EOF
{
  "status": "$status",
  "total_files": $total_files,
  "consistent_references": $consistent_refs,
  "outdated_references": $outdated_refs,
  "target_version": "$TARGET_VERSION"
}
EOF
}

output_markdown() {
  local total_files=0
  local consistent_refs=0
  local outdated_refs=0
  
  while IFS= read -r file; do
    if should_exclude "$file"; then
      continue
    fi
    
    total_files=$((total_files + 1))
    
    local result=$(verify_file "$file")
    local refs=$(echo "$result" | cut -d: -f1)
    local outdated=$(echo "$result" | cut -d: -f2)
    
    consistent_refs=$((consistent_refs + refs))
    outdated_refs=$((outdated_refs + outdated))
  done < <(find . -type f ! -path "./.git/*" ! -path "./.specify/integrations/*")
  
  local status="PASSED"
  if [[ "$outdated_refs" -gt 0 ]]; then
    status="FAILED"
  fi
  
  cat <<EOF
# Version Verification Report

**Status**: $status

| Metric | Value |
|--------|-------|
| Files Scanned | $total_files |
| Consistent References | $consistent_refs |
| Outdated References | $outdated_refs |
| Target Version | $TARGET_VERSION |

EOF
}

# --- Main Execution ---

main() {
  parse_args "$@"
  
  log_info "DirForge Version Verification Tool v$VERSION"
  log_info "Target version: $TARGET_VERSION"
  
  case "$REPORT_FORMAT" in
    text)
      output_text
      ;;
    json)
      output_json
      ;;
    markdown)
      output_markdown
      ;;
    *)
      log_error "Unknown report format: $REPORT_FORMAT"
      exit 1
      ;;
  esac
}

main "$@"
