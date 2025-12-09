#!/usr/bin/env bash
set -euo pipefail

# Manifest validator for DirForge (constitution v1.0.12)
# Preferred: uses `yq` for robust YAML parsing. Falls back to a lightweight
# grep-based check when `yq` is not available (useful for CI or minimalist systems).
# Validates checksums are referenced at `.integrity/checksums/` path.

usage() {
  echo "Usage: $0 [--strict] <manifest.yaml>"
  echo ""
  echo "Options:"
  echo "  --strict    Fail on warnings (e.g., missing checksum files)"
  exit 1
}

strict_mode=0
if [ "$#" -ge 1 ] && [ "$1" = "--strict" ]; then
  strict_mode=1
  shift
fi

if [ "$#" -lt 1 ]; then
  usage
fi

manifest_file="$1"
if [ ! -f "$manifest_file" ]; then
  echo "ERROR: manifest file not found: $manifest_file" >&2
  exit 2
fi

manifest_dir="$(cd "$(dirname "$manifest_file")" && pwd)"

required_keys=(storage_location server_or_nas path_on_store naming checksum access)
forbidden_keywords=(password passphrase secret token private_key credentials ssh_key)

errors=0
warnings=0

if command -v yq >/dev/null 2>&1; then
  # Use yq for accurate YAML handling
  for k in "${required_keys[@]}"; do
    val="$(yq eval ".${k} // "null"" "$manifest_file")"
    if [ "$val" = "null" ] || [ -z "$val" ]; then
      echo "ERROR: missing required key: $k" >&2
      errors=$((errors+1))
    fi
  done
  checksum_val="$(yq eval '.checksum' "$manifest_file")"
  
  # Constitution v1.0.12: validate checksum path uses .integrity/checksums/
  if [ -n "$checksum_val" ] && [ "$checksum_val" != "null" ]; then
    if ! echo "$checksum_val" | grep -q '\.integrity/checksums/'; then
      echo "ERROR: checksum path must use '.integrity/checksums/' directory (constitution v1.0.12)" >&2
      echo "  Found: $checksum_val" >&2
      echo "  Expected pattern: .integrity/checksums/<file>.sha256" >&2
      errors=$((errors+1))
    fi
  fi
  # Collect all map keys recursively and check for forbidden keys
  all_keys="$(yq eval '.. | select(tag == "!!map") | keys | .[]' "$manifest_file" 2>/dev/null || true)"
  for fk in "${forbidden_keywords[@]}"; do
    if echo "$all_keys" | grep -x -i -q "$fk"; then
      echo "ERROR: forbidden key detected in manifest: $fk" >&2
      errors=$((errors+1))
    fi
  done

  checksum_val="$(yq eval '.checksum' "$manifest_file")"
else
  # Lightweight fallback parser (best-effort)
  echo "WARNING: 'yq' not found; running lightweight YAML checks (less strict)" >&2
  for k in "${required_keys[@]}"; do
    if ! grep -E -qi "^\s*${k}:" "$manifest_file"; then
      echo "ERROR: missing required key (fallback): $k" >&2
      errors=$((errors+1))
    fi
  done
# Check checksum file existence if it looks like a path
if [ -n "$checksum_val" ] && [ "$checksum_val" != "null" ]; then
  # trim quotes/spaces
  checksum_val="$(echo "$checksum_val" | sed -E 's/^\s+|\s+$//g' | tr -d '"')"
  if [[ "$checksum_val" == */* ]] || [[ "$checksum_val" == *.sha256 ]] || [[ "$checksum_val" == *.sha512 ]] || [[ "$checksum_val" == *.md5 ]]; then
    checksum_path="$manifest_dir/$checksum_val"
    if [ ! -f "$checksum_path" ]; then
      if [ "$strict_mode" -eq 1 ]; then
        echo "ERROR: checksum file not found (strict mode): $checksum_path" >&2
        errors=$((errors+1))
      else
        echo "WARNING: checksum file referenced but not found: $checksum_path" >&2
        warnings=$((warnings+1))
      fi
    else
      echo "Found checksum file: $checksum_path"
    fi
  fi
fichecksum_val="$(echo "$checksum_val" | sed -E 's/^\s+|\s+$//g' | tr -d '"')"
  if [[ "$checksum_val" == */* ]] || [[ "$checksum_val" == *.sha256 ]] || [[ "$checksum_val" == *.sha512 ]] || [[ "$checksum_val" == *.md5 ]]; then
    checksum_path="$manifest_dir/$checksum_val"
    if [ ! -f "$checksum_path" ]; then
      echo "WARNING: checksum file referenced but not found: $checksum_path" >&2
      warnings=$((warnings+1))
    else
      echo "Found checksum file: $checksum_path"
    fi
  fi
fi

if [ "$errors" -gt 0 ]; then
  echo "Manifest validation failed with $errors error(s)." >&2
  exit 3
fi

echo "Manifest validation passed: $manifest_file"
if [ "$warnings" -gt 0 ]; then
  echo "Validation completed with $warnings warning(s)."
fi
exit 0
