#!/usr/bin/env bash
# tests/run.sh: golden tests for the shared auditor scripts.
#
# Builds a throwaway test skill from shared/ (three dimensions, one of them a
# floor and one conditional) and throwaway projects, then checks inventory,
# scan (ripgrep and grep paths, and which leads it shows over the --max cap),
# new-report, score arithmetic and caps, the generated blocks, and
# check-report's failure messages; the file list (with and without git,
# symlinks, submodules, deleted, type-changed, sparse, and untracked entries,
# an ignored folder, names that a mangled regex would mis-match); that
# reports are never written through a symlink and keep their permission
# bits; and that the user's grep, ripgrep, and locale settings do not change
# the leads.
#
# Usage: bash tests/run.sh      (exit 0 when every assertion passes)
# Bash 3.2 compatible. Writes only inside a temporary directory.

set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/auditor-tests.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
PASS=0
FAIL=0
TAB="$(printf '\t')"

ok()   { PASS=$((PASS + 1)); }
bad()  { FAIL=$((FAIL + 1)); printf 'FAIL: %s\n' "$*"; }
has()  { printf '%s' "$1" | grep -qF -- "$2" && ok || bad "$3 (expected to find: $2)"; }
lacks(){ printf '%s' "$1" | grep -qF -- "$2" && bad "$3 (did not expect: $2)" || ok; }

# ---- a test skill ---------------------------------------------------------
SK="$TMP/testauditor"
mkdir -p "$SK/scripts" "$SK/references" "$SK/assets"
cp "$ROOT"/shared/scripts/* "$SK/scripts/"
cp "$ROOT"/shared/references/* "$SK/references/"
cp "$ROOT"/shared/assets/* "$SK/assets/"
cat > "$SK/assets/skill.conf" <<'EOF'
SKILL_NAME="testauditor"
REPORT_FILE="testaudit.md"
REPORT_TITLE="Test audit"
AUDIT_NOUN="test audit"
HEADLINE="Test audit complete"
QUICK_HEADLINE="Test quick triage complete"
BANNER="Nothing was run."
MAP_HINT="The map"
DOMAIN_RULE="Fix carefully."
STOP_HINT=""
EOF
printf '# id\tweight\tapplies\tfloor\tname\nAA\t50\talways\tno\tAlpha\nBB\t30\talways\tyes\tBravo\nCC\t20\tconditional\tno\tCharlie\n' > "$SK/assets/dimensions.tsv"
printf '# dim\tlabel\tflags\tglobs\tregex\nCC\tcharlie markers\t-\t@code\tCHARLIE_MARKER\n' > "$SK/assets/surfaces.tsv"
printf '# card\tflags\tglobs\tregex\nAA-R1\tq\t@code\tdangerous_call\\(\nAA-R2\t-\t*\tLINK_MARKER\nBB-R1\ti\t*.py\tpassword[[:space:]]*=\n' > "$SK/assets/patterns.tsv"
for d in AA BB CC; do
  cat > "$SK/references/$d.md" <<EOF
# $d: test dimension

## Cards

### $d-R1 First card (quick)
- Leads: scan.
- Confirm: yes.
- Not a finding if: no.
- Severity: Critical.
- Fix: fix.
- Verify the fix: test.
- Refs: none

### $d-R2 Second card
- Leads: scan.
- Confirm: yes.
- Not a finding if: no.
- Severity: Low.
- Fix: fix.
- Verify the fix: test.
- Refs: none
EOF
done

# ---- a test project -------------------------------------------------------
PJ="$TMP/project"
mkdir -p "$PJ/src" "$PJ/node_modules/x"
cat > "$PJ/src/app.py" <<'EOF'
import os

def handler(request):
    value = request.args["v"]
    return dangerous_call(value)

password = "hunter2hunter2"
EOF
printf 'dangerous_call(1)\n' > "$PJ/node_modules/x/ignored.js"
(cd "$PJ" && git init -q && git add -A && git -c user.name=t -c user.email=t@example.invalid commit -qm init) || { bad "git init"; }

S="$SK/scripts"
cd "$PJ" || exit 1

# ---- inventory ------------------------------------------------------------
out="$(bash "$S/inventory.sh" 2>&1)"
has "$out" "languages (source files by extension): py 1" "inventory counts languages"
has "$out" "CC           n/a" "inventory marks the conditional dimension n/a"
has "$out" "suggested dimensions: active AA, BB; not applicable CC" "inventory suggests dimensions"
empty="$TMP/empty"; mkdir -p "$empty"; printf 'notes\n' > "$empty/README.md"
out="$(cd "$empty" && bash "$S/inventory.sh" 2>&1)"
has "$out" "NO SOURCE CODE FOUND" "inventory stops on a project with no code"

# ---- scan: ripgrep and grep give the same leads, vendored dirs skipped ----
rg_out="$(bash "$S/scan.sh" all 2>&1)"
gr_out="$(AUDITOR_NO_RG=1 bash "$S/scan.sh" all 2>&1)"
has "$gr_out" "src/app.py:5: return dangerous_call(value)" "scan finds the AA-R1 lead"
has "$gr_out" "src/app.py:7: password = \"hunter2hunter2\"" "scan finds the BB-R1 lead (ignore-case flag)"
lacks "$gr_out" "node_modules" "scan skips vendored folders"
[ "$rg_out" = "$gr_out" ] && ok || bad "ripgrep and grep scan output differ"
q_out="$(bash "$S/scan.sh" quick --show-cards 2>&1)"
has "$q_out" "== AA-R1 First card (quick) ==" "scan quick lists quick cards"
lacks "$q_out" "AA-R2" "scan quick omits non-quick cards"
has "$q_out" "- Confirm: yes." "scan --show-cards prints the card"

# ---- scan: over the cap, the leads shown are spread across files -----------
# A card with more leads than --max shows them round-robin across files in
# path order (each file's first lead, then each file's second, and so on),
# printed in path and line order, so a file late in path order is never
# hidden behind earlier files. Under the cap, nothing changes.
SPR="$TMP/spread"
mkdir -p "$SPR/src"
printf 'dangerous_call(1)\ndangerous_call(2)\ndangerous_call(3)\ndangerous_call(4)\ndangerous_call(5)\n' > "$SPR/a.js"
printf 'dangerous_call(6)\ndangerous_call(7)\ndangerous_call(8)\n' > "$SPR/b.js"
printf 'dangerous_call(9)\n' > "$SPR/c.js"
printf 'dangerous_call(10)\n' > "$SPR/src/z.js"
# leads_of OUTPUT: the lines under the first card heading, up to a blank line.
leads_of() { printf '%s\n' "$1" | awk '/^== / { on = 1; next } on && !NF { exit } on'; }
spread() { (cd "$SPR" && bash "$S/scan.sh" AA-R1 "$@" 2>&1); }
spread_grep() { (cd "$SPR" && AUDITOR_NO_RG=1 bash "$S/scan.sh" AA-R1 "$@" 2>&1); }
all10="$(printf '%s\n' 'a.js:1: dangerous_call(1)' 'a.js:2: dangerous_call(2)' 'a.js:3: dangerous_call(3)' 'a.js:4: dangerous_call(4)' 'a.js:5: dangerous_call(5)' 'b.js:1: dangerous_call(6)' 'b.js:2: dangerous_call(7)' 'b.js:3: dangerous_call(8)' 'c.js:1: dangerous_call(9)' 'src/z.js:1: dangerous_call(10)')"
g="$(spread_grep --max 5)"
want="$(printf '%s\n' 'a.js:1: dangerous_call(1)' 'a.js:2: dangerous_call(2)' 'b.js:1: dangerous_call(6)' 'c.js:1: dangerous_call(9)' 'src/z.js:1: dangerous_call(10)' '(+5 more leads; rerun with --max 10 or a path argument to see them)')"
[ "$(leads_of "$g")" = "$want" ] && ok || bad "over the cap, every file shows its first lead, sorted, with +5 more (got: $(leads_of "$g"))"
[ "$(spread --max 5)" = "$g" ] && ok || bad "over the cap, ripgrep and grep pick the same leads"
g="$(spread_grep --max 7)"
want="$(printf '%s\n' 'a.js:1: dangerous_call(1)' 'a.js:2: dangerous_call(2)' 'a.js:3: dangerous_call(3)' 'b.js:1: dangerous_call(6)' 'b.js:2: dangerous_call(7)' 'c.js:1: dangerous_call(9)' 'src/z.js:1: dangerous_call(10)' '(+3 more leads; rerun with --max 10 or a path argument to see them)')"
[ "$(leads_of "$g")" = "$want" ] && ok || bad "over the cap, second and third leads go round-robin in path order (got: $(leads_of "$g"))"
leads_of "$g" | grep -v '^(' | sort -c -t: -k1,1 -k2,2n 2>/dev/null && ok || bad "over the cap, the chosen leads print sorted by path and line"
g="$(spread_grep --max 3)"
want="$(printf '%s\n' 'a.js:1: dangerous_call(1)' 'b.js:1: dangerous_call(6)' 'c.js:1: dangerous_call(9)' '(+7 more leads; rerun with --max 10 or a path argument to see them)')"
[ "$(leads_of "$g")" = "$want" ] && ok || bad "a cap below the file count shows the first lead of the first files (got: $(leads_of "$g"))"
g="$(spread_grep --max 0)"
want='(+10 more leads; rerun with --max 10 or a path argument to see them)'
[ "$(leads_of "$g")" = "$want" ] && ok || bad "--max 0 shows no leads and counts them all (got: $(leads_of "$g"))"
# Under the cap the output is exactly what it was before the spread: every
# lead in path and line order and no count line.
g="$(spread_grep)"
want="$(printf '\n== AA-R1 First card (quick) ==\n%s\n\nLeads are not findings. For each card, read the code around every lead and apply the card: Confirm, Not a finding if, Severity.\n' "$all10")"
[ "$g" = "$want" ] && ok || bad "under the cap, scan output is unchanged (got: $g)"
[ "$(spread_grep --max 10)" = "$g" ] && ok || bad "a cap equal to the lead count prints every lead and no count line"
[ "$(spread)" = "$g" ] && ok || bad "under the cap, ripgrep and grep give the same output"
[ "$(leads_of "$gr_out")" = "src/app.py:5: return dangerous_call(value)" ] && ok || bad "an under-cap card in the first project is unchanged (got: $(leads_of "$gr_out"))"

# ---- new-report -----------------------------------------------------------
out="$(bash "$S/new-report.sh" --mode full 2>&1)"
has "$out" "created testaudit.md (mode full)" "new-report creates the report"
out="$(bash "$S/new-report.sh" --mode full 2>&1)"
has "$out" "already exists" "new-report refuses to overwrite"
R="$PJ/testaudit.md"
has "$(cat "$R")" "- Active dimensions: AA, BB" "report lists active dimensions"
has "$(cat "$R")" "- Not applicable: CC (no match for: charlie markers)" "report lists n/a dimensions with reasons"

# Fill every placeholder the way a model would.
fill_report() {
  # fill_report FINDINGS_FILE: write a complete report with these findings.
  awk -v ff="$1" '
    BEGIN { while ((getline l < ff) > 0) findings = findings l "\n" }
    /^- Checked:/ { sub(/\{\{.*\}\}/, "AA-R1, AA-R2"); if (dim == "BB") sub(/AA-R1, AA-R2/, "BB-R1, BB-R2") }
    /^### AA:/ { dim = "AA" } /^### BB:/ { dim = "BB" }
    { gsub(/\{\{[^}]*\}\}/, "filled `src/app.py:5`") }
    /^<!-- One block per finding/ { print; printf "\n%s", findings; next }
    { print }
  ' "$R" > "$R.tmp" && mv "$R.tmp" "$R"
}

finding() {
  # finding ID SEV CONF EFF: one block citing src/app.py:5.
  printf '### [%s] Test finding %s\n- Severity: %s | Confidence: %s | Effort: %s | Dimension: %s\n- Location: `src/app.py:5`\n- Evidence: the handler returns `dangerous_call(value)`.\n- Impact: impact.\n- Recommendation: fix it.\n- Verify the fix: a test.\n- References: none\n- Related: none\n\n' "$1" "$1" "$2" "$3" "$4" "${1%-*}"
}

score_of() { bash "$S/score.sh" 2>&1 | awk '/^\*\*/ { print; exit }'; }
dim_row() { bash "$S/score.sh" 2>&1 | awk -F'|' -v d="$1" '$2 ~ "^ " d " " { gsub(/ /, "", $3); print $3; exit }'; }

run_case() {
  # run_case NAME FINDINGS...: fresh report with the given finding specs (ID:SEV:CONF:EFF).
  bash "$S/new-report.sh" --mode "${MODE:-full}" --force > /dev/null 2>&1
  : > "$TMP/f.md"
  shift
  for spec in "$@"; do
    OLDIFS="$IFS"; IFS=:; set -- $spec; IFS="$OLDIFS"
    finding "$1" "$2" "$3" "$4" >> "$TMP/f.md"
  done
  fill_report "$TMP/f.md"
  bash "$S/score.sh" --write > /dev/null 2>&1
}

run_case clean
has "$(score_of)" "Overall: 100/100, Grade A" "no findings scores 100"
chk="$(bash "$S/check-report.sh" 2>&1)"; has "$chk" "check-report: OK" "a complete report passes check-report"

run_case one-critical AA-001:Critical:Confirmed:S
[ "$(dim_row AA)" = "69" ] && ok || bad "one Critical holds its dimension at 69 (got $(dim_row AA))"
has "$(score_of)" "Overall: 79/100" "one Critical holds the overall at 79"

run_case floor-critical BB-001:Critical:Confirmed:S
has "$(score_of)" "Overall: 69/100" "a Critical in a floor dimension holds the overall at 69"

run_case two-critical AA-001:Critical:Confirmed:S AA-002:Critical:Likely:M
[ "$(dim_row AA)" = "50" ] && ok || bad "two Criticals score 100-50=50 (got $(dim_row AA))"
has "$(score_of)" "Overall: 69/100" "two Criticals hold the overall at 69"

run_case suspected AA-001:Critical:Suspected:S
[ "$(dim_row AA)" = "87" ] && ok || bad "a Suspected Critical deducts half and never caps (got $(dim_row AA))"

run_case lows AA-001:Low:Confirmed:S AA-002:Low:Confirmed:S AA-003:Low:Confirmed:S AA-004:Low:Confirmed:S AA-005:Low:Confirmed:S AA-006:Low:Confirmed:S AA-007:Low:Confirmed:S AA-008:Low:Confirmed:S AA-009:Low:Confirmed:S AA-010:Low:Confirmed:S AA-011:Low:Confirmed:S AA-012:Low:Confirmed:S
[ "$(dim_row AA)" = "90" ] && ok || bad "Low findings deduct at most 10 (got $(dim_row AA))"

run_case mixed AA-001:High:Confirmed:M BB-001:Medium:Likely:S
# AA 90, BB 97; overall = (50*90 + 30*97) / 80 = 92.6 -> 93
has "$(score_of)" "Overall: 93/100, Grade A" "weights re-normalize over active dimensions"
plan="$(awk '/BEGIN GENERATED: plan/{on=1;next} /END GENERATED: plan/{on=0} on' "$R")"
has "$plan" "Plan now (Critical or High, not Suspected, effort M or L), in this order: AA-001" "High effort M goes to Plan now"
has "$plan" "Schedule (Medium): BB-001" "Medium goes to Schedule"

MODE=quick run_case quick AA-001:Critical:Confirmed:S
has "$(score_of)" "Quick triage, not scored: 1 Critical" "quick mode is not scored"
MODE=only=AA run_case only AA-001:High:Confirmed:S
has "$(score_of)" "Partial score (only=AA): 90/100" "only= mode scores the listed dimensions"
has "$(cat "$R")" "- Not assessed: BB" "only= mode lists the rest as not assessed"

# ---- check-report failure messages ----------------------------------------
run_case checks AA-001:High:Confirmed:S
cp "$R" "$TMP/good.md"
sed 's/`dangerous_call(value)`/`safe_call(value)`/' "$TMP/good.md" > "$R"
has "$(bash "$S/check-report.sh" 2>&1)" "none of the code quoted in Evidence appears" "check-report catches a wrong quote"
sed 's/`src\/app.py:5`/`src\/app.py:500`/' "$TMP/good.md" > "$R"
has "$(bash "$S/check-report.sh" 2>&1)" "is outside the file" "check-report catches a line past the end"
sed 's/`src\/app.py:5`/`src\/missing.py:5`/' "$TMP/good.md" > "$R"
has "$(bash "$S/check-report.sh" 2>&1)" "does not exist" "check-report catches a missing file"
grep -v '^- Verify the fix:' "$TMP/good.md" > "$R"
has "$(bash "$S/check-report.sh" 2>&1)" "is missing \"- Verify the fix:\"" "check-report catches a missing field"
sed 's/Severity: High/Severity: Severe/' "$TMP/good.md" > "$R"
has "$(bash "$S/check-report.sh" 2>&1)" "Severity must be Critical, High, Medium, or Low" "check-report catches a bad severity"
sed 's/Severity: High/Severity: Medium/' "$TMP/good.md" > "$R"
has "$(bash "$S/check-report.sh" 2>&1)" "does not match the findings" "check-report catches stale generated blocks"
sed 's/- Checked: AA-R1, AA-R2/- Checked: AA-R1/' "$TMP/good.md" > "$R"
has "$(bash "$S/check-report.sh" 2>&1)" "do not list card(s) AA-R2" "check-report catches unworked cards"
sed 's/^Calibration: .*/Calibration: {{write it}}/' "$TMP/good.md" > "$R"
has "$(bash "$S/check-report.sh" 2>&1)" "placeholder(s) still unfilled" "check-report catches placeholders"
awk '{ print } /^<!-- One block per finding/ { print "Some prose that is not a finding." }' "$TMP/good.md" > "$R"
has "$(bash "$S/check-report.sh" 2>&1)" "text outside a finding block" "check-report catches stray text in Findings"
cp "$TMP/good.md" "$R"
has "$(bash "$S/check-report.sh" 2>&1)" "check-report: OK" "the restored report passes again"
has "$(bash "$S/score.sh" --chat 2>&1)" "Test audit complete: 94/100 (Grade A)." "score.sh --chat prints the headline"

# ---- check-report: every dimension in exactly one list ---------------------
sed 's/^- Not applicable: .*/- Not applicable: none/' "$TMP/good.md" > "$R"
has "$(bash "$S/check-report.sh" 2>&1)" "CC is in neither" "check-report catches a conditional dimension dropped from both lists"
sed 's/^- Not applicable: .*/- Not applicable: CC/' "$TMP/good.md" > "$R"
has "$(bash "$S/check-report.sh" 2>&1)" "CC is not applicable without a reason" "check-report wants a reason for each n/a dimension"
sed 's/^- Active dimensions: .*/- Active dimensions: AA, BB, AA/' "$TMP/good.md" > "$R"
has "$(bash "$S/check-report.sh" 2>&1)" "AA is listed more than once" "check-report catches a dimension listed twice"
sed 's/^- Not applicable: .*/- Not applicable: CC (no Charlie markers (none at all), checked)/' "$TMP/good.md" > "$R"
bash "$S/score.sh" --write > /dev/null 2>&1
has "$(bash "$S/check-report.sh" 2>&1)" "check-report: OK" "check-report accepts a reason with nested parentheses"
MODE=only=AA run_case only-lists AA-001:High:Confirmed:S
cp "$R" "$TMP/only.md"
sed 's/^- Not assessed: .*/- Not assessed: none/' "$TMP/only.md" > "$R"
has "$(bash "$S/check-report.sh" 2>&1)" "BB is in none of" "check-report catches a dimension missing in only= mode"
cp "$TMP/only.md" "$R"
has "$(bash "$S/check-report.sh" 2>&1)" "check-report: OK" "an only= report passes"

# ---- check-report: SYS members and Related ignore non-finding IDs ----------
set_sys() {
  # set_sys LINE: put LINE as the only systemic pattern, then rescore.
  awk -v l="$1" '
    /^## / { sys = ($0 == "## Systemic patterns (root causes)") }
    sys && /^## / { print; print ""; print l; print ""; next }
    sys { next }
    { print }' "$TMP/sys.md" > "$R"
  bash "$S/score.sh" --write > /dev/null 2>&1
}
run_case sys AA-001:Medium:Confirmed:S AA-002:Medium:Confirmed:M
cp "$R" "$TMP/sys.md"
set_sys "- SYS-1: one shared cause. Members: AA-001, AA-002. Root fix: name outputs by SHA-256 hashes (CWE-22, CVE-2023-30861)."
has "$(bash "$S/check-report.sh" 2>&1)" "check-report: OK" "SHA-256, CWE, and CVE IDs in a root fix are not members"
set_sys "- SYS-1: one shared cause. Members: AA-001. Related to AA-002. Root fix: hash with SHA-256."
out="$(bash "$S/check-report.sh" 2>&1)"
has "$out" "SYS-1 (line" "a SYS line with one member fails"
has "$out" "needs at least two member finding IDs" "only the Members part counts as members"
set_sys "- SYS-1: one shared cause. Members: none yet. Root fix: later."
out="$(bash "$S/check-report.sh" 2>&1)"
lacks "$out" "(line )" "a SYS line with no members still reports its line number"
lacks "$out" "which is not a finding" "a SYS line with no members lists no bogus member"
set_sys "- SYS-1: one shared cause. Members: AA-001, AA-002, AX-003. Root fix: one fix."
out="$(bash "$S/check-report.sh" 2>&1)"
has "$out" "SYS-1 lists AX-003, which is not a finding" "a mistyped member after Members: is reported"
has "$out" "AX is not a dimension of testauditor" "a mistyped member's message names the unknown prefix"
set_sys "- SYS-1: one shared cause. Members: AA-001, AA-002, AA-009. Root fix: one fix."
has "$(bash "$S/check-report.sh" 2>&1)" "SYS-1 lists AA-009, which is not a finding" "a member that is not a finding is reported"
set_sys "- SYS-1: AA-001 and AA-002 share one cause (see RFC-793 and AX-004). Root fix: one fix."
has "$(bash "$S/check-report.sh" 2>&1)" "check-report: OK" "with no Members: label, only IDs with a dimension prefix count"
set_sys "- SYS-1: one shared cause. Members: AA-001, AA-002. Root fix: one fix."
cp "$R" "$TMP/sys-ok.md"
sed 's/^- Related: none/- Related: SYS-1, see CWE-614, CVE-2023-30861, SHA-256, OWASP-123, GHSA-456/' "$TMP/sys-ok.md" > "$R"
bash "$S/score.sh" --write > /dev/null 2>&1
has "$(bash "$S/check-report.sh" 2>&1)" "check-report: OK" "well-known standard IDs in Related are not finding references"
sed 's/^- Related: none/- Related: AX-001/' "$TMP/sys-ok.md" > "$R"
bash "$S/score.sh" --write > /dev/null 2>&1
out="$(bash "$S/check-report.sh" 2>&1)"
has "$out" "Related names AX-001, which is not a finding or systemic pattern" "a mistyped Related ID is reported"
has "$out" "put CWE and CVE IDs under References" "a Related ID with an unknown prefix points to References"
sed 's/^- Related: none/- Related: AA-007/' "$TMP/sys-ok.md" > "$R"
bash "$S/score.sh" --write > /dev/null 2>&1
has "$(bash "$S/check-report.sh" 2>&1)" "Related names AA-007, which is not a finding" "a Related finding ID that does not exist is reported"
cp "$TMP/sys-ok.md" "$R"

# ---- new-report: only= is normalized --------------------------------------
out="$(bash "$S/new-report.sh" --mode 'only=AA, BB' --force 2>&1)"
has "$out" "(mode only=AA,BB)" "new-report normalizes spaces in only="
has "$(cat "$R")" "Mode: only=AA,BB." "the banner records the normalized only= list"
lacks "$(bash "$S/check-report.sh" 2>&1)" "they must match" "a normalized only= skeleton has no mode mismatch"
out="$(bash "$S/new-report.sh" --mode 'only=AA,,AA' --force 2>&1)"
has "$out" "(mode only=AA)" "new-report drops empty and repeated only= IDs"
rc=0; out="$(bash "$S/new-report.sh" --mode 'only=,' --force 2>&1)" || rc=$?
[ "$rc" -eq 2 ] && ok || bad "new-report rejects only= with no dimensions (exit $rc)"
has "$out" "needs at least one dimension" "new-report explains an empty only= list"

# ---- reports: never written through a symlink, temp files stay local -------
mkdir -p "$TMP/outside" "$TMP/tmpdir"
rm -f "$R"
ln -s ../outside/planted.md "$R"
rc=0; out="$(bash "$S/new-report.sh" --mode full 2>&1)" || rc=$?
[ "$rc" -eq 2 ] && ok || bad "new-report refuses a dangling symlinked report (exit $rc)"
has "$out" "is a symlink" "new-report says why it refuses"
[ ! -e "$TMP/outside/planted.md" ] && ok || bad "new-report created a file through a dangling symlink"
printf 'IMPORTANT USER FILE\n' > "$TMP/outside/victim.txt"
rm -f "$R"; ln -s ../outside/victim.txt "$R"
bash "$S/new-report.sh" --mode full --force > /dev/null 2>&1
[ "$(cat "$TMP/outside/victim.txt")" = "IMPORTANT USER FILE" ] && ok || bad "new-report --force wrote through a symlink"
rm -f "$R"
(umask 022 && bash "$S/new-report.sh" --mode full > /dev/null 2>&1)
has "$(ls -l "$R")" "-rw-r--r--" "a new report gets the usual file mode"
mv "$R" "$TMP/outside/real.md"; cp "$TMP/outside/real.md" "$TMP/real.before"
ln -s ../outside/real.md "$R"
rc=0; out="$(bash "$S/score.sh" --write 2>&1)" || rc=$?
[ "$rc" -eq 2 ] && ok || bad "score.sh --write refuses a symlinked report (exit $rc)"
cmp -s "$TMP/outside/real.md" "$TMP/real.before" && ok || bad "score.sh --write changed the symlink target"
rm -f "$R"; mkdir "$R"
rc=0; out="$(bash "$S/new-report.sh" --mode full --force 2>&1)" || rc=$?
[ "$rc" -eq 2 ] && ok || bad "new-report refuses a folder at the report path (exit $rc)"
rmdir "$R"
bash "$S/new-report.sh" --mode full > /dev/null 2>&1
TMPDIR="$TMP/tmpdir" bash "$S/score.sh" --write > /dev/null 2>&1
[ -z "$(ls -A "$TMP/tmpdir")" ] && ok || bad "score.sh --write left files in TMPDIR"
[ -z "$(ls -A "$PJ" | grep '^\.testaudit\.md\.')" ] && ok || bad "a report temp file was left in the project"
has "$(cat "$R")" "**Overall: 100/100" "score.sh --write still fills the report"
chmod 640 "$R"
(umask 022 && bash "$S/score.sh" --write > /dev/null 2>&1)
has "$(ls -l "$R")" "-rw-r-----" "score.sh --write keeps the report's permission bits"
chmod 600 "$R"
bash "$S/score.sh" --write > /dev/null 2>&1
has "$(ls -l "$R")" "-rw-------" "score.sh --write keeps a private report private"
(umask 022 && bash "$S/new-report.sh" --mode full --force > /dev/null 2>&1)
has "$(ls -l "$R")" "-rw-------" "new-report --force keeps a private report private"
bash "$S/score.sh" --write > /dev/null 2>&1
chmod 444 "$R"; cp "$R" "$TMP/ro.before"
if [ -w "$R" ]; then
  printf 'skip: running as root, so a read-only report is still writable and the read-only case did not run\n'
else
  rc=0; out="$(bash "$S/score.sh" --write 2>&1)" || rc=$?
  [ "$rc" -eq 2 ] && ok || bad "score.sh --write refuses a read-only report (exit $rc)"
  has "$out" "is read-only" "score.sh --write says why it refuses a read-only report"
  cmp -s "$R" "$TMP/ro.before" && ok || bad "score.sh --write replaced a read-only report"
fi
chmod 644 "$R"

# ---- file lists: exact regexes, regular files only -------------------------
# BSD awk and gawk strip backslashes from awk -v values, which once turned
# \.min\.js$ into .min.js$ (dropping admin.js) and *.ts into .ts (keeping
# hosts). These names catch any regression on the grep and ripgrep paths,
# with and without git.
make_files_project() {
  mkdir -p "$1/routes" "$1/public" "$1/src"
  printf 'dangerous_call(1)\nLINK_MARKER\n' > "$1/routes/admin.js"
  printf 'dangerous_call(2)\nDANGEROUS_CALL(3)\nconst result = dangerous_call(request.body.payload, { retries: 3, timeout: 5000 })\n' > "$1/routes/users.js"
  printf 'dangerous_call(4)\n' > "$1/routes/Zed.js"
  printf '.admin { color: red; }\n' > "$1/public/admin.css"
  printf 'dangerous_call(5)\n' > "$1/public/app.min.js"
  printf 'dangerous_call(6)\n' > "$1/public/app.js.map"
  printf 'dangerous_call(7)\n' > "$1/hosts"
  printf 'dangerous_call(8)\n' > "$1/src/happy"
  printf 'dangerous_call(9)\n' > "$1/xmap"
  printf 'package main\n' > "$1/main.go"
  printf 'example.com/x v1.0.0 h1:abc=\n' > "$1/go.sum"
  printf 'registry=https://example.invalid/\n' > "$1/.npmrc"
  printf '{}\n' > "$1/.eslintrc"
  printf 'LINK_MARKER\n' > "$1/productaudit.md"
}
check_files_project() {
  # check_files_project LABEL: run from inside a project made above (not in
  # a subshell, so the pass and fail counts survive).
  local inv langs g r
  inv="$(bash "$S/inventory.sh" 2>&1)"
  has "$inv" "files: 11 considered (5 source files" "$1: inventory counts exactly the regular, non-excluded files"
  langs="$(printf '%s\n' "$inv" | grep '^languages')"
  has "$langs" "js 3" "$1: admin.js counts as source"
  lacks "$langs" "sum" "$1: go.sum is not source"
  lacks "$langs" "npmrc" "$1: .npmrc is not source"
  lacks "$langs" "eslintrc" "$1: .eslintrc is not source"
  g="$(AUDITOR_NO_RG=1 bash "$S/scan.sh" AA-R1 2>&1)"
  r="$(bash "$S/scan.sh" AA-R1 2>&1)"
  has "$g" "routes/admin.js:1: dangerous_call(1)" "$1: admin.js is scanned"
  lacks "$g" "app.min.js" "$1: minified files are skipped"
  lacks "$g" "hosts" "$1: *.ts does not match hosts"
  lacks "$g" "src/happy" "$1: *.py does not match happy"
  [ "$r" = "$g" ] && ok || bad "$1: ripgrep and grep leads differ"
  g="$(AUDITOR_NO_RG=1 bash "$S/scan.sh" AA-R2 2>&1)"
  r="$(bash "$S/scan.sh" AA-R2 2>&1)"
  has "$g" "routes/admin.js:2: LINK_MARKER" "$1: a * glob scans project files"
  lacks "$r" "productaudit.md" "$1: the productauditor report is never scanned"
  lacks "$r" "linked/" "$1: ripgrep does not follow a symlinked folder"
  [ "$r" = "$g" ] && ok || bad "$1: ripgrep and grep leads differ for a * glob"
}
FP="$TMP/plain/files"
mkdir -p "$TMP/plain/ext"
printf 'LINK_MARKER\n' > "$TMP/plain/ext/outside.js"
make_files_project "$FP"
ln -s ../ext "$FP/linked"
cd "$FP" && check_files_project "no git"
cd "$PJ" || exit 1

FG="$TMP/git/files"
mkdir -p "$TMP/git/ext"
printf 'LINK_MARKER\n' > "$TMP/git/ext/outside.js"
make_files_project "$FG"
ln -s ../ext "$FG/linked"
ln -s routes/admin.js "$FG/alias.js"
printf 'dangerous_call(10)\n' > "$FG/gone.py"
printf 'dangerous_call(12)\n' > "$FG/typechanged.py"
printf 'dangerous_call(13)\nLINK_MARKER\n' > "$FG/sparse.py"
mkdir -p "$FG/vendored_lib"
printf 'LINK_MARKER\ndangerous_call(11)\n' > "$FG/vendored_lib/lib.js"
(cd "$FG/vendored_lib" && git init -q && git add -A && git -c user.name=t -c user.email=t@example.invalid commit -qm sub) || bad "git init (submodule)"
(cd "$FG" && git init -q && git add -A 2>/dev/null && git -c user.name=t -c user.email=t@example.invalid commit -qm init) || bad "git init (files project)"
# After the commit: a deleted tracked file, a tracked file now a symlink to
# outside the project, a skip-worktree entry (a sparse checkout leaves it
# out), and untracked entries git lists without a mode (a symlinked file,
# a symlinked folder, a nested repository).
rm -f "$FG/gone.py"
rm -f "$FG/typechanged.py"; ln -s ../ext/outside.js "$FG/typechanged.py"
(cd "$FG" && git update-index --skip-worktree sparse.py) || bad "git update-index (skip-worktree)"
rm -f "$FG/sparse.py"
ln -s routes/admin.js "$FG/untracked_alias.js"
ln -s ../ext "$FG/untracked_linked"
mkdir -p "$FG/nested_repo"
printf 'LINK_MARKER\n' > "$FG/nested_repo/n.js"
(cd "$FG/nested_repo" && git init -q) || bad "git init (nested repo)"
cd "$FG" && check_files_project "git"
cd "$PJ" || exit 1
out="$(cd "$FG" && bash "$S/scan.sh" all 2>&1)"
lacks "$out" "vendored_lib" "ripgrep does not search a submodule"
lacks "$out" "alias.js" "a symlinked file is not scanned twice"
lacks "$out" "gone.py" "a deleted tracked file is not listed"
lacks "$out" "typechanged.py" "a tracked file turned into a symlink is not listed"
lacks "$out" "sparse.py" "a skip-worktree entry is not listed"
lacks "$out" "untracked_" "an untracked symlink is not listed"
lacks "$out" "nested_repo" "an untracked nested repository is not listed"

# ---- leads do not depend on the user's grep or ripgrep setup or locale -----
# Only stdout is compared: a shell may warn on stderr about a locale or an
# option it does not know, which says nothing about the leads.
printf -- '--smart-case\n--max-columns=20\n' > "$TMP/ripgreprc"
g="$(cd "$FG" && AUDITOR_NO_RG=1 bash "$S/scan.sh" AA-R1 2>/dev/null)"
r="$(cd "$FG" && RIPGREP_CONFIG_PATH="$TMP/ripgreprc" bash "$S/scan.sh" AA-R1 2>/dev/null)"
lacks "$r" "DANGEROUS_CALL(3)" "a ripgreprc with --smart-case does not change case-sensitive cards"
lacks "$r" "Omitted long matching line" "a ripgreprc with --max-columns does not hide lead text"
[ "$r" = "$g" ] && ok || bad "a ripgreprc changed the leads"
r="$(cd "$FG" && GREP_OPTIONS=-i AUDITOR_NO_RG=1 bash "$S/scan.sh" AA-R1 2>/dev/null)"
[ "$r" = "$g" ] && ok || bad "GREP_OPTIONS changed the leads"
if locale -a 2>/dev/null | grep -qiE '^en_US[.]utf-?8$'; then
  r="$(cd "$FG" && LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 bash "$S/scan.sh" AA-R1 2>/dev/null)"
  [ "$r" = "$g" ] && ok || bad "the locale changed the order of the leads"
else
  printf 'skip: the en_US.UTF-8 locale is not installed, so the locale case did not run\n'
fi

# git names deleted files relative to the repository root unless told
# otherwise; a listing from a subfolder must still drop them.
rm -f "$FG/routes/Zed.js"
out="$(cd "$FG/routes" && bash "$S/inventory.sh" 2>&1)"
has "$out" "files: 2 considered" "a deleted file is dropped when listing from a subfolder"

# ---- a project inside a folder an outer repository ignores -----------------
OUT="$TMP/outer"
mkdir -p "$OUT/sandbox/app"
printf 'sandbox/\n' > "$OUT/.gitignore"
printf 'x = dangerous_call(1)\n' > "$OUT/sandbox/app/main.py"
(cd "$OUT" && git init -q && git add -A && git -c user.name=t -c user.email=t@example.invalid commit -qm outer) || bad "git init (outer repo)"
out="$(cd "$OUT/sandbox/app" && bash "$S/inventory.sh" 2>&1)"
has "$out" "git: not a git repository" "inventory ignores an outer repo that ignores this folder"
has "$out" "files: 1 considered (1 source files" "inventory lists the files of an ignored folder"
lacks "$out" "NO SOURCE CODE FOUND" "inventory does not stop in an ignored folder"
has "$(cd "$OUT/sandbox/app" && bash "$S/scan.sh" AA-R1 2>&1)" "main.py:1: x = dangerous_call(1)" "scan reads an ignored folder"
(cd "$OUT/sandbox/app" && bash "$S/new-report.sh" --mode full > /dev/null 2>&1)
has "$(cat "$OUT/sandbox/app/testaudit.md" 2>/dev/null)" "not a git repository" "new-report's banner ignores the outer repo"

# ---- SCAN_SKIP_RE: a per-skill scan skip (tests and lockfiles) -------------
SKP="$TMP/skipproj"
mkdir -p "$SKP/src"
printf 'x = dangerous_call(1)\n' > "$SKP/src/app.ts"
printf 'x = dangerous_call(2)\n' > "$SKP/src/app.test.ts"
printf '{ "dangerous_call(3)": 1 }\n' > "$SKP/package-lock.json"
(cd "$SKP" && git init -q && git add -A && git -c user.name=t -c user.email=t@example.invalid commit -qm skip) || bad "git init (skip project)"
out="$(cd "$SKP" && bash "$S/scan.sh" AA-R2 2>&1; cd "$SKP" && bash "$S/scan.sh" AA-R1 2>&1)"
has "$out" "src/app.test.ts:1" "without SCAN_SKIP_RE, scan reads test files"
lacks "$(cd "$SKP" && bash "$S/inventory.sh" 2>&1)" "skipped by this auditor" "without SCAN_SKIP_RE, inventory prints no skip line"
cp "$SK/assets/skill.conf" "$TMP/skill.conf.before"
printf "%s\n" "SCAN_SKIP_RE='[.]test[.][A-Za-z0-9]+\$|(^|/)package-lock[.]json\$'" >> "$SK/assets/skill.conf"
out="$(cd "$SKP" && bash "$S/scan.sh" AA-R1 2>&1)"
has "$out" "src/app.ts:1" "with SCAN_SKIP_RE, scan still reads other files"
lacks "$out" "src/app.test.ts" "with SCAN_SKIP_RE, scan skips a matching test file"
lacks "$out" "package-lock.json" "with SCAN_SKIP_RE, scan skips a matching lockfile"
out="$(cd "$SKP" && bash "$S/inventory.sh" 2>&1)"
has "$out" "skipped by this auditor: 2 file(s)" "inventory counts the files SCAN_SKIP_RE skips"
has "$out" "files: 1 considered" "inventory leaves skipped files out of the totals"
cp "$TMP/skill.conf.before" "$SK/assets/skill.conf"

printf 'tests: %d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
