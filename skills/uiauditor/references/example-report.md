# UI implementation audit: clinic-booking

> Read-only UI-implementation audit of the code as written, 2026-09-26. The app was not run, and no browser, scanner, or build was used. Mode: full. Scope: whole project.
> Self-contained: every finding cites the file and line it is about, so an agent holding only this report and the code can act on it. Written with uiauditor (auditor-suite 1.2.0).

## Snapshot

- Project: clinic-booking (example fixture in tests/fixtures/uiauditor)
- Stack: Vue 3 single-file components, client-rendered (no SSR), built with Vite; plain CSS with custom-property tokens; no component library or Web Components
- Size and coverage: 5 source files, about 200 lines; read exhaustively
- Maturity and exposure: public production booking page (package.json); patients book from phones and desktops
- Active dimensions: A11Y, SEM, STYLE, COMP, RESP, PERF, DS, ASSET
- Not applicable: I18N (no match for: i18n runtime or message catalog; message catalog files; RTL or multi-locale requirement), NATIVE (no match for: React Native, Expo, or react-native-web; another native-mobile UI toolkit)
- Not assessed: none
- Excluded: none

## Map

- Surfaces: one load-bearing page (pick a slot, choose reminders, confirm); `index.html` mounts `src/App.vue`.
- Shell and globals: `lang` and a zoomable viewport (`index.html:2`, `index.html:5`); the `:root` block is the token source (`src/styles/app.css:1-7`); no reset removes focus styles.
- Interactive inventory: the therapist filter and slot buttons (`src/components/SlotPicker.vue:46`, `src/components/SlotPicker.vue:50`), a switch rebuilt from a div (`src/App.vue:42`), and the submit button (`src/App.vue:44`).
- Render cost and adaptation: no images or web fonts; slots are fetched on mount and re-sorted per keystroke (`src/components/SlotPicker.vue:23-27`); one fixed-width container (`src/styles/app.css:22`), no media queries, no RTL or dark mode.
- Paths traced: submit (`src/App.vue:38`) through `book()` (`src/App.vue:14`) to the status line (`src/App.vue:45`); the switch from markup (`src/App.vue:42`) to its handler (`src/App.vue:10`) and styles (`src/styles/app.css:41-73`).

## Overall score

<!-- BEGIN GENERATED: score (score.sh --write fills this block; do not edit it by hand) -->
**Overall: 79/100, Grade C (adequate, real gaps)**

| Dimension | Score | Grade | Weight | Critical | High | Medium | Low | Suspected |
|---|---:|---|---:|---:|---:|---:|---:|---:|
| A11Y Accessibility and Inclusive Markup | 87 | B | 22.0% | 0 | 1 | 1 | 0 | 0 |
| SEM Semantic HTML and Document Structure | 100 | A | 14.0% | 0 | 0 | 0 | 0 | 0 |
| STYLE Styling Architecture and CSS Correctness | 100 | A | 13.0% | 0 | 0 | 0 | 0 | 0 |
| COMP Component Implementation and UI State | 100 | A | 13.0% | 0 | 0 | 0 | 0 | 0 |
| RESP Responsive and Adaptive Layout | 69 | D | 12.0% | 1 | 0 | 0 | 0 | 0 |
| PERF Frontend Performance and Loading | 98 | A | 11.0% | 0 | 0 | 0 | 0 | 1 |
| DS Design System Consistency and Theming | 97 | A | 9.0% | 0 | 0 | 1 | 0 | 0 |
| ASSET Assets, Media, Icons and Fonts | 100 | A | 6.0% | 0 | 0 | 0 | 0 | 0 |
| **Overall** | **79** | **C** | 100% | 1 | 1 | 2 | 0 | 1 |

Caps applied: RESP held at 69 (one Critical finding); overall held at 79 (one Critical finding).
Not applicable (not scored): I18N (no match for: i18n runtime or message catalog; message catalog files; RTL or multi-locale requirement), NATIVE (no match for: React Native, Expo, or react-native-web; another native-mobile UI toolkit).
Findings: Critical 1, High 1, Medium 2, Low 0 (Suspected, not yet confirmed: 1).
Computed by score.sh from the findings below (rules: references/protocol.md, Scoring).
<!-- END GENERATED: score -->

Verdict: A small booking page with sound states, labels, and focus styles, whose fixed 960px container breaks the whole flow on phones and caps the score. The reminder switch hides its state from screen readers, and the helper text bypasses its own contrast-safe token. Fix `.page` first; the rest are one-line changes.

Calibration: a public, production booking page, so WCAG 2.2 AA applies and every step of the booking flow is load-bearing.

## What to fix first

<!-- BEGIN GENERATED: fix-first (score.sh --write) -->
1. [RESP-001] Booking page fixed at 960px wide scrolls sideways on phones - Critical, effort S. every phone visitor, and anyone zoomed to 400%, must scroll sideways to reach the slots and Confirm booking; the whole public booking flow fails re...
2. [A11Y-001] Reminder switch has no aria-checked, so its state is never announced - High, effort S. screen-reader users hear the switch with no on or off state, so they cannot tell whether they are opting in to text reminders before they book.
<!-- END GENERATED: fix-first -->

## Strengths (preserve these)

- Loading, error, empty, and count states all render through one persistent status line (`src/components/SlotPicker.vue:29-34`, `src/components/SlotPicker.vue:47`).
- Slots are real buttons with `aria-pressed`, keyed by `slot.id`, under a labeled filter (`src/components/SlotPicker.vue:45-50`).
- `:focus-visible` outlines on the switch and every button (`src/styles/app.css:69-73`).
- The submit is disabled while sending, and every outcome is reported (`src/App.vue:14-27`).

## Systemic patterns (root causes)

- SYS-1: the helper-text style bypasses the token set. Members: A11Y-002, DS-001. Root fix: color `.hint` with `var(--color-text-muted)`, which passes contrast and restores the single source of truth.

## Findings

### [RESP-001] Booking page fixed at 960px wide scrolls sideways on phones
- Severity: Critical | Confidence: Confirmed | Effort: S | Dimension: RESP
- Location: `src/styles/app.css:22` (the `.page` class on `<main>` at `src/App.vue:35`)
- Evidence: `.page` sets `width: 960px;` with `margin: 0 auto;`, and the stylesheet has no media or container query that overrides it.
- Impact: every phone visitor, and anyone zoomed to 400%, must scroll sideways to reach the slots and Confirm booking; the whole public booking flow fails reflow.
- Recommendation: change `.page` to `width: 100%; max-width: 960px; box-sizing: border-box;` and keep the padding.
- Verify the fix: render the page at 320 CSS px wide: no horizontal scrollbar, and the slot grid wraps to one column.
- References: WCAG 1.4.10
- Related: none

### [A11Y-001] Reminder switch has no aria-checked, so its state is never announced
- Severity: High | Confidence: Confirmed | Effort: S | Dimension: A11Y
- Location: `src/App.vue:42`
- Evidence: the control is `<div role="switch" tabindex="0" aria-labelledby="reminder-label"`, toggled by `@click="toggleReminders"`; its state is only the visual `:class="{ on: reminders }"`, with no `aria-checked`.
- Impact: screen-reader users hear the switch with no on or off state, so they cannot tell whether they are opting in to text reminders before they book.
- Recommendation: make it `<button type="button" role="switch" :aria-checked="reminders">` with the same label, classes, and click handler; the button brings Enter and Space.
- Verify the fix: the rendered switch has `aria-checked` matching the visual state; a screen reader announces on or off when it is toggled.
- References: WCAG 4.1.2; WAI-ARIA 1.2 switch role (aria-checked required); APG Switch pattern
- Related: none

### [A11Y-002] Hint and status text is gray #999999, about 2.8:1 on the white page
- Severity: Medium | Confidence: Likely | Effort: S | Dimension: A11Y
- Location: `src/styles/app.css:28` (used at `src/App.vue:37` and `src/components/SlotPicker.vue:47`)
- Evidence: `.hint` sets `color: #999999;` on the `--color-surface` white background, a contrast of about 2.8:1, below the 4.5:1 that this body-size text needs.
- Impact: low-vision patients may miss the cancellation deadline and the slot status, including its load error. Likely, not Confirmed: no other background or opacity applies in the code, but the rendered page was not checked.
- Recommendation: set `.hint { color: var(--color-text-muted); }` (#595959, about 7:1 on white).
- Verify the fix: a contrast checker on the rendered page reports at least 4.5:1 for `.hint` text.
- References: WCAG 1.4.3
- Related: SYS-1

### [DS-001] .hint hardcodes #999999 beside the declared text-muted token
- Severity: Medium | Confidence: Confirmed | Effort: S | Dimension: DS
- Location: `src/styles/app.css:28`
- Evidence: `:root` declares `--color-text-muted: #595959;` (line 3), yet `.hint` sets `color: #999999;`, the only color literal outside `:root`.
- Impact: the muted-text token is decorative for the page's two key helper texts (the cancellation policy and the slot status), so a palette change will miss them.
- Recommendation: replace the literal with `var(--color-text-muted)` and keep color literals only in `:root`.
- Verify the fix: `scan.sh DS-R1` lists hex values only on lines 2 to 5 of `src/styles/app.css`.
- References: W3C Design Tokens format (single source of truth)
- Related: SYS-1

### [PERF-001] Slot filter re-sorts every slot on each keystroke
- Severity: Medium | Confidence: Suspected | Effort: S | Dimension: PERF
- Location: `src/components/SlotPicker.vue:23-27`
- Evidence: `visible` runs `.sort((a, b) => new Date(a.start) - new Date(b.start))` after the filter on every `query` change, and `v-model` changes `query` per keystroke; the slot count comes from an API outside this repo.
- Impact: if a clinic publishes months of slots, each keystroke in the therapist filter parses and sorts thousands of rows, delaying input on phones (INP); with a week of slots it is harmless.
- Recommendation: sort once when the slots load, filter only in `visible`, and debounce `query` by about 150 ms if lists can be long.
- Verify the fix: confirm the real slot count from the API; with a 2,000-slot fixture, a performance profile of typing in the filter shows no task over 50 ms.
- References: Core Web Vitals INP
- Related: none

## Dimension notes

### A11Y: Accessibility and Inclusive Markup
- Checked: A11Y-R1, A11Y-R2, A11Y-R3, A11Y-R4, A11Y-R5, A11Y-R6, A11Y-R7, A11Y-R8, A11Y-R9, A11Y-R10, A11Y-R11
- Note: A11Y-001 and A11Y-002. The switch handles Space as its role expects (A11Y-R1 clean); labels, focus styles, and status regions are sound.

### SEM: Semantic HTML and Document Structure
- Checked: SEM-R1, SEM-R2, SEM-R3, SEM-R4, SEM-R5, SEM-R6
- Note: clean: one `h1` and `main`, a complete shell, and `role="list"` kept under `list-style: none`. The div rebuilt as a switch is filed once, as A11Y-001, whose fix makes it a button.

### STYLE: Styling Architecture and CSS Correctness
- Checked: STYLE-R1, STYLE-R2, STYLE-R3, STYLE-R4, STYLE-R5
- Note: clean: no `!important` or ID selectors, a logical inset for the switch knob, and a transform-only transition.

### COMP: Component Implementation and UI State
- Checked: COMP-R1, COMP-R2, COMP-R3, COMP-R4, COMP-R5, COMP-R6, COMP-R7
- Note: clean: the form prevents the reload, guards double submits, and reports every outcome; slots are keyed by id.

### RESP: Responsive and Adaptive Layout
- Checked: RESP-R1, RESP-R2, RESP-R3, RESP-R4, RESP-R5, RESP-R6
- Note: RESP-001, the fixed container, is the only responsive defect; the slot grid itself is fluid (`minmax(min(100%, 12rem), 1fr)`).

### PERF: Frontend Performance and Loading
- Checked: PERF-R1, PERF-R2, PERF-R3, PERF-R4, PERF-R5, PERF-R6
- Note: PERF-001 is Suspected until the slot count is known. Fetching slots on mount is not a finding: the app is client-rendered by design and shows a loading state.

### DS: Design System Consistency and Theming
- Checked: DS-R1, DS-R2, DS-R3, DS-R4, DS-R5
- Note: DS-001 is the only literal outside `:root`; there is one token source and no theme.

### ASSET: Assets, Media, Icons and Fonts
- Checked: ASSET-R1, ASSET-R2, ASSET-R3, ASSET-R4
- Note: clean: no raster images, icon sets, or web fonts; the favicon is an inline SVG data URI.

## Remediation plan

<!-- BEGIN GENERATED: plan (score.sh --write) -->
- Quick wins (Critical or High, not Suspected, effort S): RESP-001, A11Y-001
- Plan now (Critical or High, not Suspected, effort M or L), in this order: none
- Verify first (Suspected; confirm against the code before acting): PERF-001
- Schedule (Medium): A11Y-002, DS-001
- Backlog (Low): none
<!-- END GENERATED: plan -->

## Scope and limitations

Read every file. Nothing was rendered, scanned, or measured: A11Y-002's ratio is computed from two literal colors (a contrast check on the rendered page would confirm it), PERF-001 depends on the slot count the API returns, and the switch was not tried with a screen reader. The booking API is out of scope. No HTML sinks (`v-html`, `innerHTML`) exist for secauditor.

## How to use this report (for the acting agent)

1. Triage by severity and confidence. Confirmed Critical and High findings are safe to act on now, in the order under "What to fix first". Re-verify every Suspected finding against the cited code before changing anything.
2. Confirm the stated assumption on Likely findings before acting.
3. Fix root causes first: prefer a systemic pattern's root fix over its individual members.
4. Preserve the strengths; do not refactor them away while fixing something else.
5. Fix accessibility at the markup and the control: prefer the native element and a real label over a role or ARIA patch, fix the shared primitive or token once rather than each instance, and never remove a working label, focus style, token, or state branch to make another fix easier.
6. One finding, one change, verified: after each fix, run its "Verify the fix" step and keep the change traceable to the finding ID.
7. Do not widen scope silently; note adjacent issues instead of sprawling into a rewrite.
8. Re-run the audit to measure progress: confirm findings are resolved, not relocated, and that the strengths did not regress.
