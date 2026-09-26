# The Auditor Suite

Seven read-only audit skills for AI coding agents. Each auditor scores one dimension of a codebase end to end, writes a prioritized `<name>audit.md` report at the repo root, and prints the verdict in chat. Install what you need. No auditor duplicates another's work.

Release train: 1.1.0

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
2. Never runs the live system: no app runs, no tests or builds, no browsers, no live database connections, no model calls, no exploits, no crawls of the deployed site. uxauditor included: runtime behavior is inferred from code and marked Likely or Suspected.
3. May run its own bundled scripts (`scripts/inventory.sh`, `scan.sh`, `new-report.sh`, `score.sh`, `check-report.sh`). They read files and print; `new-report.sh` and `score.sh --write` write only the report.
4. Cites evidence it opened: every finding names a `path:line` and quotes the code there, and `check-report.sh` verifies both.
5. Writes exactly one self-contained, scored, prioritized report at the repo root, then prints the verdict and the highest-leverage fixes in chat.

## One report format for all seven

Every report has the same twelve sections in the same order (title and banner, Snapshot, Map, Overall score, What to fix first, Strengths, Systemic patterns, Findings, Dimension notes, Remediation plan, Scope and limitations, How to use this report) and every finding has the same eight fields (Severity line, Location, Evidence, Impact, Recommendation, Verify the fix, References, Related). A downstream agent can read any auditor's report the same way.

Scores are computed by `score.sh` from the findings with one rule set (see [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md#5-scoring)): deductions per finding, Suspected findings at half weight, caps for Critical findings, and a tighter cap for floor dimensions (accessibility in uiauditor; database security and types in dbauditor; LLM security and agents in llmauditor; the visibility floor in seoauditor).

## Modes

Every auditor accepts the same modes after its name: `full` (default), `quick` (Critical-class checks only, no numeric score), `only=DIM,DIM` (a subset, partial score), and a path to limit scope.

## Boundaries between auditors

- **codeauditor vs secauditor:** codeauditor's security lens is a survey inside a whole-codebase baseline; secauditor is the deep, OWASP/CWE-grounded specialist. Run codeauditor first for the map, secauditor for security depth.
- **uiauditor vs uxauditor:** uiauditor judges how the interface is built (markup, styling, components, performance) and owns the static accessibility line; uxauditor judges how the product behaves for a user moving through journeys and workflows, and owns whether a keyboard or screen-reader user can finish the journey.
- **seoauditor vs uiauditor:** seoauditor owns how the outside world (crawlers, answer engines) discovers and reads the site; uiauditor owns what humans interact with once there. Core Web Vitals code signals appear in both, scoped to their concern.
- **dbauditor and llmauditor** have no overlap with the others beyond codeauditor's survey lenses and secauditor's injection and LLM security surveys; each covers its layer in depth and says so.

Inside each auditor, every defect belongs to exactly one dimension: the rule cards are the ownership map.

## Install locations

The hub installer (`bash install.sh` from a clone of `hannsxpeter/auditor-suite`) symlinks each skill's runtime payload (`SKILL.md`, `references/`, `scripts/`, `assets/`) from `skills/<skill-name>/` into each detected harness, so updates from `git pull` propagate instantly.

| Platform | Install path |
|---|---|
| Claude Code | `~/.claude/skills/<skill-name>/` |
| Codex | `~/.codex/skills/<skill-name>/` |
| Cursor | `~/.cursor/skills/<skill-name>/` |
| pi | `~/.agents/skills/<skill-name>/` (neutral Agent Skills path) |
| OpenClaw | `~/.agents/skills/<skill-name>/` (neutral Agent Skills path) |
| Any Agent Skills harness | `~/.agents/skills/<skill-name>/` |
| Windsurf | Project rules or system prompt, plus access to the skill folder |
| Other agents | Upload the whole skill folder to the project context |

Claude Code users can also install via the plugin marketplace: `/plugin marketplace add hannsxpeter/auditor-suite`, then `/plugin install auditor-suite@auditor-suite`.

## Composition principles

1. **Tight scope beats combined scope.** Each auditor owns one dimension and refuses its siblings' work.
2. **The harness is the router.** Auditors never call each other; the user's words pick the auditor.
3. **Reports are the contract.** Each audit writes one file at a well-known path in one shared format; agents and humans consume it as a prioritized work order.
4. **Read-only is non-negotiable.** An auditor that edits source or runs the live system is defective by definition.
5. **Judgment by the model, bookkeeping by scripts.** The model reads code and decides; shared scripts inventory, scan, score, and validate, so results do not depend on arithmetic or memory.
6. **One shared core.** The protocol, report template, and scripts live once in `shared/` and are copied into every skill; lint proves the copies match.
7. **Version tracking is suite-wide.** The root `VERSION` file names the release train; all seven skills and the plugin packaging publish that train together.
8. **Graceful degradation.** Every auditor works standalone with no other suite member installed, and without Claude Code-specific features.

## Standards

Auditor-suite skills implement the [Agent Skills standard](https://agentskills.io): a `SKILL.md` with YAML frontmatter (`name`, `description`, and `allowed-tools`) plus `references/`, `scripts/`, and `assets/` folders loaded on demand. Verified harnesses: Claude Code (`/name`), Codex (`$name`), Cursor, plus pi and OpenClaw via the neutral `~/.agents/skills/` path.
