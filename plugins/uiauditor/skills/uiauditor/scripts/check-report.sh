#!/usr/bin/env bash
# check-report.sh: validate the audit report before you finish. Checks the
# section layout, leftover placeholders, every finding's fields, that every
# cited path:line exists and that the Evidence quotes code found there, the
# dimension notes, and that the generated blocks match the findings.
#
# Usage: bash <skill>/scripts/check-report.sh [report] [--root DIR]
#   report  defaults to this skill's report file in the current directory
#   --root  directory the cited paths are relative to (default: the report's)
# Prints "check-report: OK" and exits 0, or lists problems and exits 1.
# Read-only.

set -u
. "$(cd "$(dirname "$0")" && pwd)/_lib.sh"
as_load_conf

usage() {
  sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'
}

REPORT=""
ROOT=""
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --root) ROOT="${2:-}"; shift ;;
    -*) as_die "unknown option: $1" ;;
    *) REPORT="$1" ;;
  esac
  shift
done
[ -n "$REPORT" ] || REPORT="$REPORT_FILE"
[ -f "$REPORT" ] || as_die "no report at $REPORT; create it with: bash $AS_SKILL_DIR/scripts/new-report.sh"
[ -n "$ROOT" ] || ROOT="$(cd "$(dirname "$REPORT")" && pwd)"
[ -d "$ROOT" ] || as_die "--root $ROOT is not a directory"

PARSED="$(awk -f "$AS_SCRIPT_DIR/_parse.awk" "$REPORT")"
PROBS=""
NPROB=0
problem() {
  NPROB=$((NPROB + 1))
  PROBS="$PROBS$NPROB. $*
"
}
rec() {
  # rec TYPE: parsed records of one type, type column removed.
  printf '%s\n' "$PARSED" | awk -F'\t' -v t="$1" '$1 == t { sub(/^[^\t]*\t/, ""); print }'
}
meta() {
  printf '%s\n' "$PARSED" | awk -F'\t' -v k="$1" '$1 == "META" && $2 == k { print $3; exit }'
}

# 1. Sections, in order, each once.
REQUIRED="Snapshot|Map|Overall score|What to fix first|Strengths (preserve these)|Systemic patterns (root causes)|Findings|Dimension notes|Remediation plan|Scope and limitations|How to use this report (for the acting agent)"
headings="$(rec H2 | cut -f2)"
section_report="$(printf '%s\n' "$headings" | awk -v req="$REQUIRED" '
  BEGIN { n = split(req, want, "|"); for (i = 1; i <= n; i++) pos[want[i]] = i }
  NF {
    if (!($0 in pos)) { print "unexpected section \"## " $0 "\"; use only the template sections (put extra material inside them)"; next }
    seen[$0]++
    if (seen[$0] == 2) print "section \"## " $0 "\" appears more than once"
    if (pos[$0] < last) print "section \"## " $0 "\" is out of order; keep the template order"
    last = pos[$0]
  }
  END { for (i = 1; i <= n; i++) if (!(want[i] in seen)) print "missing section \"## " want[i] "\"; restore it from the template" }')"
if [ -n "$section_report" ]; then
  while IFS= read -r l; do problem "$l"; done <<EOF
$section_report
EOF
fi

# 2. Placeholders left.
ph="$(rec PH)"
if [ -n "$ph" ]; then
  count="$(printf '%s\n' "$ph" | wc -l | tr -d ' ')"
  first="$(printf '%s\n' "$ph" | head -5 | awk -F'\t' '{ printf "%sline %s: %s", (NR > 1 ? "; " : ""), $1, $2 }')"
  problem "$count placeholder(s) still unfilled; replace every {{...}} with real content ($first)"
fi

# 3. Mode and dimensions.
MODE="$(meta mode)"
ACTIVE_RAW="$(meta active)"
NA_RAW="$(meta na)"
case "$MODE" in
  full|quick|only=*) ;;
  "") problem "the banner has no \"Mode: ...\" text; restore the banner line from the template" ;;
  *) problem "unknown mode \"$MODE\" in the banner; use full, quick, or only=DIM,DIM" ;;
esac
ACTIVE="$(printf '%s' "$ACTIVE_RAW" | tr ', ' '\n\n' | awk 'NF')"
for d in $ACTIVE; do
  as_is_dim "$d" || problem "\"- Active dimensions:\" lists $d, which is not a dimension of $SKILL_NAME ($(as_dim_ids | tr '\n' ' '))"
done
NA_IDS="$(printf '%s\n' "$NA_RAW" | sed 's/([^)]*)//g' | tr ', )' '\n\n\n' | awk 'NF')"
for d in $NA_IDS; do
  as_is_dim "$d" || continue
  if printf '%s\n' "$ACTIVE" | grep -qx "$d"; then
    problem "$d is listed both as active and as not applicable; keep it in one list"
  fi
  if [ "$(as_dim_field "$d" 3)" = "always" ]; then
    problem "$d is always audited and cannot be not applicable; move it back to \"- Active dimensions:\""
  fi
done
case "$MODE" in
  full|quick)
    for d in $(as_dim_ids); do
      if [ "$(as_dim_field "$d" 3)" = "always" ] && ! printf '%s\n' "$ACTIVE" | grep -qx "$d"; then
        problem "$d is always audited in $MODE mode but is missing from \"- Active dimensions:\""
      fi
    done
    ;;
  only=*)
    want="$(printf '%s' "${MODE#only=}" | tr ',' '\n' | awk 'NF' | sort)"
    have="$(printf '%s\n' "$ACTIVE" | awk 'NF' | sort)"
    [ "$want" = "$have" ] || problem "mode $MODE but \"- Active dimensions:\" lists $(printf '%s' "$ACTIVE" | tr '\n' ' '); they must match"
    ;;
esac

# 4. Findings.
fx="$(rec FX)"
if [ -n "$fx" ]; then
  while IFS="$AS_TAB" read -r lno msg; do
    problem "line $lno: $msg"
  done <<EOF
$fx
EOF
fi

FIDS="$(rec F | cut -f1)"
dups="$(printf '%s\n' "$FIDS" | awk 'NF' | sort | uniq -d)"
for d in $dups; do problem "finding ID $d is used more than once; give each finding its own number"; done
SYSIDS="$(rec SYS | cut -f1)"

finding_field() {
  # finding_field ID KEY
  printf '%s\n' "$PARSED" | awk -F'\t' -v id="$1" -v k="$2" '$1 == "FF" && $2 == id && $3 == k { print $4; exit }'
}

norm() {
  tr '\t' ' ' | tr -s ' ' | sed 's/^ //; s/ $//'
}

window() {
  # window PATH START END: the cited lines plus 6 lines of context each side.
  local path s e sha gpath
  path="$1"; s=$(( $2 - 6 )); e=$(( $3 + 6 ))
  [ "$s" -ge 1 ] || s=1
  case "$path" in
    [0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]*:*)
      sha="${path%%:*}"; gpath="${path#*:}"
      git -C "$ROOT" show "$sha:$gpath" 2>/dev/null | awk -v s="$s" -v e="$e" 'NR >= s && NR <= e'
      ;;
    *)
      awk -v s="$s" -v e="$e" 'NR >= s && NR <= e' "$ROOT/$path" 2>/dev/null
      ;;
  esac
}

line_count() {
  local path sha gpath
  path="$1"
  case "$path" in
    [0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]*:*)
      sha="${path%%:*}"; gpath="${path#*:}"
      if git -C "$ROOT" cat-file -e "$sha:$gpath" 2>/dev/null; then
        git -C "$ROOT" show "$sha:$gpath" 2>/dev/null | awk 'END { print NR }'
      else
        printf -- '-1\n'
      fi
      ;;
    *)
      if [ -f "$ROOT/$path" ]; then awk 'END { print NR }' "$ROOT/$path"; else printf -- '-1\n'; fi
      ;;
  esac
}

for id in $FIDS; do
  dim="${id%-*}"
  fs="$(printf '%s\n' "$PARSED" | awk -F'\t' -v id="$id" '$1 == "FS" && $2 == id { print $3 "\t" $4 "\t" $5 "\t" $6; exit }')"
  sev="$(printf '%s' "$fs" | cut -f1)"
  conf="$(printf '%s' "$fs" | cut -f2)"
  eff="$(printf '%s' "$fs" | cut -f3)"
  fdim="$(printf '%s' "$fs" | cut -f4)"
  title="$(printf '%s\n' "$PARSED" | awk -F'\t' -v id="$id" '$1 == "F" && $2 == id { print $4; exit }')"

  [ -n "$title" ] || problem "$id has no title after the ID in its heading"
  if ! as_is_dim "$dim"; then
    problem "$id: $dim is not a dimension of $SKILL_NAME; file it under the dimension whose card found it"
  elif ! printf '%s\n' "$ACTIVE" | grep -qx "$dim"; then
    problem "$id is filed under $dim, which is not active in this report; move it to an active dimension or add $dim to \"- Active dimensions:\" if it applies"
  fi
  case "$sev" in Critical|High|Medium|Low) ;; *) problem "$id: Severity must be Critical, High, Medium, or Low (found \"$sev\"); the line is \"- Severity: High | Confidence: Confirmed | Effort: S | Dimension: $dim\"" ;; esac
  case "$conf" in Confirmed|Likely|Suspected) ;; *) problem "$id: Confidence must be Confirmed, Likely, or Suspected (found \"$conf\")" ;; esac
  case "$eff" in S|M|L) ;; *) problem "$id: Effort must be S, M, or L (found \"$eff\")" ;; esac
  [ "$fdim" = "$dim" ] || problem "$id: Dimension must be $dim, the ID prefix (found \"$fdim\")"

  for key in location evidence impact recommendation "verify the fix" references related; do
    val="$(finding_field "$id" "$key")"
    if [ -z "$val" ]; then
      label="$(printf '%s' "$key" | awk '{ print toupper(substr($0, 1, 1)) substr($0, 2) }')"
      problem "$id is missing \"- $label:\" (every finding needs Location, Evidence, Impact, Recommendation, Verify the fix, References, Related)"
    fi
  done

  rel="$(finding_field "$id" related)"
  if [ -n "$rel" ] && ! printf '%s' "$rel" | grep -qi '^none'; then
    for ref in $(printf '%s\n' "$rel" | awk '{ s = $0; while (match(s, /(SYS-[0-9]+|[A-Z][A-Z0-9]*-[0-9][0-9][0-9])/)) { print substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH) } }'); do
      if ! printf '%s\n%s\n' "$FIDS" "$SYSIDS" | grep -qx "$ref"; then
        problem "$id: Related names $ref, which is not a finding or systemic pattern in this report"
      fi
    done
  fi

  locs="$(printf '%s\n' "$PARSED" | awk -F'\t' -v id="$id" '$1 == "FL" && $2 == id { print $3 "\t" $4 "\t" $5 }')"
  if [ -z "$locs" ]; then
    problem "$id: Location has no \`path:line\` in backticks; cite at least one file and line you opened, for example \`src/app.js:42\`"
    continue
  fi
  bad_loc=0
  while IFS="$AS_TAB" read -r path start end; do
    [ -n "$path" ] || continue
    case "$path" in
      /*) problem "$id: \`$path:$start\` is absolute; cite paths relative to the project root"; bad_loc=1; continue ;;
    esac
    path="${path#./}"
    n="$(line_count "$path")"
    if [ "$n" -lt 0 ]; then
      problem "$id: cited file \`$path\` does not exist under $ROOT; cite a file you actually opened"
      bad_loc=1
    elif [ "$start" -lt 1 ] || [ "$end" -lt "$start" ] || [ "$end" -gt "$n" ]; then
      problem "$id: \`$path:$start\` is outside the file (it has $n lines); re-open the file and cite the real line"
      bad_loc=1
    fi
  done <<EOF
$locs
EOF
  [ "$bad_loc" -eq 0 ] || continue

  # Evidence must quote code found at (or within 6 lines of) the first location.
  first="$(printf '%s\n' "$locs" | head -1)"
  fpath="$(printf '%s' "$first" | cut -f1)"; fpath="${fpath#./}"
  fstart="$(printf '%s' "$first" | cut -f2)"
  fend="$(printf '%s' "$first" | cut -f3)"
  win="$(window "$fpath" "$fstart" "$fend" | norm)"
  spans="$(printf '%s\n' "$PARSED" | awk -F'\t' -v id="$id" '$1 == "FE" && $2 == id { print $3 }')"
  quoted=0
  matched=0
  if [ -n "$spans" ]; then
    while IFS= read -r span; do
      sp="$(printf '%s' "$span" | norm)"
      [ "${#sp}" -ge 6 ] || continue
      quoted=1
      if printf '%s\n' "$win" | grep -F -q -e "$sp"; then
        matched=1
        break
      fi
    done <<EOF
$spans
EOF
  fi
  if [ "$quoted" -eq 0 ]; then
    problem "$id: Evidence quotes no code; copy the exact code from \`$fpath:$fstart\` into Evidence in backticks (at least 6 characters)"
  elif [ "$matched" -eq 0 ]; then
    problem "$id: none of the code quoted in Evidence appears at \`$fpath:$fstart\` (within 6 lines); re-open the file and copy the code exactly, or fix the line number"
  fi

done

# 5. Systemic patterns.
syslines="$(rec SYS)"
if [ -n "$syslines" ]; then
  while IFS="$AS_TAB" read -r sid members lno; do
    [ -n "$sid" ] || continue
    nmem="$(printf '%s' "$members" | tr ',' '\n' | awk 'NF' | wc -l | tr -d ' ')"
    [ "$nmem" -ge 2 ] || problem "$sid (line $lno) needs at least two member finding IDs; a single finding is not a pattern"
    for m in $(printf '%s' "$members" | tr ',' ' '); do
      printf '%s\n' "$FIDS" | grep -qx "$m" || problem "$sid lists $m, which is not a finding in this report"
    done
  done <<EOF
$syslines
EOF
fi

# 6. Dimension notes: every active dimension, every card worked.
NOTES="$(rec N)"
HEADS="$(rec NH | cut -f1)"
for d in $ACTIVE; do
  as_is_dim "$d" || continue
  if ! printf '%s\n' "$HEADS" | grep -qx "$d"; then
    problem "Dimension notes has no \"### $d: ...\" subsection; add it with \"- Checked:\" and \"- Note:\" lines"
    continue
  fi
  listed="$(printf '%s\n' "$NOTES" | awk -F'\t' -v d="$d" '$1 == d { print $2; exit }')"
  if [ -z "$listed" ]; then
    problem "$d notes have no \"- Checked:\" line listing the card IDs you worked"
    continue
  fi
  if [ "$MODE" = "quick" ]; then
    expected="$(grep -E "^### $d-R[0-9]+ .*\\(quick\\)[[:space:]]*\$" "$AS_REFS/$d.md" 2>/dev/null | awk '{ print $2 }')"
  else
    expected="$(grep -E "^### $d-R[0-9]+ " "$AS_REFS/$d.md" 2>/dev/null | awk '{ print $2 }')"
  fi
  [ "$listed" != "PLACEHOLDER" ] || continue
  if [ "$listed" = "none" ]; then
    [ -z "$expected" ] || problem "$d notes say Checked: none, but $d has cards to work: $(printf '%s' "$expected" | tr '\n' ' ')"
    continue
  fi
  for c in $(printf '%s' "$listed" | tr ',' ' '); do
    printf '%s\n' "$expected" | grep -qx "$c" || grep -Eq "^### $c " "$AS_REFS/$d.md" 2>/dev/null || problem "$d notes list $c, which is not a card in references/$d.md"
  done
  missing="$(printf '%s\n' "$expected" | while read -r c; do [ -n "$c" ] || continue; printf '%s' "$listed" | tr ',' '\n' | grep -qx "$c" || printf '%s ' "$c"; done | sed 's/ $//')"
  [ -z "$missing" ] || problem "$d notes do not list card(s) $missing; work every card of the dimension (read the code it points to) and list it under Checked"
done

# 7. Strengths.
st="$(rec ST)"
st_count="$(printf '%s' "$st" | cut -f1)"
st_none="$(printf '%s' "$st" | cut -f2)"
if [ "${st_count:-0}" -eq 0 ] && [ "${st_none:-0}" -ne 1 ]; then
  problem "Strengths has no \`path:line\` citation; cite the code for each strength, or write \"None found.\""
fi

# 8. Generated blocks match the findings.
for name in score fix-first plan; do
  b="$(printf '%s\n' "$PARSED" | awk -F'\t' -v n="$name" '$1 == "G" && $2 == n && $3 == "begin" { c++ } END { print c + 0 }')"
  e="$(printf '%s\n' "$PARSED" | awk -F'\t' -v n="$name" '$1 == "G" && $2 == n && $3 == "end" { c++ } END { print c + 0 }')"
  if [ "$b" != "1" ] || [ "$e" != "1" ]; then
    problem "the \"$name\" GENERATED markers are missing or repeated; copy the marker pair from the template and run score.sh --write"
  fi
done
expected_blocks="$(bash "$AS_SCRIPT_DIR/score.sh" --blocks "$REPORT" 2>/dev/null)"
score_probs="$(printf '%s\n' "$expected_blocks" | awk '/^#BLOCK / { on = ($2 == "problems"); next } on && NF')"
if [ -n "$score_probs" ]; then
  while IFS= read -r l; do problem "scoring: $l"; done <<EOF
$score_probs
EOF
fi
for name in score fix-first plan; do
  want="$(printf '%s\n' "$expected_blocks" | awk -v n="$name" '/^#BLOCK / { on = ($2 == n); next } on')"
  have="$(awk -v n="$name" '
    /^<!-- BEGIN GENERATED: / { x = $0; sub(/^<!-- BEGIN GENERATED: /, "", x); sub(/[ (].*$/, "", x); on = (x == n); next }
    /^<!-- END GENERATED: / { on = 0 }
    on' "$REPORT")"
  if [ "$want" != "$have" ]; then
    problem "the generated \"$name\" block does not match the findings (stale or edited by hand); run: bash $AS_SKILL_DIR/scripts/score.sh --write"
  fi
done

# 9. The acting-agent protocol is intact.
grep -q '^1\. Triage by severity and confidence' "$REPORT" && grep -q '^8\. Re-run the audit to measure progress' "$REPORT" ||
  problem "the \"How to use this report\" steps are missing or edited; restore all eight steps from the template"

NF_COUNT="$(printf '%s\n' "$FIDS" | awk 'NF' | wc -l | tr -d ' ')"
if [ "$NPROB" -eq 0 ]; then
  headline="$(printf '%s\n' "$expected_blocks" | awk '/^#BLOCK / { on = ($2 == "score"); next } on && NF { print; exit }')"
  printf 'check-report: OK (%s, %s findings, mode %s). %s\n' "$(basename "$REPORT")" "$NF_COUNT" "$MODE" "$headline"
  exit 0
fi
printf 'check-report: %s problem(s) in %s\n' "$NPROB" "$REPORT"
printf '%s' "$PROBS" | head -40
[ "$NPROB" -le 40 ] || printf '(+%s more; fix these first, then rerun)\n' "$((NPROB - 40))"
printf '\nFix them in %s, then rerun: bash %s/scripts/check-report.sh\n' "$REPORT" "$AS_SKILL_DIR"
exit 1
