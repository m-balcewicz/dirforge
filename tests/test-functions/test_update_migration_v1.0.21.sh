#!/usr/bin/env bash
# Migration path tests for dirforge update
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DIRFORGE="$REPO_ROOT/tools/dirforge"
FIXTURES_DIR="$SCRIPT_DIR/fixtures"

TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT

# Test: JOURNAL_WORLD v1.0.20 -> v1.0.21
cp -a "$FIXTURES_DIR/journal_v1.0.20" "$TEST_ROOT/journal_migrate"
cd "$TEST_ROOT/journal_migrate"
bash "$DIRFORGE" update > update.log
[ -d 00_admin ] && [ -d 01_primary_authorship ] && [ -d 02_coauthor_invites ] && [ -d 03_journal_service ]

# Test: RESEARCH_WORLD v1.0.16 -> v1.0.17
cp -a "$FIXTURES_DIR/research_v1.0.16" "$TEST_ROOT/research_migrate"
cd "$TEST_ROOT/research_migrate"
bash "$DIRFORGE" update > update.log
[ -d 02_studies ]

echo "All migration path tests passed."
