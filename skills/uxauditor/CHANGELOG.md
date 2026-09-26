# Changelog

All notable changes to uxauditor are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project adheres
to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [auditor-suite 1.1.0] - 2026-09-26

Rebuilt so small and local models can run the audit, following the suite's
authoring guide (`docs/AUTHORING.md`) and the secauditor reference shape.

### Changed
- `SKILL.md` is now a thin spine (contract, modes, an eight-step workflow,
  the dimension table, and judgment notes), down from a 35 KB single file.
  The eleven lenses moved into one rule-card file per dimension under
  `references/` (56 cards, 14 tagged quick), each with Leads, Confirm, Not a
  finding if, Severity, Fix, Verify the fix, and Refs, plus "Also check" and
  "Paper controls" lists. Every checklist item of the old skill landed in a
  card, an Also check line, a paper control, the judgment notes, or
  `references/facts.md`.
- Scores are computed by `scripts/score.sh` from the findings, with the
  shared caps (one Critical holds a dimension at 69 and the overall at 79).
  The old discretionary re-weighting by product type is dropped: the default
  weights always apply, and they re-normalize only in `only=` mode.
- Findings follow the shared protocol (`references/protocol.md`): every
  finding quotes the code at its `path:line`, carries References, and lands
  in one of five remediation buckets (Medium findings now go to Schedule).
- Each defect has exactly one owning dimension. Error wording is CNT, error
  placement and kept input are FRM, and error announcement is ACC; empty
  states are CNT, the first run is CNV, dead-end error and expired states are
  JRN, and zero-result search is IA; terminology is CNT, navigation labels
  are IA, and pattern consistency is IXD; pending feedback and double submit
  are USE, and screen-level loading is PRF; redundant entry and field economy
  are FRM, and back-office overproduction and re-keying are PROC; step
  counting is PROC and journey continuity is JRN; walls before value are CNV,
  and forced consent is TRU; one primary action per screen is IXD; zoom
  blocking and target size are ACC, and reflow is PRF; a low-contrast
  "Reject all" is TRU.
- The accessibility boundary with uiauditor is explicit: uiauditor scores
  the static markup line, and uxauditor's ACC scores whether a keyboard or
  screen-reader user can complete the journey.
- The description names the triggers, the read-only and static contract, the
  modes, and the invocation tokens.

### Added
- Modes: `quick` (Critical-class cards only, no numeric score), `only=DIM,DIM`,
  and a path scope.
- Shared read-only scripts in `scripts/`: `inventory.sh`, `scan.sh`,
  `new-report.sh`, `score.sh`, and `check-report.sh`.
- `assets/skill.conf`, `dimensions.tsv`, `patterns.tsv` (lead patterns that
  work in both `grep -E` and ripgrep), and `surfaces.tsv` (probes for a UI,
  CLI, API, or workflow surface; with none, the audit stops).
- `references/facts.md`: dated facts with sources to verify, last reviewed
  2026-09-26: the WCAG 2.2 criteria new since 2.1 and the carried thresholds,
  accessibility law, GDPR and EDPB consent guidance, EU DSA Article 25,
  subscription, pricing, and review rules, and Core Web Vitals.
- `references/example-report.md`, a validated report of the small fixture in
  `tests/fixtures/uxauditor/`.
- An eval case in `evals/uxauditor/full-audit/`: a React and Express expense
  app with ten planted UX defects, two decoys, and graders.

### Fixed
- Drift from the suite's read-only contract: the old skill told the model to
  run the product and walk flows ("If you can, walk the core flows", "Prefer
  running the product where you can"). The audit is now static only: it reads
  code, copy, routes, and config, and a finding about runtime behavior is
  Likely or Suspected with the check that would confirm it (running the
  product, a Lighthouse or contrast check, analytics, or a usability test).
- The consent and cancellation guidance cited the FTC click-to-cancel rule as
  law. The US Court of Appeals for the Eighth Circuit vacated that rule in
  July 2025; the TRU cards now cite ROSCA and state automatic-renewal laws,
  and `references/facts.md` marks the rule "verify current status".

## [auditor-suite 1.0.0] - 2026-07-14

Moved into the [auditor-suite](https://github.com/hannsxpeter/auditor-suite)
monorepo as `skills/uxauditor/`, with the standalone repo's full git history
preserved. Standalone versioning is retired; the skill now follows the
auditor-suite release train.

### Changed
- `SKILL.md` now carries Agent Skills frontmatter directly (name, description,
  and the `/uxauditor` and `$uxauditor` invocation tokens); previously the
  frontmatter was synthesized at install time by the standalone installer. The
  audit engine body is unchanged from `engine/uxauditor.md`.
- The standalone per-tool installer, the npm packaging (`npx uxauditor` via
  `package.json`), and the standalone `VERSION` file are retired in favor of
  the hub installer (`install.sh`) and the suite release train.

## [1.1.0] - 2026-06-17

A self-audit (`uxaudit.md`) of the installer's developer experience, driven to
zero. No change to the audit engine or its output; this release is entirely
about the install/inspect command-line experience.

### Added
- Published to npm: `npx uxauditor` runs the installer without cloning the repo
  (`package.json` exposes `install.sh` as the `uxauditor` bin).
- `install.sh` now has a real command-line interface: `--help`/`-h` (prints usage
  and exits), `--version`/`-v`, `--dry-run`/`-n` (preview the would-write targets
  without writing), and `list`/`status` (show what is installed in each detected
  tool).
- A `VERSION` file, the single source of the version reported by `install.sh --version`.
- opencode detection honors `XDG_CONFIG_HOME`.

### Changed
- `install.sh` rejects unrecognized arguments (prints usage to stderr, exits 2)
  instead of silently treating anything that is not `uninstall` as an install.
- When no supported tools are detected, the installer now lists the exact
  directories it checked and the next step (open the tool, or copy the engine per
  `AGENTS.md`) instead of a bare "Nothing to install".
- The post-install output surfaces the re-sync, `--dry-run`, `list`, and
  `uninstall` commands.
- README "from a release download" instructions are version-agnostic
  (`unzip uxauditor-*.zip`) so they do not break on future releases.
- The cross-tool table and run instructions document the correct per-tool
  invocation: `$uxauditor` for the Codex skill, `/uxauditor` for the Codex prompt
  and the Claude Code skill.

### Fixed
- `./install.sh --help` (and typos like `uninstal`) no longer perform an install.
- Codex slash command now installs into `~/.codex/prompts/` (which Codex reads)
  instead of `~/.codex/commands/` (which it ignores), so `/uxauditor` works in
  Codex. The Codex skill at `~/.codex/skills/uxauditor/` already provided
  `$uxauditor`.

[1.1.0]: https://github.com/hannsxpeter/uxauditor/releases/tag/v1.1.0

## [1.0.0] - 2026-06-17

First release.

### Added
- The tool-neutral audit engine ([`engine/uxauditor.md`](engine/uxauditor.md)): a read-only, end-to-end UX audit that writes a scored, prioritized, self-contained `uxaudit.md` and prints the verdict in chat.
- Eleven analysis lenses grounded in established standards: Usability and Heuristics (Nielsen's 10), Accessibility and Inclusive Design (WCAG 2.2 AA), User Journeys and Flows, Process and Workflow Efficiency (Lean, Theory of Constraints), Interaction and Visual Design, Information Architecture and Navigation, Content and UX Writing, Onboarding, Conversion and Engagement (AARRR), Forms and Input (Baymard), Performance and Responsiveness (Core Web Vitals), and Trust, Ethics and Transparency (the deceptive-design taxonomy).
- A weighted scoring model with A-F bands and a Critical-caps-the-score rule, severity mapped to Nielsen's 0-4 scale, and Confirmed / Likely / Suspected confidence so runtime-only findings are flagged for verification.
- `install.sh`: detects installed AI coding tools under `$HOME` and renders the engine into each tool's native skill or slash-command format (Claude Code, Codex CLI, Gemini CLI, Cursor, opencode, Windsurf, Antigravity, pi). Idempotent, with an `uninstall` mode.
- [`AGENTS.md`](AGENTS.md) portable directive for any tool that reads `AGENTS.md`.
- Repository scaffolding: README, CONTRIBUTING, SECURITY, CODE_OF_CONDUCT, LICENSE (MIT), `.editorconfig`, `.gitignore`, and a CI workflow that enforces plain-ASCII files and installer and engine consistency.

[1.0.0]: https://github.com/hannsxpeter/uxauditor/releases/tag/v1.0.0
