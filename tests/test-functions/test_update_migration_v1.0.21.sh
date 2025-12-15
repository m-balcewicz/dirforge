#!/usr/bin/env bash
# Migration path tests for dirforge update
set -euo pipefail

TEST_ROOT="$(dirname "$0")/dirforge_test_workspace_$$"
mkdir -p "$TEST_ROOT"
trap 'rm -rf "$TEST_ROOT"' EXIT

# Test: JOURNAL_WORLD v1.0.20 -> v1.0.21
cp -a "$TEST_ROOT/../fixtures/journal_v1.0.20" "$TEST_ROOT/journal_migrate"
cd "$TEST_ROOT/journal_migrate"
../../../tools/dirforge update > update.log
[ -d 00_admin ] && [ -d 01_primary_authorship ] && [ -d 02_coauthor_invites ] && [ -d 03_journal_service ]

# Test: RESEARCH_WORLD v1.0.16 -> v1.0.17
cp -a "$TEST_ROOT/../fixtures/research_v1.0.16" "$TEST_ROOT/research_migrate"
cd "$TEST_ROOT/research_migrate"
../../../tools/dirforge update > update.log
[ -d 02_studies ]

echo "All migration path tests passed."
