---
name: uiauditor
description: Audits how a codebase implements its user interface (accessibility, semantic HTML, CSS architecture, component and UI-state correctness, responsive layout, frontend performance, design-system consistency, assets and fonts, plus internationalization and native mobile UI when present) and writes uiaudit.md, a scored, prioritized, self-contained report, then prints the verdict in chat. Use when the user asks for a UI or frontend audit, an accessibility, WCAG, or a11y review, a CSS or design-system review, a Core Web Vitals risk check, or a pre-launch UI check. Read-only: never edits source, never runs the app, a browser, a build, or a scanner. Modes: full (default), quick (Critical-class triage), only=DIM,DIM, or a path. Invoke with /uiauditor in Claude Code or $uiauditor in Codex.
allowed-tools: 'Bash(bash "${CLAUDE_SKILL_DIR}/scripts/*)'
---

# uiauditor

**You are now running this audit. Do it yourself, starting now, by working through the Workflow below with your own tools.** Nothing runs in the background. The audit is finished only when `check-report.sh` prints OK and you have sent the chat summary.

Audits how the codebase in the current directory implements its user interface and writes `uiaudit.md` at its root: scored, prioritized, and self-contained, so another agent holding only the report and the code can fix what it finds. Then prints the verdict in chat.

## Contract

- Read-only. Create or change no file except `uiaudit.md` at the project root. Never run the project, its tests, a dev server, a build, or a bundler; never open a browser, take screenshots, or run an accessibility or performance scanner (axe, Lighthouse); never call a network service or a model.
- Allowed: reading and searching files, read-only shell commands (`git log`, `git show`, `ls`, `wc`), and this skill's scripts. The scripts only read, except `new-report.sh` and `score.sh --write`, which write only `uiaudit.md`.
- Evidence: every finding cites a `path:line` you opened and quotes the code there. A `scan.sh` lead is a place to read, never a finding by itself.
- Static code cannot show real contrast, runtime focus order, screen-reader output, the rendered layout, or Core Web Vitals numbers. A finding that depends on one of them is Likely or Suspected, and its Verify the fix names what would confirm it (an axe or Lighthouse run, a keyboard pass, a contrast check, a render at a given width). Never claim you rendered, scanned, or measured anything.
- Finish by sending the output of `score.sh --chat`. Never finish silently.

## Paths

`${CLAUDE_SKILL_DIR}` is this skill's folder, the one that contains this SKILL.md; Claude Code fills it in. If you still see the literal text `${CLAUDE_SKILL_DIR}`, replace it with that folder's absolute path in every command. Run every command from the project root.

## Modes

Text after the skill name picks the mode:
- nothing or `full`: every active dimension, every card.
- `quick`: only the cards tagged (quick), the Critical-class checks; no numeric score.
- `only=A11Y,RESP`: only those dimensions, every card; the score is labeled partial.
- a path, alone or after a mode (`quick src/checkout`): audit only that part of the tree.

## Workflow

Copy this checklist into your notes and tick each step as you finish it.

- [ ] 1. Run `bash "${CLAUDE_SKILL_DIR}/scripts/inventory.sh"` (add the path if scoped). If it prints NO SOURCE CODE FOUND, tell the user and stop. If it says the domain surface was NOT FOUND, read the entry points; if there is no rendered interface, tell the user and stop.
- [ ] 2. Read `${CLAUDE_SKILL_DIR}/references/protocol.md` (the rules for every finding) and `${CLAUDE_SKILL_DIR}/references/example-report.md` (a finished report).
- [ ] 3. Run `bash "${CLAUDE_SKILL_DIR}/scripts/new-report.sh" --mode <mode>` (add the path if scoped). It creates `uiaudit.md` and lists the active dimensions. Fill the Snapshot lines; in Stack, name the rendering model (SPA, server-rendered or server components, islands, static), the styling model (Tailwind, CSS Modules, CSS-in-JS, Sass, plain CSS), the design system or component library, and any Web Components. Trace the two or three highest-risk paths (a primary form from label to error to submit; the landing page from the document shell to its largest image; a custom widget from markup to key handler to focus) and write the Map section.
- [ ] 4. Work each active dimension in the listed order:
  - a. Read `${CLAUDE_SKILL_DIR}/references/<DIM>.md`.
  - b. Run `bash "${CLAUDE_SKILL_DIR}/scripts/scan.sh" <DIM>`. In quick mode run `bash "${CLAUDE_SKILL_DIR}/scripts/scan.sh" quick --show-cards` once instead of a and b.
  - c. For every card, read the code at each lead and the files its Leads line names, then apply Confirm, Not a finding if, and Severity. Refute before you record (protocol section 5).
  - d. Add each confirmed finding under `## Findings` in the exact block format (protocol section 2).
  - e. Fill the dimension's notes: `- Checked:` lists every card ID you worked, `- Note:` says what you found.
- [ ] 5. Merge repeats into one finding, write Systemic patterns, Strengths (each with a `path:line`), and Scope and limitations.
- [ ] 6. Run `bash "${CLAUDE_SKILL_DIR}/scripts/score.sh" --write`, then write the Verdict and Calibration lines.
- [ ] 7. Run `bash "${CLAUDE_SKILL_DIR}/scripts/check-report.sh"`. Fix every problem it lists and rerun until it prints `check-report: OK`.
- [ ] 8. Run `bash "${CLAUDE_SKILL_DIR}/scripts/score.sh" --chat` and send its output as your final message.

Stop early only if inventory.sh finds no source code, if the code has no rendered interface (a pure backend, library, or CLI), or if you cannot read the files; then say so and write no report.

## Dimensions

| ID | Dimension | Weight | Active when | Cards |
|---|---|---|---|---|
| A11Y | Accessibility and Inclusive Markup | 22 | always | references/A11Y.md |
| SEM | Semantic HTML and Document Structure | 14 | always | references/SEM.md |
| STYLE | Styling Architecture and CSS Correctness | 13 | always | references/STYLE.md |
| COMP | Component Implementation and UI State | 13 | always | references/COMP.md |
| RESP | Responsive and Adaptive Layout | 12 | always | references/RESP.md |
| PERF | Frontend Performance and Loading | 11 | always | references/PERF.md |
| DS | Design System Consistency and Theming | 9 | always | references/DS.md |
| ASSET | Assets, Media, Icons and Fonts | 6 | always | references/ASSET.md |
| I18N | Internationalization and Localization Readiness | 8 | an i18n runtime, a message catalog, or an RTL or multi-locale requirement exists | references/I18N.md |
| NATIVE | Native and Cross-Platform UI Implementation | 9 | React Native, Expo, react-native-web, or another native-mobile UI toolkit is used | references/NATIVE.md |

new-report.sh decides the conditional dimensions from probes and prints why; if a probe is wrong, move the ID between the Active and Not applicable lines, keep its reason in parentheses, for example `I18N (the i18n library serves one locale only)`, and say why in Scope and limitations. Weights re-normalize over the active dimensions: the eight always-on weights sum to 100, and an active I18N or NATIVE adds its weight before re-normalizing, so A11Y stays the heaviest dimension in every combination. A11Y is the floor dimension: one A11Y Critical that is not Suspected caps the overall score at 69 instead of 79, so a fast, well-tokenized UI that locks out keyboard or screen-reader users cannot grade above D. Other caps follow protocol section 8.

## How to judge

This audit covers whether the UI is built correctly as code: accessible, semantic, correctly styled, stateful, responsive, quick to render, consistent with its design system, and ready for locales and native platforms where those apply. The experience itself (journeys, heuristics, onboarding, information architecture, UX copy, visual hierarchy, which action is primary) belongs to uxauditor. Code quality, lifecycle bugs with no visible symptom, and bundle or dependency weight belong to codeauditor. HTML sinks such as `dangerouslySetInnerHTML`, `v-html`, and `[innerHTML]`, and the CSP, belong to secauditor: note them in one line under Scope and limitations and never score them. SEO beyond the document shell belongs to seoauditor.

- Accessibility has two lines. uiauditor owns the static implementation line: the missing programmatic name, the `outline: none` with no replacement, the role on a `div`. uxauditor owns the lived-flow consequence: whether a keyboard or screen-reader user can finish the journey. File the implementation defect here once and leave the journey to uxauditor.
- Read the rendered output, not the name's promise. A component called `AccessibleModal` that never moves focus, a `role="button"` with no key handler, and a `:focus-visible` ring that a global reset defeats are all defects; the gap between the name and the markup is often the most serious finding.
- Paper controls are the most dangerous findings: they look like protection and hold nothing (a token declared while the literal sits beside it, a live region nothing writes to, `loading="lazy"` on the hero image, a `<dialog>` opened with `show()`). Every dimension file lists the ones to hunt.
- Blast radius: a load-bearing surface is the landing page, the primary task, sign-in, checkout, and anything every user touches; a hidden debug toggle or an admin-only report is not. Card severities use that word; decide it from the Map.
- Calibrate to the paradigm and the stack, and write the bar on the Calibration line. A static marketing page is not held to a data-heavy app's state bar; a Tailwind config is the token source, not the absence of one; a React Native screen is judged on native primitives and accessibility props, not semantic HTML. Public and transactional products carry legal exposure (WCAG 2.2 AA, EN 301 549, the ADA, Section 508; see facts.md), which raises the bar on A11Y and RESP.
- Recommend the native element and a real label over an ARIA patch: no ARIA is better than bad ARIA. Never write "improve accessibility", "make it responsive", "clean up the CSS", or "optimize performance"; name the element, label, token, breakpoint, or attribute to change. Cite the WCAG success criterion, APG pattern, or Core Web Vitals metric in References.
- One defect, one dimension: card placement is the ownership map (the dimension that owns the artifact scores; the consequence dimension only mentions it in Impact). The same mistake in many places (placeholder labels on every field, raw hex everywhere) is one finding; different findings with one root (no focus style on any custom control, no loading state on any data view, fixed pixel widths throughout) share a Systemic pattern. When no card fits, Critical means a keyboard or screen-reader lockout, a reflow or zoom failure, a broken load-bearing form, or accessibility theater on a core surface. Effort S is a label, a `width` and `height`, or a `div` swapped for a `button`; M is a focus-managed dialog, a state pass over one view, or one surface's token migration; L is a design-system migration, a keyboard model for a widget set, an i18n pass, or a responsive rebuild.
- When sampling a large codebase, read in this order: the document shell and globals, the token and theme source, the primitive and form components, the custom widgets, the largest assets, then the load-bearing routes. Skip vendored UI libraries, generated code, and email or print-only templates unless in scope (list them under Excluded); read Storybook stories only for a component's intended contract.

## Reference files

- `references/protocol.md`: evidence rules, finding format, severity, confidence, scoring, modes, finishing.
- `references/example-report.md`: a complete report that passes check-report.sh.
- `references/facts.md`: dated facts (WCAG 2.2 criteria, INP replacing FID, Baseline dates for dialog, popover, and inert, the Tailwind v4 outline change, accessibility law dates), with the date they were last reviewed.
- `references/A11Y.md`, `references/SEM.md`, `references/STYLE.md`, `references/COMP.md`, `references/RESP.md`, `references/PERF.md`, `references/DS.md`, `references/ASSET.md`, `references/I18N.md`, `references/NATIVE.md`: the cards for each dimension.
- `assets/report-template.md`: the report skeleton new-report.sh fills.
