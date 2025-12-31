#!/usr/bin/env bash

# Comprehensive Test Update Script
# Converts all deprecated init syntax to create syntax

set -euo pipefail

cd "/Users/martin/Documents/CODING_WORLD/bash/dirforge"

echo "🔄 Updating all test files with deprecated syntax..."

# Define the replacements as arrays for better handling
declare -a search_patterns=(
  "run_dirforge init journal"
  "run_dirforge init research"  
  "run_dirforge init coding"
  "run_dirforge init lecture"
  "run_dirforge --dry-run init journal"
  "run_dirforge --dry-run init research"
  "run_dirforge --dry-run init coding"
  "run_dirforge --dry-run init lecture"
  "run_dirforge --preview init journal"
  "run_dirforge --preview init research"
  "run_dirforge --preview init coding"
  "run_dirforge --preview init lecture"
  "\"\$DIRFORGE\" --dry-run --json init coding"
  "\"\$DIRFORGE\" --dry-run init research"
  "\"\$DIRFORGE\" --preview init lecture"
  "dirforge init journal"
  "dirforge init research"
  "dirforge init coding"
  "dirforge init lecture"
)

declare -a replacement_patterns=(
  "run_dirforge create journal"
  "run_dirforge create research"
  "run_dirforge create coding"
  "run_dirforge create lecture"
  "run_dirforge --dry-run create journal"
  "run_dirforge --dry-run create research"
  "run_dirforge --dry-run create coding"
  "run_dirforge --dry-run create lecture"
  "run_dirforge --preview create journal"
  "run_dirforge --preview create research"
  "run_dirforge --preview create coding"
  "run_dirforge --preview create lecture"
  "\"\$DIRFORGE\" --dry-run --json create coding"
  "\"\$DIRFORGE\" --dry-run create research"
  "\"\$DIRFORGE\" --preview create lecture"
  "dirforge create journal"
  "dirforge create research"
  "dirforge create coding"
  "dirforge create lecture"
)

# Get list of files to update (exclude v1.1.0 and backward compatibility tests)
files_to_update=()
while IFS= read -r -d '' file; do
  if [[ "$file" != *"v1.1.0"* ]] && [[ "$file" != *"backward_compat"* ]]; then
    files_to_update+=("$file")
  fi
done < <(find tests/test-functions -name "test_*.sh" -print0)

# Update each file
for file in "${files_to_update[@]}"; do
  echo "  📝 Processing $(basename "$file")..."
  
  # Apply all replacements
  for i in "${!search_patterns[@]}"; do
    sed -i '' "s|${search_patterns[$i]}|${replacement_patterns[$i]}|g" "$file"
  done
done

echo ""
echo "🔍 Verification - checking for remaining deprecated syntax..."

# Check for remaining instances
total_remaining=0
for file in "${files_to_update[@]}"; do
  count=$(grep -c "init journal\|init research\|init coding\|init lecture" "$file" 2>/dev/null || echo 0)
  if [ "$count" -gt 0 ]; then
    echo "  ⚠️  $(basename "$file"): $count instances remaining"
    total_remaining=$((total_remaining + count))
  fi
done

if [ "$total_remaining" -eq 0 ]; then
  echo "  ✅ All files successfully updated!"
else
  echo "  ❌ $total_remaining instances still found"
  echo ""
  echo "Investigating remaining instances..."
  for file in "${files_to_update[@]}"; do
    count=$(grep -c "init journal\|init research\|init coding\|init lecture" "$file" 2>/dev/null || echo 0)
    if [ "$count" -gt 0 ]; then
      echo ""
      echo "File: $(basename "$file")"
      grep -n "init journal\|init research\|init coding\|init lecture" "$file" | head -3
    fi
  done
fi