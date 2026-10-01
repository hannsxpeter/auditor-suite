# The Auditor Suite

Eight read-only audit skills for AI coding agents. Each auditor scores one domain of a codebase end to end, writes a prioritized `<name>audit.md` report at the repo root, and prints the verdict in chat. Install what you need. Each defect has one owning auditor; where two auditors touch one topic, the boundaries below say which one files it.

Release train: 1.2.0

## What each auditor owns

| Skill | Owns | Report | Primary trigger words |
|---|---|---|---|
| **codeauditor** | The whole-codebase baseline: nine lenses from security survey to observability | `codeaudit.md` | "audit the codebase," "code audit," "how healthy is this repo" |
| **secauditor** | Security depth: vulnerabilities grounded in OWASP and CWE across 11 dimensions | `secaudit.md` | "security audit," "find vulnerabilities," "OWASP review" |
| **dbauditor** | The data layer: schema, relationships, constraints, data types, indexing, queries, transactions, migrations, data protection, search, scale | `dbaudit.md` | "database audit," "schema review," "query performance audit" |
| **llmauditor** | LLM integration: security and trust boundaries, prompts, models, provider APIs, reliability, structured output, cost, latency, evaluation, observability, RAG, agents | `llmaudit.md` | "LLM audit," "audit our AI integration," "prompt review" |
| **seoauditor** | Discoverability: search engines and AI answer engines (SEO, GEO, AEO) across 12 dimensions | `seoaudit.md` | "SEO audit," "AI visibility," "why aren't we indexed" |
| **uiauditor** | UI implementation: accessibility, semantics, styling, components, responsiveness, frontend performance, design system, assets, i18n, native UI | `uiaudit.md` | "UI audit," "accessibility audit," "frontend implementation review" |
| **uxauditor** | Product behavior: user journeys, processes, and workflows end to end | `uxaudit.md` | "UX audit," "user journey review," "workflow audit" |
| **productauditor** | Product delivery and monetization: claims, plans and entitlements, billing lifecycle, customer accounts, product metrics and KPIs, release and sunset, experiments, feedback | `productaudit.md` | "product audit," "PM review," "does the code enforce our pricing" |

## The read-only contract

Every auditor obeys the same discipline:

1. Never edits source. The only file an audit writes is its own report.
2. Never runs the live system: no app runs, no tests or builds, no browsers, no live database connections, no model calls, no exploits, no crawls of the deployed site, no queries to analytics, billing, feature-flag, or CRM services. uxauditor and productauditor included: runtime behavior and provider state are inferred from code and marked Likely or Suspected.
3. May run its own bundled scripts (`scripts/inventory.sh`, `scan.sh`, `new-report.sh`, `score.sh`, `check-report.sh`). They read files and print; `new-report.sh` and `score.sh --write` write only the report, never through a symlink, and keep no temp files outside the project.
4. Cites evidence it opened: every finding names a `path:line` and quotes the code there. `check-report.sh` verifies that every cited line exists and that at least one quoted span of 6 or more characters appears within 6 lines of the first cited location.
5. Writes exactly one self-contained, scored, prioritized report at the repo root, then prints the verdict and the highest-leverage fixes in chat.

## One report format for all eight

Every report has the same twelve sections in the same order (title and banner, Snapshot, Map, Overall score, What to fix first, Strengths, Systemic patterns, Findings, Dimension notes, Remediation plan, Scope and limitations, How to use this report) and every finding has the same eight fields (Severity line, Location, Evidence, Impact, Recommendation, Verify the fix, References, Related). A downstream agent can read any auditor's report the same way.

Scores are computed by `score.sh` from the findings with one rule set (see [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md#5-scoring)): deductions per finding, Suspected findings at half weight, caps for Critical findings, and a tighter cap for floor dimensions, flagged in each skill's `assets/dimensions.tsv` (accessibility in uiauditor; database security and types in dbauditor; LLM security and agents in llmauditor; crawl, render, canonical, AI visibility, URL, SEO observability, and hreflang in seoauditor; plans and billing in productauditor; codeauditor, secauditor, and uxauditor have none).

## Modes

Every auditor accepts the same modes after its name: `full` (default), `quick` (Critical-class checks only, no numeric score), `only=DIM,DIM` (a subset, partial score), and a path to limit scope.

## Boundaries between auditors

- **codeauditor vs secauditor:** codeauditor's security lens is a survey inside a whole-codebase baseline; secauditor is the deep, OWASP/CWE-grounded specialist. Run codeauditor first for the map, secauditor for security depth.
- **uiauditor vs uxauditor:** uiauditor judges how the interface is built (markup, styling, components, performance) and owns the static accessibility line; uxauditor judges how the product behaves for a user moving through journeys and workflows, and owns whether a keyboard or screen-reader user can finish the journey.
- **seoauditor vs uiauditor:** seoauditor owns how the outside world (crawlers, answer engines) discovers and reads the site; uiauditor owns what humans interact with once there. Core Web Vitals code signals appear in both, scoped to their concern.
- **dbauditor and llmauditor** have no overlap with the others beyond codeauditor's survey lenses, secauditor's injection and LLM security surveys, and the productauditor hand-offs below; each covers its layer in depth and says so.
- **uxauditor vs productauditor:** uxauditor judges how the journey feels and whether it deceives, and keeps whether the activation and funnel events exist; productauditor judges whether the product delivers, charges, entitles, and measures what it promises, including whether those events fire once at the true outcome.
- **codeauditor vs productauditor:** codeauditor owns developer docs, dead code, duplicated logic, non-plan guards, per-environment config, and operator telemetry; productauditor owns customer-facing claims, plan gates and the plan catalog, flag behavior, analytics keys, and product telemetry.
- **dbauditor vs productauditor:** dbauditor owns idempotency, transactions, cascades, and references across services; productauditor owns what billing and membership changes do to customers: a provider never called, a second subscription, usage billed for failed work, and shared work lost when a member leaves.
- **secauditor vs productauditor:** secauditor owns roles, ownership, tenants, client-set fields (a plan or price included), webhook signatures, credentials, personal data in events and promises to erase it, old or debug routes as attack surface, and abuse at machine speed; productauditor owns plan gates and quotas, paid access that waits for a confirmed payment, an unreleased feature's route that skips the release flag the UI checks, deprecation and versioning of the product's own public API, and customer-facing encryption guarantees the code contradicts.
- **llmauditor vs productauditor:** llmauditor owns model spend limits with no plan term, failures turned into default answers, and model telemetry; productauditor owns model-call quotas a plan sells and invented output shown as real when no call failed.
- **seoauditor vs productauditor:** seoauditor owns how analytics tags load, consent wiring, and A/B tests as crawlers see them; productauditor owns product event correctness, identity, and test traffic, and experiment assignment, exposure, split validity, and lifecycle.

Inside each auditor, every defect belongs to exactly one dimension: the rule cards are the ownership map, and each dimension file's "Not here" line names the dimension or sibling card that owns a neighboring topic. Dimension IDs are unique only within one auditor: SCHEMA is in dbauditor and seoauditor, PERF in codeauditor, seoauditor, and uiauditor, I18N in seoauditor and uiauditor, and LLMSEC in secauditor (a survey) and llmauditor (the depth).

## Install locations

The hub installer (`bash install.sh` from a clone of `hannsxpeter/auditor-suite`) symlinks each skill's runtime payload (`SKILL.md`, `references/`, `scripts/`, `assets/`) from `skills/<skill-name>/` into each detected harness, so updates from `git pull` propagate instantly; a newly added auditor needs one more `install.sh` run. It installs every `skills/<skill-name>/` that holds a `SKILL.md`, honors `CLAUDE_CONFIG_DIR` and `CODEX_HOME`, and first moves a real copy of a skill (files, not links) to `~/.auditor-suite-backups/<platform>/<skill-name>-<timestamp>/`.

| Platform | Install path |
|---|---|
| Claude Code | `~/.claude/skills/<skill-name>/` (or `$CLAUDE_CONFIG_DIR/skills/`) |
| Codex | `~/.codex/skills/<skill-name>/` (or `$CODEX_HOME/skills/`) |
| Cursor | `~/.cursor/skills/<skill-name>/` |
| pi | `~/.agents/skills/<skill-name>/` (neutral Agent Skills path) |
| OpenClaw | `~/.agents/skills/<skill-name>/` (neutral Agent Skills path) |
| Any Agent Skills harness | `~/.agents/skills/<skill-name>/` (written when `~/.agents`, `~/.pi`, or `~/.openclaw` exists) |
| Windsurf | Project rules or system prompt, plus access to the skill folder |
| Other agents | Upload the whole skill folder to the project context |

Claude Code users can also install via the plugin marketplace: `/plugin marketplace add hannsxpeter/auditor-suite`, then `/plugin install auditor-suite@auditor-suite`.

## Composition principles

1. **Tight scope beats combined scope.** Each auditor owns one domain and refuses its siblings' work.
2. **The harness is the router.** Auditors never call each other; the user's words pick the auditor.
3. **Reports are the contract.** Each audit writes one file at a well-known path in one shared format; agents and humans consume it as a prioritized work order.
4. **Read-only is non-negotiable.** An auditor that edits source or runs the live system is defective by definition.
5. **Judgment by the model, bookkeeping by scripts.** The model reads code and decides; shared scripts inventory, scan, score, and validate, so results do not depend on arithmetic or memory.
6. **One shared core.** The protocol, report template, and scripts live once in `shared/` and are copied into every skill; lint proves the copies match.
7. **Version tracking is suite-wide.** The root `VERSION` file names the release train; all eight skills and the plugin packaging publish that train together.
8. **Graceful degradation.** Every auditor works standalone with no other suite member installed, and without Claude Code-specific features.

## Standards

Auditor-suite skills implement the [Agent Skills standard](https://agentskills.io): a `SKILL.md` with YAML frontmatter (`name`, `description`, and `allowed-tools`) plus `references/`, `scripts/`, and `assets/` folders loaded on demand. Verified harnesses: Claude Code (`/name`), Codex (`$name`), Cursor, plus pi and OpenClaw via the neutral `~/.agents/skills/` path.
