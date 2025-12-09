#!/usr/bin/env bash
set -euo pipefail

echo "Running bash -n syntax checks..."
ret=0

# Find shell scripts and the main tools/dirforge script
while IFS= read -r -d '' file; do
  echo "Checking syntax: $file"
  if ! bash -n "$file" 2>/dev/null; then
    echo "Syntax error in $file"
    ret=1
  fi
done < <(find . -type f \( -name '*.sh' -o -path './tools/dirforge' \) -print0)

if command -v shellcheck >/dev/null 2>&1; then
  echo "Running shellcheck..."
  # shellcheck can accept multiple files; limit to *.sh
  files=$(find . -type f -name '*.sh' -print | tr '\n' ' ')
  if [ -n "$files" ]; then
    shellcheck -x $files || ret=1
  fi
else
  echo "shellcheck not found; skipping shellcheck (install shellcheck for stricter linting)"
fi

exit $ret
