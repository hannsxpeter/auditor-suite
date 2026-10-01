#!/usr/bin/env bash
# tests/lint-selftest.sh: prove that the lint checks fail when they should.
#
# Copies the hub (.git plus every tracked file and every untracked file git
# does not ignore) into a temporary directory once. A baseline run proves the
# checks used here pass on that copy. Then each case starts from a fresh copy,
# injects one violation, runs only the relevant checks by name, and asserts
# that scripts/lint.sh exits 1 and prints a message naming the problem.
#
# Never runs the real tests/run.sh or tests/install.sh (the script-tests case
# swaps in stubs), so it stays fast. Every nested lint runs under the bash
# running this script ($BASH), so /bin/bash tests/lint-selftest.sh tests 3.2.
#
# Usage: bash tests/lint-selftest.sh      (exit 0 when every case passes)
# Bash 3.2 compatible. Writes only inside a temporary directory.

set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/lint-selftest.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
BASE="$TMP/base"
CASE="$TMP/case"
PASS=0
FAIL=0
OUT=""
RC=0

ok()  { PASS=$((PASS + 1)); }
bad() { FAIL=$((FAIL + 1)); printf 'FAIL: %s\n' "$*"; }
show(){ printf '%s\n' "$OUT" | sed -n '1,30p' | sed 's/^/    | /'; }

# fresh: a new working copy of the pristine base in $CASE.
fresh() { rm -rf "$CASE"; cp -Rp "$BASE" "$CASE"; }

# run [CHECK...]: run the lint in $CASE with those checks. Sets OUT and RC.
# LINT_JSON in the environment picks the JSON reader (empty: auto).
run() {
  RC=0
  OUT="$(cd "$CASE" && LINT_JSON="${JSON:-}" "${BASH:-bash}" scripts/lint.sh "$@" 2>&1)" || RC=$?
}

# expect NAME RC TEXT...: the last run exited RC and printed every TEXT.
expect() {
  local name="$1" want="$2" t miss=""
  shift 2
  if [ "$RC" != "$want" ]; then
    bad "$name: lint exited $RC, want $want"
    show
    return 0
  fi
  for t in "$@"; do
    printf '%s\n' "$OUT" | grep -qF -- "$t" || miss="$miss [$t]"
  done
  if [ -n "$miss" ]; then
    bad "$name: output lacks$miss"
    show
  else
    ok
  fi
}

# lacks NAME TEXT: the last run did not print TEXT.
lacks() {
  if printf '%s\n' "$OUT" | grep -qF -- "$2"; then
    bad "$1: output should not contain [$2]"
    show
  else
    ok
  fi
}

# has_line NAME LINE: the last run printed LINE as a whole line.
has_line() {
  if printf '%s\n' "$OUT" | grep -qxF -- "$2"; then ok; else bad "$1: no line [$2]"; show; fi
}

# replace_once FILE OLD NEW: replace the first occurrence of fixed text OLD.
replace_once() {
  awk -v o="$2" -v n="$3" '!done && (i = index($0, o)) { $0 = substr($0, 1, i - 1) n substr($0, i + length(o)); done = 1 } { print }' "$1" > "$1.tmp" && mv "$1.tmp" "$1"
}

# ---- one pristine copy -----------------------------------------------------
mkdir -p "$BASE"
if git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  (cd "$ROOT" && git ls-files -z --cached --others --exclude-standard |
    while IFS= read -r -d '' f; do [ -e "$f" ] && printf '%s\0' "$f"; done |
    tar -cf - --null -T -) | (cd "$BASE" && tar -xf -)
  if [ -d "$ROOT/.git" ]; then
    cp -Rp "$ROOT/.git" "$BASE/.git"
  else
    # A linked worktree: its .git is a file pointing elsewhere. Give the copy
    # its own repository so nothing here touches the original's index.
    (cd "$BASE" && git init -q && git add -A)
  fi
else
  cp -Rp "$ROOT/." "$BASE"
fi
[ -f "$BASE/scripts/lint.sh" ] || { printf 'could not copy the hub into %s\n' "$BASE" >&2; exit 1; }

CHECKS="suite-registry skill-frontmatter skill-structure shared-sync plugin-sync unicode-clean bash-syntax"
READERS=""
command -v jq >/dev/null 2>&1 && READERS="$READERS jq"
python3 -c 'import json' >/dev/null 2>&1 && READERS="$READERS python3"
DIM="$(grep -v '^[[:space:]]*#' "$BASE/skills/codeauditor/assets/dimensions.tsv" | grep -v '^[[:space:]]*$' | sed -n 1p | cut -f1)"
CARDS="skills/codeauditor/references/$DIM.md"

# ---- baseline: the unmodified copy passes, with every JSON reader ----------
fresh
JSON=""
run $CHECKS
expect "baseline" 0 "all checks passed"
for JSON in $READERS none; do
  run plugin-sync suite-registry
  expect "baseline JSON checks (LINT_JSON=$JSON)" 0 "all checks passed"
done
JSON=""
if [ "$FAIL" -gt 0 ]; then
  printf 'lint-selftest: the unmodified tree already fails; fix that before trusting the cases below\n'
fi

# ---- arguments ---------------------------------------------------------------
run no-such-check
expect "unknown check name" 2 "unknown check: no-such-check"

# ---- unicode-clean -----------------------------------------------------------
fresh
printf 'Launch \360\237\232\200 now\n' >> "$CASE/README.md"           # U+1F680, tracked
printf 'Done \342\234\205\n' >> "$CASE/AGENTS.md"                     # U+2705 dingbat
printf 'a \342\207\222 b\n' >> "$CASE/SUITE.md"                       # U+21D2 arrow
printf 'Note \342\232\240\357\270\217\n' >> "$CASE/CONTRIBUTING.md"   # U+26A0 + VS16
mkdir -p "$CASE/docs"
printf 'tree\n\342\224\234\342\224\200 x\n' > "$CASE/docs/new notes.md" # untracked, space in name
printf 'bullet \342\200\242 and \302\251 are fine\n' > "$CASE/docs/fine.md"
run unicode-clean
expect "unicode-clean flags emoji, dingbat, arrow, VS16, and box drawing" 1 \
  "README.md contains" "AGENTS.md contains" "SUITE.md contains" "CONTRIBUTING.md contains" "docs/new notes.md contains"
lacks "unicode-clean leaves U+2022 and U+00A9 alone" "docs/fine.md"

# One failing check must not end the run: unicode-clean fails first, then
# bash-syntax still runs and the summary prints.
fresh
printf 'a \342\200\224 b\n' >> "$CASE/README.md"                      # em dash
printf 'if then\n' > "$CASE/scripts/broken.sh"
run unicode-clean bash-syntax
expect "a unicode-clean failure does not stop later checks" 1 "scripts/broken.sh has a bash syntax error" "auditor-suite-lint: 2 failure(s)"
has_line "bash-syntax ran after unicode-clean failed" "bash-syntax"

# A check that crashes (here: awk exits 2 on the rule-card program) must fail
# the run, not pass with an empty result, and the next check still runs.
fresh
REAL_AWK="$(command -v awk)"
mkdir -p "$TMP/shim"
printf '#!/bin/sh\ncase "$*" in *can_be_critical*) echo "awk: simulated crash" >&2; exit 2 ;; esac\nexec "%s" "$@"\n' "$REAL_AWK" > "$TMP/shim/awk"
chmod +x "$TMP/shim/awk"
RC=0
OUT="$(cd "$CASE" && PATH="$TMP/shim:$PATH" "${BASH:-bash}" scripts/lint.sh skill-structure bash-syntax 2>&1)" || RC=$?
expect "a check that crashes fails the run" 1 "skill-structure: the check stopped early" "auditor-suite-lint: 1 failure(s)"
has_line "bash-syntax ran after skill-structure crashed" "bash-syntax"
lacks "a crash is never reported as a pass" "all checks passed"

# ---- bash-syntax: bash 4 constructs ------------------------------------------
fresh
printf '#!/usr/bin/env bash\nma%sfile -t lines < /dev/null\n' p > "$CASE/scripts/b4.sh"
# A nameref and a case change on a positional parameter. The printf
# arguments keep this file's own lines from matching the pattern.
printf '#!/usr/bin/env bash\nf() { local -%s ref=$1; }\n' n > "$CASE/scripts/b4n.sh"
printf '#!/usr/bin/env bash\necho "$%s{1,,}"\n' '' > "$CASE/scripts/b4c.sh"
printf '#!/usr/bin/env bash\n# a comment may say ma%sfile\nx=1\n' p > "$CASE/scripts/b3.sh"
printf '%s\n' '#!/usr/bin/env bash' 'f() { local -i n=1; declare -p n; read -n 1 c; }' 'echo "${1:-a,b}" "${#}" "${x%,}"' > "$CASE/scripts/b3b.sh"
run bash-syntax
expect "bash-syntax flags a bash 4 construct" 1 "scripts/b4.sh uses a bash 4 construct" \
  "scripts/b4n.sh uses a bash 4 construct" "scripts/b4c.sh uses a bash 4 construct"
lacks "bash-syntax skips comment lines" "scripts/b3.sh"
lacks "bash-syntax passes bash 3.2 flags and expansions" "scripts/b3b.sh"

# ---- plugin-sync -------------------------------------------------------------
for JSON in $READERS; do
  fresh
  replace_once "$CASE/plugins/codeauditor/.claude-plugin/plugin.json" '"license": "MIT",' '"license": "MIT",,'
  run plugin-sync
  expect "plugin-sync rejects invalid JSON (LINT_JSON=$JSON)" 1 "plugins/codeauditor/.claude-plugin/plugin.json is not valid JSON"
  # Two JSON values in one file (a bad merge) and an empty file are not valid
  # JSON either; jq alone would accept both.
  fresh
  printf '{"x": 1}\n' >> "$CASE/plugins/codeauditor/.claude-plugin/plugin.json"
  : > "$CASE/plugins/dbauditor/.claude-plugin/plugin.json"
  run plugin-sync
  expect "plugin-sync rejects two JSON values and an empty file (LINT_JSON=$JSON)" 1 \
    "plugins/codeauditor/.claude-plugin/plugin.json is not valid JSON" \
    "plugins/dbauditor/.claude-plugin/plugin.json is not valid JSON"
done
JSON=""

fresh
replace_once "$CASE/plugins/codeauditor/.claude-plugin/plugin.json" '"name": "codeauditor"' '"name": "codeauditr"'
run plugin-sync
expect "plugin-sync rejects a wrong plugin name" 1 'plugin.json name is "codeauditr"; want "codeauditor"'

fresh
replace_once "$CASE/.claude-plugin/marketplace.json" '"name": "dbauditor"' '"name": "dbauditr"'
run plugin-sync suite-registry
expect "a renamed marketplace entry fails both checks" 1 \
  'marketplace entry dbauditr has source "./plugins/dbauditor"; want "./plugins/dbauditr"' \
  "dbauditor: no entry in .claude-plugin/marketplace.json"

fresh
replace_once "$CASE/.claude-plugin/marketplace.json" 'Audits a whole codebase end to end' 'Audits a codebase'
run plugin-sync
expect "plugin-sync rejects a marketplace description mismatch" 1 "marketplace entry codeauditor description differs"

# ---- suite-registry ----------------------------------------------------------
fresh
replace_once "$CASE/plugins/auditor-suite/.claude-plugin/plugin.json" '"uxauditor"' '"uxauditr"'
run suite-registry
expect "suite-registry checks the meta plugin dependencies" 1 \
  "uxauditor: not a dependency of the meta plugin" "the meta plugin depends on uxauditr"

fresh
mkdir -p "$CASE/skills/zzzauditor" "$CASE/skills/Bad Name"
printf '# zzzauditor\n' > "$CASE/skills/zzzauditor/README.md"
run suite-registry skill-frontmatter skill-structure
expect "a skills/ directory without SKILL.md fails" 1 \
  "zzzauditor: missing skills/zzzauditor/SKILL.md" \
  "zzzauditor: no vendored plugin at plugins/zzzauditor/" \
  "zzzauditor: no entry in .claude-plugin/marketplace.json" \
  "zzzauditor: no eval case at evals/zzzauditor/" \
  "zzzauditor: no example-report fixture at tests/fixtures/zzzauditor/" \
  "zzzauditor: README.md has no table row" \
  "skills/Bad Name: not a valid skill name"

# Nothing suite-registry leaves out of the roster comparison goes unchecked:
# the marketplace must list the meta plugin once, evals/results/ must stay
# git-ignored, tests/fixtures/ holds only skill folders, and README.md and
# SUITE.md have no row for a name that is not a skill.
fresh
# The six-space indent picks the plugin entry, not the marketplace's own name.
replace_once "$CASE/.claude-plugin/marketplace.json" '      "name": "auditor-suite",' '      "name": "auditor-suit",'
grep -v '^evals/results/$' "$CASE/.gitignore" > "$CASE/.gitignore.tmp" && mv "$CASE/.gitignore.tmp" "$CASE/.gitignore"
mkdir -p "$CASE/tests/fixtures/non-git"
printf '| **[oldauditor](skills/oldauditor)** | Retired | 9 | `oldaudit.md` | `/oldauditor` |\n' >> "$CASE/README.md"
printf '| **oldauditor** | Retired | `oldaudit.md` | "old audit" |\n' >> "$CASE/SUITE.md"
run suite-registry
expect "suite-registry checks what it leaves out of the roster" 1 \
  "lists the meta plugin auditor-suite 0 times" \
  "evals/results/ is not git-ignored" \
  "tests/fixtures/non-git/ exists, but there is no skills/non-git/" \
  "README.md has a table row for oldauditor, but there is no skills/oldauditor/" \
  "SUITE.md has a table row for oldauditor, but there is no skills/oldauditor/"

# ---- script-tests --------------------------------------------------------------
# Stubs stand in for the real suites: each one is run and reported.
fresh
printf '#!/usr/bin/env bash\necho "tests: 1 passed, 0 failed"\n' > "$CASE/tests/run.sh"
printf '#!/usr/bin/env bash\necho "FAIL: stub"\necho "install tests: 0 passed, 1 failed"\nexit 1\n' > "$CASE/tests/install.sh"
run --verbose script-tests
expect "script-tests runs and reports tests/run.sh and tests/install.sh" 1 \
  "ok    tests/run.sh passed (tests: 1 passed, 0 failed)" \
  "fail  tests/install.sh failed:" "install tests: 0 passed, 1 failed"
rm "$CASE/tests/install.sh"
run script-tests
expect "script-tests fails when tests/install.sh is missing" 1 "tests/install.sh is missing"

# ---- shared-sync -------------------------------------------------------------
# Several check names run every one of them (CONTRIBUTING.md documents this
# exact command); an unsynced shared/ edit fails shared-sync.
fresh
printf '# drift\n' >> "$CASE/shared/scripts/scan.sh"
run shared-sync plugin-sync
expect "an unsynced shared file fails shared-sync" 1 "codeauditor: scripts/scan.sh differs from shared/"
has_line "shared-sync ran when named with plugin-sync" "shared-sync"
has_line "plugin-sync ran when named with shared-sync" "plugin-sync"

fresh
printf '#!/usr/bin/env bash\n' > "$CASE/skills/codeauditor/scripts/legacy.sh"
run shared-sync
expect "a stray file in a skill's scripts/ fails shared-sync" 1 "codeauditor: scripts/legacy.sh is not in shared/scripts/"

# ---- skill-structure ---------------------------------------------------------
fresh
awk '!done && /^- Refs:/ { done = 1; next } { print }' "$CASE/$CARDS" > "$CASE/$CARDS.tmp" && mv "$CASE/$CARDS.tmp" "$CASE/$CARDS"
run skill-structure
expect "a card missing a field fails" 1 'is missing "- Refs:"'

# card ID HEADING SEVERITY: append a complete rule card to $CARDS.
card() {
  printf '\n### %s %s\n- Leads: none.\n- Confirm: none.\n- Not a finding if: none.\n- Severity: %s\n- Fix: none.\n- Verify the fix: none.\n- Refs: none\n' "$1" "$2" "$3" >> "$CASE/$CARDS"
}

fresh
card "$DIM-R901" "Selftest card" "High; Critical when the data is public."
run skill-structure
expect "a Critical-capable card without (quick) fails" 1 "card $DIM-R901 Severity can be Critical" "lacks (quick)"

fresh
card "$DIM-R901" "Selftest card" "Medium; never Critical, since nothing is exposed."
card "$DIM-R902" "Selftest card" "High, not Critical even when public."
card "$DIM-R903" "Selftest card (quick)" "as $DIM-R1, because it is the same defect."
run skill-structure
expect "negated Critical and the as-CARD form pass" 0 "all checks passed"

fresh
card "$DIM-R901" "Selftest card (quick)" "Medium."
run skill-structure
expect "a (quick) card that cannot be Critical fails" 1 "card $DIM-R901 is tagged (quick) but its Severity never reaches Critical"

printf '\nlint-selftest: %d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
