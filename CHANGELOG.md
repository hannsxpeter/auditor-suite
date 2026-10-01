# Changelog

All notable changes to the auditor-suite hub are documented here. The format is
based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the suite
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html) at the
release-train level: the root `VERSION` file names the train, and every skill
plus the plugin packaging publish that train together.

Per-skill history from before the consolidation lives in each
`skills/<skill-name>/CHANGELOG.md`.

## [1.2.0] - 2026-10-01

An eighth auditor, productauditor, and a hub that no longer lists the skills
by hand. The shared scripts now behave the same on macOS (`/bin/bash` 3.2,
BSD awk) and on Linux (mawk or gawk), and CI proves it on both.

### Added

- productauditor (`skills/productauditor/`): audits a product's business
  layer from its code, config, copy, and product docs, and writes
  `productaudit.md`. Nine dimensions: claims and delivery (CLM); plans,
  pricing, and entitlements (ENT); billing and subscription lifecycle (BILL);
  customer accounts and operations (CUST); product metrics (MET); business
  metric definitions (KPI); release, rollout, and sunset (SHIP);
  experimentation (EXP); and customer feedback (VOC). 58 rule cards, 17 of
  them quick; ENT and BILL are floor dimensions. It never queries analytics,
  billing, feature-flag, or CRM services. It ships with an example report and
  fixture (`tests/fixtures/productauditor/`), an eval case
  (`evals/productauditor/full-audit/`), and a plugin
  (`plugins/productauditor/`) that the marketplace and the meta plugin list.
- `SCAN_SKIP_RE`, an optional per-skill key in `assets/skill.conf`: a regex of
  paths that `scan.sh`, `inventory.sh`, and `new-report.sh` skip for that
  auditor only. productauditor uses it to skip tests, stories, fixtures,
  mocks, agent planning folders, archived docs, and lockfiles; the other seven
  leave it unset. `inventory.sh` prints how many files it skipped.
- The roster comes from the `skills/` directories (`scripts/_skills.sh`):
  `scripts/lint.sh`, `scripts/sync-shared.sh`, and `scripts/refresh-plugins.sh`
  carry no list of skill names, and the installer installs every skill folder
  that holds a `SKILL.md`.
- Lint check `suite-registry`: `skills/`, `plugins/`, the marketplace, the
  meta plugin's dependencies, `evals/`, `tests/fixtures/`, and the README and
  SUITE.md tables must name the same skills, each report must be excluded
  from scans and git-ignored, and `evals/results/` must stay ignored and
  untracked. Adding an auditor now means adding files; this check names every
  place still missing one (docs/AUTHORING.md section 8).
- JSON validation of every manifest in `plugin-sync` (jq, else python3; with
  neither, the manifests are read as text and a warning says their syntax is
  unchecked): each plugin's name, version, and description, and each
  marketplace entry's source and description.
- `tests/install.sh`: tests for `install.sh` and `uninstall.sh` against a
  throwaway hub and a temporary HOME. Lint runs it, with `tests/run.sh`,
  through `script-tests`.
- `tests/lint-selftest.sh`: copies the hub, injects violations for eight of
  the thirteen lint checks (`suite-registry`, `skill-frontmatter`,
  `skill-structure`, `shared-sync`, `script-tests`, `plugin-sync`,
  `unicode-clean`, and `bash-syntax`), an unknown check name, and a check
  that crashes, and proves each run fails with a message that names the
  problem.
- CI runs the lint and the self-test on macOS (`/bin/bash` 3.2, BSD awk and
  grep) as well as Ubuntu, and on Ubuntu runs the lint again with awk set to
  mawk, then gawk. The workflow token is read-only.
- `lint.sh bash-syntax` flags bash 4 constructs that `bash -n` accepts but
  bash 3.2 cannot run: associative arrays, namerefs, `mapfile`, `readarray`,
  case-changing expansions, `coproc`, `&>>`, and `;;&`.
- A golden test in `tests/run.sh` for `SCAN_SKIP_RE`.

### Changed

- The suite is eight auditors. README.md, SUITE.md, AGENTS.md, the
  marketplace, and the meta plugin say so, and SUITE.md gains boundaries
  between productauditor and each sibling that hands it a topic: uxauditor,
  codeauditor, secauditor, dbauditor, llmauditor, and seoauditor (no
  uiauditor topic moved).
- Sibling dimension files hand product topics to productauditor on their
  "Not here" lines (uxauditor CNV, TRU, USE, and PROC; codeauditor DOC, QUAL,
  ARC, SEC, and OBS; secauditor AUTHZ, APISEC, and CRYPTO; dbauditor TXN,
  INTEGRITY, and SCHEMA; llmauditor RELIABILITY and COST; seoauditor OBSV),
  and in uxauditor JRN-R1, JRN-R2, CNV-R4, TRU-R3, and the JRN and CNV Also
  check lists; codeauditor QUAL-R4; secauditor AUTHZ-R3 (its Confirm and its patterns.tsv lead now cover a plan or plan_id taken from the request); dbauditor INTEGRITY-R2; and llmauditor
  COST-R3, with an entry in each skill's CHANGELOG. No sibling
  card is retired.
- Rule cards: 511 across the suite, 138 of them quick (1.1.0 had 453 and
  120). docs/ARCHITECTURE.md section 9 has the per-skill sizes, measured at
  1.2.0.
- The marketplace metadata drops `homepage`, which
  `claude plugin validate --strict` rejects as an unknown field.
- When a card has more leads than `--max` (12 by default), `scan.sh` picks
  the ones it shows round-robin across files in path order: the first lead of
  each file, then the second of each, until the cap, still printed in path
  and line order. Before, it showed the first 12 in path order, so one file
  full of hits hid every file after it. `scan.sh --help` now documents
  `--max` and the selection.

### Fixed

- Regexes reached awk through `awk -v`, and BSD awk and gawk strip
  backslashes from `-v` values: `\.min\.js$` became `.min.js$`, so
  `admin.js`, `admin.css`, and similar files were dropped from every audit on
  macOS and with gawk. Every regex now reaches awk through ENVIRON
  (`as_match_lines`).
- `new-report.sh` and `score.sh --write` followed a symlink at the report
  path and could write outside the project. They now refuse a symlink, write
  a temp file beside the report, and rename it over the report; no temp file
  lands in `TMPDIR`. `score.sh --write` also keeps the report's permission
  bits and refuses a read-only report.
- The file list skips symlinks, submodules, and deleted or sparse files, so
  ripgrep and grep search the same files; surface probes report their first
  hit in path and line order, so inventory.sh and new-report.sh cite the same
  hit on every run; leads no longer depend on the
  user's grep or ripgrep config or locale; and a project inside a parent
  repository's ignored folder is no longer reported as having no source.
- `install.sh` emptied the hub's own skill when the harness held a by-hand
  folder link to it, printed ok and exited 0 when a link failed, and left
  backups inside the harness skills folder, where they loaded as duplicate
  skills. It now replaces such a link without touching the clone, exits
  non-zero on any failure, and moves backups to
  `~/.auditor-suite-backups/<platform>/<skill>-<timestamp>/`.
- `install.sh` and `uninstall.sh` broke when HOME held a space, and ignored
  `CLAUDE_CONFIG_DIR` and `CODEX_HOME`. `install.sh` also ignored a lone
  `~/.agents`, which SUITE.md lists as an install path.
- `unicode-clean` checked only the em dash, the en dash, and one arrow, in
  tracked files only. It now covers all arrows, box drawing, symbols and
  dingbats, emoji, and the emoji variation selector, in tracked files and
  untracked files that git does not ignore.
- A command that crashed inside a lint check could end the run or go
  unnoticed, and a `unicode-clean` hit stopped the run before the later
  checks and the summary. Each check now runs in its own subshell, a crash
  counts as a failure, and every check runs.
- `lint.sh` ran only the last check named on its command line; it now runs
  every check it is given (`lint.sh shared-sync plugin-sync`).
- `sync-shared.sh` and `shared-sync` now report a script left in a skill's
  `scripts/` after it was removed from `shared/scripts/`.
- secauditor SECRET-R5 (secrets in logs, errors, or image layers) can be
  Critical but was not tagged `(quick)`; it is now, and `skill-structure`
  fails any card whose Severity can be Critical without the tag.
- `check-report.sh` rejected valid reports that named CWE, CVE, or hash IDs
  (CWE-306, CVE-2023-30861, SHA-256) under Related or in a systemic pattern.
  Only the IDs after "Members:" count as pattern members now.
- `check-report.sh` let a conditional dimension the probes found vanish from
  both dimension lines, or sit in Not applicable with no reason. Every
  dimension must now appear exactly once across the Active, Not applicable,
  and (in `only=` mode) Not assessed lines, and each not-applicable one needs
  its reason in parentheses.
- `new-report.sh --mode only=` normalizes spaces and repeated IDs, so the
  skeleton it writes passes its own validator.
- Docs: the check-report evidence rule, the eval fixture sizes, what the
  read-only graders see, the install paths, the context budget, and the lint
  coverage now match the code. docs/AUTHORING.md no longer says the lint
  rejects real secret formats in eval fixtures (no check looks for them), and
  CODE_OF_CONDUCT.md names the suite instead of codeauditor.
  [docs/DRIFT.md](docs/DRIFT.md) section 9 logs the drift this release
  resolved.

### Measured

Per MAINTAINING.md, a minor train records eval scores here. The 1.2.0 runs
(productauditor's new case, and the cases of the skills whose cards or
scripts changed) are pending the maintainer's go-ahead: evals call models and
cost money. Until then, the 1.1.0 scores in the next entry are the latest
measured.

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
