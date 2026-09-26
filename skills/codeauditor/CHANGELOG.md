# Changelog

All notable changes to codeauditor are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [auditor-suite 1.1.0] - 2026-09-26

Restructured so the skill works for small and local models as well as frontier
models. The audit knowledge is preserved; its shape changed.

### Changed

- `SKILL.md` is now a short spine (about 2,000 tokens, down from about 5,100):
  an opening that tells the model to run the audit itself, the contract, modes,
  an eight-step workflow checklist, the dimension table, and judgment notes.
  Detail moved to files read only when a step needs them.
- Each lens's checklist became rule cards in `references/<DIM>.md` (SEC, ARC,
  QUAL, TEST, ERR, PERF, DEP, DOC, OBS): where to look, how to confirm, when it
  is not a finding, severity, fix, and how to verify the fix. The nine
  dimensions and their default weights are unchanged.
- Scores are computed by `scripts/score.sh` from the findings, so re-runs are
  comparable. The discretionary re-weighting ("re-weight only when the project
  type warrants it") is dropped: the weights are fixed. Suspected findings
  count half and never cap a score; two Critical findings cap a dimension at
  59 and the overall at 69.
- The report follows the suite template: it gains a Map section (modules,
  layers and dependency direction, state and configuration, integrations,
  load-bearing code, and two or three flows traced with `path:line`), findings
  gain a References field and must quote the cited code in Evidence, and "How
  to use this report" has the suite's eight steps with a code-specific fixing
  rule.
- Performance findings from static code are Likely or Suspected unless the
  code alone proves the cost; each PERF card says when Confirmed is allowed.
- The description is in the third person and names trigger phrases, modes,
  and invocation tokens. The README describes the suite install, the payload
  folders, modes, and scripts instead of the retired standalone installer.

### Added

- Modes: `quick` (the 13 Critical-class cards only, no score), `only=DIM,DIM`
  (partial score), and a path scope.
- Read-only scripts: `inventory.sh`, `scan.sh` (84 search patterns in
  `assets/patterns.tsv`), `new-report.sh`, `score.sh`, `check-report.sh`.
- `references/example-report.md`, a validated report of
  `tests/fixtures/codeauditor/`; `references/facts.md` (HTTP client timeout
  defaults, Express and asyncio error behavior, runtime end-of-life dates,
  deprecated packages and APIs, reviewed 2026-09-26); and an eval case under
  `evals/codeauditor/`.
- Cards for checks that were implicit before: per-request data in shared
  global state (ARC-R8), liveness versus readiness probes (OBS-R4), destructive
  schema auto-sync at startup (OBS-R6), predictable tokens from
  non-cryptographic random (SEC-R6), Express 4 async handlers and unhandled
  rejections (ERR-R1), retries of non-idempotent operations (ERR-R4), and
  packages loaded by name rather than imported (DEP-R4).

### Fixed

- Medium findings that were not Suspected fell in no remediation bucket, and
  Likely High or Critical findings with effort S fell between Quick wins
  (Confirmed only) and Plan now (effort M or L only). The new Schedule bucket
  and `score.sh` put every finding in exactly one bucket.
- Nothing checked that a cited `file:line` existed; `check-report.sh` now
  rejects missing files, out-of-range lines, and Evidence quotes that are not
  at the cited line.
- Overlaps inside the skill now have one owner each:
  - secrets in logs (listed under Security and Observability) is OBS-R1;
  - secrets in the repo is SEC-R5, other per-environment config is OBS-R5;
  - god functions (Architecture cohesion and Code Quality size) are QUAL-R1,
    god files and classes are ARC-R3;
  - copy-pasted logic (Architecture under-abstraction and Code Quality
    duplication) is QUAL-R2, leaving over-engineering to ARC-R7;
  - competing designs for one concern are ARC-R6, style inconsistency stays in
    QUAL, and two packages doing one job are DEP-R4;
  - architecture drift is ARC-R1 when code breaks a declared layer, and DOC-R2
    when a doc describes what the code lacks;
  - verbose errors sent to clients are SEC-R7, causes lost in logs and rethrows
    are ERR-R2;
  - failures caught and dropped are ERR-R1, failures never logged or reported
    are OBS-R2 and OBS-R3;
  - constant-time comparison (Authentication and Cryptography) is SEC-R6;
  - coverage claims (Testing and Documentation) stay in TEST;
  - lockfiles and version pins are DEP-R5, the build and run definition is
    OBS-R7, and a development server running with debug on is SEC-R7;
  - missing timeouts are ERR-R3, not PERF;
  - a layer bypass whose skipped rule is an authorization check is SEC-R2.

## [auditor-suite 1.0.0] - 2026-07-14

Moved into the [auditor-suite](https://github.com/hannsxpeter/auditor-suite)
monorepo as `skills/codeauditor/`, with the standalone repo's full git history
preserved. Standalone versioning is retired; the skill now follows the
auditor-suite release train.

### Changed
- `SKILL.md` now carries Agent Skills frontmatter directly (name, description,
  and the `/codeauditor` and `$codeauditor` invocation tokens); previously the
  frontmatter was synthesized at install time by the standalone installer. The
  audit engine body is unchanged from `engine/codeauditor.md`.
- The standalone per-tool installer, its planned global-command mode, and the
  per-repo CI checks (formerly tracked here as unreleased work) are superseded
  by the hub installer (`install.sh`) and the hub lint workflow, which enforce
  the same rules suite-wide: no em dashes, en dashes, or emojis in tracked
  files, and bash-valid scripts.

## [1.0.0] - 2026-05-30

First public release.

### Added
- The `codeauditor` command: a complete, read-only audit of a codebase that
  writes `codeaudit.md` and then prints a summary to the chat.
- Nine analysis lenses: Security, Architecture and Design, Code Quality and
  Maintainability, Testing and Verification, Error Handling and Resilience,
  Performance and Efficiency, Dependencies and Supply Chain, Documentation and
  Drift, and Observability and Operability.
- Explicit scoring rubric with per-dimension weights, score bands, and a rule
  that a single Critical finding caps the dimension and the overall score.
- Self-contained findings (Severity, Confidence, Effort, Location, Evidence,
  Impact, Recommendation, Verify-the-fix, Related) and root-cause clustering
  into systemic patterns, written so another agent can act on them with no
  prior context. Includes a decision protocol for the acting agent.
- Chat summary after the report is written: headline score and grade,
  scorecard, top fixes, finding counts by severity, and the report path.
- Single source of truth in `engine/codeauditor.md`.
- `install.sh` that detects installed tools and renders the engine into each
  one's native format, with an `uninstall` mode. Supports Claude Code, OpenAI
  Codex CLI, Gemini CLI, Cursor, opencode, Windsurf, Antigravity, and pi
  (pi.dev).
- `AGENTS.md` portable directive for any other tool that reads `AGENTS.md`.
- Project documentation: README, CONTRIBUTING, SECURITY, CODE_OF_CONDUCT, and
  this changelog.
- Downloadable release archive (`codeauditor-1.0.0.zip` and `.tar.gz`) attached
  to the GitHub release: unzip and run `./install.sh`.

[1.0.0]: https://github.com/hannsxpeter/codeauditor/releases/tag/v1.0.0
