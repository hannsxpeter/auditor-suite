# The Auditor Suite

Seven read-only audit skills for AI coding agents. Each auditor scores one dimension of a codebase end to end, writes a prioritized `<name>audit.md` report at the repo root, and prints the verdict in chat. Install what you need. No auditor duplicates another's work.

Release train: 1.0.0

## What each auditor owns

| Skill | Owns | Report | Primary trigger words |
|---|---|---|---|
| **codeauditor** | The whole-codebase baseline: nine lenses from security survey to observability | `codeaudit.md` | "audit the codebase," "code audit," "how healthy is this repo" |
| **secauditor** | Security depth: vulnerabilities grounded in OWASP and CWE across 11 dimensions | `secaudit.md` | "security audit," "find vulnerabilities," "OWASP review" |
| **dbauditor** | The data layer: schema, relationships, indexing, queries, transactions, migrations, data protection, search, scale | `dbaudit.md` | "database audit," "schema review," "query performance audit" |
| **llmauditor** | LLM integration: prompts, models, provider APIs, reliability, structured output, cost, evaluation, RAG, agents | `llmaudit.md` | "LLM audit," "audit our AI integration," "prompt review" |
| **seoauditor** | Discoverability: search engines and AI answer engines (SEO, GEO, AEO) across 12 dimensions | `seoaudit.md` | "SEO audit," "AI visibility," "why aren't we indexed" |
| **uiauditor** | UI implementation: accessibility, semantics, styling, components, responsiveness, frontend performance, design system, assets, i18n, native UI | `uiaudit.md` | "UI audit," "accessibility audit," "frontend implementation review" |
| **uxauditor** | Product behavior: user journeys, processes, and workflows end to end | `uxaudit.md` | "UX audit," "user journey review," "workflow audit" |

## The read-only contract

Every auditor obeys the same discipline:

1. Never edits source. The only file an audit writes is its own report.
2. Never runs the live system: no app runs, no browsers, no live database connections, no model calls, no exploits, no crawls of the deployed site.
3. Writes exactly one self-contained, scored, prioritized report at the repo root.
4. Prints the verdict and the highest-leverage fixes in chat after writing the report.

## Boundaries between auditors

- **codeauditor vs secauditor:** codeauditor's security lens is a survey inside a whole-codebase baseline; secauditor is the deep, OWASP/CWE-grounded specialist. Run codeauditor first for the map, secauditor for security depth.
- **uiauditor vs uxauditor:** uiauditor judges how the interface is built (markup, styling, components, performance); uxauditor judges how the product behaves for a user moving through journeys and workflows.
- **seoauditor vs uiauditor:** seoauditor owns how the outside world (crawlers, answer engines) discovers and reads the site; uiauditor owns what humans interact with once there. Core Web Vitals code signals appear in both, scoped to their concern.
- **dbauditor and llmauditor** have no overlap with the others beyond codeauditor's survey lenses; they activate on their layer's presence in the codebase.

## Install locations

The hub installer (`bash install.sh` from a clone of `hannsxpeter/auditor-suite`) symlinks `SKILL.md` from `skills/<skill-name>/` into each detected harness, so updates from `git pull` propagate instantly.

| Platform | Install path |
|---|---|
| Claude Code | `~/.claude/skills/<skill-name>/` |
| Codex | `~/.codex/skills/<skill-name>/` |
| Cursor | `~/.cursor/skills/<skill-name>/` |
| pi | `~/.agents/skills/<skill-name>/` (neutral Agent Skills path) |
| OpenClaw | `~/.agents/skills/<skill-name>/` (neutral Agent Skills path) |
| Any Agent Skills harness | `~/.agents/skills/<skill-name>/` |
| Windsurf | Project rules or system prompt |
| Other agents | Upload `SKILL.md` to the project context |

Claude Code users can also install via the plugin marketplace: `/plugin marketplace add hannsxpeter/auditor-suite`, then `/plugin install auditor-suite@auditor-suite`.

## Composition principles

1. **Tight scope beats combined scope.** Each auditor owns one dimension and refuses its siblings' work.
2. **The harness is the router.** Auditors never call each other; the user's words pick the auditor.
3. **Reports are the contract.** Each audit writes one file at a well-known path; agents and humans consume it as a prioritized work order.
4. **Read-only is non-negotiable.** An auditor that edits source or runs the live system is defective by definition.
5. **Version tracking is suite-wide.** The root `VERSION` file names the release train; all seven skills and the plugin packaging publish that train together.
6. **Graceful degradation.** Every auditor works standalone with no other suite member installed.

## Standards

Auditor-suite skills implement the [Agent Skills standard](https://agentskills.io): a `SKILL.md` with YAML frontmatter (`name`, `description`) that any compatible harness loads natively. Verified harnesses: Claude Code (`/name`), Codex (`$name`), Cursor, plus pi and OpenClaw via the neutral `~/.agents/skills/` path.
