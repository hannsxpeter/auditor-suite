# uiauditor

A read-only **UI-implementation audit** skill for AI coding agents, part of the [auditor-suite](../../README.md). It audits how the codebase in the current directory builds its user interface, writes a scored, prioritized, self-contained `uiaudit.md` at the project root, and prints the verdict in chat. It reads markup, templates, components, styles, tokens, config, and assets; it never runs the app, never opens a browser, never runs a build or a scanner (axe, Lighthouse), and never edits source.

- Claude Code: `/uiauditor`
- Codex: `$uiauditor`
- Other Agent Skills harnesses: the harness's native skill invocation

## What it audits

Ten dimensions, two of them conditional, grounded in WCAG 2.2, WAI-ARIA 1.2 and the ARIA Authoring Practices Guide, ARIA in HTML, the Core Web Vitals (LCP, CLS, INP), MDN, ECMA-402, and the project's own framework docs.

| ID | Dimension | Weight | Active when |
|---|---|---|---|
| A11Y | Accessibility and Inclusive Markup | 22 | always (floor dimension) |
| SEM | Semantic HTML and Document Structure | 14 | always |
| STYLE | Styling Architecture and CSS Correctness | 13 | always |
| COMP | Component Implementation and UI State | 13 | always |
| RESP | Responsive and Adaptive Layout | 12 | always |
| PERF | Frontend Performance and Loading | 11 | always |
| DS | Design System Consistency and Theming | 9 | always |
| ASSET | Assets, Media, Icons and Fonts | 6 | always |
| I18N | Internationalization and Localization Readiness | 8 | an i18n runtime, message catalog, or RTL or multi-locale requirement exists |
| NATIVE | Native and Cross-Platform UI Implementation | 9 | React Native, Expo, react-native-web, or another native-mobile UI toolkit is used |

The eight always-on weights sum to 100; an active conditional dimension adds its weight and all weights re-normalize, so accessibility stays the heaviest dimension in every combination. A11Y is the floor dimension: one A11Y Critical that is not Suspected caps the overall score at 69 instead of 79, so a fast, well-tokenized UI that locks out keyboard or screen-reader users cannot grade above D.

## Modes

- `/uiauditor` or `/uiauditor full`: every active dimension and every card.
- `/uiauditor quick`: only the 14 Critical-class cards (pointer-only controls, unnamed controls and unlabeled fields, blocked zoom, dialogs that do not manage focus, removed focus indicators, missing captions, accessibility theater, unannounced errors and status, reflow failures, broken forms, dead controls, and native text or back-navigation failures); no numeric score.
- `/uiauditor only=A11Y,RESP`: a subset of dimensions with a partial score.
- `/uiauditor src/checkout` (or `quick src/checkout`): limit the audit to a path.

## How it works

The skill is a short procedural spine (`SKILL.md`) plus files it reads only when needed:

- `references/protocol.md`: the shared rules for evidence, the finding format, severity, confidence, scoring, and finishing.
- `references/<DIM>.md`: one file of rule cards per dimension, 60 cards in all. Each card says where to look (a `scan.sh` lead or the files to read), how to confirm the defect, when it is not a finding, the severity, the fix, and how to verify the fix. Every dimension also lists its paper controls: code that looks protective and holds nothing, such as a `:focus-visible` ring a global reset defeats, a live region nothing writes to, or `loading="lazy"` on the hero image.
- `references/example-report.md`: a complete report of the fixture in `tests/fixtures/uiauditor/`, validated in CI, as a format anchor.
- `references/facts.md`: dated facts (WCAG 2.2 criteria, INP replacing FID, Baseline dates for dialog, popover, and inert, the Tailwind v4 outline change, accessibility law dates) with a review date.
- `scripts/`: read-only helpers shared by the suite. `inventory.sh` maps the project and decides the conditional dimensions; `scan.sh` turns cards into leads; `new-report.sh` writes the report skeleton; `score.sh` computes every score from the findings; `check-report.sh` validates the report, including that every cited `path:line` exists and that code quoted in Evidence appears within 6 lines of the first cited location.
- `assets/`: the report template and the tables the scripts read (`dimensions.tsv`, `patterns.tsv`, `surfaces.tsv`, `skill.conf`).

The model does the judgment (reading the markup and styles, confirming or refuting each lead, choosing severity); the scripts do the bookkeeping. Findings that depend on what static code cannot show (real contrast, runtime focus order, screen-reader output, Core Web Vitals numbers) are marked Likely or Suspected with the check that would confirm them.

## Scope and boundaries

uiauditor owns the implementation layer: whether the interface is built correctly, accessibly, semantically, consistently, responsively, and performantly as code.

- `uxauditor` owns the experience: journeys, heuristics, onboarding, information architecture, UX copy, and visual hierarchy. For accessibility, uiauditor scores the static implementation line (the missing name, the removed outline) and uxauditor scores the lived-flow consequence.
- `codeauditor` owns general code quality, lifecycle bugs with no visible symptom, and bundle or dependency weight.
- `secauditor` owns HTML sinks (`dangerouslySetInnerHTML`, `v-html`, `[innerHTML]`) and CSP; uiauditor notes them in one line and never scores them.
- `seoauditor` owns SEO beyond the document shell: how crawlers and answer engines discover and read the site. Core Web Vitals code signals appear in both, scoped to each concern.

The suite map is in [SUITE.md](../../SUITE.md).

## Install

Use the hub installer or the plugin marketplace; see the [suite README](../../README.md#install). A manual install must copy or link the whole skill directory (`SKILL.md`, `references/`, `scripts/`, `assets/`), not just `SKILL.md`.

## Output

`uiaudit.md` is written for a reader with no memory of the audit, typically another agent that will fix the findings: snapshot, UI surface map, score and scorecard, what to fix first, strengths to preserve, systemic root causes, findings with `path:line` evidence and a way to verify each fix, dimension notes, a remediation plan, scope and limitations, and a protocol for the acting agent.

## License

MIT. See [LICENSE](LICENSE).
