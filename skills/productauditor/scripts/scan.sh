#!/usr/bin/env bash
# scan.sh: print leads for the rule cards of one dimension, one card, the
# quick set, or everything. A lead is a line worth reading, never a finding.
#
# Usage: bash <skill>/scripts/scan.sh <DIM|CARD|quick|all> [--show-cards] [--max N] [path ...]
#   DIM           every card of one dimension, for example AUTHZ
#   CARD          one card, for example AUTHZ-R1
#   quick         the cards tagged (quick): the Critical-class checks
#   all           every card of every dimension
#   --show-cards  print each card's text above its leads
#   --max N       leads shown per card (default 12)
# Run from the project root. Optional paths limit the search. Read-only.
#
# Leads print in path and line order. When a card has more than N, the N
# shown are spread across files, round-robin in path order: the first lead
# of each file, then the second of each, and so on until N, so a file late
# in path order still shows a lead. A closing line counts the leads left out.

set -u
. "$(cd "$(dirname "$0")" && pwd)/_lib.sh"
as_load_conf

# The header comment above, from line 2 to the first blank line.
usage() {
  sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'
}

# pick_leads N: stdin is one card's leads (path:line: text), sorted by path
# then line, more than N of them. Print N, chosen round-robin across files in
# path order, still sorted by path then line. A lead's rank is its place in
# its own file (1 for the file's first lead); every lead ranked below the
# first rank that does not fit whole is shown, plus the first leads of that
# rank in path order until N. N reaches awk with -v: a number, never a regex.
pick_leads() {
  awk -v max="$1" '
    {
      lead[NR] = $0
      p = index($0, ":")
      f = (p > 0) ? substr($0, 1, p - 1) : $0
      r = (NR > 1 && f == prev) ? r + 1 : 1
      prev = f
      rank[NR] = r
      per[r]++
      if (r > top) top = r
    }
    END {
      left = max + 0
      for (cut = 1; cut <= top && left >= per[cut]; cut++) left -= per[cut]
      for (i = 1; i <= NR; i++) {
        if (rank[i] < cut) print lead[i]
        else if (rank[i] == cut && left > 0) { print lead[i]; left-- }
      }
    }'
}

SEL=""
MAX=12
SHOW=0
PATHS=""
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --max) MAX="${2:-12}"; shift ;;
    --show-cards) SHOW=1 ;;
    *)
      if [ -z "$SEL" ]; then SEL="$1"; else PATHS="$PATHS$1
"; fi
      ;;
  esac
  shift
done
[ -n "$SEL" ] || { usage; exit 2; }
case "$MAX" in ''|*[!0-9]*) as_die "--max needs a number" ;; esac

# Card headings: "### ID-Rn Title" lines, optionally ending in "(quick)".
cards_in() {
  [ -f "$1" ] || return 0
  grep -E '^### [A-Z][A-Z0-9]*-R[0-9]+ ' "$1" | sed 's/^### //'
}

CARDS=""
case "$SEL" in
  all)
    for d in $(as_dim_ids); do CARDS="$CARDS$(cards_in "$AS_REFS/$d.md")
"; done
    ;;
  quick)
    for d in $(as_dim_ids); do CARDS="$CARDS$(cards_in "$AS_REFS/$d.md" | grep '(quick)[[:space:]]*$')
"; done
    ;;
  *-R[0-9]*)
    dim="${SEL%-R*}"
    as_is_dim "$dim" || as_die "unknown dimension in card id: $SEL"
    CARDS="$(cards_in "$AS_REFS/$dim.md" | awk -v id="$SEL" '$1 == id')"
    [ -n "$CARDS" ] || as_die "no card $SEL in references/$dim.md"
    ;;
  *)
    as_is_dim "$SEL" || as_die "unknown dimension or selector: $SEL (dimensions: $(as_dim_ids | tr '\n' ' '))"
    CARDS="$(cards_in "$AS_REFS/$SEL.md")"
    ;;
esac
CARDS="$(printf '%s\n' "$CARDS" | awk 'NF')"
[ -n "$CARDS" ] || as_die "no cards matched $SEL"

if [ -n "$PATHS" ]; then
  OLDIFS="$IFS"
  IFS='
'
  set -f
  # shellcheck disable=SC2086
  AS_FILE_LIST="$(as_files $PATHS)"
  set +f
  IFS="$OLDIFS"
else
  AS_FILE_LIST="$(as_files)"
fi

PATTERNS="$(as_rows "$AS_ASSETS/patterns.tsv")"

printf '%s\n' "$CARDS" | while IFS= read -r card; do
  id="${card%% *}"
  printf '\n== %s ==\n' "$card"
  if [ "$SHOW" -eq 1 ]; then
    awk -v id="$id" '
      /^### / { on = ($2 == id); next }
      /^## / { on = 0 }
      on && NF' "$AS_REFS/${id%-R*}.md"
    printf -- '-- leads --\n'
  fi
  rows="$(printf '%s\n' "$PATTERNS" | awk -F'\t' -v id="$id" '$1 == id')"
  if [ -z "$rows" ]; then
    printf '(no search pattern for this card: read the files its Leads line names)\n'
    continue
  fi
  hits="$(printf '%s\n' "$rows" | while IFS="$AS_TAB" read -r rid flags globs regex; do
    printf '%s\n' "$AS_FILE_LIST" | as_filter_globs "$globs" | as_search "$flags" "$regex" | as_trim_hits
  done | sort -t: -k1,1 -k2,2n -u)"
  if [ -z "$hits" ]; then
    printf '(no leads: the card still applies; follow its Leads and Confirm lines)\n'
    continue
  fi
  count="$(printf '%s\n' "$hits" | wc -l | tr -d ' ')"
  if [ "$count" -gt "$MAX" ]; then
    printf '%s\n' "$hits" | pick_leads "$MAX"
    printf '(+%s more leads; rerun with --max %s or a path argument to see them)\n' "$((count - MAX))" "$count"
  else
    printf '%s\n' "$hits"
  fi
done

printf '\nLeads are not findings. For each card, read the code around every lead and apply the card: Confirm, Not a finding if, Severity.\n'
