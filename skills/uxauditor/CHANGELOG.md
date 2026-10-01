# Changelog

All notable changes to uxauditor are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project adheres
to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [auditor-suite 1.2.0] - 2026-10-01

Released with productauditor, the suite's eighth auditor. The cards now name
the product topics that moved to it, and the shared scripts pick leads more
fairly and gain fixes.

### Changed

- `SKILL.md`: the judgment notes hand whether the product delivers, charges,
  entitles, and measures what it promises (including whether activation and
  funnel events fire once at the true outcome) to productauditor.
- `CNV.md`: the Not here line hands whether product events, including the
  activation event and funnel steps, fire once at the true outcome, carry user
  and account identity, match the tracking plan, and capture revenue to
  productauditor MET. Whether those events exist at all stays in CNV-R4,
  whose Not a finding if now hands an event that exists but fires at the
  wrong moment, more than once, or without identity to productauditor MET-R2
  and MET-R3. The paper control "an analytics event named activated that
  fires on sign-up" moved to productauditor MET-R2. The Also check on sign-up
  anxiety reducers hands a guarantee or trial whose number the code
  contradicts (a 30-day refund checked at 14 days, a 14-day trial set to 7)
  to productauditor CLM-R5.
- `JRN.md`: JRN-R1's Not a finding if hands a missing route that belongs to
  a sold or announced feature whose code exists but is not registered to
  productauditor CLM-R3. JRN-R2's Not a finding if hands a past-due or locked
  account with no update-payment action after a failed renewal to
  productauditor BILL-R6; a failed payment at checkout stays in JRN-R2. The
  Also check on README, marketing, and docs promises now covers only journeys
  that exist in the code and break; a capability that does not exist at all
  is productauditor CLM-R1.
- `PROC.md`: the Not here line hands routine account, plan, and billing
  operations done by SQL or scripts to productauditor CUST-R5.
- `TRU.md`: the Not here line hands what cancellation, downgrade, and renewal
  do at the billing provider and to access (productauditor BILL), the charged
  amount differing from the final amount shown (productauditor ENT-R1),
  invented product output and capability or technical-guarantee claims the
  code does not back (productauditor CLM), and a contact or support
  destination that is a placeholder or test value (productauditor VOC-R2) to
  productauditor. TRU-R3's Verify the fix now compares the first price shown
  with the final total shown before payment; whether the charge equals that
  total is productauditor ENT-R1.
- `USE.md`: the Not here line hands a submission that succeeds but reaches no
  one (productauditor VOC-R1), a sold feature that is a stub (productauditor
  CLM-R2), shared work deleted as a side effect of removing a member or
  deleting a member's user, even after a confirmation (productauditor
  CUST-R2), and records deleted or locked as a side effect of a downgrade, a
  lapse, or a trial end, even after a confirmation (productauditor BILL-R8),
  so USE-R1 and BILL-R8 no longer both file a data-deleting downgrade.
- `scan.sh`: when a card has more leads than `--max` (12 by default), it
  picks the ones it shows round-robin across files in path order (the first
  lead of each file, then the second of each, until the cap) and still prints
  them in path and line order. Before, it showed the first 12 in path order,
  so one file full of hits hid every file after it. `scan.sh --help` now
  explains `--max` and the selection.
- The scripts read an optional `SCAN_SKIP_RE` from `assets/skill.conf`, a
  regex of paths this auditor's scans and probes skip. uxauditor sets none, so
  the setting changes nothing here.
- Scans skip `productaudit.md`, the new auditor's report, as they skip the
  other reports.

### Fixed

- On macOS and with gawk, files such as `admin.js` and `admin.css` are no
  longer dropped from scans and probes as if they were minified bundles: the
  scripts now pass regexes to awk through `ENVIRON`, which keeps their
  backslashes.
- The file list leaves out symlinks, submodules, and tracked files that are
  deleted or outside a sparse checkout, so ripgrep and grep search the same
  files and no scan follows a link out of the project.
- Surface probes take their first hit in path and line order, so
  `inventory.sh` and `new-report.sh` cite the same hit on every run; ripgrep
  prints files in no fixed order.
- Reports are never written through a symlink, and the temporary file for a
  report write stays in the project, beside the report. `score.sh --write`
  keeps the report's permission bits and refuses a read-only report instead
  of replacing it.
- `check-report.sh` requires every dimension in exactly one of the Active and
  Not applicable lines (Not assessed in `only=` mode), with a reason in
  parentheses for each not-applicable dimension.
- Only the IDs after "Members:" count as systemic-pattern members, and CWE,
  CVE, and hash names (such as SHA-256) in a root fix or Related line are no
  longer read as finding IDs.
- `new-report.sh --mode only=` normalizes its list: spaces and empty items
  are dropped, and each ID is kept once.
- Leads no longer depend on the user's ripgrep config, `GREP_OPTIONS`, or
  locale.
- Projects inside a folder that an outer repository ignores are scanned.

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
- The tool-neutral audit engine (`engine/uxauditor.md` in the standalone repo): a read-only, end-to-end UX audit that writes a scored, prioritized, self-contained `uxaudit.md` and prints the verdict in chat.
- Eleven analysis lenses grounded in established standards: Usability and Heuristics (Nielsen's 10), Accessibility and Inclusive Design (WCAG 2.2 AA), User Journeys and Flows, Process and Workflow Efficiency (Lean, Theory of Constraints), Interaction and Visual Design, Information Architecture and Navigation, Content and UX Writing, Onboarding, Conversion and Engagement (AARRR), Forms and Input (Baymard), Performance and Responsiveness (Core Web Vitals), and Trust, Ethics and Transparency (the deceptive-design taxonomy).
- A weighted scoring model with A-F bands and a Critical-caps-the-score rule, severity mapped to Nielsen's 0-4 scale, and Confirmed / Likely / Suspected confidence so runtime-only findings are flagged for verification.
- `install.sh`: detects installed AI coding tools under `$HOME` and renders the engine into each tool's native skill or slash-command format (Claude Code, Codex CLI, Gemini CLI, Cursor, opencode, Windsurf, Antigravity, pi). Idempotent, with an `uninstall` mode.
- An `AGENTS.md` portable directive (standalone repo) for any tool that reads `AGENTS.md`.
- Repository scaffolding: README, CONTRIBUTING, SECURITY, CODE_OF_CONDUCT, LICENSE (MIT), `.editorconfig`, `.gitignore`, and a CI workflow that enforces plain-ASCII files and installer and engine consistency.

[1.0.0]: https://github.com/hannsxpeter/uxauditor/releases/tag/v1.0.0
