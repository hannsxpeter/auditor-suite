# The Auditor Suite

[![lint](https://github.com/hannsxpeter/auditor-suite/actions/workflows/lint.yml/badge.svg)](https://github.com/hannsxpeter/auditor-suite/actions/workflows/lint.yml)
[![release](https://img.shields.io/badge/release-v1.2.0-blue)](https://github.com/hannsxpeter/auditor-suite/releases/tag/v1.2.0)
[![version](https://img.shields.io/badge/version-1.2.0-blue)](VERSION)
[![agent skills](https://img.shields.io/badge/Agent%20Skills-compatible-2f6fed)](SUITE.md)
[![ready-suite](https://img.shields.io/badge/ready--suite-sibling-7c3aed)](https://github.com/hannsxpeter/ready-suite)
[![license](https://img.shields.io/github/license/hannsxpeter/auditor-suite)](LICENSE)

> Eight read-only audit skills for AI coding agents, one repo, one install. Each auditor scores one domain of a codebase end to end, writes a prioritized report you or another agent can act on, and prints the verdict in chat. Built to work on small and local models as well as frontier ones: a short procedural spine, rule cards loaded on demand, and shared scripts that inventory, scan, score, and validate. Implements the [Agent Skills standard](https://agentskills.io); runs in Claude Code, Codex, Cursor, pi, OpenClaw, or any harness that reads `SKILL.md`.

This is the monorepo. Every auditor lives under `skills/<skill-name>/`. It is the sibling of [`hannsxpeter/ready-suite`](https://github.com/hannsxpeter/ready-suite): the ready skills build a product from idea to launch; the auditors judge what got built.

## The eight auditors

| Skill | Audits | Dimensions | Report | Invoke |
|---|---|---|---|---|
| **[codeauditor](skills/codeauditor)** | The whole codebase: a security survey, architecture, quality, testing, error handling, performance, dependencies, docs, observability | 9 | `codeaudit.md` | `/codeauditor` |
| **[secauditor](skills/secauditor)** | Security vulnerabilities, grounded in OWASP and CWE | 11 | `secaudit.md` | `/secauditor` |
| **[dbauditor](skills/dbauditor)** | The database layer: schema, relationships, constraints, data types, indexing, queries, transactions, migrations, data protection, search, scale | 11 | `dbaudit.md` | `/dbauditor` |
| **[llmauditor](skills/llmauditor)** | LLM integration: security and trust boundaries, prompts, model selection, API usage, reliability, output handling, cost, latency, evaluation, observability, RAG, agents | 12 | `llmaudit.md` | `/llmauditor` |
| **[seoauditor](skills/seoauditor)** | Search and AI answer-engine visibility (SEO, GEO, AEO): crawlability, rendering, structured data, Core Web Vitals signals | 12 | `seoaudit.md` | `/seoauditor` |
| **[uiauditor](skills/uiauditor)** | UI implementation: accessibility, semantic HTML, styling, components, responsive layout, performance, design system, assets, i18n, native UI | 10 | `uiaudit.md` | `/uiauditor` |
| **[uxauditor](skills/uxauditor)** | The product's UX: user journeys, processes, and workflows end to end | 11 | `uxaudit.md` | `/uxauditor` |
| **[productauditor](skills/productauditor)** | The product's business layer: claims, plans and entitlements, billing lifecycle, accounts, metrics, KPIs, release and sunset, experiments, feedback | 9 | `productaudit.md` | `/productauditor` |

In Codex the same skills invoke with a `$` prefix: `$codeauditor`, `$secauditor`, and so on.

## Modes

Every auditor takes the same arguments after its name:

- nothing or `full`: every dimension that applies, every check.
- `quick`: only the Critical-class checks, no numeric score. A fast triage, and the best first pass for small models or huge repos.
- `only=DIM,DIM`: a subset of dimensions (for example `/secauditor only=AUTHZ,INJ`), with a partial score.
- a path, alone or after a mode (`/dbauditor quick services/billing`): audit only that part of the tree.

## How the auditors work

Frontier models already know OWASP, WCAG, and N+1 queries; what they lack is a shared contract. Small models lack the knowledge and the judgment. So each auditor is:

- **A short spine** (`SKILL.md`, about 2,000 to 3,800 tokens, down from 5,200 to 17,900 in 1.0.0): the contract, the modes, an eight-step workflow checklist, the dimension table, and the domain judgment that is easy to get wrong.
- **Rule cards** (`references/<DIM>.md`), read just before each dimension's pass: where to look, how to confirm a defect, when it is not a finding, the severity, the fix, and how to verify the fix, plus the "paper controls" that look protective and do nothing.
- **Shared read-only scripts** (`scripts/`): `inventory.sh` maps the project and decides which dimensions apply; `scan.sh` turns cards into `path:line` leads; `new-report.sh` writes the report skeleton; `score.sh` computes every score from the findings; `check-report.sh` validates the report, including that each cited `path:line` exists and that at least one span of 6 or more characters quoted in the Evidence appears within 6 lines of the finding's first cited location.
- **A validated example report** and **dated facts** (`references/`), and **the report template and tables** the scripts read (`assets/`).

The model does the judgment; the scripts do the bookkeeping. Scores are deterministic, so re-running an audit after fixes measures progress. See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for the design and [docs/AUTHORING.md](docs/AUTHORING.md) for how an auditor is built.

## The read-only contract

1. **Never edits source.** An audit changes nothing in the repository except its own report file.
2. **Never runs the live system.** No app runs, tests, builds, browsers, live database connections, model calls, exploits, crawls, or queries to analytics, billing, feature-flag, or CRM services. The audit reads code, and runs only read-only commands: its own bundled scripts and read-only shell commands such as `git log` and `git show`.
3. **Evidence it opened.** Every finding cites a `path:line` and quotes the code there; the validator checks that every cited line exists and that the quote appears at the first one (within 6 lines).
4. **One self-contained report.** Each run writes exactly one `<name>audit.md` at the repo root, in one format shared by all eight auditors: scored, prioritized, and readable without this suite or the conversation that produced it.
5. **Verdict in chat.** After the report validates, the auditor prints the score, the scorecard, and the highest-leverage fixes.

Reports are designed to be handed to another agent as a work order: every finding names the file, the defect, the severity, the fix, and how to verify the fix.

## Why eight auditors, not one

A single mega-auditor flattens every domain into generic advice. Splitting the work gives each auditor room to be opinionated: its own dimensions and weights, its own rule cards and paper controls, and a tight trigger surface so the harness routes precisely. Run one when you care about one domain; run several for a full-product review. Each report stands alone, so the audits compose on disk, not in memory.

## Install

### Claude Code plugin

```text
/plugin marketplace add hannsxpeter/auditor-suite
/plugin install auditor-suite@auditor-suite
```

This installs the `auditor-suite` meta plugin, which depends on every auditor. Want only one? `/plugin install secauditor@auditor-suite`. The marketplace lives at [`.claude-plugin/marketplace.json`](.claude-plugin/marketplace.json); each plugin is vendored under [`plugins/<skill-name>/`](plugins/) from the canonical `skills/<skill-name>/`.

### One command (Claude Code, Codex, Cursor, pi, OpenClaw)

```bash
git clone https://github.com/hannsxpeter/auditor-suite.git ~/Projects/auditor-suite
bash ~/Projects/auditor-suite/install.sh
```

The installer detects which harnesses you have (`$CLAUDE_CONFIG_DIR`, else `~/.claude`; `$CODEX_HOME`, else `~/.codex`; `~/.cursor`, `~/.agents`, `~/.pi`, `~/.openclaw`), writes the neutral `~/.agents/skills/` path when `~/.agents`, pi, or OpenClaw is present, and symlinks each skill's runtime payload (`SKILL.md`, `references/`, `scripts/`, `assets/`) into every detected harness. It installs every `skills/<skill-name>/` that holds a `SKILL.md`. An existing skill folder that holds a real copy of the skill (files, not links) is first moved whole to `~/.auditor-suite-backups/<platform>/<skill-name>-<timestamp>/`, outside every harness skills directory, so the old copy cannot load as a duplicate skill. A folder link to another location is moved there too (the link, never what it points to), and a dangling link is replaced. The installer never moves or deletes anything inside the clone. It is idempotent and exits non-zero if any skill fails to link. Add `-v` for verbose output.

`git pull` updates every installed skill at once, because each harness reads the clone through the links. A release that adds an auditor needs one more run of `install.sh` to link the new skill: after pulling 1.2.0, run it once to add productauditor.

Older versions of the installer left backups as `<skill-name>.backup-<timestamp>/` inside the skills directory, where a harness can load them as duplicate skills. The installer now warns about each one; move them out by hand.

### One skill, by hand

Link the whole skill folder, not just `SKILL.md` (the skill reads its `references/` and runs its `scripts/`):

```bash
ln -s ~/Projects/auditor-suite/skills/dbauditor ~/.claude/skills/dbauditor
```

If you run `install.sh` later, it replaces this folder link with a folder of per-item links and leaves the clone untouched; `uninstall.sh` removes either form.

**Windsurf or agents without a native skills directory:** point the project rules at `skills/<skill-name>/SKILL.md` and give the agent access to that folder, so it can read the references and run the scripts.

### Uninstall

```bash
bash ~/Projects/auditor-suite/uninstall.sh
```

Removes the suite's links from every detected harness: the installer's per-item links and a by-hand folder link to a skill, then each skill folder the removal left empty. Leaves the clone, the backups in `~/.auditor-suite-backups/`, and any older `.backup-*/` directories untouched.

## Composition

Auditors do not call each other. The harness is the router.

- **Routing:** each auditor has a distinct trigger surface (its name, its report, its domain vocabulary).
- **Reports are the contract.** Downstream agents (or the ready-suite build skills) read every auditor's report the same way and act on it as a prioritized work order.
- **Full-product review:** run codeauditor for the baseline, then the specialists for depth (secauditor before launch, dbauditor after schema changes, llmauditor on AI features, seoauditor and uiauditor on the web surface, uxauditor on the journeys, productauditor before a pricing change, a launch, or due diligence).
- **Boundaries:** secauditor owns security depth (codeauditor's security lens is a survey); uiauditor owns how the interface is built, uxauditor owns how the product behaves end to end; seoauditor owns how the outside world discovers it; productauditor owns whether the product delivers, charges, entitles, and measures what it promises. See [SUITE.md](SUITE.md).

## Evals

Each auditor ships an eval case (`evals/<skill>/full-audit/`): a small project with planted defects and decoys, an answer key, and graders for recall, precision, format, and read-only behavior. `bash scripts/eval.sh <skill> --model claude-haiku-4-5` runs it through `claude plugin eval` (Claude Code 2.1.269 or later) against a no-skill baseline, so the result is what the skill adds on that model. Runs call the model and bill your plan or API account; set `--max-cost-usd`. See [evals/README.md](evals/README.md).

## Maintenance

```bash
bash scripts/sync-shared.sh        # copy shared/ (protocol, template, scripts) into every skill
bash scripts/refresh-plugins.sh    # run sync-shared, then vendor each skill's payload into plugins/
bash scripts/lint.sh --verbose     # every check; name checks to run only those
bash tests/run.sh                  # golden tests for the shared scripts
bash tests/install.sh              # tests for install.sh and uninstall.sh
bash tests/lint-selftest.sh        # proves eight of the thirteen lint checks fail on an injected violation
```

The roster is the `skills/` directories (`scripts/_skills.sh`); no script keeps a list of skill names. The linter's checks:

- `suite-registry`: `skills/`, `plugins/`, the marketplace, the meta plugin's dependencies, `evals/`, `tests/fixtures/`, and the README and SUITE.md tables name the same skills; each README row's dimension count matches `dimensions.tsv`; each report file is excluded from scans and git-ignored.
- `skill-frontmatter`: the name matches the directory; the description is present and at most 1,024 characters.
- `skill-structure`: the spine budget, reference links, well-formed cards and tables, a `(quick)` tag on every card whose Severity can be Critical, and a valid `SCAN_SKIP_RE`.
- `patterns-valid`: every scan pattern compiles under `grep -E` and, when installed, ripgrep.
- `shared-sync`: each skill's shared copies are identical to `shared/`.
- `examples-valid`: every example report passes its own validator.
- `evals-structure`: every skill has a complete eval case.
- `script-tests`: `tests/run.sh` and `tests/install.sh` pass.
- `plugin-sync`: vendored payloads match `skills/`; every manifest is valid JSON with the right name, version, source, and description.
- `suite-release` and `changelog-top`: VERSION matches the README badges, SUITE.md, the marketplace metadata, the shared scripts, and the top CHANGELOG entry.
- `unicode-clean`: no dashes, arrows, box drawing, symbols, or emojis in tracked files or in untracked files git does not ignore.
- `bash-syntax`: every script parses and uses no bash 4 construct.

GitHub Actions runs the lint and its self-test on Ubuntu and macOS (`/bin/bash` 3.2 and BSD awk) on every push and pull request to `main`, then the lint again on Ubuntu with awk set to mawk, then gawk.

## Docs

- [SUITE.md](SUITE.md): the suite map, contract, boundaries, and composition principles.
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md): why the auditors are built this way.
- [docs/AUTHORING.md](docs/AUTHORING.md): how to write or change an auditor.
- [docs/DRIFT.md](docs/DRIFT.md): the drift found at 1.0.0 and how 1.1.0 resolved it (sections 1 to 8), and the docs-against-tooling drift 1.2.0 resolved (section 9).
- [CHANGELOG.md](CHANGELOG.md): what each release changed.
- [CONTRIBUTING.md](CONTRIBUTING.md) and [MAINTAINING.md](MAINTAINING.md): workflow, rituals, and version rules.

## Lineage

This monorepo consolidated seven standalone repos on 2026-07-14. Each was merged with its full git history preserved (subtree merges); trace a skill's past with `git log -- skills/<skill-name>/`. Release notes, pull-request prose, and tag messages from the deleted standalone repos are preserved in [docs/STANDALONE-ARCHIVE.md](docs/STANDALONE-ARCHIVE.md).

| Skill | Former repo | Final standalone version |
|---|---|---|
| codeauditor | `hannsxpeter/codeauditor` | 1.0.0 |
| secauditor | `hannsxpeter/secauditor` | 0.1.0 |
| dbauditor | `hannsxpeter/dbauditor` | 0.1.1 |
| llmauditor | `hannsxpeter/llmauditor` | 0.1.0 |
| seoauditor | `hannsxpeter/seoauditor` | 0.1.0 |
| uiauditor | `hannsxpeter/uiauditor` | 0.1.0 |
| uxauditor | `hannsxpeter/uxauditor` | 1.1.0 |

productauditor, added in 1.2.0, was built in this monorepo and has no standalone history. Standalone versioning is retired; every skill follows the release train named in [`VERSION`](VERSION).

## Contributing

PRs welcome. See [`CONTRIBUTING.md`](CONTRIBUTING.md). Report a vulnerability privately, as [`SECURITY.md`](SECURITY.md) describes.

## License

MIT. Each skill under `skills/<skill-name>/` carries its own LICENSE file with the same terms.
