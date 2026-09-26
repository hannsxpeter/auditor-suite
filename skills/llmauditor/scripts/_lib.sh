#!/usr/bin/env bash
# _lib.sh: helpers shared by the auditor-suite scripts. Sourced, never run.
#
# Canonical copy: shared/scripts/_lib.sh in the auditor-suite hub. Every skill
# carries a byte-identical copy under scripts/; edit the shared copy and run
# scripts/sync-shared.sh.
#
# Contract: these helpers only read. The only file any auditor script writes
# is the audit report itself (new-report.sh, score.sh --write).
# Bash 3.2 compatible: no associative arrays, no mapfile, no ${var,,}.

AS_SUITE_VERSION="1.1.0"

AS_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AS_SKILL_DIR="$(cd "$AS_SCRIPT_DIR/.." && pwd)"
AS_ASSETS="$AS_SKILL_DIR/assets"
AS_REFS="$AS_SKILL_DIR/references"
AS_TAB="$(printf '\t')"

# Directories and files never scanned: vendored code, build output, caches,
# agent-harness folders, and the audit reports themselves.
AS_EXCLUDE_RE='(^|/)(node_modules|vendor|bower_components|dist|build|out|\.next|\.nuxt|\.svelte-kit|\.output|\.vercel|coverage|__pycache__|\.venv|venv|\.tox|\.terraform|\.cache|Pods|DerivedData|\.gradle|\.git|\.claude|\.codex|\.cursor|\.agents)/|\.min\.(js|css)$|\.map$|(^|/)(code|sec|db|llm|seo|ui|ux)audit\.md$'

as_die() {
  printf 'error: %s\n' "$*" >&2
  exit 2
}

as_load_conf() {
  [ -f "$AS_ASSETS/skill.conf" ] || as_die "missing $AS_ASSETS/skill.conf; run this script from inside an auditor skill's scripts/ folder"
  # shellcheck source=/dev/null
  . "$AS_ASSETS/skill.conf"
}

# Data rows of a TSV asset: comments and blank lines removed.
as_rows() {
  [ -f "$1" ] || return 0
  grep -v '^[[:space:]]*#' "$1" | grep -v '^[[:space:]]*$' || true
}

# Dimension IDs in table order.
as_dim_ids() {
  as_rows "$AS_ASSETS/dimensions.tsv" | cut -f1
}

# Field N (1-based) of dimension ID's row in dimensions.tsv.
# Columns: id, weight, applies (always|conditional), floor (yes|no), name.
as_dim_field() {
  as_rows "$AS_ASSETS/dimensions.tsv" | awk -F'\t' -v id="$1" -v n="$2" '$1 == id { print $n; exit }'
}

as_is_dim() {
  [ -n "$1" ] || return 1
  as_dim_ids | grep -qx "$1"
}

# Files to consider, one per line, relative to the current directory. Uses
# git's view of the tree when available (tracked plus untracked-not-ignored),
# otherwise find. Vendored, build, cache, and harness folders are dropped.
# Arguments: optional paths to limit the listing.
as_files() {
  if [ $# -eq 0 ]; then
    set -- .
  fi
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git ls-files --cached --others --exclude-standard -- "$@" 2>/dev/null
  else
    find "$@" -type f 2>/dev/null | sed 's|^\./||'
  fi | awk -v excl="$AS_EXCLUDE_RE" 'NF && $0 !~ excl' | sort -u
}

# Glob macros usable in patterns.tsv and surfaces.tsv.
AS_GLOB_CODE='*.js,*.jsx,*.mjs,*.cjs,*.ts,*.tsx,*.mts,*.cts,*.py,*.rb,*.go,*.rs,*.java,*.kt,*.kts,*.scala,*.cs,*.php,*.swift,*.ex,*.exs,*.dart,*.lua,*.pl,*.vue,*.svelte,*.astro'
AS_GLOB_WEB='*.html,*.htm,*.vue,*.svelte,*.astro,*.jsx,*.tsx,*.ejs,*.hbs,*.handlebars,*.njk,*.jinja,*.jinja2,*.j2,*.erb,*.liquid,*.twig,*.php,*.cshtml,*.razor,*.mdx'
AS_GLOB_STYLE='*.css,*.scss,*.sass,*.less,*.styl,*.pcss'
AS_GLOB_CONFIG='*.json,*.jsonc,*.yml,*.yaml,*.toml,*.ini,*.cfg,*.conf,*.env,.env,.env.*,*.properties,*.xml,*.config.js,*.config.ts,*.config.mjs,*.config.cjs'
AS_GLOB_SQL='*.sql,*.prisma,*.psql,*.ddl'
AS_GLOB_INFRA='Dockerfile,Dockerfile.*,*.dockerfile,docker-compose*.yml,docker-compose*.yaml,compose*.yml,compose*.yaml,*.tf,*.tfvars,*.hcl,Chart.yaml,values*.yaml,kustomization.yaml,*.bicep,serverless.yml,serverless.yaml,Procfile,fly.toml,render.yaml,vercel.json,netlify.toml,nginx.conf,*.nginx'
AS_GLOB_CI='*.yml,*.yaml,Jenkinsfile,.gitlab-ci.yml'
AS_GLOB_DOCS='*.md,*.mdx,*.txt,*.rst,*.adoc'
AS_GLOB_SHELL='*.sh,*.bash,*.zsh,*.ps1,Makefile,*.mk'

# Expand @code, @web, @style, @config, @sql, @infra, @ci, @docs, @shell.
as_glob_expand() {
  printf '%s\n' "$1" | awk -F',' \
    -v code="$AS_GLOB_CODE" -v web="$AS_GLOB_WEB" -v style="$AS_GLOB_STYLE" \
    -v config="$AS_GLOB_CONFIG" -v sql="$AS_GLOB_SQL" -v infra="$AS_GLOB_INFRA" \
    -v ci="$AS_GLOB_CI" -v docs="$AS_GLOB_DOCS" -v shell="$AS_GLOB_SHELL" '{
    out = ""
    for (i = 1; i <= NF; i++) {
      g = $i
      gsub(/^[ ]+|[ ]+$/, "", g)
      if (g == "@code") g = code
      else if (g == "@web") g = web
      else if (g == "@style") g = style
      else if (g == "@config") g = config
      else if (g == "@sql") g = sql
      else if (g == "@infra") g = infra
      else if (g == "@ci") g = ci
      else if (g == "@docs") g = docs
      else if (g == "@shell") g = shell
      out = out (out == "" ? "" : ",") g
    }
    print out
  }'
}

# Convert comma-separated basename globs (*.js,Dockerfile*) and macros to one
# ERE that matches whole paths. Supports * and ? only. "*" matches every file.
as_glob_re() {
  as_glob_expand "$1" | awk -F',' '{
    out = ""
    for (i = 1; i <= NF; i++) {
      g = $i
      gsub(/^[ ]+|[ ]+$/, "", g)
      if (g == "") continue
      re = ""
      for (j = 1; j <= length(g); j++) {
        c = substr(g, j, 1)
        if (c == "*") re = re "[^/]*"
        else if (c == "?") re = re "[^/]"
        else if (index(".+()|[]{}^$\\", c) > 0) re = re "\\" c
        else re = re c
      }
      out = out (out == "" ? "" : "|") "(^|/)" re "$"
    }
    print out
  }'
}

# Filter a file list (stdin) to the given globs.
as_filter_globs() {
  local re
  re="$(as_glob_re "$1")"
  awk -v re="$re" '$0 ~ re'
}

# Search the files named on stdin (one per line) for an extended regex.
# Prints path:line:text. Uses ripgrep when present, grep -E otherwise; both
# see the same file list. Set AUDITOR_NO_RG=1 to force grep.
# Arguments: flags (letters; i = ignore case), regex.
as_search() {
  local flags regex list icase
  flags="$1"
  regex="$2"
  list="$(cat)"
  [ -n "$list" ] || return 0
  icase=""
  case "$flags" in *i*) icase="-i" ;; esac
  if [ -z "${AUDITOR_NO_RG:-}" ] && command -v rg >/dev/null 2>&1; then
    printf '%s\n' "$list" | tr '\n' '\0' |
      xargs -0 rg -n -H --no-heading --color never --no-messages $icase -e "$regex" -- 2>/dev/null
  else
    printf '%s\n' "$list" | tr '\n' '\0' |
      xargs -0 grep -n -H -I -E $icase -e "$regex" -- 2>/dev/null
  fi
  return 0
}

# Trim search output to path:line: text, text cut to 160 characters.
as_trim_hits() {
  awk '{
    sub(/\r$/, "")
    p = index($0, ":")
    if (p == 0) next
    rest = substr($0, p + 1)
    q = index(rest, ":")
    if (q == 0) next
    file = substr($0, 1, p - 1)
    line = substr(rest, 1, q - 1)
    text = substr(rest, q + 1)
    sub(/^\.\//, "", file)
    gsub(/\t/, " ", text)
    sub(/^[ ]+/, "", text)
    if (length(text) > 160) text = substr(text, 1, 157) "..."
    print file ":" line ": " text
  }'
}

# Surface probes (assets/surfaces.tsv): does the project contain what a
# conditional dimension audits? Columns: dim, label, flags, globs, regex.
# Prints one line per probe row: dim<TAB>found|none<TAB>first-hit<TAB>label.
# Reads the file list from AS_FILE_LIST (set by the caller).
as_probe_surfaces() {
  local dim label flags globs regex hit
  as_rows "$AS_ASSETS/surfaces.tsv" | while IFS="$AS_TAB" read -r dim label flags globs regex; do
    [ -n "$dim" ] || continue
    hit="$(printf '%s\n' "$AS_FILE_LIST" | as_filter_globs "$globs" | as_search "$flags" "$regex" | as_trim_hits | head -1)"
    if [ -n "$hit" ]; then
      printf '%s\tfound\t%s\t%s\n' "$dim" "$hit" "$label"
    else
      printf '%s\tnone\t-\t%s\n' "$dim" "$label"
    fi
  done
}

# Decide dimension status from probe output (stdin, as_probe_surfaces format).
# Prints dim<TAB>active|na<TAB>reason for every dimension in table order.
as_dim_status() {
  local probes id applies
  probes="$(cat)"
  as_dim_ids | while read -r id; do
    applies="$(as_dim_field "$id" 3)"
    if [ "$applies" = "always" ]; then
      printf '%s\tactive\talways audited\n' "$id"
    elif printf '%s\n' "$probes" | awk -F'\t' -v d="$id" '$1 == d && $2 == "found" { f = 1 } END { exit !f }'; then
      printf '%s\tactive\t%s\n' "$id" "$(printf '%s\n' "$probes" | awk -F'\t' -v d="$id" '$1 == d && $2 == "found" { print "surface found at " $3; exit }')"
    else
      printf '%s\tna\t%s\n' "$id" "$(printf '%s\n' "$probes" | awk -F'\t' -v d="$id" '$1 == d { l = l (l == "" ? "" : "; ") $4 } END { if (l == "") l = "no probe defined"; print "no match for: " l }')"
    fi
  done
}
