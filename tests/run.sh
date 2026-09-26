#!/usr/bin/env bash
# tests/run.sh: golden tests for the shared auditor scripts.
#
# Builds a throwaway test skill from shared/ (three dimensions, one of them a
# floor and one conditional) and a throwaway project, then checks inventory,
# scan (ripgrep and grep paths), new-report, score arithmetic and caps, the
# generated blocks, and check-report's failure messages.
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
printf '# card\tflags\tglobs\tregex\nAA-R1\tq\t@code\tdangerous_call\\(\nBB-R1\ti\t*.py\tpassword[[:space:]]*=\n' > "$SK/assets/patterns.tsv"
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

printf 'tests: %d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
