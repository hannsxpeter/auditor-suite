#!/usr/bin/env bash
# uninstall.sh: remove auditor-suite symlinks from every detected harness.
#
# - Removes only symlinks that point into the auditor-suite hub
#   (skills/<skill>/) or into the legacy ~/Projects/<skill>/ layout: the
#   per-item links install.sh makes, and a whole-folder link to a skill
#   (the by-hand install). Removes a link itself, never what it points to.
# - Covers every skills/<skill>/ in this repo that holds a SKILL.md.
# - Leaves dev copies, ~/.auditor-suite-backups/, and any older
#   *.backup-<timestamp>/ directories alone.
# - Covers Claude Code ($CLAUDE_CONFIG_DIR, else ~/.claude), Codex
#   ($CODEX_HOME, else ~/.codex), Cursor, plus the neutral Agent Skills
#   path at ~/.agents/skills/ used by pi and OpenClaw.
# - Bash 3.2 compatible.

set -eu
unset CDPATH

VERBOSE=0
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HUB_DIR="$SCRIPT_DIR"
SKILLS_DIR="$HUB_DIR/skills"
LEGACY_PROJECTS_DIR="$HOME/Projects"
BACKUP_ROOT="$HOME/.auditor-suite-backups"

PLATFORM_NAMES="Claude_Code Codex Cursor Agent_Skills"

if [ -t 1 ]; then
  C_RESET="$(printf '\033[0m')"; C_BOLD="$(printf '\033[1m')"; C_DIM="$(printf '\033[2m')"
  C_GREEN="$(printf '\033[32m')"; C_YELLOW="$(printf '\033[33m')"; C_RED="$(printf '\033[31m')"
else
  C_RESET=""; C_BOLD=""; C_DIM=""; C_GREEN=""; C_YELLOW=""; C_RED=""
fi

usage() {
  cat <<EOF
auditor-suite uninstaller

Usage: uninstall.sh [-v] [-h]

Removes auditor-suite symlinks from Claude Code, Codex, Cursor, and the
neutral Agent Skills path (~/.agents/skills/) read by pi and OpenClaw.
Claude Code and Codex honor CLAUDE_CONFIG_DIR and CODEX_HOME.
Does not delete dev copies in ~/Projects/ or any backup directories.
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    -v|--verbose) VERBOSE=1 ;;
    -h|--help) usage; exit 0 ;;
    *) printf "%sunknown flag: %s%s\n" "$C_RED" "$1" "$C_RESET" >&2; exit 2 ;;
  esac
  shift
done

ok()    { printf "  %sok%s    %s\n" "$C_GREEN" "$C_RESET" "$*"; }
warn()  { printf "  %swarn%s  %s\n" "$C_YELLOW" "$C_RESET" "$*"; }
vstep() { [ "$VERBOSE" = "1" ] && printf "  %s..%s    %s\n" "$C_DIM" "$C_RESET" "$*" || true; }

# Every skills/<skill>/ that holds a SKILL.md, the same list install.sh uses.
SKILLS=""
for f in "$SKILLS_DIR"/*/SKILL.md; do
  [ -f "$f" ] || continue
  skill="${f%/SKILL.md}"
  SKILLS="$SKILLS ${skill##*/}"
done
if [ -z "$SKILLS" ]; then
  printf "%sno skills/<skill>/SKILL.md found under %s%s\n" "$C_RED" "$SKILLS_DIR" "$C_RESET" >&2
  printf "Run uninstall.sh from inside an auditor-suite clone.\n" >&2
  exit 1
fi

# The skills dir for a platform name, the same mapping install.sh uses.
platform_dir_for() {
  case "$1" in
    Claude_Code)  printf '%s' "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills" ;;
    Codex)        printf '%s' "${CODEX_HOME:-$HOME/.codex}/skills" ;;
    Cursor)       printf '%s' "$HOME/.cursor/skills" ;;
    Agent_Skills) printf '%s' "$HOME/.agents/skills" ;;
    *) return 1 ;;
  esac
}

platform_label_for() {
  local name
  name="$1"
  case "$name" in
    Agent_Skills) printf "Agent Skills" ;;
    *) printf '%s' "$name" | tr '_' ' ' ;;
  esac
}

# Detect a platform as present if its skills dir exists. For Agent_Skills,
# also detect when ~/.pi or ~/.openclaw exists (so we still walk the
# skills dir to clean it if the harness markers are present).
platform_present() {
  local name pdir
  name="$1"
  pdir="$(platform_dir_for "$name")"
  case "$name" in
    Agent_Skills)
      if [ -d "$pdir" ] || [ -d "$HOME/.pi" ] || [ -d "$HOME/.openclaw" ]; then
        return 0
      fi
      return 1
      ;;
    *)
      if [ -d "$(dirname "$pdir")" ]; then
        return 0
      fi
      return 1
      ;;
  esac
}

# Physical path (every symlink resolved) of an existing directory, or nothing.
phys_dir() { (cd "$1" 2>/dev/null && pwd -P) || true; }

# True when the existing directory $1 is the directory $2 or lies inside
# it, the same check install.sh uses. Walks up from $1's physical path and
# compares each step with $2 by identity (test -ef), never by path string:
# pwd -P keeps the letter case it was given on a case-insensitive disk and
# keeps a /System/Volumes/Data firmlink spelling.
dir_within() {
  local d
  d="$(phys_dir "$1")"
  while [ -n "$d" ]; do
    if [ "$d" -ef "$2" ]; then return 0; fi
    if [ "$d" = "/" ]; then return 1; fi
    d="${d%/*}"
    [ -n "$d" ] || d="/"
  done
  return 1
}

# True when the existing directory $1 is this repo or lies inside it.
in_hub() { dir_within "$1" "$HUB_DIR"; }

# True when the symlink $1, whose target is $2, points into this hub's
# skills/ or the legacy ~/Projects/<skill>/ layout. The string match also
# catches a link whose target is gone; the identity match catches a hub
# reached through another path (a symlinked ~/Projects, /tmp versus
# /private/tmp, another letter case, /System/Volumes/Data).
points_into_suite() {
  local link target dir
  link="$1"
  target="$2"
  case "$target" in
    "$SKILLS_DIR"/*|"$LEGACY_PROJECTS_DIR"/*) return 0 ;;
  esac
  [ -e "$link" ] || return 1
  if [ -d "$link" ]; then
    dir="$link"
  else
    # The folder that holds the link's target.
    dir="$(cd "$(dirname "$link")" 2>/dev/null && cd "$(dirname "$target")" 2>/dev/null && pwd -P || true)"
    [ -n "$dir" ] || return 1
  fi
  if dir_within "$dir" "$SKILLS_DIR"; then
    return 0
  fi
  return 1
}

REMOVED=0
KEPT=0
EMPTY_DIRS=0

remove_link() {
  local path target
  path="$1"
  if [ -L "$path" ]; then
    target="$(readlink "$path" 2>/dev/null || true)"
    if points_into_suite "$path" "$target"; then
      rm -f "$path"
      REMOVED=$((REMOVED + 1))
      return 0
    fi
    warn "skipped (foreign symlink): $path -> $target"
    KEPT=$((KEPT + 1))
    return 1
  elif [ -e "$path" ]; then
    warn "skipped (not a symlink): $path"
    KEPT=$((KEPT + 1))
    return 1
  fi
  return 0
}

printf "\n%sauditor-suite uninstaller%s\n\n" "$C_BOLD" "$C_RESET"

for name in $PLATFORM_NAMES; do
  if ! platform_present "$name"; then
    vstep "$name not detected; skipping"
    continue
  fi
  pdir="$(platform_dir_for "$name")"
  label="$(platform_label_for "$name")"
  printf "%s%s%s\n" "$C_BOLD" "$label" "$C_RESET"
  # A skills dir that resolves into the hub (a link to skills/, under any
  # spelling of the hub's path) holds the hub's own files; never remove
  # anything there.
  if [ -d "$pdir" ] && in_hub "$pdir"; then
    warn "skipped: $pdir resolves inside the hub at $HUB_DIR"
    printf "\n"
    continue
  fi
  for skill in $SKILLS; do
    sdir="$pdir/$skill"
    if [ -L "$sdir" ]; then
      # A whole-folder link: remove the link itself (no trailing slash),
      # never what it points to.
      if remove_link "$sdir"; then
        ok "$skill removed (folder link)"
      fi
      continue
    fi
    if [ ! -d "$sdir" ]; then
      vstep "$skill: nothing to remove"
      continue
    fi
    for item in SKILL.md references scripts assets; do
      remove_link "$sdir/$item" || true
    done
    # If the skill dir is now empty, remove it. Otherwise leave it.
    if [ -z "$(ls -A "$sdir" 2>/dev/null)" ]; then
      rmdir "$sdir"
      EMPTY_DIRS=$((EMPTY_DIRS + 1))
      ok "$skill removed"
    else
      warn "$skill: directory not empty, kept"
    fi
  done
  printf "\n"
done

printf "%ssummary%s\n" "$C_BOLD" "$C_RESET"
printf "  %s%d symlinks removed%s, %d skill dirs cleaned\n" "$C_GREEN" "$REMOVED" "$C_RESET" "$EMPTY_DIRS"
if [ "$KEPT" -gt 0 ]; then
  printf "  %s%d items kept%s (foreign symlinks or non-symlinks)\n" "$C_YELLOW" "$KEPT" "$C_RESET"
fi
printf "\nIn-tree skills under %s, backups in %s, and any older *.backup-*/ dirs are untouched.\n\n" "$SKILLS_DIR" "$BACKUP_ROOT"
