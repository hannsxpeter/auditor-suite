#!/usr/bin/env bash
# score.sh: compute the scorecard, "What to fix first", and the remediation
# buckets from the findings in the report, so no model does the arithmetic.
#
# Usage: bash <skill>/scripts/score.sh [--write | --chat | --blocks] [report]
#   (no flag)  print the generated blocks
#   --write    put them into the report between its GENERATED markers
#   --chat     print the final chat summary (send it as your last message)
#   --blocks   machine output for check-report.sh
# Run from the project root. The report defaults to this skill's report file.
# Only --write writes, and only into the report.

set -u
. "$(cd "$(dirname "$0")" && pwd)/_lib.sh"
as_load_conf

usage() {
  sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'
}

ACTION="print"
REPORT=""
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --write) ACTION="write" ;;
    --chat) ACTION="chat" ;;
    --blocks) ACTION="blocks" ;;
    -*) as_die "unknown option: $1" ;;
    *) REPORT="$1" ;;
  esac
  shift
done
[ -n "$REPORT" ] || REPORT="$REPORT_FILE"
[ -f "$REPORT" ] || as_die "no report at $REPORT; create it first with: bash $AS_SKILL_DIR/scripts/new-report.sh"

BLOCKS="$(awk -v dims=" $(as_dim_ids | tr '\n' ' ')" -f "$AS_SCRIPT_DIR/_parse.awk" "$REPORT" |
  awk -f "$AS_SCRIPT_DIR/_score.awk" \
    -v headline="$HEADLINE" -v quick_headline="$QUICK_HEADLINE" -v report_file="$(basename "$REPORT")" \
    "$AS_ASSETS/dimensions.tsv" -)" || as_die "scoring failed"

block() {
  printf '%s\n' "$BLOCKS" | awk -v want="$1" '/^#BLOCK / { on = ($2 == want); next } on'
}

problems="$(block problems)"

case "$ACTION" in
  blocks)
    printf '%s\n' "$BLOCKS"
    ;;
  chat)
    if [ -n "$problems" ]; then
      printf 'note: the report has problems; run check-report.sh and fix them before sending this summary.\n' >&2
    fi
    block chat
    ;;
  print)
    printf '== score ==\n%s\n\n== fix-first ==\n%s\n\n== plan ==\n%s\n' "$(block score)" "$(block fix-first)" "$(block plan)"
    if [ -n "$problems" ]; then
      printf '\n== problems (fix these in the report) ==\n%s\n' "$problems"
    fi
    ;;
  write)
    as_report_path_ok "$REPORT"
    for name in score fix-first plan; do
      grep -q "^<!-- BEGIN GENERATED: $name" "$REPORT" || as_die "the report has no '<!-- BEGIN GENERATED: $name' line; copy the marker pair back from $AS_ASSETS/report-template.md"
      grep -q "^<!-- END GENERATED: $name -->" "$REPORT" || as_die "the report has no '<!-- END GENERATED: $name -->' line; copy the marker pair back from $AS_ASSETS/report-template.md"
    done
    # The rename below would replace a read-only report, which writing into
    # it never did; refuse instead.
    [ -w "$REPORT" ] || as_die "$REPORT is read-only; make it writable (chmod u+w $REPORT) to update its generated blocks"
    # The new report goes to a temp file beside it, renamed over it and
    # keeping its permission bits; the blocks reach awk through ENVIRON, so
    # nothing is written to TMPDIR.
    tmp="$(as_report_tmp "$REPORT")" || exit 2
    trap 'rm -f "$tmp"' EXIT
    AS_BLOCKS="$BLOCKS" awk '
      BEGIN {
        n = split(ENVIRON["AS_BLOCKS"], bl, "\n")
        for (i = 1; i <= n; i++) {
          l = bl[i]
          if (l ~ /^#BLOCK /) { cur = substr(l, 8); continue }
          body[cur] = body[cur] l "\n"
        }
      }
      /^<!-- BEGIN GENERATED: / {
        name = $0; sub(/^<!-- BEGIN GENERATED: /, "", name); sub(/[ (].*$/, "", name)
        print; printf "%s", body[name]; skip = 1; next
      }
      /^<!-- END GENERATED: / { skip = 0 }
      !skip { print }
    ' "$REPORT" > "$tmp" || as_die "could not update $REPORT"
    as_report_commit "$tmp" "$REPORT" keep
    printf 'updated the generated blocks in %s\n' "$REPORT"
    printf '%s\n' "$(block score)" | head -1
    if [ -n "$problems" ]; then
      printf '\nproblems scoring could not use (fix them in the report, then rerun):\n%s\n' "$problems"
    fi
    ;;
esac
