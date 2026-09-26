#!/usr/bin/env bash
# auditor-suite-lint: mechanical enforcement of the suite's discipline rules.
#
# Checks:
#   skill-frontmatter  every skills/<name>/SKILL.md carries valid Agent Skills
#                      frontmatter (name matches the directory, description
#                      present and at most 1024 characters)
#   skill-structure    every skill has the spine, references, scripts, and
#                      assets the shared scripts need; SKILL.md stays under the
#                      token budget and names every reference file; dimension
#                      files, rule cards, dimensions.tsv, patterns.tsv,
#                      surfaces.tsv, and skill.conf are well formed
#   patterns-valid     every regex in patterns.tsv and surfaces.tsv compiles
#                      under grep -E (and ripgrep when installed)
#   shared-sync        every skill's copies of the shared core are
#                      byte-identical to shared/
#   examples-valid     every references/example-report.md passes its own
#                      check-report.sh against tests/fixtures/<name>/
#   evals-structure    every skill has an eval case with prompt, case.yaml,
#                      scaffold, answer key, fixture repo, and core graders
#   script-tests       tests/run.sh passes (golden tests for the scripts)
#   plugin-sync        every vendored plugins/<name>/skills/<name>/ payload is
#                      identical to the canonical skill payload; manifests match
#                      VERSION and the skill description; the meta plugin
#                      depends on all seven; the marketplace lists all eight
#   suite-release      VERSION matches the README badges, SUITE.md, the
#                      marketplace metadata, and the shared scripts' version
#   changelog-top      the hub CHANGELOG.md top entry matches VERSION
#   unicode-clean      no em dash, en dash, or decorative arrow in tracked files
#   bash-syntax        every shell script in the hub parses as bash
#
# Bash 3.2 compatible (macOS default). No associative arrays.
#
# Usage:
#   bash scripts/lint.sh                 # all checks
#   bash scripts/lint.sh --verbose      # show ok lines
#   bash scripts/lint.sh plugin-sync    # one specific check
#   bash scripts/lint.sh --help

set -eu

VERBOSE=0
ONLY_CHECK=""
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

SKILLS="codeauditor secauditor dbauditor llmauditor seoauditor uiauditor uxauditor"
ALL_CHECKS="skill-frontmatter skill-structure patterns-valid shared-sync examples-valid evals-structure script-tests plugin-sync suite-release changelog-top unicode-clean bash-syntax"
PAYLOAD="SKILL.md references scripts assets"
TAB="$(printf '\t')"

usage() {
  cat <<EOF
auditor-suite-lint

Usage: lint.sh [--verbose] [check-name]

Checks: $ALL_CHECKS
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    -v|--verbose) VERBOSE=1 ;;
    -h|--help) usage; exit 0 ;;
    -*) printf "unknown flag: %s\n" "$1" >&2; usage >&2; exit 2 ;;
    *) ONLY_CHECK="$1" ;;
  esac
  shift
done

FAILURES=0

fail() { printf "  fail  %s\n" "$*"; FAILURES=$((FAILURES + 1)); }
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

check_skill_frontmatter() {
  title "skill-frontmatter"
  local s f fm desc
  for s in $SKILLS; do
    f="$ROOT/skills/$s/SKILL.md"
    if [ ! -f "$f" ]; then
      fail "$s: missing $f"
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
  local s d f bytes lines conf key dims id rest cards card
  for s in $SKILLS; do
    d="$ROOT/skills/$s"
    for f in SKILL.md README.md CHANGELOG.md LICENSE references/protocol.md references/example-report.md assets/report-template.md assets/skill.conf assets/dimensions.tsv assets/patterns.tsv assets/surfaces.tsv scripts/_lib.sh scripts/inventory.sh scripts/scan.sh scripts/new-report.sh scripts/score.sh scripts/check-report.sh; do
      [ -f "$d/$f" ] || fail "$s: missing $f"
    done
    [ -f "$d/SKILL.md" ] || continue

    bytes="$(body_of "$d/SKILL.md" | wc -c | tr -d ' ')"
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
    fi

    [ -f "$d/assets/dimensions.tsv" ] || continue
    dims="$(rows_of "$d/assets/dimensions.tsv" | cut -f1)"
    fail_lines "$(rows_of "$d/assets/dimensions.tsv" | awk -F'\t' -v s="$s" '
      NF != 5 { printf "%s: dimensions.tsv row \"%s\" has %d fields; want id, weight, applies, floor, name\n", s, $0, NF; next }
      $1 !~ /^[A-Z][A-Z0-9]*$/ { printf "%s: dimension id %s is not upper-case letters and digits\n", s, $1 }
      $2 !~ /^[1-9][0-9]*$/ { printf "%s: dimension %s weight %s is not a positive integer\n", s, $1, $2 }
      $3 != "always" && $3 != "conditional" { printf "%s: dimension %s applies is %s; want always or conditional\n", s, $1, $3 }
      $4 != "yes" && $4 != "no" { printf "%s: dimension %s floor is %s; want yes or no\n", s, $1, $4 }
      seen[$1]++ == 1 { printf "%s: dimension %s is listed twice\n", s, $1 }
    ')"

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
          card = $2; fields = ""
          if (card !~ "^" id "-R[0-9]+$") printf "%s: %s.md heading \"%s\" is not a card of %s (### %s-R<n> Title)\n", s, id, $0, id, id
          if (card in seen) printf "%s: card %s appears twice\n", s, card
          seen[card] = 1
          ncards++
          if (NF < 3) printf "%s: card %s has no title\n", s, card
          next
        }
        /^## / { if (card != "") check(); card = ""; next }
        card != "" && /^- [A-Za-z ]+:/ { k = $0; sub(/^- /, "", k); sub(/:.*/, "", k); fields = fields "|" k "|" }
        function check(   want, n, i) {
          n = split("Leads|Confirm|Not a finding if|Severity|Fix|Verify the fix|Refs", want, "|")
          for (i = 1; i <= n; i++) if (index(fields, "|" want[i] "|") == 0) printf "%s: card %s is missing \"- %s:\"\n", s, card, want[i]
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

    for id in $(rows_of "$d/assets/dimensions.tsv" | awk -F'\t' '$3 == "conditional" { print $1 }'); do
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
    if out="$(cd "$fx" && bash "$ROOT/skills/$s/scripts/check-report.sh" "$ex" --root "$fx" 2>&1)"; then
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
    ok "$s: eval case present"
  done
}

check_script_tests() {
  title "script-tests"
  if [ ! -f "$ROOT/tests/run.sh" ]; then
    fail "tests/run.sh is missing"
    return
  fi
  local out
  if out="$(bash "$ROOT/tests/run.sh" 2>&1)"; then
    ok "tests/run.sh passed"
  else
    fail "tests/run.sh failed:"
    printf "%s\n" "$out" | tail -15 | sed 's/^/          /'
  fi
}

check_plugin_sync() {
  title "plugin-sync"
  local version s item vendored manifest desc
  version="$(cat "$ROOT/VERSION" | tr -d '[:space:]')"
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
      fail "$s: plugin manifest missing"
    else
      if ! grep -q "\"version\": \"$version\"" "$manifest"; then
        fail "$s: plugin manifest version is not $version"
      else
        ok "$s: plugin manifest at $version"
      fi
      desc="$(description_of "$ROOT/skills/$s/SKILL.md")"
      if ! grep -qF "\"description\": \"$desc\"" "$manifest"; then
        fail "$s: plugin.json description differs from the SKILL.md description"
      else
        ok "$s: plugin.json description matches SKILL.md"
      fi
      if ! grep -qF "\"description\": \"$desc\"" "$ROOT/.claude-plugin/marketplace.json"; then
        fail "$s: marketplace.json description differs from the SKILL.md description"
      else
        ok "$s: marketplace description matches SKILL.md"
      fi
    fi
  done
  manifest="$ROOT/plugins/auditor-suite/.claude-plugin/plugin.json"
  if [ ! -f "$manifest" ]; then
    fail "meta plugin manifest missing"
  else
    if ! grep -q "\"version\": \"$version\"" "$manifest"; then
      fail "meta plugin manifest version is not $version"
    else
      ok "meta plugin manifest at $version"
    fi
    for s in $SKILLS; do
      if ! grep -q "\"$s\"" "$manifest"; then
        fail "meta plugin does not depend on $s"
      else
        ok "meta plugin depends on $s"
      fi
    done
  fi
  local marketplace="$ROOT/.claude-plugin/marketplace.json"
  if [ ! -f "$marketplace" ]; then
    fail "marketplace.json missing"
  else
    for s in auditor-suite $SKILLS; do
      if ! grep -q "\"source\": \"./plugins/$s\"" "$marketplace"; then
        fail "marketplace does not list ./plugins/$s"
      else
        ok "marketplace lists $s"
      fi
    done
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

check_unicode_clean() {
  title "unicode-clean"
  local f bad found
  found=0
  # em dash U+2014, en dash U+2013, rightwards arrow U+2192
  for f in $(cd "$ROOT" && git ls-files 2>/dev/null || find . -type f -name '*.md' -o -name '*.sh' -o -name '*.json' -o -name '*.yml'); do
    [ -f "$ROOT/$f" ] || continue
    bad="$(LC_ALL=C grep -n $'\xe2\x80\x94\|\xe2\x80\x93\|\xe2\x86\x92' "$ROOT/$f" 2>/dev/null | head -3 || true)"
    if [ -n "$bad" ]; then
      fail "$f contains an em dash, en dash, or arrow:"
      printf "%s\n" "$bad" | sed 's/^/          /'
      found=1
    fi
  done
  [ "$found" = "0" ] && ok "no em dashes, en dashes, or arrows in tracked files"
}

check_bash_syntax() {
  title "bash-syntax"
  local f
  for f in "$ROOT/install.sh" "$ROOT/uninstall.sh" "$ROOT"/scripts/*.sh "$ROOT"/shared/scripts/*.sh "$ROOT"/tests/*.sh "$ROOT"/evals/*/*/scaffold.sh; do
    [ -f "$f" ] || continue
    if bash -n "$f" 2>/dev/null; then
      ok "${f#$ROOT/} parses"
    else
      fail "${f#$ROOT/} has a bash syntax error"
    fi
  done
}

run_check() {
  case "$1" in
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

if [ -n "$ONLY_CHECK" ]; then
  run_check "$ONLY_CHECK"
else
  for c in $ALL_CHECKS; do
    run_check "$c"
  done
fi

printf "\n"
if [ "$FAILURES" -gt 0 ]; then
  printf "auditor-suite-lint: %d failure(s)\n" "$FAILURES"
  exit 1
fi
printf "auditor-suite-lint: all checks passed\n"
