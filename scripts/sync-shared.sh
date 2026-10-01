#!/usr/bin/env bash
# sync-shared.sh: copy the shared core into every skill.
#
# The canonical shared core lives in shared/scripts, shared/references, and
# shared/assets. Each skill carries byte-identical copies in its own
# scripts/, references/, and assets/ folders so it works standalone, from a
# symlinked install or a plugin cache alike. Edit the shared copy, run this
# script, then verify with: bash scripts/lint.sh shared-sync
#
# The skills are every directory under skills/ (scripts/_skills.sh). A skill's
# scripts/ holds only the shared core: a file there with no counterpart in
# shared/scripts/ is reported, not deleted, and lint shared-sync fails on it.
#
# Bash 3.2 compatible.

set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$ROOT/scripts/_skills.sh"

if [ -n "$SKILLS_INVALID" ]; then
  printf "skills/ holds directories that are not valid skill names (use lower-case letters, digits, and hyphens):\n%s" "$SKILLS_INVALID" >&2
  exit 1
fi
if [ -z "$SKILLS" ]; then
  printf "no skill directories under %s/skills\n" "$ROOT" >&2
  exit 1
fi
for s in $SKILLS; do
  if [ ! -f "$ROOT/skills/$s/SKILL.md" ]; then
    printf "skills/%s has no SKILL.md; add it, or remove the directory, before syncing\n" "$s" >&2
    exit 1
  fi
done

for s in $SKILLS; do
  for sub in scripts references assets; do
    [ -d "$ROOT/shared/$sub" ] || continue
    mkdir -p "$ROOT/skills/$s/$sub"
    for f in "$ROOT/shared/$sub"/*; do
      [ -f "$f" ] || continue
      cp -p "$f" "$ROOT/skills/$s/$sub/$(basename "$f")"
    done
  done
  chmod +x "$ROOT/skills/$s/scripts/"*.sh
  for f in "$ROOT/skills/$s/scripts"/*; do
    [ -e "$f" ] || continue
    [ -e "$ROOT/shared/scripts/$(basename "$f")" ] || printf "warning: skills/%s/scripts/%s is not in shared/scripts/; delete it, or move it into shared/scripts/ and sync again\n" "$s" "$(basename "$f")" >&2
  done
  printf "synced %s\n" "$s"
done

printf "done. verify with: bash scripts/lint.sh shared-sync\n"
