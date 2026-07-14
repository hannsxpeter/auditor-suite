#!/usr/bin/env bash
# auditor-suite-lint: mechanical enforcement of the suite's discipline rules.
#
# Checks:
#   skill-frontmatter  every skills/<name>/SKILL.md exists and carries valid
#                      Agent Skills frontmatter (name matches the directory,
#                      description present)
#   plugin-sync        every vendored plugins/<name>/skills/<name>/SKILL.md is
#                      byte-identical to the canonical skills/<name>/SKILL.md;
#                      every plugin manifest version matches root VERSION; the
#                      meta plugin depends on all seven auditors; the
#                      marketplace lists all eight plugins
#   suite-release      root VERSION matches the README version and release
#                      badges, the SUITE.md release-train line, and the
#                      marketplace metadata version
#   changelog-top      the hub CHANGELOG.md top entry matches root VERSION
#   unicode-clean      no em dash, en dash, or decorative arrow anywhere in
#                      tracked files
#   bash-syntax        install.sh, uninstall.sh, and scripts/*.sh parse as bash
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
ALL_CHECKS="skill-frontmatter plugin-sync suite-release changelog-top unicode-clean bash-syntax"

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

frontmatter_of() {
  # Print the frontmatter block (between the first two --- lines) of a file.
  awk 'NR==1 && $0!="---" {exit} NR>1 && $0=="---" {exit} NR>1 {print}' "$1"
}

check_skill_frontmatter() {
  title "skill-frontmatter"
  local s f fm
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
    if ! printf "%s\n" "$fm" | grep -q "^description:"; then
      fail "$s: frontmatter has no description"
    else
      ok "$s: description present"
    fi
  done
}

check_plugin_sync() {
  title "plugin-sync"
  local version s vendored manifest
  version="$(cat "$ROOT/VERSION" | tr -d '[:space:]')"
  for s in $SKILLS; do
    vendored="$ROOT/plugins/$s/skills/$s/SKILL.md"
    manifest="$ROOT/plugins/$s/.claude-plugin/plugin.json"
    if [ ! -f "$vendored" ]; then
      fail "$s: vendored SKILL.md missing"
    elif ! cmp -s "$ROOT/skills/$s/SKILL.md" "$vendored"; then
      fail "$s: vendored SKILL.md differs from canonical (run scripts/refresh-plugins.sh)"
    else
      ok "$s: vendored SKILL.md byte-identical"
    fi
    if [ ! -f "$manifest" ]; then
      fail "$s: plugin manifest missing"
    elif ! grep -q "\"version\": \"$version\"" "$manifest"; then
      fail "$s: plugin manifest version is not $version"
    else
      ok "$s: plugin manifest at $version"
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
  for f in "$ROOT/install.sh" "$ROOT/uninstall.sh" "$ROOT"/scripts/*.sh; do
    if bash -n "$f" 2>/dev/null; then
      ok "$(basename "$f") parses"
    else
      fail "$(basename "$f") has a bash syntax error"
    fi
  done
}

run_check() {
  case "$1" in
    skill-frontmatter) check_skill_frontmatter ;;
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
