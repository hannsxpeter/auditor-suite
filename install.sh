#!/usr/bin/env bash
# install.sh: install the auditor-suite into every detected harness.
#
# - Reads skills from this repo's skills/<skill>/ directory (in-tree;
#   no per-skill clone needed). Every skills/<skill>/ that holds a
#   SKILL.md is installed, so a new auditor needs no edit here.
# - Detects native-skill harnesses by their config directories:
#     Claude Code  -> $CLAUDE_CONFIG_DIR, else ~/.claude -> writes <dir>/skills/<skill>/
#     Codex        -> $CODEX_HOME, else ~/.codex         -> writes <dir>/skills/<skill>/
#     Cursor       -> ~/.cursor        -> writes ~/.cursor/skills/<skill>/
#     Agent Skills -> ~/.agents        -> writes ~/.agents/skills/<skill>/
#     pi           -> ~/.pi            -> via the neutral Agent Skills path
#     OpenClaw     -> ~/.openclaw      -> via the neutral Agent Skills path
# - Writes the neutral ~/.agents/skills/<skill>/ path when ~/.agents, pi,
#   or OpenClaw is present. pi and OpenClaw read this path natively per
#   the Agent Skills standard at agentskills.io, as does any other
#   AgentSkills-compatible harness that reads ~/.agents/skills/.
# - For each auditor, symlinks the runtime payload from skills/<skill>/
#   into every detected harness: SKILL.md plus the references/, scripts/,
#   and assets/ folders the skill reads and runs.
# - Never moves or deletes anything inside this repo, however its path is
#   spelled (directories are compared by identity, not by path string). A
#   folder link into this repo's skills/ (the by-hand install) and a
#   dangling link are replaced by a fresh folder of links; only the link
#   is removed. A skill folder holding real files, or a link to somewhere
#   else, is moved whole to
#   ~/.auditor-suite-backups/<platform>/<skill>-<timestamp>, outside every
#   harness skills dir, so it cannot load as a duplicate. A moved link is
#   re-made there with an absolute target, so it still opens what it did.
# - Exits non-zero when any skill fails to install into any harness.
# - Idempotent. Re-run anytime.
# - Bash 3.2 compatible (macOS default). No associative arrays.
#
# Usage:
#   git clone https://github.com/hannsxpeter/auditor-suite && bash auditor-suite/install.sh
#   or run from inside an existing clone: bash install.sh
#
# Flags:
#   -v   verbose (show skipped-because-correct steps)
#   -h   help

set -eu
unset CDPATH

VERBOSE=0
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HUB_DIR="$SCRIPT_DIR"
SKILLS_DIR="$HUB_DIR/skills"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_ROOT="$HOME/.auditor-suite-backups"

# The runtime payload each skill needs. The skills themselves are every
# skills/<skill>/ that holds a SKILL.md; see SKILLS below.
PAYLOAD="SKILL.md references scripts assets"

# Platforms by name; platform_dir_for maps each to its skills dir.
# Agent_Skills is the neutral Agent Skills standard path read by pi,
# OpenClaw, and any other AgentSkills-compatible harness.
PLATFORM_NAMES="Claude_Code Codex Cursor Agent_Skills"

# ANSI colors only when stdout is a TTY.
if [ -t 1 ]; then
  C_RESET="$(printf '\033[0m')"
  C_BOLD="$(printf '\033[1m')"
  C_DIM="$(printf '\033[2m')"
  C_GREEN="$(printf '\033[32m')"
  C_YELLOW="$(printf '\033[33m')"
  C_RED="$(printf '\033[31m')"
  C_CYAN="$(printf '\033[36m')"
else
  C_RESET=""; C_BOLD=""; C_DIM=""; C_GREEN=""; C_YELLOW=""; C_RED=""; C_CYAN=""
fi

usage() {
  cat <<EOF
auditor-suite installer

Usage: install.sh [-v] [-h]

  -v   verbose output
  -h   show this help

Detects Claude Code, Codex, Cursor, pi, OpenClaw, and ~/.agents; installs
every auditor-suite skill (each skills/<skill>/ with a SKILL.md) into every
detected harness via symlinks to each skill's SKILL.md, references/,
scripts/, and assets/ in this repo. Claude Code and Codex honor
CLAUDE_CONFIG_DIR and CODEX_HOME. pi, OpenClaw, and ~/.agents are served
via the neutral Agent Skills path at ~/.agents/skills/. An existing skill
folder that holds real files is first moved to
~/.auditor-suite-backups/<platform>/<skill>-<timestamp>/.
Exits non-zero when any skill fails to install.
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    -v|--verbose) VERBOSE=1 ;;
    -h|--help) usage; exit 0 ;;
    *) printf "%sunknown flag: %s%s\n" "$C_RED" "$1" "$C_RESET" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

log()   { printf "%s\n" "$*"; }
info()  { printf "%s%s%s\n" "$C_DIM" "$*" "$C_RESET"; }
ok()    { printf "  %sok%s    %s\n" "$C_GREEN" "$C_RESET" "$*"; }
warn()  { printf "  %swarn%s  %s\n" "$C_YELLOW" "$C_RESET" "$*"; }
err()   { printf "  %sfail%s  %s\n" "$C_RED" "$C_RESET" "$*"; }
step()  { printf "  %s..%s    %s\n" "$C_CYAN" "$C_RESET" "$*"; }
vstep() { [ "$VERBOSE" = "1" ] && printf "  %s..%s    %s\n" "$C_DIM" "$C_RESET" "$*" || true; }

# The skills dir for a platform name. Every path stays quoted end to end,
# so a HOME with a space works.
platform_dir_for() {
  case "$1" in
    Claude_Code)  printf '%s' "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills" ;;
    Codex)        printf '%s' "${CODEX_HOME:-$HOME/.codex}/skills" ;;
    Cursor)       printf '%s' "$HOME/.cursor/skills" ;;
    Agent_Skills) printf '%s' "$HOME/.agents/skills" ;;
    *) return 1 ;;
  esac
}

# Human label for a platform name.
platform_label_for() {
  local name markers
  name="$1"
  case "$name" in
    Agent_Skills)
      markers=""
      [ -d "$HOME/.pi" ] && markers="pi"
      if [ -d "$HOME/.openclaw" ]; then
        if [ -n "$markers" ]; then markers="$markers, OpenClaw"; else markers="OpenClaw"; fi
      fi
      if [ -n "$markers" ]; then
        printf "Agent Skills (%s)" "$markers"
      else
        printf "Agent Skills"
      fi
      ;;
    *)
      printf '%s' "$name" | tr '_' ' '
      ;;
  esac
}

# Detection: a harness is present when the parent of its skills dir exists.
# The neutral path is also written when pi or OpenClaw is present.
DETECTED_PLATFORMS=""
for name in $PLATFORM_NAMES; do
  dir="$(platform_dir_for "$name")"
  parent="$(dirname "$dir")"
  case "$name" in
    Agent_Skills)
      if [ -d "$parent" ] || [ -d "$HOME/.pi" ] || [ -d "$HOME/.openclaw" ]; then
        DETECTED_PLATFORMS="$DETECTED_PLATFORMS $name"
      fi
      ;;
    *)
      if [ -d "$parent" ]; then
        DETECTED_PLATFORMS="$DETECTED_PLATFORMS $name"
      fi
      ;;
  esac
done

if [ -z "$DETECTED_PLATFORMS" ]; then
  printf "%sNo Claude Code, Codex, Cursor, Agent Skills, pi, or OpenClaw install detected.%s\n" "$C_RED" "$C_RESET" >&2
  printf "Expected one of ~/.claude (or \$CLAUDE_CONFIG_DIR), ~/.codex (or \$CODEX_HOME), ~/.cursor, ~/.agents, ~/.pi, ~/.openclaw.\n" >&2
  exit 1
fi

if [ ! -d "$SKILLS_DIR" ]; then
  printf "%sskills/ directory not found at %s%s\n" "$C_RED" "$SKILLS_DIR" "$C_RESET" >&2
  printf "Run install.sh from inside an auditor-suite clone.\n" >&2
  exit 1
fi

# Every skills/<skill>/ that holds a SKILL.md, so a new auditor installs
# with no edit here.
SKILLS=""
for f in "$SKILLS_DIR"/*/SKILL.md; do
  [ -f "$f" ] || continue
  skill="${f%/SKILL.md}"
  SKILLS="$SKILLS ${skill##*/}"
done
if [ -z "$SKILLS" ]; then
  printf "%sno skills/<skill>/SKILL.md found under %s%s\n" "$C_RED" "$SKILLS_DIR" "$C_RESET" >&2
  exit 1
fi

# Physical path (every symlink resolved) of an existing directory, or
# nothing.
phys_dir() { (cd "$1" 2>/dev/null && pwd -P) || true; }

# True when the existing directory $1 is the directory $2 or lies inside
# it. Walks up from $1's physical path and compares each step with $2 by
# identity (test -ef: same device and inode), never by path string: pwd -P
# keeps the letter case it was given on a case-insensitive disk and keeps
# a /System/Volumes/Data firmlink spelling, so two strings can name one
# directory. This also covers a symlinked ~/Projects and /tmp versus
# /private/tmp.
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

log ""
printf "%sauditor-suite installer%s\n" "$C_BOLD" "$C_RESET"
log ""
info "skills dir   : $SKILLS_DIR"
detected_label=""
for n in $DETECTED_PLATFORMS; do
  detected_label="$detected_label, $(platform_label_for "$n")"
done
detected_label="${detected_label#, }"
info "platforms    : $detected_label"
log ""

INSTALLED_COUNT=0
FAILED_COUNT=0
PLATFORM_LINK_COUNT=0

# Move an existing skill entry (a folder, or a link but never what it
# points to) to ~/.auditor-suite-backups/<platform>/<skill>-<timestamp>,
# outside every harness skills dir. A link is re-made there with an
# absolute target, so a relative link still opens what it did, and then
# the original link is removed.
backup_entry() {
  local path platform skill dest n where target base
  path="$1"
  platform="$2"
  skill="$3"
  # Defense in depth: never move anything that lies inside the hub.
  if [ ! -L "$path" ]; then
    where="$path"
    [ -d "$where" ] || where="$(dirname "$path")"
    if in_hub "$where"; then
      err "$skill: $path is inside the hub; not moving it"
      return 1
    fi
  fi
  dest="$BACKUP_ROOT/$platform/$skill-$TIMESTAMP"
  n=1
  while [ -e "$dest" ] || [ -L "$dest" ]; do
    n=$((n + 1))
    dest="$BACKUP_ROOT/$platform/$skill-$TIMESTAMP-$n"
  done
  if ! mkdir -p "$BACKUP_ROOT/$platform"; then
    err "$skill: could not create $BACKUP_ROOT/$platform"
    return 1
  fi
  if [ -L "$path" ]; then
    target="$(readlink "$path" 2>/dev/null || true)"
    case "$target" in
      "")
        err "$skill: could not read the link $path"
        return 1
        ;;
      /*) ;;
      *)
        # A relative target resolves from the folder that holds the link.
        base="$(phys_dir "$(dirname "$path")")"
        if [ -z "$base" ]; then
          err "$skill: could not resolve the folder of $path"
          return 1
        fi
        target="$base/$target"
        ;;
    esac
    if ! ln -s "$target" "$dest"; then
      err "$skill: could not link $dest to $target"
      return 1
    fi
    if ! rm "$path"; then
      rm -f "$dest"
      err "$skill: could not remove the link $path"
      return 1
    fi
  elif ! mv "$path" "$dest"; then
    err "$skill: could not move $path to $dest"
    return 1
  fi
  warn "backed up existing $path -> $dest"
  return 0
}

# Symlink one item from src to dst. A real file or folder at dst is never
# moved here: install_skill_into_platform backs up its whole folder first.
link_item() {
  local src dst label current
  src="$1"
  dst="$2"
  label="$3"
  if [ ! -e "$src" ]; then
    err "missing source: $src"
    return 1
  fi
  if [ -L "$dst" ]; then
    current="$(readlink "$dst" 2>/dev/null || true)"
    if [ "$current" = "$src" ]; then
      vstep "$label already linked"
      return 0
    fi
    if ! rm -f "$dst"; then
      err "could not remove the old link $dst"
      return 1
    fi
  elif [ -e "$dst" ]; then
    err "$dst exists and is not a link; left in place"
    return 1
  fi
  if ! ln -s "$src" "$dst"; then
    err "could not link $label into $(dirname "$dst")"
    return 1
  fi
  return 0
}

install_skill_into_platform() {
  local skill platform_name platform_dir src dst_dir item p
  skill="$1"
  platform_name="$2"
  platform_dir="$3"
  src="$SKILLS_DIR/$skill"
  dst_dir="$platform_dir/$skill"

  if [ ! -f "$src/SKILL.md" ]; then
    err "$skill: SKILL.md missing at $src/SKILL.md"
    return 1
  fi

  # Never write inside the hub. A skills dir that resolves into it (a link
  # to skills/, under any spelling of the hub's path) already serves the
  # skill; anything else there is refused.
  p="$platform_dir"
  [ -d "$p" ] || p="$(dirname "$platform_dir")"
  if in_hub "$p"; then
    if [ "$dst_dir" -ef "$src" ]; then
      vstep "$skill is served directly from the hub"
      return 0
    fi
    err "$skill: $platform_dir resolves inside the hub; not writing there"
    return 1
  fi

  if [ -L "$dst_dir" ]; then
    # A whole-folder link. Remove or move the link itself, never what it
    # points to (no trailing slash on dst_dir). A link into this repo's
    # skills/, under any spelling of its path, is the by-hand install.
    if [ -d "$dst_dir" ] && dir_within "$dst_dir" "$SKILLS_DIR"; then
      if ! rm "$dst_dir"; then
        err "$skill: could not remove the folder link $dst_dir"
        return 1
      fi
      step "replaced the folder link $dst_dir with per-item links"
    elif [ ! -e "$dst_dir" ]; then
      if ! rm "$dst_dir"; then
        err "$skill: could not remove the dangling link $dst_dir"
        return 1
      fi
      warn "removed the dangling link $dst_dir"
    else
      backup_entry "$dst_dir" "$platform_name" "$skill" || return 1
    fi
  elif [ -e "$dst_dir" ] && [ ! -d "$dst_dir" ]; then
    backup_entry "$dst_dir" "$platform_name" "$skill" || return 1
  elif [ -d "$dst_dir" ]; then
    # A folder that already holds only links is refreshed in place; one
    # with a real payload item is an older copy, backed up as a whole.
    for item in $PAYLOAD; do
      if [ -e "$dst_dir/$item" ] && [ ! -L "$dst_dir/$item" ]; then
        backup_entry "$dst_dir" "$platform_name" "$skill" || return 1
        break
      fi
    done
  fi

  if ! mkdir -p "$dst_dir"; then
    err "$skill: could not create $dst_dir"
    return 1
  fi
  for item in $PAYLOAD; do
    [ -e "$src/$item" ] || continue
    if ! link_item "$src/$item" "$dst_dir/$item" "$item"; then
      return 1
    fi
  done

  # Report ok only when the harness can read the hub's SKILL.md there.
  if [ ! "$dst_dir/SKILL.md" -ef "$src/SKILL.md" ]; then
    err "$skill: $dst_dir/SKILL.md does not resolve to $src/SKILL.md"
    return 1
  fi
  PLATFORM_LINK_COUNT=$((PLATFORM_LINK_COUNT + 1))
  return 0
}

for skill in $SKILLS; do
  log ""
  printf "%s%s%s\n" "$C_BOLD" "$skill" "$C_RESET"
  skill_failed=0
  for name in $DETECTED_PLATFORMS; do
    pdir="$(platform_dir_for "$name")"
    label="$(platform_label_for "$name")"
    if install_skill_into_platform "$skill" "$name" "$pdir"; then
      ok "$label"
    else
      err "$label"
      skill_failed=1
      FAILED_COUNT=$((FAILED_COUNT + 1))
    fi
    # Older installers left <skill>.backup-<timestamp>/ inside the skills
    # dir, where a harness loads it as a duplicate skill.
    for old in "$pdir/$skill".backup-*; do
      [ -d "$old" ] || continue
      warn "$old may load as a duplicate $skill; move it out of $pdir"
    done
  done
  if [ "$skill_failed" = "0" ]; then
    INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
  fi
done

PLATFORM_COUNT=0
for n in $DETECTED_PLATFORMS; do
  PLATFORM_COUNT=$((PLATFORM_COUNT + 1))
done

log ""
printf "%ssummary%s\n" "$C_BOLD" "$C_RESET"
printf "  %s%d skills installed%s across %d platforms\n" "$C_GREEN" "$INSTALLED_COUNT" "$C_RESET" "$PLATFORM_COUNT"
if [ "$FAILED_COUNT" -gt 0 ]; then
  printf "  %s%d installs failed%s; see the fail lines above, fix them, and re-run\n" "$C_RED" "$FAILED_COUNT" "$C_RESET"
fi
log ""
info "Re-run anytime; install.sh is idempotent."
info "Uninstall: bash uninstall.sh"
log ""

if [ "$FAILED_COUNT" -gt 0 ]; then
  exit 1
fi
