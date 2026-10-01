#!/usr/bin/env bash
# tests/install.sh: tests for install.sh and uninstall.sh.
#
# Copies the two scripts into a throwaway hub (under a path with a space)
# with test skills, snapshots that hub with git so any change to it shows
# in git status, and runs every case with HOME pointed at a temporary
# directory: a fresh install, an idempotent re-run, an existing real skill
# folder (backed up outside the skills dir), a folder link into the hub
# (the hub stays untouched), a foreign folder link (absolute and
# relative), a dangling link, a skills dir that is itself a link into the
# hub, the hub reached by another spelling of its path (letter case, the
# /System/Volumes/Data firmlink), a HOME with a space, CLAUDE_CONFIG_DIR
# and CODEX_HOME, ~/.agents alone, nothing detected, a link that cannot be
# made (non-zero exit, no ok line), a skill added to the hub later, and
# uninstall (removes only what install created).
#
# Usage: bash tests/install.sh      (exit 0 when every assertion passes)
# Bash 3.2 compatible. Never touches this repository or the real HOME.

set -u
# The installers honor these; never let them point at a real harness.
unset CLAUDE_CONFIG_DIR CODEX_HOME CDPATH

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/auditor-install-tests.XXXXXX")"
# Without a scratch dir every path below would land at the filesystem root.
if [ -z "$TMP" ] || [ ! -d "$TMP" ]; then
  printf 'FAIL: mktemp could not make a scratch directory\n'
  exit 1
fi
trap 'chmod -R u+w "$TMP" 2>/dev/null; rm -rf "$TMP"' EXIT
PASS=0
FAIL=0

ok()   { PASS=$((PASS + 1)); }
bad()  { FAIL=$((FAIL + 1)); printf 'FAIL: %s\n' "$*"; }
has()  { printf '%s' "$1" | grep -qF -- "$2" && ok || bad "$3 (expected to find: $2)"; }
lacks(){ printf '%s' "$1" | grep -qF -- "$2" && bad "$3 (did not expect: $2)" || ok; }
check(){ local msg; msg="$1"; shift; if "$@"; then ok; else bad "$msg"; fi; }

# ---- a throwaway hub ------------------------------------------------------
HUB="$TMP/hub copy"
mkdir -p "$HUB/skills"
cp "$ROOT/install.sh" "$ROOT/uninstall.sh" "$HUB/"
make_skill() {
  local s
  s="$HUB/skills/$1"
  mkdir -p "$s/references"
  printf '%s\n' '---' "name: $1" 'description: test skill' '---' > "$s/SKILL.md"
  printf 'card\n' > "$s/references/A.md"
  printf 'readme\n' > "$s/README.md"
}
make_skill codeauditor
make_skill secauditor
make_skill uxauditor
for s in codeauditor secauditor; do
  mkdir -p "$HUB/skills/$s/scripts" "$HUB/skills/$s/assets"
  printf '#!/usr/bin/env bash\n' > "$HUB/skills/$s/scripts/x.sh"
  printf 'id\n' > "$HUB/skills/$s/assets/t.tsv"
done
# A folder with no SKILL.md is not a skill and must not be installed.
mkdir -p "$HUB/skills/notaskill"
printf 'notes\n' > "$HUB/skills/notaskill/README.md"
SKILLS="codeauditor secauditor uxauditor"

# git with no user or system config, so the snapshot works anywhere.
hub_git() {
  HOME="$TMP/git-home" XDG_CONFIG_HOME="$TMP/git-home" GIT_CONFIG_NOSYSTEM=1 \
    git -C "$HUB" -c user.name=installer-test -c user.email=installer-test@example.invalid \
    -c commit.gpgsign=false "$@"
}
if ! command -v git >/dev/null 2>&1; then
  printf 'FAIL: git is required for tests/install.sh\n'
  exit 1
fi
mkdir -p "$TMP/git-home"
hub_git init -q >/dev/null 2>&1 && hub_git add -A >/dev/null 2>&1 \
  && hub_git commit -q -m snapshot >/dev/null 2>&1 || bad "could not snapshot the test hub with git"
hub_clean() { [ -z "$(hub_git status --porcelain 2>&1)" ]; }

# Another path to the same hub, so comparisons must use physical paths.
ln -s "$HUB" "$TMP/hub alias"

# Every run starts in an empty scratch cwd that must stay empty.
CWD="$TMP/cwd"
mkdir -p "$CWD"

# run SCRIPT HOME [NAME=VALUE...]: run the hub copy's script from CWD with
# that HOME; sets OUT (stdout and stderr) and RC.
run() {
  local script home
  script="$1"
  home="$2"
  shift 2
  OUT="$(cd "$CWD" && env HOME="$home" "$@" "$BASH" "$HUB/$script" 2>&1)"
  RC=$?
}

# new_home NAME [DIR...]: a fresh HOME holding the given directories.
new_home() {
  local h d
  h="$TMP/homes/$1"
  shift
  mkdir -p "$h"
  for d in "$@"; do mkdir -p "$h/$d"; done
  printf '%s' "$h"
}

# installed DIR SKILL: DIR/SKILL is a real folder holding one link per
# payload item the hub skill has, each resolving into the hub copy.
installed() {
  local d s item
  d="$1/$2"
  s="$HUB/skills/$2"
  [ -d "$d" ] && [ ! -L "$d" ] || return 1
  for item in SKILL.md references scripts assets; do
    if [ -e "$s/$item" ]; then
      [ -L "$d/$item" ] && [ "$d/$item" -ef "$s/$item" ] || return 1
    else
      [ ! -e "$d/$item" ] && [ ! -L "$d/$item" ] || return 1
    fi
  done
  return 0
}

gone() { [ ! -e "$1" ] && [ ! -L "$1" ]; }
count_lines() { printf '%s\n' "$1" | grep -cF -- "$2"; }

# ---- fresh install --------------------------------------------------------
H="$(new_home fresh .claude/skills)"
run install.sh "$H"
check "fresh install exits 0 (got $RC)" [ "$RC" -eq 0 ]
for s in $SKILLS; do
  check "fresh install links $s into Claude Code" installed "$H/.claude/skills" "$s"
done
check "a folder without SKILL.md is not installed" gone "$H/.claude/skills/notaskill"
check "no Codex dir is created" gone "$H/.codex"
check "no Agent Skills dir without ~/.agents, pi, or OpenClaw" gone "$H/.agents"
has "$OUT" "3 skills installed across 1 platforms" "fresh install summary"
lacks "$OUT" "fail" "fresh install reports no failure"
lacks "$OUT" "No such file" "fresh install prints no shell errors"
check "fresh install leaves the hub untouched" hub_clean

# ---- re-run ---------------------------------------------------------------
before="$(ls -lR "$H/.claude/skills")"
run install.sh "$H"
check "re-run exits 0 (got $RC)" [ "$RC" -eq 0 ]
lacks "$OUT" "warn" "re-run warns about nothing"
check "re-run makes no backup" gone "$H/.auditor-suite-backups"
check "re-run leaves the links as they were" [ "$before" = "$(ls -lR "$H/.claude/skills")" ]

# ---- an existing real skill folder ----------------------------------------
H="$(new_home realdir .claude/skills)"
old="$H/.claude/skills/codeauditor"
mkdir -p "$old/references"
printf '%s\n' '---' 'name: codeauditor' 'description: old copy' '---' > "$old/SKILL.md"
printf 'old readme\n' > "$old/README.md"
printf 'old card\n' > "$old/references/old.md"
run install.sh "$H"
check "install over a real folder exits 0 (got $RC)" [ "$RC" -eq 0 ]
check "install over a real folder links codeauditor" installed "$H/.claude/skills" codeauditor
bk="$(ls -d "$H/.auditor-suite-backups/Claude_Code/codeauditor-"* 2>/dev/null)"
check "the old folder is moved whole to ~/.auditor-suite-backups/<platform>/" [ -n "$bk" ]
check "the backup keeps the old SKILL.md" grep -qs "old copy" "$bk/SKILL.md"
check "the backup keeps the old README.md and references/" [ -f "$bk/README.md" -a -f "$bk/references/old.md" ]
check "no stale file is left in the new install" gone "$old/README.md"
check "no *.backup-* folder is made inside the skills dir" [ -z "$(ls -d "$H/.claude/skills/"*.backup-* 2>/dev/null)" ]
dups="$(cat "$H/.claude/skills"/*/SKILL.md | grep '^name:' | sort | uniq -d)"
check "no duplicate skill name loads from the skills dir" [ -z "$dups" ]
run install.sh "$H"
check "a re-run over the replaced folder makes no second backup" \
  [ "$(ls -d "$H/.auditor-suite-backups/Claude_Code/"* 2>/dev/null | wc -l | tr -d ' ')" = "1" ]

# ---- a backup an older installer left inside the skills dir ---------------
H="$(new_home oldbackup .claude/skills)"
mkdir -p "$H/.claude/skills/codeauditor.backup-20260926-120000"
printf 'old\n' > "$H/.claude/skills/codeauditor.backup-20260926-120000/SKILL.md"
run install.sh "$H"
check "install next to an old in-dir backup exits 0 (got $RC)" [ "$RC" -eq 0 ]
has "$OUT" "codeauditor.backup-20260926-120000 may load as a duplicate codeauditor" "an old in-dir backup is reported"
check "an old in-dir backup is left where it is" [ -f "$H/.claude/skills/codeauditor.backup-20260926-120000/SKILL.md" ]

# ---- a folder link into the hub (the README's by-hand install) ------------
H="$(new_home dirlink .claude/skills)"
ln -s "$HUB/skills/codeauditor" "$H/.claude/skills/codeauditor"
ln -s "$TMP/hub alias/skills/secauditor" "$H/.claude/skills/secauditor"
run install.sh "$H"
check "install over a folder link exits 0 (got $RC)" [ "$RC" -eq 0 ]
check "a folder link into the hub leaves the hub untouched (git status clean)" hub_clean
check "the hub's SKILL.md is still a regular file" [ -f "$HUB/skills/codeauditor/SKILL.md" -a ! -L "$HUB/skills/codeauditor/SKILL.md" ]
check "the hub keeps its references/" [ -f "$HUB/skills/codeauditor/references/A.md" ]
check "a folder link into the hub is replaced by per-item links" installed "$H/.claude/skills" codeauditor
check "a folder link through another path to the hub is replaced too" installed "$H/.claude/skills" secauditor
check "a folder link into the hub is not backed up" gone "$H/.auditor-suite-backups"
lacks "$OUT" "backed up" "a folder link into the hub is not reported as a backup"

# ---- a foreign folder link ------------------------------------------------
H="$(new_home foreign .claude/skills)"
mkdir -p "$TMP/elsewhere/codeauditor"
printf 'keep me\n' > "$TMP/elsewhere/codeauditor/SKILL.md"
ln -s "$TMP/elsewhere/codeauditor" "$H/.claude/skills/codeauditor"
# A relative link resolves from the folder that holds it, so a plain move
# into the backups dir would point it somewhere else.
mkdir -p "$H/.claude/mine/secauditor"
printf 'keep me too\n' > "$H/.claude/mine/secauditor/SKILL.md"
ln -s "../mine/secauditor" "$H/.claude/skills/secauditor"
run install.sh "$H"
check "install over a foreign folder link exits 0 (got $RC)" [ "$RC" -eq 0 ]
check "a foreign folder link is replaced by per-item links" installed "$H/.claude/skills" codeauditor
bk="$(ls -d "$H/.auditor-suite-backups/Claude_Code/codeauditor-"* 2>/dev/null)"
check "the foreign link itself is moved to the backups" [ -L "$bk" ]
check "the moved link still points where it did" [ "$(readlink "$bk")" = "$TMP/elsewhere/codeauditor" ]
check "what a foreign link points to is untouched" grep -qs "keep me" "$TMP/elsewhere/codeauditor/SKILL.md"
check "a relative foreign folder link is replaced by per-item links" installed "$H/.claude/skills" secauditor
bk="$(ls -d "$H/.auditor-suite-backups/Claude_Code/secauditor-"* 2>/dev/null)"
check "a relative foreign link is backed up as a link" [ -L "$bk" ]
check "the backed-up relative link opens the same folder" [ "$bk" -ef "$H/.claude/mine/secauditor" ]
case "$(readlink "$bk" 2>/dev/null)" in
  /*) ok ;;
  *) bad "the backed-up relative link gets an absolute target" ;;
esac
check "what a relative foreign link points to is untouched" grep -qs "keep me too" "$H/.claude/mine/secauditor/SKILL.md"

# ---- dangling links -------------------------------------------------------
H="$(new_home dangling .claude/skills)"
ln -s "$TMP/deleted clone/codeauditor" "$H/.claude/skills/codeauditor"
mkdir -p "$H/.claude/skills/secauditor"
ln -s "$TMP/deleted clone/secauditor/SKILL.md" "$H/.claude/skills/secauditor/SKILL.md"
run install.sh "$H"
check "install over dangling links exits 0 (got $RC)" [ "$RC" -eq 0 ]
check "a dangling folder link is replaced by a folder of links" installed "$H/.claude/skills" codeauditor
check "a dangling item link is replaced" installed "$H/.claude/skills" secauditor
check "the dangling target is not created" gone "$TMP/deleted clone"
lacks "$OUT" "No such file" "dangling links cause no shell errors"

# ---- a skills dir that is itself a link into the hub ----------------------
H="$(new_home skillslink .claude)"
ln -s "$HUB/skills" "$H/.claude/skills"
run install.sh "$H"
check "install into a skills dir linked to the hub exits 0 (got $RC)" [ "$RC" -eq 0 ]
check "a skills dir linked to the hub leaves the hub untouched" hub_clean
run uninstall.sh "$H"
check "uninstall of a skills dir linked to the hub exits 0 (got $RC)" [ "$RC" -eq 0 ]
check "uninstall leaves a hub reached through the skills dir untouched" hub_clean
check "the hub keeps its skills" [ -f "$HUB/skills/codeauditor/SKILL.md" ]

# ---- the hub reached by another spelling of its path ----------------------
# pwd -P keeps the letter case it is given on a case-insensitive disk and
# keeps a /System/Volumes/Data firmlink spelling, so two physical path
# strings can name one directory. The installers must compare by identity.
# Each spelling runs only where it reaches the hub (not on a case-sensitive
# disk, and the firmlink only on macOS).
HUB_P="$(cd "$HUB" && pwd -P)"
UPPER="$(printf '%s' "$HUB_P" | tr '[:lower:]' '[:upper:]')"
ALTS=0
for kind in upper firmlink; do
  case "$kind" in
    upper)    alt="$UPPER"; how="in upper case" ;;
    firmlink) alt="/System/Volumes/Data$HUB_P"; how="through /System/Volumes/Data" ;;
  esac
  [ "$alt" != "$HUB_P" ] && [ -d "$alt/skills" ] && [ "$alt/skills" -ef "$HUB/skills" ] || continue
  ALTS=$((ALTS + 1))
  H="$(new_home "alt-$kind-skills" .claude)"
  ln -s "$alt/skills" "$H/.claude/skills"
  run install.sh "$H"
  check "install into a skills dir linked to the hub $how exits 0 (got $RC)" [ "$RC" -eq 0 ]
  check "a skills dir linked to the hub $how leaves the hub untouched" hub_clean
  check "a skills dir linked to the hub $how makes no backup" gone "$H/.auditor-suite-backups"
  run uninstall.sh "$H"
  check "uninstall of a skills dir linked to the hub $how exits 0 (got $RC)" [ "$RC" -eq 0 ]
  has "$OUT" "resolves inside the hub" "uninstall skips a skills dir linked to the hub $how"
  check "uninstall of a skills dir linked to the hub $how leaves the hub untouched" hub_clean

  H="$(new_home "alt-$kind-link" .claude/skills)"
  ln -s "$alt/skills/codeauditor" "$H/.claude/skills/codeauditor"
  run install.sh "$H"
  check "install over a folder link into the hub $how exits 0 (got $RC)" [ "$RC" -eq 0 ]
  check "a folder link into the hub $how is replaced by per-item links" installed "$H/.claude/skills" codeauditor
  check "a folder link into the hub $how is not backed up" gone "$H/.auditor-suite-backups"
  check "a folder link into the hub $how leaves the hub untouched" hub_clean

  H="$(new_home "alt-$kind-uninstall" .claude/skills)"
  ln -s "$alt/skills/codeauditor" "$H/.claude/skills/codeauditor"
  mkdir -p "$H/.claude/skills/secauditor"
  for item in SKILL.md references scripts assets; do
    ln -s "$alt/skills/secauditor/$item" "$H/.claude/skills/secauditor/$item"
  done
  run uninstall.sh "$H"
  check "uninstall of links into the hub $how exits 0 (got $RC)" [ "$RC" -eq 0 ]
  check "uninstall removes a folder link into the hub $how" gone "$H/.claude/skills/codeauditor"
  check "uninstall removes per-item links into the hub $how" gone "$H/.claude/skills/secauditor"
  check "uninstall of links into the hub $how leaves the hub untouched" hub_clean

  # Put the hub back if a run damaged it, so later cases still mean something.
  hub_clean || { hub_git reset -q --hard >/dev/null 2>&1; hub_git clean -qfd >/dev/null 2>&1; }
done
[ "$ALTS" -gt 0 ] || printf 'note: no other spelling reaches the hub here; those cases were skipped\n'

# ---- a HOME with a space --------------------------------------------------
H="$(new_home "home with space" .claude/skills)"
run install.sh "$H"
check "install with a space in HOME exits 0 (got $RC)" [ "$RC" -eq 0 ]
for s in $SKILLS; do
  check "a HOME with a space gets $s" installed "$H/.claude/skills" "$s"
done
check "a HOME with a space writes nothing into the cwd" [ -z "$(ls -A "$CWD")" ]
check "a HOME with a space writes nothing next to HOME" gone "$TMP/homes/home"
lacks "$OUT" "Codex" "a HOME with a space does not detect Codex"

# ---- CLAUDE_CONFIG_DIR and CODEX_HOME -------------------------------------
H="$(new_home envdirs)"
mkdir -p "$TMP/claude config" "$TMP/codex home"
run install.sh "$H" CLAUDE_CONFIG_DIR="$TMP/claude config" CODEX_HOME="$TMP/codex home"
check "install with CLAUDE_CONFIG_DIR and CODEX_HOME exits 0 (got $RC)" [ "$RC" -eq 0 ]
check "CLAUDE_CONFIG_DIR is honored" installed "$TMP/claude config/skills" codeauditor
check "CODEX_HOME is honored" installed "$TMP/codex home/skills" codeauditor
check "nothing is written to ~/.claude or ~/.codex when they are moved" [ -z "$(ls -A "$H")" ]
run uninstall.sh "$H" CLAUDE_CONFIG_DIR="$TMP/claude config" CODEX_HOME="$TMP/codex home"
check "uninstall with CLAUDE_CONFIG_DIR and CODEX_HOME exits 0 (got $RC)" [ "$RC" -eq 0 ]
check "uninstall honors CLAUDE_CONFIG_DIR" gone "$TMP/claude config/skills/codeauditor"
check "uninstall honors CODEX_HOME" gone "$TMP/codex home/skills/codeauditor"

# ---- ~/.agents alone, and nothing at all ----------------------------------
H="$(new_home agents .agents)"
run install.sh "$H"
check "install with only ~/.agents exits 0 (got $RC)" [ "$RC" -eq 0 ]
for s in $SKILLS; do
  check "~/.agents alone gets $s" installed "$H/.agents/skills" "$s"
done
H="$(new_home empty)"
run install.sh "$H"
check "install with no harness exits non-zero" [ "$RC" -ne 0 ]
has "$OUT" "~/.agents" "the no-harness message names ~/.agents"

# ---- a link that cannot be made -------------------------------------------
if [ "$(id -u)" != "0" ]; then
  H="$(new_home readonly .claude/skills)"
  mkdir -p "$H/.claude/skills/codeauditor"
  chmod 555 "$H/.claude/skills/codeauditor"
  run install.sh "$H"
  chmod 755 "$H/.claude/skills/codeauditor"
  check "a failed link exits non-zero" [ "$RC" -ne 0 ]
  has "$OUT" "fail  Claude Code" "a failed link prints a fail line"
  has "$OUT" "1 installs failed" "the summary counts the failure"
  check "only the skills that linked report ok" [ "$(count_lines "$OUT" "ok    Claude Code")" = "2" ]
  H="$(new_home readonly-all .claude/skills)"
  chmod 555 "$H/.claude/skills"
  run install.sh "$H"
  chmod 755 "$H/.claude/skills"
  check "an unwritable skills dir exits non-zero" [ "$RC" -ne 0 ]
  lacks "$OUT" "ok    Claude Code" "an unwritable skills dir prints no ok line"
fi

# ---- uninstall removes only what install created --------------------------
H="$(new_home uninstall .claude/skills)"
mkdir -p "$H/.claude/skills/userskill" "$H/.claude/skills/codeauditor" "$H/.claude/skills/secauditor"
printf 'mine\n' > "$H/.claude/skills/userskill/SKILL.md"
printf 'my notes\n' > "$H/.claude/skills/codeauditor/NOTES.md"
printf '%s\n' '---' 'name: secauditor' 'description: old copy' '---' > "$H/.claude/skills/secauditor/SKILL.md"
ln -s "$TMP/elsewhere" "$H/.claude/skills/foreignlink"
snap() { (cd "$1" && find . | LC_ALL=C sort | grep -v -e '^\./\.auditor-suite-backups' -e '^\./\.claude/skills/secauditor'); }
before="$(snap "$H")"
run install.sh "$H"
check "install before uninstall exits 0 (got $RC)" [ "$RC" -eq 0 ]
run uninstall.sh "$H"
check "uninstall exits 0 (got $RC)" [ "$RC" -eq 0 ]
for s in $SKILLS; do
  check "uninstall removes the $s links" gone "$H/.claude/skills/$s/SKILL.md"
done
check "uninstall removes the folders it emptied" gone "$H/.claude/skills/uxauditor"
check "uninstall leaves everything else as it was" [ "$before" = "$(snap "$H")" ]
check "uninstall keeps a user file in a skill folder" [ -f "$H/.claude/skills/codeauditor/NOTES.md" ]
check "uninstall keeps the backups" [ -n "$(ls -d "$H/.auditor-suite-backups/Claude_Code/secauditor-"* 2>/dev/null)" ]
check "uninstall leaves the hub untouched" hub_clean

# ---- uninstall of the by-hand folder link alone ---------------------------
H="$(new_home byhand .claude/skills)"
ln -s "$HUB/skills/codeauditor" "$H/.claude/skills/codeauditor"
ln -s "$TMP/hub alias/skills/secauditor" "$H/.claude/skills/secauditor"
ln -s "$TMP/elsewhere/codeauditor" "$H/.claude/skills/uxauditor"
run uninstall.sh "$H"
check "uninstall of folder links exits 0 (got $RC)" [ "$RC" -eq 0 ]
check "uninstall removes a by-hand folder link" gone "$H/.claude/skills/codeauditor"
check "uninstall removes a folder link through another path to the hub" gone "$H/.claude/skills/secauditor"
check "uninstall keeps a foreign folder link" [ -L "$H/.claude/skills/uxauditor" ]
check "uninstall of folder links leaves the hub untouched" hub_clean
check "the hub keeps its files after a folder link is removed" [ -f "$HUB/skills/codeauditor/references/A.md" ]

# ---- a skill added to the hub later needs no installer edit ---------------
make_skill productauditor
H="$(new_home roster .claude/skills)"
run install.sh "$H"
check "install with a new skill exits 0 (got $RC)" [ "$RC" -eq 0 ]
check "a skill added to the hub is installed with no installer edit" installed "$H/.claude/skills" productauditor
run uninstall.sh "$H"
check "a skill added to the hub is uninstalled too" gone "$H/.claude/skills/productauditor"

check "no run wrote into the cwd" [ -z "$(ls -A "$CWD")" ]

printf 'install tests: %d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
