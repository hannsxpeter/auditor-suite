# Changelog

All notable changes to uiauditor are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

[0.1.0]: https://github.com/aihxp/uiauditor/releases/tag/v0.1.0
