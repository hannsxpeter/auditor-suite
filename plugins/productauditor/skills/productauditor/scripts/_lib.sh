#!/usr/bin/env bash
# _lib.sh: helpers shared by the auditor-suite scripts. Sourced, never run.
#
# Canonical copy: shared/scripts/_lib.sh in the auditor-suite hub. Every skill
# carries a byte-identical copy under scripts/; edit the shared copy and run
# scripts/sync-shared.sh.
#
# Contract: these helpers only read, except the as_report_* helpers. The only
# file any auditor script writes is the audit report itself (new-report.sh,
# score.sh --write), through those helpers.
# Bash 3.2 compatible: no associative arrays, no mapfile, no ${var,,}.

AS_SUITE_VERSION="1.2.0"

AS_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AS_SKILL_DIR="$(cd "$AS_SCRIPT_DIR/.." && pwd)"
AS_ASSETS="$AS_SKILL_DIR/assets"
AS_REFS="$AS_SKILL_DIR/references"
AS_TAB="$(printf '\t')"

# The same project gives the same leads on every machine: byte-wise sort
# order and character handling (sort decides which leads scan.sh shows), and
# no user configuration of grep or ripgrep (a ripgreprc with --smart-case
# would make case-sensitive cards ignore case).
LC_ALL=C
export LC_ALL
unset GREP_OPTIONS GREP_COLOR GREP_COLORS RIPGREP_CONFIG_PATH

# Directories and files never scanned: vendored code, build output, caches,
# agent-harness folders, and the audit reports themselves. Literal dots are
# written [.], not with a backslash, and every regex reaches awk through
# as_match_lines (ENVIRON), never awk -v: BSD awk and gawk strip the
# backslashes from -v values, which turned \.min\.js$ into .min.js$ and
# dropped admin.js from every audit.
AS_EXCLUDE_RE='(^|/)(node_modules|vendor|bower_components|dist|build|out|[.]next|[.]nuxt|[.]svelte-kit|[.]output|[.]vercel|coverage|__pycache__|[.]venv|venv|[.]tox|[.]terraform|[.]cache|Pods|DerivedData|[.]gradle|[.]git|[.]claude|[.]codex|[.]cursor|[.]agents)/|[.]min[.](js|css)$|[.]map$|(^|/)(code|sec|db|llm|seo|ui|ux|product)audit[.]md$'

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

# Print the non-empty lines of stdin that match an extended regex.
# Arguments: flags (letters; v = keep the lines that do NOT match, l = match
# the lowercased line, so write the regex in lowercase; - for none), regex.
# The regex goes through ENVIRON, which no awk escape-processes; awk -v
# would strip its backslashes on BSD awk and gawk (mawk keeps them).
as_match_lines() {
  AS_RE_FLAGS="$1" AS_RE="$2" awk '
    BEGIN {
      re = ENVIRON["AS_RE"]
      inv = (index(ENVIRON["AS_RE_FLAGS"], "v") > 0)
      low = (index(ENVIRON["AS_RE_FLAGS"], "l") > 0)
    }
    NF {
      s = low ? tolower($0) : $0
      if ((s ~ re) != inv) print
    }'
}

# True when git's view of the tree applies: inside a work tree, and not in a
# folder that work tree ignores (code unpacked inside another checkout).
as_use_git() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 1
  ! git check-ignore -q . 2>/dev/null
}

# The lines of stdin that name a regular file here, not a symlink. It tests
# each line in the shell, which is slow on long lists, so as_files uses it
# only where git gives no file type: untracked files. (find -type f already
# skips symlinks, since find does not follow them by default.)
as_regular_files() {
  local f
  while IFS= read -r f; do
    if [ -f "$f" ] && [ ! -L "$f" ]; then printf '%s\n' "$f"; fi
  done
}

# Files to consider, one per line, relative to the current directory. Uses
# git's view of the tree when it applies (tracked plus untracked-not-ignored),
# otherwise find. Vendored, build, cache, and harness folders are dropped,
# and so is every entry that is not a regular file here: submodules and
# symlinks (rg would search through them, even outside the project, while
# grep skips them), and tracked files that are deleted, outside a sparse
# checkout, or no longer a regular file here.
# Arguments: optional paths to limit the listing.
as_files() {
  if [ $# -eq 0 ]; then
    set -- .
  fi
  if as_use_git; then
    # Tracked files, in one awk pass with no shell test per file: diff-files
    # names the paths deleted here or no longer regular files (D and T; read
    # first, relative to this folder like ls-files), and ls-files -s -t
    # tags skip-worktree entries S and gives each mode (120000 is a symlink,
    # 160000 a submodule). Unlike ls-files -m, diff-files never rereads a
    # file's content, which a fresh copy of a checkout would force.
    {
      git -c core.quotePath=false diff-files --relative --name-only --diff-filter=DT -- "$@" 2>/dev/null |
        awk '{ print "gone\t" $0 }'
      git -c core.quotePath=false ls-files -s -t -- "$@" 2>/dev/null
    } | awk -F'\t' '
      $1 == "gone" { gone[$2] = 1; next }
      { m = substr($1, 3, 6) }
      substr($1, 1, 1) != "S" && m != "120000" && m != "160000" && !($2 in gone) { print $2 }' |
      as_match_lines v "$AS_EXCLUDE_RE"
    # Untracked files carry no mode, so each is tested; a nested repository
    # is listed as "dir/" and fails the test too.
    git -c core.quotePath=false ls-files --others --exclude-standard -- "$@" 2>/dev/null |
      as_match_lines v "$AS_EXCLUDE_RE" | as_regular_files
  else
    find "$@" -type f 2>/dev/null | sed 's|^\./||' | as_match_lines v "$AS_EXCLUDE_RE"
  fi | sort -u | as_skip_filter
}

# Per-skill scan skip: when assets/skill.conf sets SCAN_SKIP_RE (optional,
# for example tests, fixtures, and lockfiles), drop the paths it matches, so
# leads and surface probes skip them. check-report.sh lists no files, so a
# finding may still cite a skipped file the model opened on purpose.
as_skip_filter() {
  if [ -n "${SCAN_SKIP_RE:-}" ]; then
    as_match_lines v "$SCAN_SKIP_RE"
  else
    cat
  fi
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
# Other ERE metacharacters become one-character bracket expressions ([.]),
# not backslash escapes; only ^ and \ keep a backslash, since they cannot be
# bracketed alone.
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
        else if (c == "^" || c == "\\") re = re "\\" c
        else if (index(".+()|[]{}$", c) > 0) re = re "[" c "]"
        else re = re c
      }
      out = out (out == "" ? "" : "|") "(^|/)" re "$"
    }
    print out
  }'
}

# Filter a file list (stdin) to the given globs.
as_filter_globs() {
  as_match_lines - "$(as_glob_re "$1")"
}

# Search the files named on stdin (one per line) for an extended regex.
# Prints path:line:text. Uses ripgrep when present, grep -E otherwise; both
# see the same file list. Set AUDITOR_NO_RG=1 to force grep. ripgrep ignores
# any user config (--no-config) and never descends into a folder argument
# (--max-depth 0), so it searches exactly the files grep does.
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
      xargs -0 rg --no-config --max-depth 0 -n -H --no-heading --color never --no-messages $icase -e "$regex" -- 2>/dev/null
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
# Reads the file list from AS_FILE_LIST (set by the caller). The first hit
# is taken in path and line order: ripgrep searches files in parallel and
# prints them in no fixed order.
as_probe_surfaces() {
  local dim label flags globs regex hit
  as_rows "$AS_ASSETS/surfaces.tsv" | while IFS="$AS_TAB" read -r dim label flags globs regex; do
    [ -n "$dim" ] || continue
    hit="$(printf '%s\n' "$AS_FILE_LIST" | as_filter_globs "$globs" | as_search "$flags" "$regex" | as_trim_hits | sort -t: -k1,1 -k2,2n | head -1)"
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

# Report writes (new-report.sh and score.sh --write only). The audited project
# is untrusted input, so never write through a path it planted: refuse a
# symlink or a non-regular file at the report path, write the new content to
# a fresh temp file beside the report (mktemp picks an unused random name),
# then rename that over the report. A rename replaces a link instead of
# following it, and no temp file lands outside the project.
as_report_path_ok() {
  [ ! -L "$1" ] || as_die "$1 is a symlink; refusing to write through it (delete the link, or audit a clean checkout)"
  if [ -e "$1" ] && [ ! -f "$1" ]; then
    as_die "$1 exists and is not a regular file; move it out of the way first"
  fi
}

# as_report_tmp REPORT: create the temp file beside REPORT and print its path.
as_report_tmp() {
  as_report_path_ok "$1"
  mktemp "$(dirname "$1")/.$(basename "$1").XXXXXX" 2>/dev/null || as_die "could not create a temporary file beside $1"
}

# as_mode_of FILE: the permission bits (owner, group, other) of FILE in
# octal, read from the mode string of ls -l, which describes a symlink
# itself and never follows it; stat's options differ between BSD and GNU.
as_mode_of() {
  ls -ld -- "$1" 2>/dev/null | awk 'NR == 1 {
    m = substr($1, 2, 9)
    if (length(m) != 9) exit
    v = 0
    for (i = 1; i <= 9; i++) {
      c = substr(m, i, 1)
      v = v * 2 + (c != "-" && c != "S" && c != "T")
    }
    printf "%o\n", v
  }'
}

# as_report_commit TMP REPORT [keep]: give TMP the mode a new file gets
# under the current umask, or with "keep" the permission bits of the
# existing REPORT (checked above to be a regular file, not a link), then
# rename TMP over REPORT.
as_report_commit() {
  local mode
  as_report_path_ok "$2"
  mode=""
  if [ "${3:-}" = "keep" ] && [ -f "$2" ]; then
    mode="$(as_mode_of "$2")"
  fi
  [ -n "$mode" ] || mode="$(printf '%o' $(( 0666 & ~0$(umask) )))"
  if chmod "$mode" "$1" && mv -f "$1" "$2"; then
    return 0
  fi
  rm -f "$1"
  as_die "could not write $2"
}
