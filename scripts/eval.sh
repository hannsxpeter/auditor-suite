#!/usr/bin/env bash
# eval.sh: run one auditor's eval suite with `claude plugin eval`.
#
# Usage: bash scripts/eval.sh <skill> [--ref <git-ref>] [claude plugin eval options ...]
#   --ref   evaluate the skill as it was at a git ref (for example v1.0.0),
#           to get a baseline for the current version
#
# Examples:
#   bash scripts/eval.sh secauditor --model claude-haiku-4-5 --runs 1 --max-cost-usd 5
#   bash scripts/eval.sh secauditor --ref v1.0.0 --model claude-haiku-4-5 --runs 1
#
# Assembles a temporary plugin (the vendored plugins/<skill> plus
# evals/<skill> as its evals/ folder) and runs `claude plugin eval` with the
# fixture scaffold enabled, Write, Edit, and Bash granted (auditors write and
# fill their report and run their bundled scripts), and results under evals/results/.
# Requires Claude Code 2.1.269 or later. Model calls use your credentials and
# count against your plan or API bill; set --max-cost-usd.
#
# Bash 3.2 compatible.

set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

die() {
  printf 'eval.sh: %s\n' "$*" >&2
  exit 2
}

[ $# -ge 1 ] || die "usage: bash scripts/eval.sh <skill> [--ref <git-ref>] [claude plugin eval options ...]"
skill="$1"
shift
REF=""
if [ "${1:-}" = "--ref" ]; then
  [ $# -ge 2 ] || die "--ref needs a git ref"
  REF="$2"
  shift 2
fi

[ -d "$ROOT/evals/$skill" ] || die "no eval suite at evals/$skill"
[ -d "$ROOT/plugins/$skill" ] || die "no plugin at plugins/$skill"
command -v claude >/dev/null 2>&1 || die "the claude CLI is not on PATH"

tmp="$(mktemp -d "${TMPDIR:-/tmp}/auditor-eval.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT
plugin="$tmp/$skill"

if [ -n "$REF" ]; then
  mkdir -p "$tmp/ref"
  git -C "$ROOT" archive "$REF" "plugins/$skill" | tar -x -C "$tmp/ref" || die "could not read plugins/$skill at $REF"
  mv "$tmp/ref/plugins/$skill" "$plugin"
else
  cp -R "$ROOT/plugins/$skill" "$plugin"
fi
rm -rf "$plugin/evals"
cp -R "$ROOT/evals/$skill" "$plugin/evals"

label="$(printf '%s' "${REF:-working-tree}" | tr '/ ' '--')"
out="$ROOT/evals/results/$skill-$label-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$out"

printf 'evaluating %s (%s); results: %s\n' "$skill" "${REF:-working tree}" "$out"
claude plugin eval "$plugin" "$@" --scaffold --trust-plugin --output-dir "$out" --allow-tools Write Edit Bash
