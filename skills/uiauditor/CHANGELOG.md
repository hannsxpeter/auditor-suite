# Changelog

All notable changes to uiauditor are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [auditor-suite 1.2.0] - 2026-10-01

Released with productauditor, the suite's eighth auditor. No uiauditor topic
moved to it; the shared scripts pick leads more fairly and gain fixes.

### Changed

- `SKILL.md`: when a probe is wrong and you move a dimension between the
  Active and Not applicable lines, keep its reason in parentheses, for example
  `I18N (the i18n library serves one locale only)`; `check-report.sh` now
  requires one.
- `scan.sh`: when a card has more leads than `--max` (12 by default), it
  picks the ones it shows round-robin across files in path order (the first
  lead of each file, then the second of each, until the cap) and still prints
  them in path and line order. Before, it showed the first 12 in path order,
  so one file full of hits hid every file after it. `scan.sh --help` now
  explains `--max` and the selection.
- The scripts read an optional `SCAN_SKIP_RE` from `assets/skill.conf`, a
  regex of paths this auditor's scans and probes skip. uiauditor sets none, so
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

Restructured so the skill works for small and local models as well as frontier
models. The audit knowledge is preserved; its shape changed.

### Changed

- `SKILL.md` is now a short spine (about 2,700 tokens, down from about 15,400):
  contract, modes, an eight-step workflow checklist, the dimension table, and
  judgment notes. Detail moved to files read only when a step needs them.
- Each dimension's checklist became rule cards in `references/<DIM>.md`: 60
  cards, 14 of them tagged quick. The ten dimensions, their weights, the
  conditional re-normalization, and the accessibility floor are unchanged.
- The ownership map became card placement: each defect has exactly one card,
  in the dimension that owns the artifact. Items owned by sibling auditors
  (HTML sinks, bundle weight, lifecycle bugs, visual hierarchy, UX copy) are
  "Not here" lines, not cards.
- Scores are computed by `scripts/score.sh` from the findings, so re-runs are
  comparable. Suspected findings count half and never cap a score.
- Findings drop the `Owner` field (the ID prefix is the owning dimension) and
  must quote the cited code in Evidence; `check-report.sh` verifies it.
- The acting-agent protocol is the suite's shared eight steps, with the UI rule
  (fix at the markup and the control, prefer the native element over an ARIA
  patch) as step 5.

### Added

- Modes: `quick` (Critical-class cards only, no score), `only=DIM,DIM`, and a
  path scope.
- Read-only scripts: `inventory.sh`, `scan.sh`, `new-report.sh`, `score.sh`,
  `check-report.sh`, driven by 80 search patterns and by surface probes for
  the I18N and NATIVE dimensions.
- `references/example-report.md` (validated against `tests/fixtures/uiauditor/`),
  `references/facts.md` (WCAG 2.2 criteria, INP replacing FID, Baseline dates
  for dialog, popover, inert, `:focus-visible`, viewport units, container
  queries, and `fetchpriority`, the Tailwind v4 outline change, and
  accessibility law dates), and an eval case under `evals/uiauditor/`.
- Checks that were implicit before: paste blocked on login fields (WCAG 3.3.8),
  focus hidden under sticky bars (2.4.11), live regions mounted together with
  their message, React Native text rendered outside `<Text>`, blocked back
  navigation, Astro islands and Stimulus controllers that never hydrate,
  unlayered styles that override an `@layer` order, and token sources that
  disagree.

### Fixed

- Conflicts in the old ownership map now have one owner each: a pointer-only
  `div` control is A11Y-R1, so its Critical reaches the accessibility floor,
  while SEM-R1 keeps wrong-element hygiene; a focus indicator lost in the
  cascade is A11Y-R6, not STYLE; captions for load-bearing media moved from
  ASSET to A11Y-R7; a missing viewport meta is RESP-R2 and zoom blocking is
  A11Y-R4; favicon and manifest are ASSET-R4, not SEM; native accessibility
  props are A11Y cards, not NATIVE; a hover menu keyboard users cannot open is
  A11Y-R1, while touch-only failures are RESP-R5; client-directive cost is
  PERF-R4 and islands that never hydrate are COMP-R7; component types created
  during render, styled components included, are COMP-R4; `@font-face`
  settings are ASSET-R3 and font-swap layout shift is PERF-R6.
- Corrected or sharpened claims: CSS custom properties do inherit through the
  shadow boundary (document class rules and `:root` rules inside a shadow
  stylesheet do not); a placeholder is announced as a fallback accessible
  name, so a placeholder-only label is High, not an unnamed-control Critical;
  several `h1` elements are not a failure by themselves; WCAG 2.2 removed
  4.1.1 Parsing; Safari on iOS ignores `user-scalable=no`, but Android
  browsers and in-app web views still honor it.

## [auditor-suite 1.0.0] - 2026-07-14

Moved into the [auditor-suite](https://github.com/hannsxpeter/auditor-suite)
monorepo as `skills/uiauditor/`, with the standalone repo's full git history
preserved. Standalone versioning is retired; the skill now follows the
auditor-suite release train.

### Changed
- The standalone `.claude-plugin/plugin.json` manifest is retired; plugin
  packaging now lives in the hub under `plugins/uiauditor/`.
- The audit content in `SKILL.md` is unchanged from standalone 0.1.0.

## [0.1.0] - 2026-06-19

First release.

### Added
- The `uiauditor` skill: a read-only audit of how a codebase implements its user
  interface that writes a scored, prioritized `uiaudit.md` and then prints the
  verdict in chat. Dual-compatible: the same `SKILL.md` runs in Claude Code
  (`/uiauditor`) and Codex (`$uiauditor`).
- Ten analysis dimensions, two of them conditional on the project's surface:
  Accessibility and Inclusive Markup (A11Y); Semantic HTML and Document Structure
  (SEM); Styling Architecture and CSS Correctness (STYLE); Component
  Implementation and UI State (COMP); Responsive and Adaptive Layout (RESP);
  Frontend Performance and Loading (PERF); Design System Consistency and Theming
  (DS); Assets, Media, Icons and Fonts (ASSET); Internationalization and
  Localization Readiness (I18N, conditional); and Native and Cross-Platform UI
  Implementation (NATIVE, conditional).
- Explicit scoring rubric with per-dimension weights (the eight always-on
  dimensions sum to exactly 100), conditional re-normalization, score bands, a
  rule that a single Critical caps its dimension and the overall score, a
  multi-Critical overall cap, and an accessibility floor that caps the overall
  grade for any A11Y-owned Critical.
- An ownership map that assigns each cross-lens defect (a `div` doing a button's
  job, an undimensioned image, a hardcoded hex, a DOM-XSS sink) to exactly one
  owner, with the artifact/root dimension scoring it and the consequence
  dimension only cross-referencing, so findings are not triple-counted. It also
  draws the boundary with `uxauditor` (experience), `codeauditor` (code quality),
  and `secauditor` (security sinks).
- A seven-phase method: orient and detect surfaces; map the UI surface and the
  high-risk render paths; analyze across every lens with `file:line` evidence;
  verify adversarially and cluster; score; prioritize into Quick wins / Plan now
  / Verify first / Backlog; and write the report, then summarize in chat.
- Self-contained findings (Severity, Confidence, Effort, Location, Evidence,
  Impact, Recommendation, Verify-the-fix, References, Related) grounded in WCAG
  2.2, the WAI-ARIA Authoring Practices Guide, Core Web Vitals, MDN, and the
  ECMAScript Internationalization API, written so another agent can act on them
  with no prior context.
- Project documentation: README, LICENSE, this changelog, and a
  `.claude-plugin/plugin.json` manifest.

[0.1.0]: https://github.com/hannsxpeter/uiauditor/releases/tag/v0.1.0
