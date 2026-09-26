#!/usr/bin/env bash
# new-report.sh: create the audit report skeleton at the project root.
#
# Usage: bash <skill>/scripts/new-report.sh [--mode full|quick|only=DIM,DIM] [--force] [path ...]
#   --mode   full (default), quick (Critical-class cards only, no scores),
#            or only=DIM,DIM (a subset of dimensions, partial score)
#   --force  replace an existing report instead of refusing
#   path     limit the audit scope to these paths (recorded in the banner)
# Run from the project root. Writes exactly one file: the report.

set -u
. "$(cd "$(dirname "$0")" && pwd)/_lib.sh"
as_load_conf

usage() {
  sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'
}

MODE="full"
FORCE=0
SCOPE_ARGS=""
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --mode) MODE="${2:-}"; shift ;;
    --mode=*) MODE="${1#--mode=}" ;;
    --force) FORCE=1 ;;
    -*) as_die "unknown option: $1" ;;
    *) SCOPE_ARGS="$SCOPE_ARGS$1
" ;;
  esac
  shift
done

ONLY=""
case "$MODE" in
  full|quick) ;;
  only=*)
    ONLY="$(printf '%s' "${MODE#only=}" | tr ',' ' ')"
    for d in $ONLY; do
      as_is_dim "$d" || as_die "unknown dimension in --mode $MODE: $d (dimensions: $(as_dim_ids | tr '\n' ' '))"
    done
    [ -n "$ONLY" ] || as_die "--mode only= needs at least one dimension, for example only=$(as_dim_ids | head -1)"
    ;;
  *) as_die "unknown mode: $MODE (use full, quick, or only=DIM,DIM)" ;;
esac

REPORT="$REPORT_FILE"
if [ -e "$REPORT" ] && [ "$FORCE" -ne 1 ]; then
  printf '%s already exists. Keep editing it, or rerun with --force to start over.\n' "$REPORT" >&2
  exit 1
fi

if [ -n "$SCOPE_ARGS" ]; then
  OLDIFS="$IFS"
  IFS='
'
  set -f
  # shellcheck disable=SC2086
  AS_FILE_LIST="$(as_files $SCOPE_ARGS)"
  set +f
  IFS="$OLDIFS"
  SCOPE="$(printf '%s' "$SCOPE_ARGS" | awk 'NF' | awk '{ printf "%s%s", (NR > 1 ? ", " : ""), $0 }')"
else
  AS_FILE_LIST="$(as_files)"
  SCOPE="whole project"
fi

STATUS="$(as_probe_surfaces | as_dim_status)"

if [ -n "$ONLY" ]; then
  ACTIVE="$(printf '%s' "$ONLY" | tr ' ' '\n' | awk 'NF' | awk '{ printf "%s%s", (NR > 1 ? ", " : ""), $0 }')"
  NA="$(printf '%s\n' "$STATUS" | awk -F'\t' -v only=" $ONLY " '$2 == "na" && index(only, " " $1 " ") == 0 { printf "%s%s (%s)", (n++ ? ", " : ""), $1, $3 }')"
  NOT_ASSESSED="$(printf '%s\n' "$STATUS" | awk -F'\t' -v only=" $ONLY " '$2 == "active" && index(only, " " $1 " ") == 0 { printf "%s%s", (n++ ? ", " : ""), $1 }')"
else
  ACTIVE="$(printf '%s\n' "$STATUS" | awk -F'\t' '$2 == "active" { printf "%s%s", (n++ ? ", " : ""), $1 }')"
  NA="$(printf '%s\n' "$STATUS" | awk -F'\t' '$2 == "na" { printf "%s%s (%s)", (n++ ? ", " : ""), $1, $3 }')"
  NOT_ASSESSED=""
fi
[ -n "$NA" ] || NA="none"
[ -n "$NOT_ASSESSED" ] || NOT_ASSESSED="none"

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  commit="$(git rev-parse --short HEAD 2>/dev/null || printf 'no commits yet')"
  branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || printf 'unknown')"
  changed="$(git status --porcelain 2>/dev/null | awk -v r="$REPORT" '$NF != r' | wc -l | tr -d ' ')"
  COMMIT="commit $commit on $branch"
  [ "$changed" = "0" ] || COMMIT="$COMMIT, $changed uncommitted change(s)"
else
  COMMIT="not a git repository"
fi

# One notes subsection per active dimension, in table order.
NOTES=""
for d in $(printf '%s' "$ACTIVE" | tr ',' ' '); do
  name="$(as_dim_field "$d" 5)"
  if [ "$MODE" = "quick" ]; then
    if [ -f "$AS_REFS/$d.md" ] && grep -Eq '^### [A-Z][A-Z0-9]*-R[0-9]+ .*\(quick\)[[:space:]]*$' "$AS_REFS/$d.md"; then
      checked="{{the (quick) card IDs of this dimension you worked through, for example $d-R1}}"
    else
      checked="none (this dimension has no quick cards)"
    fi
  else
    checked="{{every card ID of this dimension you worked through, for example $d-R1, $d-R2}}"
  fi
  NOTES="$NOTES### $d: $name
- Checked: $checked
- Note: {{one or two sentences tying this dimension's result to its findings, or saying what you checked and found clean}}

"
done

AS_V_REPORT_TITLE="$REPORT_TITLE" \
AS_V_PROJECT="$(basename "$(pwd)")" \
AS_V_AUDIT_NOUN="$AUDIT_NOUN" \
AS_V_DATE="$(date +%Y-%m-%d)" \
AS_V_BANNER="$BANNER" \
AS_V_MODE="$MODE" \
AS_V_SCOPE="$SCOPE" \
AS_V_SKILL_NAME="$SKILL_NAME" \
AS_V_SUITE_VERSION="$AS_SUITE_VERSION" \
AS_V_COMMIT="$COMMIT" \
AS_V_ACTIVE="$ACTIVE" \
AS_V_NA="$NA" \
AS_V_NOT_ASSESSED="$NOT_ASSESSED" \
AS_V_MAP_HINT="$MAP_HINT" \
AS_V_DIMENSION_NOTES="$(printf '%s' "$NOTES" | sed '$d')" \
AS_V_DOMAIN_RULE="$DOMAIN_RULE" \
awk '
  function replace_all(s, key, val,    out, p) {
    out = ""
    while ((p = index(s, key)) > 0) {
      out = out substr(s, 1, p - 1) val
      s = substr(s, p + length(key))
    }
    return out s
  }
  BEGIN {
    n = split("REPORT_TITLE PROJECT AUDIT_NOUN DATE BANNER MODE SCOPE SKILL_NAME SUITE_VERSION COMMIT ACTIVE NA NOT_ASSESSED MAP_HINT DIMENSION_NOTES DOMAIN_RULE", keys, " ")
  }
  {
    line = $0
    for (i = 1; i <= n; i++) line = replace_all(line, "@@" keys[i] "@@", ENVIRON["AS_V_" keys[i]])
    print line
  }
' "$AS_ASSETS/report-template.md" > "$REPORT" || as_die "could not write $REPORT"

S="$AS_SKILL_DIR"
printf 'created %s (mode %s)\n' "$REPORT" "$MODE"
printf '  active: %s\n  not applicable: %s\n' "$ACTIVE" "$NA"
[ "$NOT_ASSESSED" = "none" ] || printf '  not assessed: %s\n' "$NOT_ASSESSED"
printf '\nnext steps:\n'
printf '  1. Read %s/references/example-report.md once. Fill Snapshot and Map in %s.\n' "$S" "$REPORT"
if [ "$MODE" = "quick" ]; then
  printf '  2. Run: bash %s/scripts/scan.sh quick\n' "$S"
  printf '     For each (quick) card of each active dimension: read its card in %s/references/<DIM>.md, confirm or refute every lead by reading the code, and add confirmed findings.\n' "$S"
else
  printf '  2. For each active dimension, in this order: %s\n' "$ACTIVE"
  printf '     a. read %s/references/<DIM>.md\n' "$S"
  printf '     b. run: bash %s/scripts/scan.sh <DIM>\n' "$S"
  printf '     c. apply every card: confirm or refute each lead by reading the code; add each confirmed finding under ## Findings\n'
  printf '     d. fill that dimension'"'"'s notes (Checked: card IDs)\n'
fi
printf '  3. Group repeats into systemic patterns (SYS-1, ...), write Strengths, Scope and limitations.\n'
printf '  4. Run: bash %s/scripts/score.sh --write      then write the Verdict and Calibration lines.\n' "$S"
printf '  5. Run: bash %s/scripts/check-report.sh       fix every problem it lists; rerun until it prints OK.\n' "$S"
printf '  6. Run: bash %s/scripts/score.sh --chat       and send its output as your final message.\n' "$S"
