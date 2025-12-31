#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." >/dev/null 2>&1 && pwd)"
DIRFORGE="$REPO_ROOT/tools/dirforge"

if [ ! -x "$DIRFORGE" ]; then
  echo "dirforge not executable at $DIRFORGE" >&2
  exit 1
fi

OUT="$("$DIRFORGE" create coding --help 2>&1)"

# Ensure each language is mentioned in the help text
for LANG in python matlab fortran bash; do
  echo "$OUT" | grep -i "$LANG" >/dev/null || {
    echo "FAILED: help output does not mention language: $LANG" >&2
    exit 2
  }
done

echo "OK: coding help includes supported languages"
