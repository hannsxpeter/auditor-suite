#!/usr/bin/env bash
# inventory.sh: Phase 0 in one command. Prints what the project is made of,
# how big it is, and which conditional dimensions have a surface to audit.
#
# Usage: bash <skill>/scripts/inventory.sh [path ...]
#   Run from the project root. Optional paths limit the inventory to a subtree.
#
# Read-only: prints to stdout, writes nothing.

set -u
. "$(cd "$(dirname "$0")" && pwd)/_lib.sh"
as_load_conf

case "${1:-}" in
  -h|--help)
    sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'
    exit 0
    ;;
esac

AS_FILE_LIST="$(as_files "$@")"
ROOT_ABS="$(pwd)"

printf 'auditor-suite %s inventory for %s\n' "$SKILL_NAME" "$ROOT_ABS"
[ $# -gt 0 ] && printf 'scope: %s\n' "$*"

# Version control state.
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || printf 'unknown')"
  commit="$(git rev-parse --short HEAD 2>/dev/null || printf 'no commits')"
  changed="$(git status --porcelain 2>/dev/null | awk -v r="$REPORT_FILE" '$NF != r' | wc -l | tr -d ' ')"
  printf 'git: branch %s, commit %s, %s uncommitted change(s)\n' "$branch" "$commit" "$changed"
else
  printf 'git: not a git repository\n'
fi

CODE_EXT_RE='\.(js|jsx|mjs|cjs|ts|tsx|mts|cts|py|rb|go|rs|java|kt|kts|scala|cs|fs|php|swift|m|mm|c|cc|cpp|cxx|h|hpp|sql|vue|svelte|astro|html|htm|css|scss|sass|less|dart|ex|exs|erl|clj|lua|pl|sh|bash|zsh|ps1|tf|hcl|prisma|graphql|gql|jinja|j2|njk|hbs|ejs|erb|liquid|twig|mdx)$'

total="$(printf '%s\n' "$AS_FILE_LIST" | awk 'NF' | wc -l | tr -d ' ')"
code_list="$(printf '%s\n' "$AS_FILE_LIST" | awk -v re="$CODE_EXT_RE" 'tolower($0) ~ re')"
code_count="$(printf '%s\n' "$code_list" | awk 'NF' | wc -l | tr -d ' ')"
lines=0
if [ "$code_count" -gt 0 ]; then
  lines="$(printf '%s\n' "$code_list" | awk 'NF' | tr '\n' '\0' | xargs -0 cat 2>/dev/null | wc -l | tr -d ' ')"
fi
printf 'files: %s considered (%s source files, about %s source lines); vendored, build, and cache folders skipped\n' "$total" "$code_count" "$lines"

if [ "$code_count" -eq 0 ]; then
  printf '\nNO SOURCE CODE FOUND. Stop: tell the user this directory is not a codebase this audit can read, and do not write a report.\n'
  exit 0
fi
if [ "$code_count" -le 300 ]; then
  printf 'read strategy: exhaustive (300 source files or fewer): read every file the active dimensions touch\n'
else
  printf 'read strategy: sampled (more than 300 source files): read entry points, hot paths, and every file a lead points to; name what you sampled in Snapshot\n'
fi

printf 'languages (source files by extension): %s\n' "$(printf '%s\n' "$code_list" | awk -F. 'NF > 1 { c[tolower($NF)]++ } END { for (e in c) printf "%d %s\n", c[e], e }' | sort -rn | awk '{ printf "%s%s %s", (NR > 1 ? ", " : ""), $2, $1 } END { print "" }')"

list_matching() {
  # list_matching LABEL ERE: comma-joined files whose path matches, max 12.
  local found
  found="$(printf '%s\n' "$AS_FILE_LIST" | awk -v re="$2" '$0 ~ re' | head -12 | awk '{ printf "%s%s", (NR > 1 ? ", " : ""), $0 }')"
  [ -n "$found" ] || found="none"
  printf '%s: %s\n' "$1" "$found"
}

list_matching 'manifests' '(^|/)(package\.json|pyproject\.toml|requirements[^/]*\.txt|Pipfile|setup\.py|go\.mod|Cargo\.toml|Gemfile|composer\.json|pom\.xml|build\.gradle(\.kts)?|[^/]*\.csproj|mix\.exs|pubspec\.yaml|Package\.swift|deno\.jsonc?)$'
list_matching 'lockfiles' '(^|/)(package-lock\.json|yarn\.lock|pnpm-lock\.yaml|bun\.lockb?|poetry\.lock|Pipfile\.lock|uv\.lock|go\.sum|Cargo\.lock|Gemfile\.lock|composer\.lock|packages\.lock\.json|mix\.lock|pubspec\.lock|Package\.resolved|deno\.lock)$'
list_matching 'ci' '(^|/)(\.github/workflows/[^/]+\.ya?ml|\.gitlab-ci\.yml|Jenkinsfile|\.circleci/config\.yml|azure-pipelines\.yml|bitbucket-pipelines\.yml|\.buildkite/[^/]+)$'
list_matching 'containers and infrastructure' '(^|/)(Dockerfile[^/]*|[^/]*\.dockerfile|docker-compose[^/]*\.ya?ml|compose[^/]*\.ya?ml|[^/]*\.tf|[^/]*\.tfvars|Chart\.yaml|kustomization\.ya?ml|serverless\.ya?ml|cdk\.json|Pulumi\.ya?ml|[^/]*\.bicep|template\.ya?ml)$'
list_matching 'docs' '^(README[^/]*|CHANGELOG[^/]*|SECURITY\.md|CONTRIBUTING\.md|ARCHITECTURE\.md|docs/README[^/]*)$'
list_matching 'entry points (candidates)' '(^|/)(main|index|app|server|cli|manage|wsgi|asgi|program|application|bootstrap)\.[a-z]+$|^bin/[^/]+$|^cmd/[^/]+/main\.go$|(^|/)src/main\.rs$|(^|/)app/(layout|page)\.[jt]sx?$|(^|/)pages/_app\.[jt]sx?$'
tests="$(printf '%s\n' "$AS_FILE_LIST" | awk '/(^|\/)(tests?|__tests__|spec)\/|_test\.(go|py|rb)$|\.(test|spec)\.[a-z]+$|(^|\/)test_[^\/]+\.py$/' | wc -l | tr -d ' ')"
printf 'tests: %s test file(s)\n' "$tests"

# Frameworks and notable libraries named in manifests.
manifests="$(printf '%s\n' "$AS_FILE_LIST" | awk '/(^|\/)(package\.json|pyproject\.toml|requirements[^\/]*\.txt|Pipfile|go\.mod|Cargo\.toml|Gemfile|composer\.json|pom\.xml|build\.gradle(\.kts)?|mix\.exs|pubspec\.yaml)$/' | head -40)"
if [ -n "$manifests" ]; then
  libs="$(printf '%s\n' "$manifests" | tr '\n' '\0' | xargs -0 cat 2>/dev/null | awk '
    BEGIN {
      n = split("react react-dom next vue nuxt svelte @sveltejs/kit astro @angular/core solid-js preact gatsby @remix-run/react react-router react-native expo express fastify koa hono @nestjs/core django flask fastapi starlette rails sinatra laravel/framework symfony/framework-bundle spring-boot-starter-web gin-gonic/gin labstack/echo gofiber/fiber actix-web axum rocket prisma @prisma/client sequelize typeorm drizzle-orm knex mongoose mongodb sqlalchemy alembic psycopg psycopg2 asyncpg pg mysql2 sqlite3 better-sqlite3 gorm.io/gorm diesel sqlx redis ioredis @elastic/elasticsearch @opensearch-project/opensearch pinecone weaviate-client qdrant-client chromadb pgvector openai anthropic @anthropic-ai/sdk google-genai @google/genai google-generativeai @google/generative-ai mistralai cohere langchain @langchain/core langgraph llama-index llamaindex @modelcontextprotocol/sdk mcp litellm ollama transformers tailwindcss styled-components @emotion/react @mui/material @chakra-ui/react @radix-ui/react-dialog @mantine/core antd bootstrap i18next react-i18next next-intl vue-i18n @formatjs/intl react-intl @lingui/core jsonwebtoken jose passport next-auth @auth/core bcrypt bcryptjs argon2 helmet cors express-rate-limit stripe @aws-sdk/client-s3 aws-sdk boto3 firebase-admin @supabase/supabase-js graphql @apollo/server zod pydantic", names, " ")
      for (i = 1; i <= n; i++) want[names[i]] = 1
    }
    {
      line = $0
      gsub(/["'\'',=<>~^:@ \t\[\]]+/, " ", line)
      m = split(line, tok, " ")
      for (i = 1; i <= m; i++) {
        t = tolower(tok[i])
        if (t in want) seen[t] = 1
        p = index(t, "/")
        if (p > 0 && (substr(t, p + 1) in want)) seen[substr(t, p + 1)] = 1
      }
      raw = $0
      while (match(raw, /@[a-z0-9-]+\/[a-z0-9.-]+/)) {
        t = substr(raw, RSTART, RLENGTH)
        if (t in want) seen[t] = 1
        raw = substr(raw, RSTART + RLENGTH)
      }
    }
    END { for (t in seen) print t }' | sort | awk '{ printf "%s%s", (NR > 1 ? ", " : ""), $0 } END { print "" }')"
  [ -n "$libs" ] || libs="none recognized"
  printf 'frameworks and libraries (from manifests): %s\n' "$libs"
fi

skipped="$(git ls-files --cached --others --exclude-standard 2>/dev/null | awk -v excl="$AS_EXCLUDE_RE" '$0 ~ excl' | awk -F/ '{ print $1 }' | sort -u | head -8 | awk '{ printf "%s%s", (NR > 1 ? ", " : ""), $0 }')"
[ -n "$skipped" ] && printf 'skipped folders present: %s (read them only if a lead points there)\n' "$skipped"

# Surfaces and dimension status.
probes="$(as_probe_surfaces)"
printf '\nsurface probes (%s):\n' "$SKILL_NAME"
surface="$(printf '%s\n' "$probes" | awk -F'\t' '$1 == "_SURFACE" && $2 == "found" { print $3; exit }')"
if printf '%s\n' "$probes" | awk -F'\t' '$1 == "_SURFACE" { f = 1 } END { exit !f }'; then
  if [ -n "$surface" ]; then
    printf '  domain surface: found (%s)\n' "$surface"
  else
    printf '  domain surface: NOT FOUND by the probes (%s).\n' "$(printf '%s\n' "$probes" | awk -F'\t' '$1 == "_SURFACE" { l = l (l == "" ? "" : "; ") $4 } END { print l }')"
    printf '  If reading the code confirms there is nothing to audit, stop: tell the user and do not write a report. %s\n' "${STOP_HINT:-}"
  fi
fi
status="$(printf '%s\n' "$probes" | as_dim_status)"
printf '%s\n' "$status" | awk -F'\t' '{ printf "  %-12s %-6s %s\n", $1, ($2 == "na" ? "n/a" : $2), $3 }'

active="$(printf '%s\n' "$status" | awk -F'\t' '$2 == "active" { printf "%s%s", (n++ ? ", " : ""), $1 }')"
na="$(printf '%s\n' "$status" | awk -F'\t' '$2 == "na" { printf "%s%s", (n++ ? ", " : ""), $1 }')"
[ -n "$na" ] || na="none"
printf '\nsuggested dimensions: active %s; not applicable %s\n' "$active" "$na"
printf 'next: bash %s/scripts/new-report.sh --mode full   (or --mode quick, or --mode only=%s)\n' "$AS_SKILL_DIR" "$(printf '%s' "$active" | cut -d, -f1)"
