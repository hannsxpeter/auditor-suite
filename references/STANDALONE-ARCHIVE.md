# Standalone-era archive

Verbatim preservation of the GitHub-hosted prose that did not live in git when
the seven standalone auditor repos were consolidated into this monorepo and
deleted on 2026-07-14: release notes, pull-request descriptions and review
comments, and annotated tag messages. The release binary assets were
re-attached to this repo's v1.0.0 release. Every tagged commit is reachable in
this repo's history under the namespaced tags listed below.

Content below is preserved verbatim from the deleted repos, except that
emoji characters are replaced with their codepoint in brackets (for example
[U+1F916]) per this repo's no-emoji rule.

## Release notes

### codeauditor v1.0.0 (codeauditor 1.0.0), published 2026-05-30

First public release.

codeauditor is an installable skill for AI coding agents. Install it once, then run it from whichever AI tool you use. It audits a codebase end to end, writes a scored and prioritized `codeaudit.md`, and prints the verdict in your chat. The report is self-contained, so another AI agent can read it and decide what to fix on its own.

## Highlights

- Nine analysis lenses: Security, Architecture and Design, Code Quality and Maintainability, Testing and Verification, Error Handling and Resilience, Performance and Efficiency, Dependencies and Supply Chain, Documentation and Drift, Observability and Operability.
- Explicit scoring rubric with a weighted overall score. A single Critical finding caps the score so risk does not average away.
- Self-contained findings (severity, confidence, effort, location, evidence, impact, recommendation, verify-the-fix), clustered into root-cause patterns, plus a decision protocol for the acting agent.
- Chat summary after the file is written: score, scorecard, top fixes, finding counts by severity, and the report path.
- One source of truth (`engine/codeauditor.md`) rendered by `install.sh` into each tool's native format, with an `uninstall` mode.

## Supported tools

Claude Code, OpenAI Codex CLI, Gemini CLI, Cursor, opencode, Windsurf, Antigravity, and pi (pi.dev). Any other tool that reads `AGENTS.md` is covered by the portable directive.

## Install

From source:

```sh
git clone https://github.com/aihxp/codeauditor
cd codeauditor
./install.sh
```

Or download `codeauditor-1.0.0.zip` (or `.tar.gz`) from the assets below, unzip, and run `./install.sh`.

## Run it

Open your AI coding tool in the project you want audited, then:

- Codex, Gemini, Cursor, Windsurf, opencode, pi: type `/codeauditor`
- Claude Code, Antigravity: say "audit my codebase"

It writes `codeaudit.md` at the project root and prints the score, scorecard, and top fixes in the chat. Read-only: it never edits source.

### dbauditor v0.1.0 (dbauditor v0.1.0), published 2026-06-18

First release of **dbauditor**, a read-only database audit skill for AI coding agents. It is the data-layer counterpart to `codeauditor`, `uxauditor`, and `secauditor`.

It reads the schema files, migrations, ORM models, and queries in a repo (never connecting to a live database, running a migration, or mutating data), writes a scored, prioritized, self-contained `dbaudit.md`, and prints the verdict in chat.

## What it scores

Eleven weighted dimensions, three of them conditional with re-normalization:

- Referential integrity and relationships (linkage), 14
- Indexing strategy, 13
- Query performance and access patterns, 12
- Security and data protection at the DB layer, 12
- Schema design and data modeling, 11
- Constraints and data validation, 10
- Transactions, concurrency and consistency, 9 (if a write path exists)
- Data types and storage efficiency, 7
- Migrations and schema evolution, 6 (if migration tooling exists)
- Search and text retrieval, 4 (if a search surface exists)
- Scalability, growth and operations, 2 (re-weighted up on growth signals)

A separate non-relational and analytics lens re-points findings for MongoDB, DynamoDB, Cassandra, Redis, vector stores, Snowflake/BigQuery/dbt, and time-series.

## How it is different from a linter

- It reads the shipped DDL, not the ORM's promise: an ORM-only uniqueness or association is reported as unenforced.
- It actively hunts paper controls: a foreign key added `NOT VALID` and never validated, a `UNIQUE` on a nullable column, an index whose leftmost column no query filters, an inert `@Transactional`, RLS enabled but not `FORCE`d, an external search index kept in sync by best-effort dual-write.
- An ownership map scores each defect under exactly one dimension instead of triple-counting across lenses.
- A single Critical caps its dimension at 69 and the overall at 79; a security or data-loss critical caps the overall grade outright.
- Every recommendation includes the lock-safe migration path so the fix cannot cause the outage.

## Install

Claude Code (personal skill):

```sh
mkdir -p ~/.claude/skills/dbauditor
cp skills/dbauditor/SKILL.md ~/.claude/skills/dbauditor/SKILL.md
```

Then invoke `/dbauditor` (Claude Code) or `$dbauditor` (Codex). The attached `dbauditor-0.1.0.tar.gz` contains the full skill, README, LICENSE, and Claude Code plugin manifest.

Generated with [Claude Code](https://claude.com/claude-code)

### dbauditor v0.1.1 (dbauditor v0.1.1), published 2026-06-18

Patch release: explicit dual Claude Code and Codex compatibility.

The skill is a single `SKILL.md` that runs in both tools (discovery is by the `name` frontmatter, not the typed prefix). This release spells out both invocations in the description and the invocation line:

- Claude Code: `/dbauditor`
- Codex: `$dbauditor`

Install the same file into whichever tool you use:

```sh
# Claude Code
mkdir -p ~/.claude/skills/dbauditor && cp skills/dbauditor/SKILL.md ~/.claude/skills/dbauditor/SKILL.md
# Codex (also reads ~/.agents/skills and repo-local .agents/skills)
mkdir -p ~/.codex/skills/dbauditor && cp skills/dbauditor/SKILL.md ~/.codex/skills/dbauditor/SKILL.md
```

No change to the audit method, dimensions, or scoring since v0.1.0.

Generated with [Claude Code](https://claude.com/claude-code)

### llmauditor v0.1.0 (llmauditor v0.1.0), published 2026-06-18

First release of **llmauditor**: a read-only audit of how a codebase integrates Large Language Models. It writes a scored, prioritized, self-contained `llmaudit.md` at the repo root and prints the verdict in chat. It never calls a model, runs the app, or mutates data or an index.

Dual-compatible: the same `SKILL.md` runs in both tools.

- Claude Code: `/llmauditor`
- Codex: `$llmauditor`

## What it scores

Twelve dimensions (two conditional on the project's surface), weighted and re-normalized so the score is meaningful for a single-call summarizer and a tool-using agent alike:

Security and Trust Boundaries (17), Prompt Construction (12), Model Selection and Routing (10), Provider API and SDK Usage (10), Reliability (10), Output Handling (8), Cost and Quotas (6), Evaluation (5), Observability (5), Latency (4), plus the conditional Retrieval/RAG (7) and Agent/Tool (6) lenses.

Grounded in the OWASP Top 10 for LLM Applications 2025, the OWASP Top 10 for Agentic Applications, NIST AI 600-1, MITRE ATLAS, and provider documentation. A single Critical finding caps its dimension and the overall grade; an ownership map keeps each defect scored once; and the method actively hunts paper controls.

## Install

Install the single `SKILL.md` into whichever tool you use:

\`\`\`sh
# Claude Code
mkdir -p ~/.claude/skills/llmauditor && cp skills/llmauditor/SKILL.md ~/.claude/skills/llmauditor/SKILL.md
# Codex (also reads ~/.agents/skills and repo-local .agents/skills)
mkdir -p ~/.codex/skills/llmauditor && cp skills/llmauditor/SKILL.md ~/.codex/skills/llmauditor/SKILL.md
\`\`\`

Or install the whole repo as a Claude Code plugin (it ships a `.claude-plugin/plugin.json` manifest). The attached `llmauditor-0.1.0.tar.gz` contains the full repo.

Generated with [Claude Code](https://claude.com/claude-code)

### secauditor v0.1.0 (secauditor v0.1.0), published 2026-06-18

Initial release of **secauditor**, a read-only security audit skill for AI coding agents.

- Audits a codebase end to end and writes a scored, prioritized, self-contained `secaudit.md`, then reports the verdict in chat. Never edits source, never runs exploits.
- Dual-compatible: invoke `/secauditor` in Claude Code or `$secauditor` in Codex (one `SKILL.md`, the Agent Skills standard).
- Scores 11 dimensions grounded in OWASP Top 10:2025/2021, OWASP API Top 10 2023, OWASP LLM Top 10 2025, ASVS 5.0, OWASP CI/CD Top 10, CWE Top 25, SLSA v1.2, and CIS Benchmarks. Cloud/IaC and AI/LLM dimensions are conditional with weight re-normalization.

## Install
Claude Code:
```sh
mkdir -p ~/.claude/skills/secauditor && cp skills/secauditor/SKILL.md ~/.claude/skills/secauditor/SKILL.md
```
Codex:
```sh
mkdir -p ~/.codex/skills/secauditor && cp skills/secauditor/SKILL.md ~/.codex/skills/secauditor/SKILL.md
```

## Package
`secauditor-0.1.0.tar.gz` contains the full plugin (skill, `.claude-plugin/plugin.json` manifest, README, LICENSE).

[U+1F916] Generated with [Claude Code](https://claude.com/claude-code)

### seoauditor v0.1.0 (seoauditor v0.1.0), published 2026-06-19

First release of **seoauditor**, a read-only SEO and AI-visibility (GEO/AEO) audit skill for Claude Code (`/seoauditor`) and Codex (`$seoauditor`). It audits how a codebase makes its website discoverable to search engines and AI answer engines, writes a scored, prioritized, self-contained `seoaudit.md`, and prints the verdict in chat.

### Scores 12 dimensions (10 always-on + 2 conditional, weights sum to 100)

Crawlability and Indexation Control (14%), Rendering and Content-in-HTML (13%), On-Page Content / Headings / Semantic HTML (12%), Canonicalization and Duplicate Content (11%), Structured Data and Rich Results (10%), AI and Generative-Engine Visibility / GEO-AEO (9%), URL Architecture and Technical Configuration (8%), Performance and Core Web Vitals code signals (6%), Social and Sharing Metadata (5%), Analytics / Verification / SEO Observability (3%), plus conditional Internationalization and hreflang (5%) and Feeds / Syndication / Installability / Fast-Indexing (4%).

### What makes it different

- Verifies against **what actually reaches the crawler**, not the markup's intent.
- Hunts **paper controls** and separates inert theater (remove) from actively harmful controls (fix).
- **Ownership map** scores each cross-lens defect exactly once.
- **Visibility floor** caps the grade on sitewide deindexing, CSR-invisibility to no-JS AI crawlers, cloaking, canonical collapse, or self-defeating AI blocks.
- Dual mandate: classic search **and** AI answer engines, with the training-vs-citation crawler distinction and an honest, aspirational treatment of llms.txt / ai.txt.
- **Read-only**: never crawls the live site, runs Lighthouse, calls Search Console / the Rich Results Test, or calls a model.

### Install

Claude Code: copy `skills/seoauditor/SKILL.md` to `~/.claude/skills/seoauditor/SKILL.md`, or install the repo as a plugin (ships `.claude-plugin/plugin.json`). Codex: copy to `~/.codex/skills/seoauditor/SKILL.md`. See the README for details.

The attached `seoauditor-0.1.0.tar.gz` is the packaged plugin (README, LICENSE, CHANGELOG, plugin manifest, and the skill).

[U+1F916] Generated with [Claude Code](https://claude.com/claude-code)

### uiauditor v0.1.0 (uiauditor v0.1.0), published 2026-06-19

First release of **uiauditor**: a read-only audit of how a codebase implements its user interface. It writes a scored, prioritized, self-contained `uiaudit.md` at the repo root and prints the verdict in chat. It never runs the app, opens a browser, takes screenshots, runs a build or scanner, or mutates source.

Dual-compatible: the same `SKILL.md` runs in both tools.

- Claude Code: `/uiauditor`
- Codex: `$uiauditor`

## What it scores

Ten dimensions (two conditional on the project's surface). The eight always-on dimensions sum to exactly 100; the conditional lenses re-normalize all active weights back to 100 on activation and are dropped when N/A:

Accessibility and Inclusive Markup (22), Semantic HTML and Document Structure (14), Styling Architecture and CSS Correctness (13), Component Implementation and UI State (13), Responsive and Adaptive Layout (12), Frontend Performance and Loading (11), Design System Consistency and Theming (9), Assets, Media, Icons and Fonts (6), plus the conditional Internationalization (8) and Native/Cross-Platform UI (9) lenses.

Grounded in WCAG 2.2, the WAI-ARIA Authoring Practices Guide, Core Web Vitals (LCP/CLS/INP), MDN, and ECMA-402. A single Critical caps its dimension and the overall grade, two or more cap the overall at 69, and an accessibility floor caps the overall at 69 for any A11Y-owned Critical; an ownership map keeps each defect scored once (artifact/root owns it, the consequence dimension cross-references); and the method actively hunts paper controls.

## Install

Install the single `SKILL.md` into whichever tool you use:

\`\`\`sh
# Claude Code
mkdir -p ~/.claude/skills/uiauditor && cp skills/uiauditor/SKILL.md ~/.claude/skills/uiauditor/SKILL.md
# Codex (also reads ~/.agents/skills and repo-local .agents/skills)
mkdir -p ~/.codex/skills/uiauditor && cp skills/uiauditor/SKILL.md ~/.codex/skills/uiauditor/SKILL.md
\`\`\`

Or install the whole repo as a Claude Code plugin (it ships a `.claude-plugin/plugin.json` manifest). The attached `uiauditor-0.1.0.tar.gz` contains the full repo.

Generated with [Claude Code](https://claude.com/claude-code)

### uxauditor v1.0.0 (uxauditor v1.0.0), published 2026-06-17

## uxauditor v1.0.0

First release. **uxauditor is an installable, read-only UX audit skill for AI coding agents.** Install it once, run it from whichever AI coding tool you use, and it audits a product end to end, writes a single scored `uxaudit.md`, and prints the verdict right in your chat.

The report is written for a reader with no memory of the audit (often another AI agent): every finding cites an exact location and carries the context needed to act on it cold.

### What it audits

Eleven lenses grounded in established standards:

- **Usability and Heuristics** (Nielsen's 10)
- **Accessibility and Inclusive Design** (WCAG 2.2 AA, POUR)
- **User Journeys and Flows** (journey mapping, friction, jobs-to-be-done)
- **Process and Workflow Efficiency** (Lean waste, Theory of Constraints, multi-actor handoffs)
- **Interaction and Visual Design** (Gestalt, affordances, component states)
- **Information Architecture and Navigation** (scent, findability, labels)
- **Content and UX Writing** (plain language, microcopy, error messages)
- **Onboarding, Conversion and Engagement** (activation, funnels, empty states)
- **Forms and Input** (labels, validation, autofill, field economy)
- **Performance and Responsiveness** (Core Web Vitals, perceived speed)
- **Trust, Ethics and Transparency** (dark patterns, credibility, consent)

It scores each lens against an explicit rubric, clusters repeated issues into root-cause patterns, ends with a weighted overall score, and prints a chat summary so you see the verdict without opening the file.

### Install

Download `uxauditor-1.0.0.zip` or `uxauditor-1.0.0.tar.gz` below, unpack it, and run the installer:

```sh
unzip uxauditor-1.0.0.zip
cd uxauditor-1.0.0
./install.sh
```

The installer detects the AI coding tools you have (Claude Code, Codex CLI, Gemini CLI, Cursor, opencode, Windsurf, Antigravity, pi) and renders the skill into each. You can also clone the repository and run `./install.sh` from there.

### Run it

- **Claude Code, Antigravity, pi:** say "audit my UX" (the skill auto-triggers) or `/uxauditor`
- **Codex, Gemini, Cursor, Windsurf, opencode:** `/uxauditor`

It is read-only and never modifies your source. The only file it writes is `uxaudit.md`.

See the [README](https://github.com/aihxp/uxauditor#readme) for the full lens list, the weighted scoring model, and the cross-tool support table.

## Pull requests

### dbauditor PR #1: feat: add dbauditor database audit skill

Adds `dbauditor`, a read-only database-layer audit skill, the data-layer counterpart to `codeauditor`, `uxauditor`, and `secauditor`.

## What it does

Reads the schema files, migrations, ORM models, and queries in a repo (it never connects to a live database, runs a migration, or mutates data), then writes a scored, prioritized, self-contained `dbaudit.md` and prints the verdict in chat.

## Dimensions (weighted, with conditional re-normalization)

Referential integrity / linkage (14), indexing (13), query performance (12), DB-layer security and data protection (12), schema design (11), constraints (10), transactions and concurrency (9), data types (7), migrations (6), search (4), scalability and operations (2). Three dimensions are conditional (transactions, migrations, search) and a separate non-relational and analytics lens re-points findings for MongoDB, DynamoDB, Cassandra, Redis, vector, warehouse, and time-series stores.

## Design notes

- Reads the shipped DDL, not the ORM's promise: an ORM-only uniqueness or association is reported as unenforced.
- Actively hunts paper controls (FK `NOT VALID` never validated, `UNIQUE` on a nullable column, an unusable index, an inert `@Transactional`, RLS not `FORCE`d, dual-write search drift).
- An ownership map scores each defect under exactly one dimension instead of triple-counting across lenses.
- A single Critical caps its dimension at 69 and the overall at 79; a security or data-loss critical caps the overall grade outright.
- Every recommendation includes the lock-safe migration path so the fix cannot cause the outage.

Ships a Claude Code plugin manifest and is dual-compatible with Codex.

Generated with [Claude Code](https://claude.com/claude-code)

**Review by chatgpt-codex-connector (COMMENTED):**

### [U+1F4A1] Codex Review

https://github.com/aihxp/dbauditor/blob/d53339fc263a584547f03094eacde854fecf04d8/README.md#L54
**<sub><sub>![P2 Badge](https://img.shields.io/badge/P2-yellow?style=flat)</sub></sub>  Correct the plugin invocation command**

For users who follow the plugin install path described here, `/dbauditor` will not invoke this packaged skill. The Claude Code plugin docs state that skills under `skills/<name>/SKILL.md` are prefixed with the plugin namespace (for example, `/my-first-plugin:hello`), and this repo packages the skill as `skills/dbauditor/SKILL.md` inside a plugin named `dbauditor`, so the plugin command is `/dbauditor:dbauditor`; `/dbauditor` only works for the standalone `~/.claude/skills/dbauditor/SKILL.md` install.
    

<details> <summary>ℹ[U+FE0F] About Codex in GitHub</summary>
<br/>

[Your team has set up Codex to review pull requests in this repo](https://chatgpt.com/codex/cloud/settings/general). Reviews are triggered when you
- Open a pull request for review
- Mark a draft as ready
- Comment "@codex review".

If Codex has suggestions, it will comment; otherwise it will react with [U+1F44D].




Codex can also answer questions or update the PR. Try commenting "@codex address that feedback".
            
</details>

### llmauditor PR #1: Add llmauditor LLM-integration audit skill

Adds the **llmauditor** skill: a read-only audit of how a codebase integrates Large Language Models. It writes a scored, prioritized, self-contained `llmaudit.md` at the repo root and prints the verdict in chat. It never calls a model, runs the app, or mutates data or an index.

It is the AI-layer counterpart to `codeauditor`, `secauditor`, `dbauditor`, and `uxauditor`, and is dual-compatible: the same `SKILL.md` runs in Claude Code (`/llmauditor`) and Codex (`$llmauditor`).

## Dimensions (12, two conditional)

- Security, Trust Boundaries, Safety and Data Governance (17%)
- Prompt Construction and Context Management (12%)
- Model Selection, Configuration and Routing (10%)
- Provider API and SDK Usage (10%)
- Reliability, Retries and Fallback (10%)
- Output Handling and Structured-Output Consumption (8%)
- Cost, Quotas and Token Efficiency (6%)
- Evaluation, Testing and Quality (5%)
- Observability and Monitoring (5%)
- Latency and Throughput (4%)
- Retrieval, RAG, Indexing and Vector Search (7%, conditional)
- Agent and Tool Integration (6%, conditional)

## How it works

Seven-phase method (orient, map the LLM data flow and trust boundaries, analyze per lens with `file:line` evidence, verify adversarially and cluster, score with conditional re-normalization and risk caps, prioritize, write and summarize). Grounded in the OWASP Top 10 for LLM Applications 2025, the OWASP Top 10 for Agentic Applications, NIST AI 600-1, MITRE ATLAS, and provider documentation. An ownership map prevents the same defect from being scored under multiple lenses, and the method actively hunts paper controls (a guardrail never called, a cache marker after a volatile prefix, a retry that misses the rate-limit error, an ACL stored but never filtered, an eval never run in CI).

## Contents

- `skills/llmauditor/SKILL.md` - the skill
- `.claude-plugin/plugin.json` - plugin manifest
- `README.md`, `CHANGELOG.md`, `LICENSE`

Generated with [Claude Code](https://claude.com/claude-code)

### secauditor PR #1: Add secauditor security audit skill

## Summary
Adds **secauditor**, a read-only security audit skill for AI coding agents. It audits the codebase end to end, writes a scored, prioritized, self-contained `secaudit.md`, and reports the verdict in chat. It never edits source and never runs exploits.

Dual-compatible by design (one `SKILL.md`, the Agent Skills standard):
- Claude Code: invoke with `/secauditor`
- Codex: invoke with `$secauditor`

## What it scores
Eleven dimensions grounded in current frameworks (OWASP Top 10:2025 and 2021, OWASP API Security Top 10 2023, OWASP Top 10 for LLM Applications 2025, OWASP ASVS 5.0, OWASP Top 10 CI/CD Security Risks, CWE Top 25, SLSA v1.2, CIS Benchmarks, NIST SP 800-series). Two dimensions (Cloud/IaC, AI/LLM) are conditional, with weight re-normalization when their surface is absent:

| Dimension | Weight |
|---|---|
| Authorization & Access Control | 18% |
| Injection & Unsafe Input Handling | 16% |
| Authentication & Session Management | 15% |
| Cryptography & Data Protection | 11% |
| Security Misconfiguration & Hardening | 9% |
| Dependencies & Software Supply Chain | 9% |
| Secrets Management | 8% |
| API & Web Service Security | 6% |
| Logging, Monitoring & Data Privacy | 4% |
| Cloud, Container & IaC Security (conditional) | 2% |
| AI / LLM Application Security (conditional) | 2% |

## Method
Orient and detect surfaces, map attack surface and trust boundaries (lightweight STRIDE), analyze across every security lens with source-to-sink evidence, verify adversarially and cluster into systemic patterns, score (a single Critical caps the dimension at 69 and the overall at 79), prioritize, write `secaudit.md`, report in chat. It actively hunts "paper" controls a passing scanner can mask.

## Files
- `skills/secauditor/SKILL.md` - the skill
- `.claude-plugin/plugin.json` - Claude Code plugin manifest
- `README.md`, `LICENSE` (MIT), `.gitignore`

[U+1F916] Generated with [Claude Code](https://claude.com/claude-code)

### seoauditor PR #1: feat: add seoauditor SEO and AI-visibility audit skill

## seoauditor

A read-only **SEO and AI-visibility (GEO/AEO) audit** skill, the visibility-layer counterpart to `codeauditor`, `secauditor`, `dbauditor`, `uxauditor`, and `llmauditor`. Dual-compatible: the same `SKILL.md` runs in Claude Code (`/seoauditor`) and Codex (`$seoauditor`).

It audits how a codebase makes its website discoverable to search engines **and** AI answer engines (Google AI Overviews, ChatGPT Search, Perplexity, Bing Copilot, Claude), writes a scored, prioritized, self-contained `seoaudit.md`, and prints the verdict in chat.

### What it scores (12 dimensions, 10 always-on + 2 conditional, weights sum to 100)

| Dimension | Weight |
|---|---|
| Crawlability and Indexation Control | 14% |
| Rendering and Content-in-HTML | 13% |
| On-Page Content, Headings and Semantic HTML | 12% |
| Canonicalization and Duplicate Content | 11% |
| Structured Data and Rich Results | 10% |
| AI and Generative-Engine Visibility (GEO/AEO) | 9% |
| URL Architecture and Technical Configuration | 8% |
| Performance and Core Web Vitals (code signals) | 6% |
| Social and Sharing Metadata | 5% |
| Analytics, Verification and SEO Observability | 3% |
| Internationalization and hreflang (conditional) | 5% |
| Feeds, Syndication, Installability and Fast-Indexing (conditional) | 4% |

### Design

- **Verifies against what reaches the crawler**, not the markup's intent (a client-injected tag, a non-200 canonical, a robots-blocked noindex are reported as such).
- **Hunts paper controls** and separates inert theater (remove) from actively harmful controls (fix).
- **Ownership map** so each cross-lens defect is scored once.
- **Visibility floor** that caps the grade on sitewide deindexing, CSR-invisibility to no-JS AI crawlers, cloaking, canonical collapse, or self-defeating AI blocks.
- **Read-only**: never crawls the live site, runs Lighthouse, calls Search Console / the Rich Results Test, or calls a model; runtime-dependent findings are marked Suspected with a named verification step.

Grounded in Google Search Central, RFC 9309 / RFC 6596, schema.org, web.dev Core Web Vitals, the Open Graph protocol, the AI-crawler docs (training-vs-citation bot distinction), the llms.txt proposal (treated as aspirational), IndexNow, and the framework SEO docs.

Ships README, CHANGELOG, LICENSE, and a `.claude-plugin/plugin.json` manifest.

[U+1F916] Generated with [Claude Code](https://claude.com/claude-code)

### uiauditor PR #1: Add uiauditor UI-implementation audit skill

Adds the **uiauditor** skill: a read-only audit of how a codebase implements its user interface. It writes a scored, prioritized, self-contained `uiaudit.md` at the repo root and prints the verdict in chat. It never runs the app, opens a browser, takes screenshots, runs a build or scanner, or mutates source.

It is the interface-implementation counterpart to `codeauditor`, `secauditor`, `dbauditor`, `llmauditor`, and `uxauditor`, and is dual-compatible: the same `SKILL.md` runs in Claude Code (`/uiauditor`) and Codex (`$uiauditor`).

## Dimensions (10, two conditional)

- Accessibility and Inclusive Markup (22%)
- Semantic HTML and Document Structure (14%)
- Styling Architecture and CSS Correctness (13%)
- Component Implementation and UI State (13%)
- Responsive and Adaptive Layout (12%)
- Frontend Performance and Loading / Core Web Vitals risk (11%)
- Design System Consistency and Theming (9%)
- Assets, Media, Icons and Fonts (6%)
- Internationalization and Localization Readiness (8% nominal, conditional)
- Native and Cross-Platform UI Implementation (9% nominal, conditional)

The eight always-on dimensions sum to exactly 100; the conditional lenses re-normalize all active weights back to 100 on activation and are dropped when N/A. Accessibility is the highest-weighted dimension under every combination.

## How it works

Seven-phase method (orient, map the UI surface and high-risk render paths, analyze per lens with `file:line` evidence, verify adversarially and cluster, score with conditional re-normalization and risk caps, prioritize, write and summarize). Grounded in WCAG 2.2, the WAI-ARIA Authoring Practices Guide, Core Web Vitals (LCP/CLS/INP), MDN, and ECMA-402. A single Critical caps its dimension at 69 and the overall at 79, two or more cap the overall at 69, and an accessibility floor caps the overall at 69 for any A11Y-owned Critical. An ownership map prevents the same defect from being scored under multiple lenses (the artifact/root dimension owns it, the consequence dimension cross-references) and draws the boundary with uxauditor (experience), codeauditor (code quality), and secauditor (security sinks). The method actively hunts paper controls (an aria-label that mismatches visible text, a focus-visible style defeated in the cascade, a token declared but bypassed, a live region nothing writes to, a loading="lazy" on the LCP image, a dialog opened with show()).

## Contents

- `skills/uiauditor/SKILL.md` - the skill
- `.claude-plugin/plugin.json` - plugin manifest
- `README.md`, `CHANGELOG.md`, `LICENSE`

Generated with [Claude Code](https://claude.com/claude-code)

## Annotated tag messages

Namespaced equivalents of every standalone tag now exist in this repo as `<skill>-v<version>`.

### codeauditor

```text
=== v1.0.0 -> 53db00b7b334b6e6cdbbe5f230611aa790f1c403
codeauditor 1.0.0
```

### dbauditor

```text
=== v0.1.0 -> 3f736db722fc22fda67bf1237fb74a878ff130e2
dbauditor v0.1.0

First release of the read-only database audit skill.

=== v0.1.1 -> 6332f9c83dab46529ad181bd096859b3c31ed132
dbauditor v0.1.1

Document dual Claude Code (/dbauditor) and Codex ($dbauditor) invocation.
```

### llmauditor

```text
=== v0.1.0 -> f51b0661e63df17a39f76e650a5907743b8aa734
llmauditor v0.1.0 - first release
```

### seoauditor

```text
=== v0.1.0 -> 0f4cfa7cf6c6a4dff7526587e9864f13a744adf7
seoauditor v0.1.0

First release: read-only SEO and AI-visibility (GEO/AEO) audit skill for
Claude Code and Codex. 12 scored dimensions, ownership map, visibility-floor
grade caps, and self-contained findings written to seoaudit.md.
```

### uiauditor

```text
=== v0.1.0 -> 67e3e9c12658232ddb8ccf19eff12f3963dfacab
uiauditor v0.1.0
```

### uxauditor

```text
=== v1.0.0 -> e788564e303764e96bb93c08b24e83b51dcefafc
uxauditor v1.0.0
```
