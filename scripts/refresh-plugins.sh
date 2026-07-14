#!/usr/bin/env bash
# refresh-plugins.sh: re-vendor the canonical skill content into the Claude
# Code plugin packaging under plugins/<skill>/skills/<skill>/SKILL.md.
#
# The canonical source of truth is skills/<skill>/SKILL.md. Run this after any
# canonical skill change, then verify with: bash scripts/lint.sh plugin-sync
#
# Bash 3.2 compatible.

set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILLS="codeauditor secauditor dbauditor llmauditor seoauditor uiauditor uxauditor"

for s in $SKILLS; do
  src="$ROOT/skills/$s/SKILL.md"
  dst_dir="$ROOT/plugins/$s/skills/$s"
  if [ ! -f "$src" ]; then
    printf "missing canonical skill: %s\n" "$src" >&2
    exit 1
  fi
  mkdir -p "$dst_dir"
  cp "$src" "$dst_dir/SKILL.md"
  printf "refreshed %s\n" "$s"
done

printf "done. verify with: bash scripts/lint.sh plugin-sync\n"
