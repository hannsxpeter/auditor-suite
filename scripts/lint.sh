#!/usr/bin/env bash
# auditor-suite-lint: mechanical enforcement of the suite's discipline rules.
#
# Checks:
#   suite-registry     the roster agrees everywhere: skills/*, plugins/* (less
#                      auditor-suite), the marketplace plugins (less
#                      auditor-suite), the meta plugin's dependencies, evals/*,
#                      and tests/fixtures/* name the same skills; the
#                      marketplace lists the meta plugin once; evals/results/
#                      (skipped as eval output) is git-ignored and untracked;
#                      README.md and SUITE.md carry a table row for each skill
#                      and for nothing else (README's dimension count matches
#                      dimensions.tsv); each report file is excluded from
#                      scans in shared/scripts/_lib.sh and is git-ignored
#   skill-frontmatter  every skills/<name>/SKILL.md carries valid Agent Skills
#                      frontmatter (name matches the directory, description
#                      present and at most 1024 characters)
#   skill-structure    every skill has the spine, references, scripts, and
#                      assets the shared scripts need; SKILL.md stays under the
#                      token budget and names every reference file; dimension
#                      files, rule cards, dimensions.tsv, patterns.tsv,
#                      surfaces.tsv, and skill.conf are well formed; a card
#                      whose Severity can be Critical is tagged (quick), and a
#                      (quick) card's Severity names Critical or "as <CARD>"
#   patterns-valid     every regex in patterns.tsv and surfaces.tsv compiles
#                      under grep -E (and ripgrep when installed)
#   shared-sync        every skill's copies of the shared core are
#                      byte-identical to shared/, and a skill's scripts/ holds
#                      nothing that shared/scripts/ does not
#   examples-valid     every references/example-report.md passes its own
#                      check-report.sh against tests/fixtures/<name>/
#   evals-structure    every skill has an eval case with prompt, case.yaml,
#                      scaffold, answer key, fixture repo, and core graders
#   script-tests       tests/run.sh (golden tests for the shared scripts) and
#                      tests/install.sh (the installer tests) each pass
#   plugin-sync        every vendored plugins/<name>/skills/<name>/ payload is
#                      identical to the canonical skill payload; every manifest
#                      is valid JSON; each skill manifest's name is its
#                      directory and its version and description match VERSION
#                      and SKILL.md; the meta plugin is named auditor-suite at
#                      VERSION; each marketplace entry's source is
#                      ./plugins/<name> and a skill entry's description matches
#                      its SKILL.md
#   suite-release      VERSION matches the README badges, SUITE.md, the
#                      marketplace metadata, and the shared scripts' version
#   changelog-top      the hub CHANGELOG.md top entry matches VERSION
#   unicode-clean      no en or em dash, arrow (U+2190-21FF), box drawing
#                      (U+2500-257F), symbol or dingbat (U+2600-27BF), U+1Fxxx
#                      emoji, or emoji variation selector (U+FE0F) in tracked
#                      files or in untracked files that are not git-ignored
#   bash-syntax        every shell script in the hub parses as bash and uses no
#                      bash 4 construct (associative arrays, namerefs,
#                      mapfile, readarray, case-changing expansions, coproc,
#                      &>>, ;;&)
#
# The roster comes from the skills/ directories (scripts/_skills.sh); there is
# no list of skill names to edit. JSON is read with jq, else python3, else as
# text with a warning (LINT_JSON=jq|python3|none forces one).
#
# Each check runs in its own subshell with errexit on: a command that crashes
# inside a check (an awk or grep error, an unset variable) stops that check and
# counts as a failure, and the next check still runs. Nested bash runs use the
# bash running this script ($BASH), so /bin/bash scripts/lint.sh tests 3.2.
#
# Bash 3.2 compatible (macOS default). No associative arrays.
#
# Usage:
#   bash scripts/lint.sh                          # all checks
#   bash scripts/lint.sh --verbose               # show ok lines
#   bash scripts/lint.sh plugin-sync             # one specific check
#   bash scripts/lint.sh shared-sync plugin-sync # several checks
#   bash scripts/lint.sh --help

set -eu

VERBOSE=0
ONLY_CHECKS=""
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

. "$ROOT/scripts/_skills.sh"
ALL_CHECKS="suite-registry skill-frontmatter skill-structure patterns-valid shared-sync examples-valid evals-structure script-tests plugin-sync suite-release changelog-top unicode-clean bash-syntax"
PAYLOAD="SKILL.md references scripts assets"
TAB="$(printf '\t')"

usage() {
  cat <<EOF
auditor-suite-lint

Usage: lint.sh [--verbose] [check-name ...]

With no check names, runs every check. One failing check never stops the
others; a check that stops on an error counts as a failure. The exit status
is 1 when any check failed.

Checks: $ALL_CHECKS
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    -v|--verbose) VERBOSE=1 ;;
    -h|--help) usage; exit 0 ;;
    -*) printf "unknown flag: %s\n" "$1" >&2; usage >&2; exit 2 ;;
    *) ONLY_CHECKS="$ONLY_CHECKS${ONLY_CHECKS:+ }$1" ;;
  esac
  shift
done

# Reject an unknown name before any check runs.
for c in $ONLY_CHECKS; do
  case " $ALL_CHECKS " in
    *" $c "*) ;;
    *) printf "unknown check: %s\n" "$c" >&2; usage >&2; exit 2 ;;
  esac
done

# Scratch space for state that must outlive a check's subshell: one line per
# failure in FAIL_LOG, and the marker for the once-only JSON warning.
LINT_TMP="$(mktemp -d "${TMPDIR:-/tmp}/auditor-suite-lint.XXXXXX")" || exit 2
trap 'rm -rf "$LINT_TMP"' EXIT
FAIL_LOG="$LINT_TMP/failures"
: > "$FAIL_LOG"

fail() { printf "  fail  %s\n" "$*"; printf '.\n' >> "$FAIL_LOG"; }
ok()   { [ "$VERBOSE" = "1" ] && printf "  ok    %s\n" "$*" || true; }
title(){ printf "%s\n" "$*"; }

# fail_lines TEXT: one failure per non-empty line of TEXT (no subshell).
fail_lines() {
  [ -n "$1" ] || return 0
  while IFS= read -r msg; do
    if [ -n "$msg" ]; then fail "$msg"; fi
  done <<EOF
$1
EOF
  return 0
}

frontmatter_of() {
  # Print the frontmatter block (between the first two --- lines) of a file.
  awk 'NR==1 && $0!="---" {exit} NR>1 && $0=="---" {exit} NR>1 {print}' "$1"
}

body_of() {
  # Print everything after the frontmatter.
  awk 'NR==1 && $0=="---" {fm=1; next} fm && $0=="---" {fm=0; body=1; next} body || (!fm && NR>1) {print}' "$1"
}

rows_of() {
  [ -f "$1" ] || return 0
  grep -v '^[[:space:]]*#' "$1" | grep -v '^[[:space:]]*$' || true
}

description_of() {
  frontmatter_of "$1" | awk '/^description:/ { sub(/^description:[ ]*/, ""); print; exit }'
}

# ---- JSON ------------------------------------------------------------------
# The manifests are read with jq when installed, else python3. With neither,
# they are read as text: syntax goes unchecked and a warning says so.
# LINT_JSON=jq|python3|none forces one reader (tests/lint-selftest.sh uses it).
JSON_TOOL="${LINT_JSON:-}"
if [ -z "$JSON_TOOL" ]; then
  if command -v jq >/dev/null 2>&1; then
    JSON_TOOL="jq"
  elif python3 -c 'import json' >/dev/null 2>&1; then
    JSON_TOOL="python3"
  else
    JSON_TOOL="none"
  fi
fi
case "$JSON_TOOL" in
  jq|python3) command -v "$JSON_TOOL" >/dev/null 2>&1 || { printf "LINT_JSON=%s, but %s is not installed\n" "$JSON_TOOL" "$JSON_TOOL" >&2; exit 2; } ;;
  none) ;;
  *) printf "LINT_JSON must be jq, python3, or none (got %s)\n" "$JSON_TOOL" >&2; exit 2 ;;
esac
US="$(printf '\037')"   # field separator for json_plugins rows

# A marker file, not a variable: each check runs in its own subshell.
json_warn_once() {
  if [ "$JSON_TOOL" = "none" ] && [ ! -e "$LINT_TMP/json-warned" ]; then
    printf "lint: reading JSON manifests as text (no jq or python3, or LINT_JSON=none); their syntax is not checked\n" >&2
    : > "$LINT_TMP/json-warned"
  fi
  return 0
}

# Python readers. Single-quoted shell strings, so no single quotes inside.
PY_VALID='import json,sys
try:
    json.load(open(sys.argv[1], encoding="utf-8"))
except Exception as e:
    sys.stderr.write(str(e) + "\n")
    sys.exit(1)'
PY_FIELD='import json,sys
d = json.load(open(sys.argv[1], encoding="utf-8"))
v = d.get(sys.argv[2]) if isinstance(d, dict) else None
if isinstance(v, str):
    sys.stdout.write(v + "\n")'
PY_PLUGINS='import json,sys
d = json.load(open(sys.argv[1], encoding="utf-8"))
ps = d.get("plugins") if isinstance(d, dict) else None
txt = lambda v: v if isinstance(v, str) else ("" if v is None else json.dumps(v))
for p in (ps if isinstance(ps, list) else []):
    if isinstance(p, dict):
        sys.stdout.write("\x1f".join(txt(p.get(k)) for k in ("name", "source", "description")) + "\n")'
PY_DEPS='import json,sys
d = json.load(open(sys.argv[1], encoding="utf-8"))
ds = d.get("dependencies") if isinstance(d, dict) else None
for v in (ds if isinstance(ds, list) else []):
    sys.stdout.write((v if isinstance(v, str) else json.dumps(v)) + "\n")'

# Text fallbacks for the layout the hub's manifests use (one key per line).
AWK_JSON_VAL='function val(s) { sub(/^[^:]*:[[:space:]]*"/, "", s); sub(/"[[:space:]]*,?[[:space:]]*$/, "", s); return s }
'

# json_error FILE: print why FILE is not valid JSON and return 1; else return 0.
# Valid means exactly one JSON value: jq alone accepts an empty file or a
# stream of several values, so it reads the file as an array (-s) and counts.
json_error() {
  local out
  case "$JSON_TOOL" in
    jq) out="$(jq -s -e 'length == 1' "$1" 2>&1 >/dev/null)" && return 0
        [ -n "$out" ] || out="the file must hold exactly one JSON value" ;;
    python3) out="$(PYTHONIOENCODING=utf-8 python3 -c "$PY_VALID" "$1" 2>&1)" && return 0 ;;
    *) return 0 ;;
  esac
  printf '%s\n' "$out" | sed -n '$p'
  return 1
}

# json_field FILE KEY: the top-level string KEY of FILE, or nothing.
json_field() {
  case "$JSON_TOOL" in
    jq) jq -r --arg k "$2" 'if type == "object" and (.[$k] | type) == "string" then .[$k] else empty end' "$1" 2>/dev/null || true ;;
    python3) PYTHONIOENCODING=utf-8 python3 -c "$PY_FIELD" "$1" "$2" 2>/dev/null || true ;;
    *) awk -v k="\"$2\"" "$AWK_JSON_VAL"' index($0, k) && $0 ~ /^[[:space:]]*"[^"]*"[[:space:]]*:[[:space:]]*"/ { split($0, a, "\""); if ("\"" a[2] "\"" == k) { print val($0); exit } }' "$1" ;;
  esac
}

# json_plugins FILE: one "name US source US description" row per marketplace entry.
json_plugins() {
  case "$JSON_TOOL" in
    jq) jq -r '(.plugins // []) | if type == "array" then .[] else empty end | select(type == "object") | [.name, .source, .description] | map(if type == "string" then . elif . == null then "" else tojson end) | join("\u001f")' "$1" 2>/dev/null || true ;;
    python3) PYTHONIOENCODING=utf-8 python3 -c "$PY_PLUGINS" "$1" 2>/dev/null || true ;;
    *) awk -v us="$US" "$AWK_JSON_VAL"'
         /"plugins"[[:space:]]*:/ { inp = 1; next }
         inp && /^[[:space:]]*"name"[[:space:]]*:/ { n = val($0) }
         inp && /^[[:space:]]*"source"[[:space:]]*:/ { src = val($0) }
         inp && /^[[:space:]]*"description"[[:space:]]*:/ { d = val($0) }
         inp && /^[[:space:]]*}/ { if (n != "") print n us src us d; n = ""; src = ""; d = "" }' "$1" ;;
  esac
}

# json_deps FILE: one dependency per line from the meta plugin manifest.
json_deps() {
  case "$JSON_TOOL" in
    jq) jq -r '(.dependencies // []) | if type == "array" then .[] else empty end | if type == "string" then . else tojson end' "$1" 2>/dev/null || true ;;
    python3) PYTHONIOENCODING=utf-8 python3 -c "$PY_DEPS" "$1" 2>/dev/null || true ;;
    *) awk '/"dependencies"[[:space:]]*:/ { ind = 1; next } ind && /\]/ { exit } ind { gsub(/[",[:space:]]/, ""); if ($0 != "") print }' "$1" ;;
  esac
}

# in_list WORD LIST: whether WORD is one of the space- or newline-separated
# words of LIST.
in_list() {
  case " $(printf '%s' "$2" | tr '\n' ' ') " in
    *" $1 "*) return 0 ;;
  esac
  return 1
}

# dirs_in DIR: the names of DIR's subdirectories, one per line.
dirs_in() {
  local d
  for d in "$1"/*/; do
    [ -d "$d" ] || continue
    d="${d%/}"
    printf '%s\n' "${d##*/}"
  done
}

check_suite_registry() {
  title "suite-registry"
  local s n label where jf have want extra rest dims report re
  if [ -n "$SKILLS_INVALID" ]; then
    while IFS= read -r n; do
      if [ -n "$n" ]; then fail "skills/$n: not a valid skill name; use lower-case letters, digits, and hyphens"; fi
    done <<EOF
$SKILLS_INVALID
EOF
  fi
  if [ -z "$SKILLS" ]; then
    fail "no skill directories under skills/"
    return 0
  fi
  json_warn_once

  # Every place that names the roster must name exactly the skills/*
  # directories. Each label sets the names it holds, the message for a skill
  # it lacks, and the message for a name it holds that is not a skill (printf
  # templates; %s is the name).
  for label in plugins market deps evals fixtures; do
    jf=""
    case "$label" in
      plugins)  where="plugins/"
                have="$(dirs_in "$ROOT/plugins" | grep -vx 'auditor-suite' || true)"
                want="no vendored plugin at plugins/%s/ (run scripts/refresh-plugins.sh, then add its .claude-plugin/plugin.json)"
                extra="plugins/%s/ exists, but there is no skills/%s/" ;;
      market)   where="marketplace.json"
                jf="$ROOT/.claude-plugin/marketplace.json"
                want="no entry in .claude-plugin/marketplace.json"
                extra=".claude-plugin/marketplace.json lists %s, but there is no skills/%s/" ;;
      deps)     where="meta plugin dependencies"
                jf="$ROOT/plugins/auditor-suite/.claude-plugin/plugin.json"
                want="not a dependency of the meta plugin (plugins/auditor-suite/.claude-plugin/plugin.json)"
                extra="the meta plugin depends on %s, but there is no skills/%s/" ;;
      evals)    where="evals/"
                have="$(dirs_in "$ROOT/evals" | grep -vx 'results' || true)"
                want="no eval case at evals/%s/"
                extra="evals/%s/ exists, but there is no skills/%s/" ;;
      fixtures) where="tests/fixtures/"
                have="$(dirs_in "$ROOT/tests/fixtures")"
                want="no example-report fixture at tests/fixtures/%s/"
                extra="tests/fixtures/%s/ exists, but there is no skills/%s/" ;;
    esac
    if [ -n "$jf" ]; then
      if [ ! -f "$jf" ] || ! json_error "$jf" >/dev/null; then
        fail "${jf#$ROOT/} is missing or not valid JSON, so its skill names cannot be checked (plugin-sync gives the details)"
        continue
      fi
      if [ "$label" = "market" ]; then
        have="$(json_plugins "$jf" | cut -d "$US" -f1 | grep -vx 'auditor-suite' || true)"
        # The meta plugin is left out of the roster comparison, not unchecked.
        n="$(json_plugins "$jf" | cut -d "$US" -f1 | grep -cx 'auditor-suite' || true)"
        if [ "$n" = "1" ]; then
          ok "marketplace.json: lists the meta plugin auditor-suite"
        else
          fail ".claude-plugin/marketplace.json lists the meta plugin auditor-suite $n times; want once, with source ./plugins/auditor-suite"
        fi
      else
        have="$(json_deps "$jf")"
      fi
    fi
    rest=""
    for s in $SKILLS; do
      in_list "$s" "$have" || { fail "$s: $(printf "$want" "$s")"; rest=1; }
    done
    for n in $have; do
      in_list "$n" "$SKILLS" || { fail "$(printf "$extra" "$n" "$n")"; rest=1; }
    done
    for n in $(printf '%s\n' "$have" | sort | uniq -d); do
      fail "$(printf "$extra" "$n" "$n" | sed 's/, but there is no .*//; s/ exists$//') more than once"
      rest=1
    done
    [ -n "$rest" ] || ok "$where: names every skill and nothing else"
  done

  # evals/results/ is skipped above because it holds eval run output, which
  # is git-ignored and never committed; the skip is safe only while both hold.
  if git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    if ! git -C "$ROOT" check-ignore -q --no-index evals/results/; then
      fail "evals/results/ is not git-ignored; .gitignore should cover it (suite-registry skips it as eval output)"
    elif [ -n "$(git -C "$ROOT" ls-files -- evals/results | sed -n 1p)" ]; then
      fail "evals/results/ holds tracked files; eval results are never committed (git rm -r --cached evals/results)"
    else
      ok "evals/results/: git-ignored and untracked"
    fi
  fi

  for s in $SKILLS; do
    # README: a table row linking the skill, whose Dimensions column (when
    # the table has one) matches dimensions.tsv.
    have="$(awk -F'|' -v s="$s" '
      /^\|/ {
        for (i = 1; i <= NF; i++) { c = $i; sub(/^[[:space:]]+/, "", c); sub(/[[:space:]]+$/, "", c); if (c == "Dimensions") { col = i; next } }
      }
      /^\|/ && index($0, "[" s "](skills/" s ")") { found = 1; c = "?"; if (col) { c = $col; sub(/^[[:space:]]+/, "", c); sub(/[[:space:]]+$/, "", c) } print c; exit }
      END { if (!found) print "none" }' "$ROOT/README.md")"
    dims="$(rows_of "$ROOT/skills/$s/assets/dimensions.tsv" | wc -l | tr -d ' ')"
    case "$have" in
      none) fail "$s: README.md has no table row linking [$s](skills/$s)" ;;
      "?")  ok "$s: README.md row present" ;;
      *)    if [ "$have" = "$dims" ]; then ok "$s: README.md row present, $dims dimensions"; else fail "$s: README.md row says $have dimensions; assets/dimensions.tsv has $dims"; fi ;;
    esac
    if awk -v s="$s" 'index($0, "| **" s "** |") == 1 { f = 1 } END { exit !f }' "$ROOT/SUITE.md"; then
      ok "$s: SUITE.md row present"
    else
      fail "$s: SUITE.md has no table row starting \"| **$s** |\""
    fi

    # The report must never be scanned as project content by a sibling
    # auditor, and must never be committed from a dogfooding run.
    report="$(sed -n 's/^REPORT_FILE="\(.*\)"$/\1/p' "$ROOT/skills/$s/assets/skill.conf" 2>/dev/null | sed -n 1p)"
    [ -n "$report" ] || continue
    re="$(sed -n "s/^AS_EXCLUDE_RE='\\(.*\\)'\$/\\1/p" "$ROOT/shared/scripts/_lib.sh" 2>/dev/null | sed -n 1p)"
    if [ -z "$re" ]; then
      fail "shared/scripts/_lib.sh has no AS_EXCLUDE_RE='...' line to check $report against"
    elif printf '%s\n' "$report" | grep -Eq -e "$re"; then
      ok "$s: $report excluded from scans"
    else
      fail "$s: $report is not matched by AS_EXCLUDE_RE in shared/scripts/_lib.sh, so sibling auditors would scan it; add it there and run scripts/sync-shared.sh"
    fi
    if git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      if git -C "$ROOT" check-ignore -q --no-index "$report"; then
        ok "$s: $report git-ignored"
      else
        fail "$s: $report at the repo root is not git-ignored; .gitignore should cover /*audit.md"
      fi
    fi
  done

  # The reverse: every README.md row link and SUITE.md row names a skill, so a
  # removed or renamed auditor leaves no stale row behind.
  rest=""
  for n in $(grep '^|' "$ROOT/README.md" | grep -oE '\[[a-z0-9-]+\]\(skills/[a-z0-9-]+\)' | sed 's/.*(skills\///; s/)$//' | sort -u); do
    in_list "$n" "$SKILLS" || { fail "README.md has a table row for $n, but there is no skills/$n/"; rest=1; }
  done
  for n in $(sed -n 's/^| \*\*\([a-z0-9-]*auditor\)\*\* |.*/\1/p' "$ROOT/SUITE.md" | sort -u); do
    in_list "$n" "$SKILLS" || { fail "SUITE.md has a table row for $n, but there is no skills/$n/"; rest=1; }
  done
  [ -n "$rest" ] || ok "README.md and SUITE.md: no row for a name that is not a skill"
}

check_skill_frontmatter() {
  title "skill-frontmatter"
  local s f fm desc
  for s in $SKILLS; do
    f="$ROOT/skills/$s/SKILL.md"
    if [ ! -f "$f" ]; then
      fail "$s: missing skills/$s/SKILL.md (every directory under skills/ is a skill)"
      continue
    fi
    if [ "$(head -1 "$f")" != "---" ]; then
      fail "$s: SKILL.md does not start with frontmatter"
      continue
    fi
    fm="$(frontmatter_of "$f")"
    if ! printf "%s\n" "$fm" | grep -q "^name: $s$"; then
      fail "$s: frontmatter name does not match directory"
    else
      ok "$s: name matches"
    fi
    desc="$(description_of "$f")"
    if [ -z "$desc" ]; then
      fail "$s: frontmatter has no description"
    elif [ "${#desc}" -gt 1024 ]; then
      fail "$s: description is ${#desc} characters; the Agent Skills limit is 1024"
    else
      ok "$s: description present (${#desc} characters)"
    fi
  done
}

check_skill_structure() {
  title "skill-structure"
  local s d f bytes lines conf key dims id rest cards card conds re
  for s in $SKILLS; do
    d="$ROOT/skills/$s"
    for f in SKILL.md README.md CHANGELOG.md LICENSE references/protocol.md references/example-report.md assets/report-template.md assets/skill.conf assets/dimensions.tsv assets/patterns.tsv assets/surfaces.tsv scripts/_lib.sh scripts/inventory.sh scripts/scan.sh scripts/new-report.sh scripts/score.sh scripts/check-report.sh; do
      [ -f "$d/$f" ] || fail "$s: missing $f"
    done
    [ -f "$d/SKILL.md" ] || continue

    body_of "$d/SKILL.md" > "$LINT_TMP/body"
    bytes="$(wc -c < "$LINT_TMP/body" | tr -d ' ')"
    lines="$(wc -l < "$d/SKILL.md" | tr -d ' ')"
    if [ "$bytes" -gt 20000 ]; then
      fail "$s: SKILL.md body is $bytes bytes (about $((bytes / 4)) tokens); keep it under 20000 bytes (5000 tokens) and move detail to references/"
    else
      ok "$s: SKILL.md body $bytes bytes (about $((bytes / 4)) tokens)"
    fi
    [ "$lines" -le 500 ] || fail "$s: SKILL.md is $lines lines; keep it under 500"

    for f in "$d"/references/*.md; do
      [ -f "$f" ] || continue
      grep -qF "references/$(basename "$f")" "$d/SKILL.md" || fail "$s: SKILL.md does not mention references/$(basename "$f"); link every reference file from the spine"
    done

    conf="$d/assets/skill.conf"
    if [ -f "$conf" ]; then
      for key in SKILL_NAME REPORT_FILE REPORT_TITLE AUDIT_NOUN HEADLINE QUICK_HEADLINE BANNER MAP_HINT DOMAIN_RULE; do
        grep -q "^$key=\"..*\"$" "$conf" || fail "$s: skill.conf has no non-empty $key"
      done
      grep -q "^SKILL_NAME=\"$s\"$" "$conf" || fail "$s: skill.conf SKILL_NAME is not \"$s\""
      grep -q "^REPORT_FILE=\"${s%auditor}audit.md\"$" "$conf" || fail "$s: skill.conf REPORT_FILE is not \"${s%auditor}audit.md\""
      # Optional per-skill scan skip: one single-quoted line that awk accepts
      # (the scripts pass it to awk through ENVIRON, like every path regex).
      if grep -q '^SCAN_SKIP_RE=' "$conf"; then
        if [ "$(grep -c '^SCAN_SKIP_RE=' "$conf")" != "1" ] || ! grep -q "^SCAN_SKIP_RE='[^']\{1,\}'$" "$conf"; then
          fail "$s: skill.conf SCAN_SKIP_RE must be one non-empty single-quoted line"
        else
          re="$(. "$conf"; printf '%s' "${SCAN_SKIP_RE:-}")"
          if ! printf 'x\n' | AS_RE="$re" awk '{ if ($0 ~ ENVIRON["AS_RE"]) n++ }' 2>/dev/null; then
            fail "$s: skill.conf SCAN_SKIP_RE is not a regex awk accepts"
          else
            ok "$s: SCAN_SKIP_RE is valid"
          fi
        fi
      fi
    fi

    [ -f "$d/assets/dimensions.tsv" ] || continue
    dims="$(rows_of "$d/assets/dimensions.tsv" | cut -f1)"
    # Assigned, not passed straight to fail_lines, so errexit sees an awk crash.
    rest="$(rows_of "$d/assets/dimensions.tsv" | awk -F'\t' -v s="$s" '
      NF != 5 { printf "%s: dimensions.tsv row \"%s\" has %d fields; want id, weight, applies, floor, name\n", s, $0, NF; next }
      $1 !~ /^[A-Z][A-Z0-9]*$/ { printf "%s: dimension id %s is not upper-case letters and digits\n", s, $1 }
      $2 !~ /^[1-9][0-9]*$/ { printf "%s: dimension %s weight %s is not a positive integer\n", s, $1, $2 }
      $3 != "always" && $3 != "conditional" { printf "%s: dimension %s applies is %s; want always or conditional\n", s, $1, $3 }
      $4 != "yes" && $4 != "no" { printf "%s: dimension %s floor is %s; want yes or no\n", s, $1, $4 }
      seen[$1]++ == 1 { printf "%s: dimension %s is listed twice\n", s, $1 }
    ')"
    fail_lines "$rest"

    for id in $dims; do
      f="$d/references/$id.md"
      if [ ! -f "$f" ]; then
        fail "$s: dimension $id has no references/$id.md"
        continue
      fi
      grep -qF "references/$id.md" "$d/SKILL.md" || fail "$s: SKILL.md dimension table does not name references/$id.md"
      rest="$(awk -v id="$id" -v s="$s" '
        /^### / {
          if (card != "") check()
          card = $2; fields = ""; sev = ""
          head = $0; sub(/[[:space:]]+$/, "", head)
          quick = (length(head) > 7 && substr(head, length(head) - 6) == "(quick)")
          if (card !~ "^" id "-R[0-9]+$") printf "%s: %s.md heading \"%s\" is not a card of %s (### %s-R<n> Title)\n", s, id, $0, id, id
          if (card in seen) printf "%s: card %s appears twice\n", s, card
          seen[card] = 1
          ncards++
          if (NF < 3) printf "%s: card %s has no title\n", s, card
          next
        }
        /^## / { if (card != "") check(); card = ""; next }
        card != "" && /^- [A-Za-z ]+:/ { k = $0; sub(/^- /, "", k); sub(/:.*/, "", k); fields = fields "|" k "|" }
        card != "" && /^- Severity:/ { sev = $0; sub(/^- Severity:[[:space:]]*/, "", sev) }
        # can_be_critical TEXT: 1 when a clause of TEXT (split at ; , .) names
        # Critical with no "never" or "not" before it in that clause.
        function can_be_critical(t,   cl, n, i, p, pre) {
          n = split(t, cl, "[;,.]")
          for (i = 1; i <= n; i++) {
            p = index(cl[i], "Critical")
            if (p == 0) continue
            pre = " " tolower(substr(cl[i], 1, p - 1)) " "
            if (pre !~ /[^a-z](never|not)[^a-z]/) return 1
          }
          return 0
        }
        function check(   want, n, i, crit) {
          n = split("Leads|Confirm|Not a finding if|Severity|Fix|Verify the fix|Refs", want, "|")
          for (i = 1; i <= n; i++) if (index(fields, "|" want[i] "|") == 0) printf "%s: card %s is missing \"- %s:\"\n", s, card, want[i]
          if (sev == "") return
          # Quick mode works only (quick) cards, so every Critical-class
          # defect needs one (docs/AUTHORING.md, rule cards).
          crit = can_be_critical(sev)
          if (crit && !quick) printf "%s: card %s Severity can be Critical (\"%s\") but its heading lacks (quick); tag it (quick) and give its patterns.tsv rows flag q\n", s, card, sev
          if (quick && !crit && sev !~ /(^|[^A-Za-z0-9])as [A-Z][A-Z0-9]*-R[0-9]+/) printf "%s: card %s is tagged (quick) but its Severity never reaches Critical; name the Critical case, or \"as <CARD>\", or drop the tag\n", s, card
        }
        END { if (card != "") check(); if (ncards == 0) printf "%s: %s.md has no cards\n", s, id }
      ' "$f")"
      if [ -n "$rest" ]; then
        fail_lines "$rest"
      else
        ok "$s: $id.md cards well formed"
      fi
      grep -q '^## Cards$' "$f" || fail "$s: $id.md has no \"## Cards\" section"
    done

    cards="$(for id in $dims; do [ -f "$d/references/$id.md" ] && grep -E '^### [A-Z][A-Z0-9]*-R[0-9]+ ' "$d/references/$id.md"; done | sed 's/^### //')"
    rest="$(rows_of "$d/assets/patterns.tsv" | while IFS="$TAB" read -r card flags globs regex; do
      [ -n "$card" ] || continue
      if [ -z "$regex" ]; then printf '%s: patterns.tsv row for %s needs 4 tab-separated fields\n' "$s" "$card"; continue; fi
      line="$(printf '%s\n' "$cards" | awk -v c="$card" '$1 == c')"
      if [ -z "$line" ]; then printf '%s: patterns.tsv names %s, which is not a card\n' "$s" "$card"; continue; fi
      # Parenthesized case patterns: bash 3.2 cannot parse a bare ")" pattern
      # inside $(...). Every branch ends in "true" so set -e never fires here.
      case "$flags" in (-|*[!iq]*) [ "$flags" = "-" ] || printf '%s: patterns.tsv %s flags "%s"; use -, i, q, or iq\n' "$s" "$card" "$flags" ;; esac
      is_quick=0
      printf '%s\n' "$line" | grep -q '(quick)[[:space:]]*$' && is_quick=1
      case "$flags" in
        (*q*) [ "$is_quick" = "1" ] || printf '%s: patterns.tsv %s has flag q but the card is not tagged (quick)\n' "$s" "$card" ;;
        (*) [ "$is_quick" = "0" ] || printf '%s: patterns.tsv %s belongs to a (quick) card; add flag q\n' "$s" "$card" ;;
      esac
      true
    done; true)"
    if [ -n "$rest" ]; then
      fail_lines "$rest"
    else
      ok "$s: patterns.tsv rows name real cards"
    fi

    conds="$(rows_of "$d/assets/dimensions.tsv" | awk -F'\t' '$3 == "conditional" { print $1 }')"
    for id in $conds; do
      rows_of "$d/assets/surfaces.tsv" | awk -F'\t' -v id="$id" '$1 == id { f = 1 } END { exit !f }' || fail "$s: conditional dimension $id has no probe row in surfaces.tsv"
    done
    rest="$(rows_of "$d/assets/surfaces.tsv" | awk -F'\t' -v s="$s" -v dims=" $(printf '%s' "$dims" | tr '\n' ' ') _SURFACE " '
      NF != 5 { printf "%s: surfaces.tsv row \"%s\" needs 5 tab-separated fields\n", s, $0; next }
      index(dims, " " $1 " ") == 0 { printf "%s: surfaces.tsv names %s, which is not a dimension\n", s, $1 }')"
    fail_lines "$rest"
  done
}

check_patterns_valid() {
  title "patterns-valid"
  local s f card flags globs regex have_rg n rc
  have_rg=0
  command -v rg >/dev/null 2>&1 && have_rg=1
  [ "$have_rg" = "1" ] || printf "patterns-valid: ripgrep is not installed; patterns are compiled with grep -E only\n" >&2
  for s in $SKILLS; do
    n=0
    for f in "$ROOT/skills/$s/assets/patterns.tsv" "$ROOT/skills/$s/assets/surfaces.tsv"; do
      [ -f "$f" ] || continue
      while IFS="$TAB" read -r card flags globs regex; do
        # surfaces.tsv has an extra label column: dim label flags globs regex
        case "$f" in
          *surfaces.tsv) regex="$(printf '%s' "$regex" | cut -f2-)"; ;;
        esac
        [ -n "$regex" ] || continue
        n=$((n + 1))
        rc=0
        printf '' | grep -E -e "$regex" >/dev/null 2>&1 || rc=$?
        [ "$rc" -le 1 ] || fail "$s: $(basename "$f") $card: grep -E rejects /$regex/"
        if [ "$have_rg" = "1" ]; then
          rc=0
          printf '' | rg -e "$regex" >/dev/null 2>&1 || rc=$?
          [ "$rc" -le 1 ] || fail "$s: $(basename "$f") $card: ripgrep rejects /$regex/"
        fi
        case "$regex" in
          *'\s'*|*'\d'*|*'\w'*|*'\b'*|*'(?'*) fail "$s: $(basename "$f") $card uses \\s, \\d, \\w, \\b, or (?...); use POSIX classes and the i flag" ;;
        esac
      done <<EOF
$(rows_of "$f")
EOF
    done
    ok "$s: $n patterns compile"
  done
}

check_shared_sync() {
  title "shared-sync"
  local s sub f
  for s in $SKILLS; do
    for sub in scripts references assets; do
      for f in "$ROOT/shared/$sub"/*; do
        [ -f "$f" ] || continue
        if [ ! -f "$ROOT/skills/$s/$sub/$(basename "$f")" ]; then
          fail "$s: missing $sub/$(basename "$f") (run scripts/sync-shared.sh)"
        elif ! cmp -s "$f" "$ROOT/skills/$s/$sub/$(basename "$f")"; then
          fail "$s: $sub/$(basename "$f") differs from shared/ (edit shared/, then run scripts/sync-shared.sh)"
        else
          ok "$s: $sub/$(basename "$f") matches shared/"
        fi
      done
    done
    for f in "$ROOT/skills/$s/scripts"/*.sh; do
      [ -f "$f" ] || continue
      [ -x "$f" ] || fail "$s: scripts/$(basename "$f") is not executable (run scripts/sync-shared.sh)"
    done
    # A skill's scripts/ is all shared core: anything else is a stale copy of
    # a retired or renamed shared script, or a skill-only script that belongs
    # in shared/.
    for f in "$ROOT/skills/$s/scripts"/*; do
      [ -e "$f" ] || continue
      [ -e "$ROOT/shared/scripts/$(basename "$f")" ] || fail "$s: scripts/$(basename "$f") is not in shared/scripts/; a skill's scripts/ holds only the shared core (delete it, or move it into shared/scripts/ and run scripts/sync-shared.sh)"
    done
  done
}

check_examples_valid() {
  title "examples-valid"
  local s ex fx out
  for s in $SKILLS; do
    ex="$ROOT/skills/$s/references/example-report.md"
    fx="$ROOT/tests/fixtures/$s"
    if [ ! -f "$ex" ]; then fail "$s: no references/example-report.md"; continue; fi
    if [ ! -d "$fx" ]; then fail "$s: no tests/fixtures/$s/ for the example report"; continue; fi
    if out="$(cd "$fx" && "${BASH:-bash}" "$ROOT/skills/$s/scripts/check-report.sh" "$ex" --root "$fx" 2>&1)"; then
      ok "$s: example report passes check-report.sh"
    else
      fail "$s: example report fails check-report.sh:"
      printf "%s\n" "$out" | sed -n '2,8p' | sed 's/^/          /'
    fi
  done
}

check_evals_structure() {
  title "evals-structure"
  local s c g
  for s in $SKILLS; do
    c="$ROOT/evals/$s/full-audit"
    if [ ! -d "$c" ]; then fail "$s: no eval case at evals/$s/full-audit"; continue; fi
    for g in prompt.md case.yaml scaffold.sh ANSWERS.md graders/report-written.md graders/finding-format.md graders/read-only.md graders/only-report-created.md graders/skill-used.md graders/validator-used.md; do
      [ -f "$c/$g" ] || fail "$s: eval case is missing $g"
    done
    [ -d "$c/repo" ] || fail "$s: eval case has no repo/ fixture"
    [ "$(ls "$c/graders" 2>/dev/null | grep -c '^finds-')" -ge 5 ] || fail "$s: eval case needs at least 5 graders/finds-*.md (one per planted defect)"
    [ "$(ls "$c/graders" 2>/dev/null | grep -c '^ignores-')" -ge 1 ] || fail "$s: eval case needs at least 1 graders/ignores-*.md (a decoy)"
    grep -q "${s%auditor}audit\\.md" "$c/prompt.md" 2>/dev/null || fail "$s: eval prompt does not name the report file ${s%auditor}audit.md"
    for g in "$c/prompt.md" "$c"/graders/*.md; do
      [ -f "$g" ] || continue
      for r in $(grep -o '[a-z]*audit[\\]*\.md' "$g" | tr -d '\\' | sort -u); do
        [ "$r" = "${s%auditor}audit.md" ] || fail "$s: ${g#$ROOT/} names $r; it must name this skill's report, ${s%auditor}audit.md"
      done
    done
    ok "$s: eval case present"
  done
}

# Each suite is run and reported on its own line: tests/run.sh (the shared
# scripts) and tests/install.sh (install.sh and uninstall.sh).
check_script_tests() {
  title "script-tests"
  local t out
  for t in tests/run.sh tests/install.sh; do
    if [ ! -f "$ROOT/$t" ]; then
      fail "$t is missing"
      continue
    fi
    if out="$("${BASH:-bash}" "$ROOT/$t" 2>&1)"; then
      ok "$t passed ($(printf '%s\n' "$out" | sed -n '$p'))"
    else
      fail "$t failed:"
      printf "%s\n" "$out" | tail -15 | sed 's/^/          /'
    fi
  done
}

check_plugin_sync() {
  title "plugin-sync"
  local version s item vendored manifest desc err n src d entries
  version="$(cat "$ROOT/VERSION" | tr -d '[:space:]')"
  json_warn_once
  for s in $SKILLS; do
    vendored="$ROOT/plugins/$s/skills/$s"
    manifest="$ROOT/plugins/$s/.claude-plugin/plugin.json"
    for item in $PAYLOAD; do
      if [ ! -e "$ROOT/skills/$s/$item" ]; then
        continue
      elif [ ! -e "$vendored/$item" ]; then
        fail "$s: vendored $item missing (run scripts/refresh-plugins.sh)"
      elif ! diff -r "$ROOT/skills/$s/$item" "$vendored/$item" >/dev/null 2>&1; then
        fail "$s: vendored $item differs from canonical (run scripts/refresh-plugins.sh)"
      else
        ok "$s: vendored $item identical"
      fi
    done
    for item in README.md CHANGELOG.md LICENSE evals; do
      [ ! -e "$vendored/$item" ] || fail "$s: plugins/$s/skills/$s/$item should not be vendored (runtime payload only)"
    done
    if [ ! -f "$manifest" ]; then
      fail "$s: no plugins/$s/.claude-plugin/plugin.json (give it name, version, and the SKILL.md description)"
      continue
    fi
    if ! err="$(json_error "$manifest")"; then
      fail "$s: plugins/$s/.claude-plugin/plugin.json is not valid JSON: $err"
      continue
    fi
    expect_field "$manifest" name "$s" "$s: plugins/$s/.claude-plugin/plugin.json name"
    expect_field "$manifest" version "$version" "$s: plugins/$s/.claude-plugin/plugin.json version"
    desc="$(description_of "$ROOT/skills/$s/SKILL.md")"
    if [ "$(json_field "$manifest" description)" = "$desc" ]; then
      ok "$s: plugin.json description matches SKILL.md"
    else
      fail "$s: plugins/$s/.claude-plugin/plugin.json description differs from the SKILL.md description"
    fi
  done

  manifest="$ROOT/plugins/auditor-suite/.claude-plugin/plugin.json"
  if [ ! -f "$manifest" ]; then
    fail "meta plugin manifest plugins/auditor-suite/.claude-plugin/plugin.json is missing"
  elif ! err="$(json_error "$manifest")"; then
    fail "plugins/auditor-suite/.claude-plugin/plugin.json is not valid JSON: $err"
  else
    expect_field "$manifest" name "auditor-suite" "meta plugin name"
    expect_field "$manifest" version "$version" "meta plugin version"
  fi

  # Each marketplace entry maps its name to ./plugins/<name>, and a skill's
  # entry carries that skill's description. Which names must appear is
  # suite-registry's job.
  manifest="$ROOT/.claude-plugin/marketplace.json"
  if [ ! -f "$manifest" ]; then
    fail ".claude-plugin/marketplace.json is missing"
  elif ! err="$(json_error "$manifest")"; then
    fail ".claude-plugin/marketplace.json is not valid JSON: $err"
  else
    entries="$(json_plugins "$manifest")"
    [ -n "$entries" ] || fail ".claude-plugin/marketplace.json lists no plugins"
    while IFS="$US" read -r n src d; do
      [ -n "$n$src$d" ] || continue
      if [ -z "$n" ]; then
        fail "marketplace entry with source \"$src\" has no name"
        continue
      fi
      if [ "$src" != "./plugins/$n" ]; then
        fail "marketplace entry $n has source \"$src\"; want \"./plugins/$n\""
      elif [ ! -f "$ROOT/plugins/$n/.claude-plugin/plugin.json" ]; then
        fail "marketplace entry $n points to ./plugins/$n, which has no .claude-plugin/plugin.json"
      else
        ok "marketplace entry $n points to ./plugins/$n"
      fi
      if [ "$n" != "auditor-suite" ] && [ -f "$ROOT/skills/$n/SKILL.md" ]; then
        if [ "$d" = "$(description_of "$ROOT/skills/$n/SKILL.md")" ]; then
          ok "marketplace entry $n description matches SKILL.md"
        else
          fail "marketplace entry $n description differs from the skills/$n/SKILL.md description"
        fi
      fi
    done <<EOF
$entries
EOF
  fi
}

# expect_field FILE KEY WANT LABEL: KEY of JSON FILE must equal WANT.
expect_field() {
  local got
  got="$(json_field "$1" "$2")"
  if [ "$got" = "$3" ]; then
    ok "$4 is $3"
  else
    fail "$4 is \"$got\"; want \"$3\""
  fi
}

check_suite_release() {
  title "suite-release"
  local version
  version="$(cat "$ROOT/VERSION" | tr -d '[:space:]')"
  if ! grep -q "version-$version-blue" "$ROOT/README.md"; then
    fail "README version badge is not $version"
  else
    ok "README version badge at $version"
  fi
  if ! grep -q "release-v$version-blue" "$ROOT/README.md"; then
    fail "README release badge is not v$version"
  else
    ok "README release badge at v$version"
  fi
  if ! grep -q "releases/tag/v$version" "$ROOT/README.md"; then
    fail "README release badge does not link releases/tag/v$version"
  else
    ok "README release badge links v$version"
  fi
  if ! grep -q "Release train: $version" "$ROOT/SUITE.md"; then
    fail "SUITE.md release-train line is not $version"
  else
    ok "SUITE.md release train at $version"
  fi
  if ! grep -q "\"version\": \"$version\"" "$ROOT/.claude-plugin/marketplace.json"; then
    fail "marketplace metadata version is not $version"
  else
    ok "marketplace metadata at $version"
  fi
  if ! grep -q "^AS_SUITE_VERSION=\"$version\"$" "$ROOT/shared/scripts/_lib.sh"; then
    fail "shared/scripts/_lib.sh AS_SUITE_VERSION is not $version"
  else
    ok "shared scripts report version $version"
  fi
}

check_changelog_top() {
  title "changelog-top"
  local version top
  version="$(cat "$ROOT/VERSION" | tr -d '[:space:]')"
  top="$(grep -m1 '^## \[' "$ROOT/CHANGELOG.md" || true)"
  case "$top" in
    "## [$version]"*) ok "hub CHANGELOG top entry is $version" ;;
    *) fail "hub CHANGELOG top entry ($top) does not match VERSION ($version)" ;;
  esac
}

# lint_files: every tracked file plus every untracked file git does not
# ignore, NUL-separated and relative to ROOT. Outside a git work tree, every
# file except .git/ and .claude/.
lint_files() {
  if git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git -C "$ROOT" ls-files -z --cached --others --exclude-standard
  else
    (cd "$ROOT" && find . \( -name .git -o -name .claude \) -prune -o -type f -print0)
  fi
}

check_unicode_clean() {
  title "unicode-clean"
  local f bad found pat
  found=0
  # One byte-level ERE, matched with LC_ALL=C grep (not ripgrep, which
  # rejects patterns that are not UTF-8): en and em dash U+2013-2014, arrows
  # U+2190-21FF, box drawing U+2500-257F, symbols and dingbats U+2600-27BF,
  # every U+1Fxxx emoji, and the emoji variation selector VS16 (U+FE0F).
  pat=$'\xe2\x80[\x93\x94]|\xe2\x86[\x90-\xbf]|\xe2\x87[\x80-\xbf]|\xe2[\x94\x95][\x80-\xbf]|\xe2[\x98-\x9e][\x80-\xbf]|\xf0\x9f|\xef\xb8\x8f'
  # A file, not a process substitution, so errexit sees a git failure.
  lint_files > "$LINT_TMP/files"
  while IFS= read -r -d '' f; do
    f="${f#./}"
    [ -f "$ROOT/$f" ] || continue
    bad="$(LC_ALL=C grep -I -n -E -e "$pat" "$ROOT/$f" 2>/dev/null | head -3 || true)"
    if [ -n "$bad" ]; then
      fail "$f contains a dash, arrow, box-drawing character, symbol, or emoji:"
      printf "%s\n" "$bad" | sed 's/^/          /'
      found=1
    fi
  done < "$LINT_TMP/files"
  if [ "$found" = "0" ]; then
    ok "no dashes, arrows, box drawing, symbols, or emojis in tracked or untracked files"
  fi
}

check_bash_syntax() {
  title "bash-syntax"
  local f bad b4
  # Bash 4 constructs that bash -n accepts (or that only a 3.2 parse rejects)
  # but macOS /bin/bash 3.2 cannot run: associative arrays (declare -A),
  # namerefs (declare -n, local -n), mapfile and readarray, case-changing
  # expansions on a name, an array element, or a positional or special
  # parameter (${1,,}), coproc, &>>, and ;;&. Comment lines are skipped. The
  # brackets keep this pattern from matching its own line.
  b4='(^|[^[:alnum:]_])(declare|local|typeset)[[:space:]]+-[[:alpha:]]*[An]|(^|[^[:alnum:]_-])(ma[p]file|read[a]rray|co[p]roc)([^[:alnum:]_-]|$)|[$][{]([[:alpha:]_][[:alnum:]_]*([[][^]]*[]])?|[0-9@*])[,^]|&[>]>|;;[&]'
  for f in "$ROOT/install.sh" "$ROOT/uninstall.sh" "$ROOT"/scripts/*.sh "$ROOT"/shared/scripts/*.sh "$ROOT"/tests/*.sh "$ROOT"/evals/*/*/scaffold.sh; do
    [ -f "$f" ] || continue
    if "${BASH:-bash}" -n "$f" 2>/dev/null; then
      ok "${f#$ROOT/} parses"
    else
      fail "${f#$ROOT/} has a bash syntax error"
    fi
    bad="$(grep -n -E -e "$b4" "$f" 2>/dev/null | grep -v -E '^[0-9]+:[[:space:]]*#' | head -3 || true)"
    if [ -n "$bad" ]; then
      fail "${f#$ROOT/} uses a bash 4 construct that bash 3.2 cannot run:"
      printf "%s\n" "$bad" | sed 's/^/          /'
    fi
  done
}

run_check() {
  case "$1" in
    suite-registry)    check_suite_registry ;;
    skill-frontmatter) check_skill_frontmatter ;;
    skill-structure)   check_skill_structure ;;
    patterns-valid)    check_patterns_valid ;;
    shared-sync)       check_shared_sync ;;
    examples-valid)    check_examples_valid ;;
    evals-structure)   check_evals_structure ;;
    script-tests)      check_script_tests ;;
    plugin-sync)       check_plugin_sync ;;
    suite-release)     check_suite_release ;;
    changelog-top)     check_changelog_top ;;
    unicode-clean)     check_unicode_clean ;;
    bash-syntax)       check_bash_syntax ;;
    *) printf "unknown check: %s\n" "$1" >&2; usage >&2; exit 2 ;;
  esac
}

# Each check runs in a subshell with errexit on, so a command that crashes
# inside it (an awk error, an unset variable) stops that check and is counted,
# instead of being ignored. The subshell must not sit in an if, ||, &&, or !
# list: bash turns errexit off inside those, which would hide the crash. fail()
# appends to FAIL_LOG, so the count survives the subshell; the EXIT trap is not
# run when a subshell exits, so LINT_TMP survives too.
for c in ${ONLY_CHECKS:-$ALL_CHECKS}; do
  set +e
  ( set -e; run_check "$c" )
  rc=$?
  set -e
  if [ "$rc" -ne 0 ]; then
    fail "$c: the check stopped early (exit $rc); a command inside it failed, see the error above"
  fi
done
FAILURES="$(wc -l < "$FAIL_LOG" | tr -d ' ')"

printf "\n"
if [ "$FAILURES" -gt 0 ]; then
  printf "auditor-suite-lint: %d failure(s)\n" "$FAILURES"
  exit 1
fi
printf "auditor-suite-lint: all checks passed\n"
