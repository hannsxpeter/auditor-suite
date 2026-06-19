# uiauditor

A read-only **UI-implementation audit** skill for AI coding agents. It audits how the codebase in the current working directory builds its user interface end to end (accessibility, semantic markup, styling architecture, component and UI-state correctness, responsive layout, frontend performance, design-system consistency, assets and media, internationalization readiness, and native/cross-platform UI), writes a scored, prioritized, self-contained `uiaudit.md` at the repo root, then prints the verdict in chat. It works from the markup and templates, the styles, the component code, the design-token and theme files, the framework config, and the image, icon, and font assets in the repo: it never runs the app, never opens a browser, never takes screenshots, never runs a build or a scanner, and never mutates source.

It is the interface-implementation counterpart to `codeauditor` (code quality), `secauditor` (security), `dbauditor` (database), `llmauditor` (LLM integration), and `uxauditor` (user experience), and it is **dual-compatible**: the same `SKILL.md` runs in both Claude Code and Codex.

- In **Claude Code**: invoke with `/uiauditor`
- In **Codex**: invoke with `$uiauditor`

## What it audits

The audit is grounded in the current UI-engineering and accessibility standards: WCAG 2.2 (W3C Recommendation) and its success criteria, the WAI-ARIA Authoring Practices Guide and ARIA-in-HTML, the Core Web Vitals guidance on web.dev (LCP, CLS, INP), MDN for HTML and CSS semantics and behavior, the ECMAScript Internationalization API (ECMA-402), and the project's own framework UI documentation (React, Vue, Svelte, Angular, Next.js, Astro, React Native). EN 301 549 and ADA/Section 508 frame the accessibility legal exposure used for calibration. It scores ten dimensions, two of which are conditional on the project's surface:

| Dimension | Weight | Applies |
|---|---|---|
| Accessibility and Inclusive Markup | 22% | always |
| Semantic HTML and Document Structure | 14% | always |
| Styling Architecture and CSS Correctness | 13% | always |
| Component Implementation and UI State | 13% | always |
| Responsive and Adaptive Layout | 12% | always |
| Frontend Performance and Loading (Core Web Vitals risk) | 11% | always |
| Design System Consistency and Theming | 9% | always |
| Assets, Media, Icons and Fonts | 6% | always |
| Internationalization and Localization Readiness | 8% (nominal) | if an i18n runtime, message catalog, or RTL/multi-locale requirement exists |
| Native and Cross-Platform UI Implementation | 9% (nominal) | if React Native or another native-mobile UI toolkit exists |

The eight always-on dimensions sum to exactly 100. The conditional dimensions (I18N and NATIVE) carry nominal weights that sit outside that pool; when active they are added and all active weights are proportionally re-normalized back to 100, and when N/A they are dropped, so the score stays meaningful for a static marketing page and a React Native app alike. Accessibility is the highest-weighted dimension under every activation combination, because it is both the dominant correctness surface and the primary legal-exposure surface for UI.

These dimensions map onto the things teams ask about when they build interfaces: is it accessible and operable by keyboard and screen reader, is the markup semantic, is the CSS correct and maintainable, do components render every interaction state, does the layout adapt across viewports, is it shaped for fast loading, is it built consistently against a design system, are its assets handled well, and is it ready to be localized and to ship on native platforms.

## How it works

The method runs in phases: orient and detect the framework, rendering model, styling model, design system, and i18n/native surfaces, and the UI paradigm; map the UI surface and the high-risk render paths; analyze across every lens with `file:line` evidence and the produced markup; verify each candidate adversarially and cluster duplicates into systemic patterns; score with conditional re-normalization (a single Critical caps its dimension at 69 and the overall at 79, two or more cap the overall at 69, and an accessibility floor caps the overall at 69 for any A11Y-owned Critical); prioritize into Quick wins / Plan now / Verify first / Backlog; write `uiaudit.md`; and report the verdict in chat.

Two principles make it different from a linter:

- **It reads the rendered output, not the prop's promise.** A component called `<AccessibleModal>` is not accessible if it never moves focus or sets `aria-modal`; a `role="button"` is not operable without a key handler; a `:focus-visible` ring is decorative if a global reset strips `outline` everywhere. The gap between the name's claim and the shipped markup is itself a finding.
- **It actively hunts paper controls.** An `aria-label` that does not match the visible text (breaking voice control), `alt="image"` on an informative image, a `:focus-visible` style defeated later in the cascade, a design token declared in `:root` while components hardcode the raw hex next to it, an `aria-live` region nothing writes to, a focus trap with no keyboard escape, a `loading="lazy"` on the LCP hero image, a `<dialog>` opened with `show()` so it has no modal semantics: each looks correct and holds nothing.

Every finding is self-contained: an exact `file:line` and the produced markup or style, the concrete consequence and its blast radius, a specific fix in the project's own framework and styling model, a way to verify the fix (a scan, a keyboard pass, a contrast check, a render at a width), and a reference (a WCAG 2.2 success criterion, a WAI-ARIA pattern, a Core Web Vitals metric, or an MDN/framework doc). An ownership map ensures each defect is scored by exactly one dimension, with the artifact/root dimension owning it and the consequence dimension only cross-referencing, instead of triple-counting across lenses.

## Scope and boundaries

`uiauditor` owns the UI **implementation** layer: is the interface built correctly, accessibly, semantically, consistently, responsively, and performantly as code. The neighboring concerns belong to its siblings:

- `uxauditor` owns the **experience**: the journey design, Nielsen heuristics, onboarding, conversion, information architecture, and UX copy as a designed artifact. Where both read the same WCAG criterion, `uiauditor` scores the static implementation line (the missing programmatic name, the `outline:none` with no replacement) and `uxauditor` scores the lived-flow consequence.
- `codeauditor` owns general code quality (typing, dead application logic, module boundaries, bundle/dependency weight). `uiauditor` touches component code only where the defect degrades the rendered interface.
- `secauditor` owns all security sinks, including DOM-XSS via `dangerouslySetInnerHTML` / `v-html` / `[innerHTML]` and CSP. `uiauditor` cross-references such a sink as a one-liner but never scores it.

## Install

The skill is a single `skills/uiauditor/SKILL.md`. Install it into whichever tool you use.

### Claude Code

As a personal skill:

```sh
mkdir -p ~/.claude/skills/uiauditor
cp skills/uiauditor/SKILL.md ~/.claude/skills/uiauditor/SKILL.md
```

Or install the whole repo as a Claude Code plugin (it ships a `.claude-plugin/plugin.json` manifest) via your plugin workflow, then invoke `/uiauditor`.

### Codex

```sh
mkdir -p ~/.codex/skills/uiauditor
cp skills/uiauditor/SKILL.md ~/.codex/skills/uiauditor/SKILL.md
```

Codex also reads skills from `~/.agents/skills/` and `.agents/skills/` (repo-local); any of these works. Invoke with `$uiauditor`, or run `/skills` to list.

## Usage

From the root of the project you want to audit:

- Claude Code: `/uiauditor` (optionally pass a subpath, a single route or screen, or one component library to scope the audit)
- Codex: `$uiauditor`

The skill writes `uiaudit.md` to the audited project's root and prints the score, scorecard, and top fixes in chat.

## Output

`uiaudit.md` is written for a reader with no memory of the audit (typically another agent that will fix the findings). It contains the snapshot, the UI surface map, the overall score and scorecard, "what to fix first", strengths to preserve, systemic root causes, the full findings, a remediation plan, scope and limitations, and a "how to use this report" protocol.

## License

MIT. See [LICENSE](LICENSE).
