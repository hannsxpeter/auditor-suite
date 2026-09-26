# Changelog

All notable changes to the auditor-suite hub are documented here. The format is
based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the suite
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html) at the
release-train level: the root `VERSION` file names the train, and all seven
skills plus the plugin packaging publish that train together.

Per-skill history from before the consolidation lives in each
`skills/<skill-name>/CHANGELOG.md`.

## [1.1.0] - 2026-09-26

Every auditor rebuilt so it works on small and local models, not only on
frontier models. The domain knowledge is preserved; its shape changed. See
[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for the design and
[docs/DRIFT.md](docs/DRIFT.md) for the inconsistencies this release resolved.

### Added

- `shared/`: the one editable copy of the audit protocol
  (`references/protocol.md`), the report template
  (`assets/report-template.md`), and the read-only scripts every auditor runs:
  `inventory.sh` (maps the project and decides conditional dimensions),
  `scan.sh` (turns rule cards into `path:line` leads with ripgrep or grep),
  `new-report.sh` (writes the report skeleton), `score.sh` (computes scores,
  "What to fix first", remediation buckets, and the chat summary), and
  `check-report.sh` (validates layout, fields, cited paths and lines, quoted
  evidence, card coverage, and generated blocks).
- `scripts/sync-shared.sh` copies the shared core into every skill.
- Modes for every auditor: `quick` (Critical-class checks, no score),
  `only=DIM,DIM` (partial score), and a path scope.
- Per skill: rule cards per dimension (`references/<DIM>.md`; 453 cards across
  the suite, 120 of them Critical-class quick cards), a validated example
  report, dated facts, and tables in `assets/` (dimensions, search patterns,
  surface probes).
- Eval cases for all seven auditors (`evals/<skill>/full-audit/`: a fixture
  project with planted defects and decoys, an answer key, and graders) and
  `scripts/eval.sh`, a runner for `claude plugin eval` with a no-skill baseline
  and `--ref` for comparing versions.
- `tests/run.sh`: golden tests for the shared scripts (inventory, scan on
  ripgrep and grep, report skeleton, scoring arithmetic and caps, validator
  messages), run by lint.
- Lint checks: `skill-structure`, `patterns-valid` (every pattern compiled with
  grep and ripgrep), `shared-sync`, `examples-valid`, `evals-structure` (which
  also requires every grader to name its own skill's report), `script-tests`; `plugin-sync` now compares the whole runtime payload and the
  plugin and marketplace descriptions; `suite-release` also checks the version
  the scripts print.
- Docs: `docs/ARCHITECTURE.md`, `docs/AUTHORING.md`, `docs/DRIFT.md`,
  `evals/README.md`.

### Changed

- Each `SKILL.md` is now a short spine (about 2,000 to 3,200 tokens; 1.0.0
  ranged from about 5,200 to 17,900) that opens by telling the model to do the audit itself,
  then gives the contract, modes, an eight-step workflow checklist, the
  dimension table, and domain judgment. Detail loads on demand.
- One report format for all seven auditors (12 sections, 8 finding fields) and
  one scoring rule set, computed by `score.sh`: deductions per finding,
  Suspected findings at half weight and never capping, caps for Critical
  findings, and floor dimensions per skill.
- Findings must quote the code at their first cited `path:line`; the validator
  checks it.
- The installer, uninstaller, plugin vendoring, and lint all handle the full
  runtime payload: `SKILL.md`, `references/`, `scripts/`, `assets/`.
- CI installs ripgrep so pattern checks run under both engines.
- `references/STANDALONE-ARCHIVE.md` moved to `docs/STANDALONE-ARCHIVE.md` and
  is linked from the README.

### Measured

`claude plugin eval` on each auditor's eval case (a fixture project with 9 to
11 planted defects and 2 safe decoys), Haiku 4.5, one run per arm unless
noted. Scores are the fraction of graders passed: recall of each planted
defect by file and line, the report exists, finding format, and read-only
behavior.

| Skill | 1.1.0 skill | No skill | 1.0.0 skill |
|---|---|---|---|
| codeauditor | 0.86 | 0.57 | 0.17 (no report) |
| secauditor (3 runs) | 1.00 (1.00, 1.00, 1.00) | 0.60 (0.87, 0.73, 0.20) | 0.16 (no report) |
| dbauditor | 0.92 | 0.31 | 0.18 (no report) |
| llmauditor | 1.00 | 0.36 | 0.89 |
| seoauditor | 1.00 | 0.23 | 0.82 |
| uiauditor | 1.00 | 0.64 | 0.89 |
| uxauditor | 0.86 | 0.21 | 0.83 |

- The 1.1.0 skills add 0.29 to 0.77 over no skill on Haiku (mean +0.53).
- Three 1.0.0 skills (code, sec, db) wrote no report on Haiku: the model read
  the long third-person skill as a background job, replied that the audit
  was running, and stopped. The other four found most defects but never used
  the report format, which caps their score below 1.00.
- On Sonnet 5, secauditor scored 1.00 with the skill and 0.87 without (it
  found 10 of 11 natively and missed the MD5 password hashing): the frontier
  model needs the skill less, which is the point of the design.
- A review of a kept run showed the decoy graders were too strict: a correct
  finding that mentioned a decoy file as context counted as a false positive.
  Decoy graders now check only a finding's first cited location.

### Fixed

- The cross-skill drift listed in `docs/DRIFT.md`, including uxauditor telling
  the model to run the product, inconsistent Critical caps and floors,
  remediation buckets that dropped Medium and Likely findings, the unclosed
  quote in dbauditor's finding template, and plugin packaging that shipped only
  `SKILL.md`.

## [1.0.0] - 2026-07-14

First release of the auditor-suite monorepo: seven previously standalone
auditor repos consolidated into one hub, ready-suite style.

### Added

- Hub documentation: `README.md` (overview, install paths, lineage),
  `SUITE.md` (suite map, auditor boundaries, read-only contract),
  `AGENTS.md` (agent brief), `CONTRIBUTING.md`, `MAINTAINING.md`,
  `SECURITY.md`, `CODE_OF_CONDUCT.md`, and `RELEASE-CHECKLIST.md`.
- One-command installer (`install.sh`) and uninstaller (`uninstall.sh`)
  covering Claude Code, Codex, Cursor, and the neutral Agent Skills path
  read by pi and OpenClaw. Symlink-based and idempotent.
- Claude Code plugin marketplace (`.claude-plugin/marketplace.json`) with
  seven specialist plugins plus an `auditor-suite` meta plugin that bundles
  them all, vendored under `plugins/<skill-name>/`.
- Meta-linter (`scripts/lint.sh`) enforcing skill frontmatter validity,
  plugin-packaging sync, suite-wide version agreement, changelog discipline,
  a unicode-clean tree (no em dashes, en dashes, or decorative arrows), and
  bash-3.2 script syntax. Runs in CI on every push and pull request
  (`.github/workflows/lint.yml`).
- `scripts/refresh-plugins.sh` to re-vendor plugin packaging from the
  canonical skill sources.

### Changed

- Consolidated seven standalone repos into `skills/<skill-name>/` via subtree
  merges, preserving the full git history of every repo:

  | Skill | Former repo | Final standalone version |
  |---|---|---|
  | codeauditor | `hannsxpeter/codeauditor` | 1.0.0 |
  | secauditor | `hannsxpeter/secauditor` | 0.1.0 |
  | dbauditor | `hannsxpeter/dbauditor` | 0.1.1 |
  | llmauditor | `hannsxpeter/llmauditor` | 0.1.0 |
  | seoauditor | `hannsxpeter/seoauditor` | 0.1.0 |
  | uiauditor | `hannsxpeter/uiauditor` | 0.1.0 |
  | uxauditor | `hannsxpeter/uxauditor` | 1.1.0 |

- Normalized every skill to the Agent Skills layout `skills/<name>/SKILL.md`.
  For codeauditor and uxauditor, which shipped as frontmatter-less engine
  files rendered by a per-repo installer, valid `name` and `description`
  frontmatter was synthesized from their installer metadata; the audit
  engine bodies are unchanged.
- Retired per-repo scaffolding superseded by the hub: standalone installers,
  per-repo CI, `.claude-plugin/` manifests, gitignores, editorconfigs, and
  per-repo policy docs. Each skill keeps its README, CHANGELOG, and LICENSE.
- Retired standalone versioning in favor of the suite release train.
