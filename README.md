# The Auditor Suite

[![lint](https://github.com/hannsxpeter/auditor-suite/actions/workflows/lint.yml/badge.svg)](https://github.com/hannsxpeter/auditor-suite/actions/workflows/lint.yml)
[![release](https://img.shields.io/badge/release-v1.0.0-blue)](https://github.com/hannsxpeter/auditor-suite/releases/tag/v1.0.0)
[![version](https://img.shields.io/badge/version-1.0.0-blue)](VERSION)
[![agent skills](https://img.shields.io/badge/Agent%20Skills-compatible-2f6fed)](SUITE.md)
[![ready-suite](https://img.shields.io/badge/ready--suite-sibling-7c3aed)](https://github.com/hannsxpeter/ready-suite)
[![license](https://img.shields.io/github/license/hannsxpeter/auditor-suite)](LICENSE)

> Seven read-only audit skills for AI coding agents, one repo, one install. Each auditor scores one dimension of a codebase end to end, writes a prioritized report you or another agent can act on, and prints the verdict in chat. Implements the [Agent Skills standard](https://agentskills.io). Plug them into Claude Code, Codex, Cursor, pi, OpenClaw, or any harness that parses `SKILL.md` frontmatter natively.

This is the monorepo. Every auditor lives under `skills/<skill-name>/` with its own SKILL.md, README, CHANGELOG, and LICENSE. It is the sibling of [`hannsxpeter/ready-suite`](https://github.com/hannsxpeter/ready-suite): the ready skills build a product from idea to launch; the auditors judge what got built.

## The seven auditors

| Skill | Audits | Dimensions | Report | Invoke |
|---|---|---|---|---|
| **[codeauditor](skills/codeauditor)** | The whole codebase: security, architecture, quality, testing, error handling, performance, dependencies, docs, observability | 9 lenses | `codeaudit.md` | `/codeauditor` |
| **[secauditor](skills/secauditor)** | Security vulnerabilities, grounded in OWASP and CWE | 11 | `secaudit.md` | `/secauditor` |
| **[dbauditor](skills/dbauditor)** | The database layer: schema, relationships, indexing, queries, transactions, migrations, data protection, search, scale | 11 | `dbaudit.md` | `/dbauditor` |
| **[llmauditor](skills/llmauditor)** | LLM integration: prompts, model selection, API usage, reliability, output handling, cost, evaluation, observability, RAG, agents | 12 | `llmaudit.md` | `/llmauditor` |
| **[seoauditor](skills/seoauditor)** | Search and AI answer-engine visibility (SEO, GEO, AEO): crawlability, rendering, structured data, Core Web Vitals signals | 12 | `seoaudit.md` | `/seoauditor` |
| **[uiauditor](skills/uiauditor)** | UI implementation: accessibility, semantic HTML, styling, components, responsive layout, performance, design system, assets, i18n, native UI | 10 | `uiaudit.md` | `/uiauditor` |
| **[uxauditor](skills/uxauditor)** | The product's UX: user journeys, processes, and workflows end to end | end to end | `uxaudit.md` | `/uxauditor` |

In Codex the same skills invoke with a `$` prefix: `$codeauditor`, `$secauditor`, and so on.

## The read-only contract

Every auditor in the suite obeys the same discipline:

1. **Never edits source.** An audit changes nothing in the repository except its own report file.
2. **Never runs the live system.** No app runs, no browsers, no live database connections, no model calls, no exploits, no crawls of the deployed site. The audit reads code.
3. **One self-contained report.** Each run writes exactly one `<name>audit.md` at the repo root: scored, prioritized, and readable without access to this suite or the conversation that produced it.
4. **Verdict in chat.** After writing the report, the auditor summarizes the score, the top findings, and the highest-leverage fixes in the conversation.

Reports are designed to be handed to another agent as a work order: every finding names the file, the defect, the severity, and the fix.

## Why seven auditors, not one

A single mega-auditor flattens every domain into generic advice. Splitting the work gives each auditor room to be opinionated: its own dimension list, its own scoring rubric with per-dimension weights and severity caps, its own named defect classes, and a tight trigger surface so the harness routes precisely. Run one when you care about one dimension; run several in sequence for a full-product review. Each report stands alone, so the audits compose on disk, not in memory.

## Claude Code plugin install

Inside Claude Code:

```text
/plugin marketplace add hannsxpeter/auditor-suite
/plugin install auditor-suite@auditor-suite
```

This adds the suite's marketplace and installs the `auditor-suite` meta plugin, which depends on every auditor. One install command, seven skills.

Want only one auditor? Install it directly:

```text
/plugin install secauditor@auditor-suite
```

The marketplace lives in this hub repo at [`.claude-plugin/marketplace.json`](.claude-plugin/marketplace.json). Each plugin is vendored under [`plugins/<skill-name>/`](plugins/) with its own manifest, refreshed from the canonical content under `skills/<skill-name>/`.

## One-command install (Claude Code, Codex, Cursor, pi, OpenClaw)

Installs every auditor into every detected harness with a single shell command. Idempotent. Re-run anytime.

```bash
git clone https://github.com/hannsxpeter/auditor-suite.git ~/Projects/auditor-suite
bash ~/Projects/auditor-suite/install.sh
```

What it does:

1. Detects which harnesses you have (`~/.claude`, `~/.codex`, `~/.cursor`, `~/.pi`, `~/.openclaw`). Skips ones that aren't installed.
2. When pi or OpenClaw is detected, also writes to the neutral `~/.agents/skills/` path defined by the [Agent Skills standard](https://agentskills.io).
3. For each of the seven auditors, symlinks `SKILL.md` from `skills/<skill>/` into every detected harness's skills directory.
4. Existing non-symlink installs are backed up to `<target>.backup-<timestamp>/` first.

Edit a file in `skills/<skill>/` (or `git pull` to update) and the change is live in every harness immediately. No re-install needed.

Verbose mode shows every step:

```bash
bash install.sh -v
```

## Per-skill install (manual)

To install just one auditor into a single harness, symlink that skill's `SKILL.md` into the harness's skills directory:

```bash
# Claude Code (example: just dbauditor)
mkdir -p ~/.claude/skills/dbauditor
ln -s ~/Projects/auditor-suite/skills/dbauditor/SKILL.md ~/.claude/skills/dbauditor/SKILL.md
```

**Windsurf or other agents without a native skills directory:** point your project rules or system prompt at the skill's `SKILL.md` (`skills/<skill-name>/SKILL.md`).

## Uninstall

Removes the suite's symlinks from every detected harness. Leaves the in-tree skills under `skills/` and any `.backup-*/` directories untouched.

```bash
bash uninstall.sh
```

## Composition

Auditors do not call each other. The harness is the router.

- **Routing:** each auditor has a distinct trigger surface (its name, its report, its domain vocabulary). Say what you want audited; the harness picks the auditor.
- **Reports are the contract.** Every auditor writes `<name>audit.md` at the repo root. Downstream agents (or the ready-suite build skills) consume the report as a prioritized work order.
- **Full-product review:** run codeauditor for the whole-codebase baseline, then the specialists for depth (secauditor before launch, dbauditor after schema changes, llmauditor on AI features, seoauditor and uiauditor on the web surface, uxauditor on the journeys).
- **Boundaries:** secauditor owns security depth (codeauditor's security lens is a survey); uiauditor owns how the interface is built, uxauditor owns how the product behaves end to end; seoauditor owns how the outside world discovers it.

## Lineage

This monorepo consolidated seven standalone repos on 2026-07-14. Each was merged with its full git history preserved (subtree merges), so every pre-consolidation commit is reachable here; trace a skill's past with `git log -- skills/<skill-name>/`.

| Skill | Former repo | Final standalone version |
|---|---|---|
| codeauditor | `hannsxpeter/codeauditor` | 1.0.0 |
| secauditor | `hannsxpeter/secauditor` | 0.1.0 |
| dbauditor | `hannsxpeter/dbauditor` | 0.1.1 |
| llmauditor | `hannsxpeter/llmauditor` | 0.1.0 |
| seoauditor | `hannsxpeter/seoauditor` | 0.1.0 |
| uiauditor | `hannsxpeter/uiauditor` | 0.1.0 |
| uxauditor | `hannsxpeter/uxauditor` | 1.1.0 |

Standalone versioning is retired; every skill now follows the auditor-suite release train named in [`VERSION`](VERSION).

## Maintenance: auditor-suite-lint

The hub ships a meta-linter that mechanically enforces the suite's discipline rules: valid Agent Skills frontmatter on every skill, plugin packaging byte-identical to the canonical skill files, version agreement across VERSION, README badges, SUITE.md, and every plugin manifest, a hub CHANGELOG top entry that matches the release train, no em dashes, en dashes, or decorative arrows anywhere in tracked files, and bash-3.2-parseable scripts.

```bash
bash scripts/lint.sh                 # all checks
bash scripts/lint.sh --verbose      # show ok lines
bash scripts/lint.sh plugin-sync    # one specific check
```

The same lint runs in GitHub Actions on every push to `main` and on pull requests ([`.github/workflows/lint.yml`](.github/workflows/lint.yml)).

## Contributing

PRs welcome. See [`CONTRIBUTING.md`](CONTRIBUTING.md) for the contribution model, the unicode rule, the bash-3.2 rule, and how to land a single-skill or coordinated cross-suite change. For maintainer rituals (version bumps, plugin refresh, release trains), see [`MAINTAINING.md`](MAINTAINING.md).

## License

MIT. Each skill under `skills/<skill-name>/` carries its own LICENSE file with the same terms.
