#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." >/dev/null 2>&1 && pwd)"
DIRFORGE="$REPO_ROOT/tools/dirforge"

if [ ! -x "$DIRFORGE" ]; then
  echo "dirforge not executable at $DIRFORGE" >&2
  exit 1
fi

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT
pushd "$TMPDIR" >/dev/null

for LANG in python matlab fortran bash; do
  PROJ="test_${LANG}"
  echo "Testing dry-run JSON for $LANG"
  OUT="$("$DIRFORGE" --dry-run --json init coding --language $LANG --project $PROJ --no-conda --no-git 2>&1)" || true
  # Look for the expected CODING_WORLD path in the JSON output
  EXPECT="CODING_WORLD/$LANG/$PROJ"
  echo "$OUT" | grep -F "$EXPECT" >/dev/null || {
    echo "FAILED: dry-run JSON did not contain expected path: $EXPECT" >&2
    echo "Output was:" >&2
    echo "$OUT" >&2
    exit 2
  }
  echo "  -> ok: $EXPECT present"
done

popd >/dev/null

echo "OK: coding dry-run JSON produced expected language project paths"
