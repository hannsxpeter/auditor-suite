#!/usr/bin/env bash
# sync-shared.sh: copy the shared core into every skill.
#
# The canonical shared core lives in shared/scripts, shared/references, and
# shared/assets. Each skill carries byte-identical copies in its own
# scripts/, references/, and assets/ folders so it works standalone, from a
# symlinked install or a plugin cache alike. Edit the shared copy, run this
# script, then verify with: bash scripts/lint.sh shared-sync
#
# Bash 3.2 compatible.

set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILLS="codeauditor secauditor dbauditor llmauditor seoauditor uiauditor uxauditor"

for s in $SKILLS; do
  if [ ! -d "$ROOT/skills/$s" ]; then
    printf "missing skill directory: skills/%s\n" "$s" >&2
    exit 1
  fi
  for sub in scripts references assets; do
    [ -d "$ROOT/shared/$sub" ] || continue
    mkdir -p "$ROOT/skills/$s/$sub"
    for f in "$ROOT/shared/$sub"/*; do
      [ -f "$f" ] || continue
      cp -p "$f" "$ROOT/skills/$s/$sub/$(basename "$f")"
    done
  done
  chmod +x "$ROOT/skills/$s/scripts/"*.sh
  printf "synced %s\n" "$s"
done

printf "done. verify with: bash scripts/lint.sh shared-sync\n"
