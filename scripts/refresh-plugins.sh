#!/usr/bin/env bash
# refresh-plugins.sh: re-vendor the canonical skill payload into the Claude
# Code plugin packaging under plugins/<skill>/skills/<skill>/.
#
# The payload is what a harness needs at runtime: SKILL.md, references/,
# scripts/, and assets/. README, CHANGELOG, LICENSE, and evals stay in the
# canonical tree only. The canonical source of truth is skills/<skill>/, and
# the skills are every directory under skills/ (scripts/_skills.sh).
#
# Runs scripts/sync-shared.sh first so the shared core is current, then copies
# the payload. Verify with: bash scripts/lint.sh plugin-sync
#
# Bash 3.2 compatible.

set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$ROOT/scripts/_skills.sh"
PAYLOAD="SKILL.md references scripts assets"

"${BASH:-bash}" "$ROOT/scripts/sync-shared.sh" > /dev/null

for s in $SKILLS; do
  src="$ROOT/skills/$s"
  dst="$ROOT/plugins/$s/skills/$s"
  if [ ! -f "$src/SKILL.md" ]; then
    printf "missing canonical skill: %s/SKILL.md\n" "$src" >&2
    exit 1
  fi
  mkdir -p "$dst"
  for item in $PAYLOAD; do
    rm -rf "$dst/$item"
    if [ -e "$src/$item" ]; then
      cp -Rp "$src/$item" "$dst/$item"
    fi
  done
  printf "refreshed %s\n" "$s"
done

printf "done. verify with: bash scripts/lint.sh plugin-sync\n"
