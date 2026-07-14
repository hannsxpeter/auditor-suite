---
name: uiauditor
description: Audit how the codebase implements its user interface end to end (accessibility, semantic markup, styling architecture, component and UI-state correctness, responsive layout, frontend performance, design-system consistency, assets and media, internationalization readiness, and native/cross-platform UI), write uiaudit.md (a scored, prioritized, self-contained report), then display the results in chat. Read-only: never runs the app, never opens a browser, never takes screenshots, never mutates source. Invoke with /uiauditor in Claude Code or $uiauditor in Codex.
---

> Invocation: type `/uiauditor` (Claude Code) or `$uiauditor` (Codex) to run this command. The same skill works in both tools. Treat any text after it as the optional path-or-scope argument (a subpath, a single route or screen, or one component library).

# uiauditor

Audit how the codebase in the current working directory implements its user interface end to end: how accessible the rendered markup is to assistive technology and keyboard users, how semantically correct the HTML is, how the styles are authored, how components render their interaction states, how the layout adapts across viewports, how the frontend is shaped for load and interaction performance, how consistently it is built against a design system, how its media and font assets are handled, how ready it is to be localized, and how any native or cross-platform UI is built. Then do two things:

1. **Write a report** named `uiaudit.md` at the root of that codebase.
2. **Display the results in this chat**: the overall score, the scorecard, and the top fixes (see "Report in chat" below). Do not finish silently.

This is **read-only analysis of the code as written**. Do not run the application, do not open a browser, do not start a dev server, do not take screenshots, do not run a build or a bundler, do not execute a Lighthouse or axe scan, and do not modify any source, style, asset, or config file. Work from the markup and templates (HTML, JSX/TSX, Vue SFCs, Svelte, Angular templates), the styles (CSS, SCSS/Less, Tailwind classes, CSS-in-JS, CSS modules), the component code, the design-token and theme files, the framework and build config, and the image, icon, and font assets in the repository. The only file you create is `uiaudit.md`. If an optional path or scope was provided as an argument, audit that subtree, route, or component set; otherwise audit the whole UI surface rooted at the working directory.

The report is written for a reader who has **no memory of the audit**, typically an AI agent that will open `uiaudit.md` later and decide, on its own, what to fix. Every finding must therefore stand alone: cite exact locations (`path/to/Component.tsx:line`), name the element, control, selector, token, asset, or route, carry its own context, and say how to verify the fix. If a finding cannot be acted on by someone who only has the report and the code, it is not finished.

This is a **UI-implementation correctness, accessibility, consistency, and performance audit**. Scope is the implementation layer: whether the interface is built correctly, accessibly, semantically, consistently, responsively, and performantly as code. Its question is always "is this UI implemented correctly?", not "is this experience well designed?" That experience question (the journey design, Nielsen heuristics, onboarding, conversion, information architecture, and UX copy as a designed artifact) belongs to `uxauditor`. General code quality (typing, dead application logic, module boundaries, generic test coverage) belongs to `codeauditor`. All security sinks (DOM-XSS via `dangerouslySetInnerHTML` / `v-html` / `[innerHTML]` / Solid `innerHTML`, unsanitized template injection, CSP) belong to `secauditor`; cite such a sink as a one-line cross-reference but never score it here. The database layer belongs to `dbauditor` and LLM integration to `llmauditor`. Where a concern is shared with `uxauditor`, including its own WCAG lens, **uiauditor scores the static implementation line** (the missing programmatic name, the `outline:none` with no replacement, the role on a `div`) **and uxauditor scores the lived-flow consequence** (can a real screen-reader or keyboard user complete the journey); emit one finding and cross-reference, do not double-count.

---

## Operating principles (non-negotiable)

These govern the whole audit. A report that violates any of them is not done.

1. **Evidence over assertion.** No claim without a concrete, checkable reference (`file:line`) and the markup, selector, or component expression that makes it real. Apply the substitution test to every sentence: if you could swap in a different project and it would read equally true, it is filler. "Accessibility could be improved" fails. "`IconButton.tsx:18` renders an icon-only `<button>` whose only child is an `<svg>` with no `aria-label`, `aria-labelledby`, or visible text, so screen readers announce it as an unnamed button (WCAG 4.1.2)" passes.
2. **Verify against the rendered output, not the prop's promise.** Read the markup the code actually produces and the styles that actually apply, not a component name, a comment, or the design doc. A component called `<AccessibleModal>` is not accessible if it never moves focus or sets `aria-modal`; a `role="button"` is not operable without a key handler; a `:focus-visible` ring is decorative if a global reset strips `outline` everywhere. The gap between the name's claim and the shipped markup is itself a finding, and often the most serious one.
3. **Refuse theater. Hunt for paper controls.** The most dangerous defects look correct but carry no weight: an `aria-label` that does not match the visible text (breaking voice control, WCAG 2.5.3); `alt="image"` or `alt=""` on an informative image so it is silently dropped; a `:focus-visible` style defeated by a global `*{outline:none}` later in the cascade; a design token declared in `:root` while components hardcode the raw hex next to it; a loading state that never reflects real status; an `aria-live` region that nothing ever writes to; a focus trap with no keyboard escape; a responsive `@media` query whose breakpoint sits below the layout's own fixed min-width; a `<dialog>` opened with `show()` instead of `showModal()` so it has no modal semantics; a custom element styled only by global CSS variables that never cross its shadow boundary. Flag anything that exists for appearance but does not actually hold.
4. **Reachability and blast radius.** A defect matters in proportion to where it sits and who hits it. A missing label on a hidden debug toggle is not a missing label on the checkout submit; an unindexed responsive bug on an admin-only report is not one on the public landing page; an `outline:none` on a decorative element is not one on every focusable control. Calibrate to whether the surface is load-bearing (used by everyone, on a primary task, or guarding money or data) and to who can reach it. Where the consequence depends on rendered pixels, runtime focus order, real contrast, actual bundle size, or live performance you cannot see from static code, mark it Suspected and say what would confirm it.
5. **Find the root, not the leaves.** If the same mistake appears across the UI (placeholder-as-label on every field, no focus state on any custom control, raw hex instead of a token everywhere, no loading state on any data view, fixed pixel widths throughout), that is one systemic finding, not forty. Cluster instances into a class-level finding so the reader fixes the cause once.
6. **Verify adversarially.** For every candidate, try to refute it before keeping it: is there a visually-hidden label, a native element doing the work, a keyboard handler you missed, a `:focus-visible` rule elsewhere, a framework default, a global token applied higher up, or a deliberate documented choice that already neutralizes it? Assign a confidence level; when you cannot confirm by reading, mark it Suspected.
7. **Calibrate to the paradigm and the stack, not to one framework's ideal.** Grade against what the UI actually is. A static marketing page is not held to the component-state bar of a data-heavy SPA; Tailwind utility classes are not a "no design tokens" finding when the Tailwind config is the token source; a React Native screen is judged on native primitives and accessibility props, not on semantic HTML. State the detected paradigm and styling model and calibrate every lens to it.
8. **Be honest about scope.** Say which templates, components, and stylesheets you read, whether you read exhaustively or sampled, which surfaces are present and which are N/A, and which findings need a running app, a browser, an assistive-technology pass, or a Lighthouse/axe run to confirm. Never imply you rendered the UI, measured a Core Web Vital, ran an accessibility scanner, or checked real contrast. Static code cannot reveal real pixel contrast, runtime focus order, screen-reader announcement quality, actual CWV numbers, shipped bundle size, or cross-browser degradation; those become Suspected findings or "verify with X" items.
9. **Score with reasons, not vibes.** Every dimension score is justified against its specific findings. No number appears without the evidence that produced it.
10. **Name the strengths.** Record what the UI gets right, with evidence (native controls with real labels, a single token source actually consumed, every data view with loading/empty/error states, `prefers-reduced-motion` honored, responsive images with `srcset` and intrinsic dimensions, a focus-managed dialog), so the acting agent preserves them instead of removing them while fixing something else.
11. **Recommendations are specific, actionable, and stack-accurate.** Banned: "improve accessibility," "make it responsive," "clean up the CSS," "optimize performance." Required: the exact change (the element to swap, the label to add, the token to consume, the breakpoint to fix, the `width`/`height` to set, the focus to manage), the safe pattern in the project's own framework and styling model, and how to confirm it (a markup shape to inspect, a scan to run, a count that should now be zero). Cite the WCAG success criterion, ARIA pattern, or Core Web Vitals metric where it anchors the fix.

---

## Ownership rule (the de-duplication discipline)

Many defects surface through several lenses: a `div` with an `onClick` touches semantics and accessibility; an oversized hero image with no dimensions touches assets, responsiveness, and performance; a hardcoded hex touches styling and the design system; a blocked viewport zoom touches responsiveness and accessibility. **Each finding is emitted by exactly one dimension, its owner, and contributes only to that dimension's score.** Other dimensions may cross-reference it ("see DS for the token root") but must not re-score it.

The tie-break is deterministic: **the artifact/root dimension scores the finding; the consequence dimension may only cross-reference, never score.** Tag every finding with its owner. Use this ownership map:

| Defect | Owner | Rule |
|---|---|---|
| Wrong element for the job (a `div` doing a button's work) and its AT/keyboard consequence | **SEM** owns the wrong element; **A11Y** cross-references | SEM owns "the markup uses the wrong element"; A11Y owns "AT and keyboard users cannot operate it". Emit one finding owned by the actionable root; cross-reference the other. |
| Missing accessible name, label, role/state, focus management, color-only signaling | **A11Y** | the code-level WCAG/ARIA implementation defect; `uxauditor`'s WCAG lens owns the walked-flow outcome, not this line |
| Blocked viewport zoom (`user-scalable=no`, `maximum-scale=1`) | **A11Y** (WCAG 1.4.4 failure); **RESP** cross-references the viewport intent | the zoom failure is the accessibility defect; RESP only owns whether the viewport meta is set for responsiveness at all |
| Content cannot reflow / forces horizontal scroll at 320px | **RESP** (WCAG 1.4.10) | the adaptive-layout defect; A11Y cross-references the low-vision/zoom consequence |
| Hardcoded color/spacing/type literal instead of a design token | **DS** | token adherence and the single-source-of-truth gap; STYLE cross-references only when the same literal also creates a cascade/override problem |
| `!important` war, specificity conflict, dead/duplicated/never-matched CSS, lost `:focus-visible` rule | **STYLE** | CSS-correctness and cascade mechanics, including dead and never-matched styles (cascade-level analysis `codeauditor` does not perform). If the root is that the design system was bypassed, DS owns the systemic cause and STYLE cross-references |
| Image/iframe/embed with no `width`/`height`/`aspect-ratio` (layout shift) | **RESP** owns the layout-reservation defect; **PERF** cross-references the CLS framing | score the missing dimension once, in RESP; PERF only frames it as a Core Web Vitals risk |
| Unoptimized/oversized image, full icon-library import, missing `srcset`, wrong format | **ASSET** owns the artifact; **PERF** cross-references the load consequence | ASSET owns the asset itself (format, weight, broken reference, icon strategy); PERF owns the LCP/bundle consequence only when it sits on the render path |
| Bundle/dependency weight, duplicate libraries, tree-shaking, polyfills shipped to modern browsers | **codeauditor** (Performance + Dependencies) | uiauditor PERF owns only the render-path/CWV-shaped consequence (the heavy lib sits on the LCP path, blocks first paint, or is eagerly imported into a route chunk). Generic "this dep is heavy" with no render-path link is `codeauditor` |
| Missing/unwired/visibly broken loading, empty, error, or disabled state branch | **COMP** owns the structural presence and wiring in code; **uxauditor** owns whether the state is needed and whether it guides | uiauditor never judges whether a surface should have an empty state; it flags a branch declared-but-never-rendered, broken, or inconsistent across instances |
| React/Vue/Svelte lifecycle correctness in the abstract (uncleaned subscription, missing effect dep, stale closure) | **codeauditor** | the correctness/leak defect belongs to `codeauditor`. COMP claims it only when the same defect is observably a rendering artifact (a visible flash, a remount that drops input state, a hydration mismatch that paints wrong markup) and must cite the rendered symptom |
| DOM-XSS sink (`dangerouslySetInnerHTML`, `v-html`, `[innerHTML]`, Solid `innerHTML`, unescaped template output) | **secauditor** | any untrusted content reaching an HTML sink is a security trust-boundary defect. uiauditor notes the sink as a one-line cross-reference under SEM/COMP and does not score it |
| Hardcoded user-facing string not externalized for translation | **I18N** (when active); otherwise not a uiauditor finding | I18N owns externalization, locale-aware formatting, directionality, and translation-safe layout. The wording and tone of the copy is `uxauditor` regardless |
| Visual hierarchy, which action is the primary CTA, scannability | **uxauditor** | whether the eye is guided to the right action is experience design. uiauditor owns only whether variant/state styling is implemented consistently (DS) and correctly (STYLE) |

---

## Method

Run these phases in order. Use search to find candidates, then **read the cited template, component, or stylesheet to confirm the rendered output** before recording anything. A grep hit (an `onClick`, a hex literal, a `<div>`, a `px`) is a lead, not a finding.

### Phase 0 - Orient

- Detect the **framework and rendering model** from manifests and config (`package.json`, framework configs): React/Preact/Solid SPA, Vue, Svelte/SvelteKit, Angular, server-rendered or streamed (Next.js App Router, Remix, Nuxt, SvelteKit, Astro islands), static site or MPA (plain HTML, Astro, 11ty, Hugo, Jekyll), or plain HTML/CSS/vanilla JS. Note whether SSR/RSC is in use (it activates hydration-mismatch and `use client`/island-directive checks).
- Detect the **styling model**: Tailwind / utility-first, CSS Modules, CSS-in-JS (styled-components, Emotion, vanilla-extract), Sass/SCSS/Less, plain CSS with custom properties, or a zero-runtime system (Panda, StyleX). The styling model decides what "design token" means here (a Tailwind config, a `tokens.json`, a `theme.ts`, CSS custom properties) and how DS and STYLE are calibrated.
- Detect the **design system / component library**: MUI, Chakra, Radix, shadcn/ui, Mantine, Carbon, Ant, Bootstrap, or an in-house system; and whether the project consumes one or authors one. Locate the token, theme, and primitive-component sources.
- Detect **Web Components / shadow DOM** (Lit, Stencil, vanilla custom elements). Their presence activates shadow-boundary checks across SEM (slotting), STYLE (`:host`/`::part`/`::slotted` and the fact that global tokens and stylesheets do not pierce the shadow root), A11Y (`delegatesFocus`, `formAssociated` + `ElementInternals`), and DS (token adherence re-checked inside the boundary).
- Detect **internationalization and native surfaces** (they decide which conditional lenses apply): an i18n runtime or message catalog (i18next/react-i18next, next-intl, vue-i18n, `@angular/localize`, react-intl/FormatJS, lingui, svelte-i18n, paraglide, Fluent, gettext `.po`), or an explicit `dir="rtl"` / RTL primary locale, activates **I18N**; React Native / Expo / react-native-web or another native-mobile UI toolkit activates **NATIVE**.
- Locate the **UI surface**: routes and pages, screens, layouts, primary and primitive components, global styles and resets, the `<head>`/document shell (or framework metadata API), and the assets directory (images, icons, fonts, favicon, web app manifest).
- Determine the **UI paradigm** (content site, marketing page, dashboard/admin SPA, transactional app, component-library package) and the **evident maturity** (prototype, internal tool, production product, public service). These set the calibration and raise the bar on A11Y and RESP for public, transactional surfaces.
- Measure size (route count, component count, stylesheet count) and decide exhaustive vs sampled reading. Declare which in the report.
- Note explicitly **what static code cannot reveal**: real pixel contrast after inheritance/opacity/theme, runtime focus order and whether the focus ring is actually visible, screen-reader announcement quality, concrete Core Web Vitals numbers, shipped bundle size after tree-shaking, layout/overflow behavior on real devices, real font-swap timing, and cross-browser/AT degradation. These become Suspected findings or "verify with X" items, never confident claims.
- Identify what to exclude: vendored UI libraries, generated code, design fixtures, Storybook-only demo files (but do read them for the intended component contract), and email-HTML or print-only templates unless in scope. Record exclusions.
- If version control is present, record the current commit or branch.
- If there is **no user interface** (a pure backend service, a library with no UI, a CLI with no rendered surface), say so plainly in chat and stop. Do not invent findings.

### Phase 1 - Map the UI surface and the high-risk render paths

Do a short, lightweight pass before the per-dimension checklist. Keep it to roughly a half page; it informs prioritization.
- **Surfaces and load-bearing screens:** the routes/pages and the primary components, and which are load-bearing (the landing page, the primary task flow, the auth and checkout forms, anything every user hits).
- **The document shell and globals:** the `<html lang>` and viewport meta (or the framework equivalent), the global reset/normalize and where it strips focus or list semantics, the root layout and provider tree, and the single source of truth for tokens and theme.
- **The interactive inventory:** the custom controls (menus, tabs, dialogs, comboboxes, accordions, tooltips, carousels), the forms, and any element that handles a pointer event without being a native control. These are where accessibility and component-state defects concentrate.
- **The render-cost shape:** the largest assets and the components likely on the LCP path (hero images, web fonts, above-the-fold data views), the heavy client islands, and where layout shift can originate (images/embeds without dimensions, late-injected content).
- **The adaptation surface:** where the layout must respond (breakpoints, fluid containers), and whether RTL, dark mode, reduced motion, or multiple locales are in scope.
Trace two or three highest-risk paths end to end: a primary form from label to error to submit; the landing page from document shell to LCP asset; a custom interactive widget from markup to keyboard handler to focus management. Spend effort proportional to how many users a surface touches.

### Phase 2 - Analyze across every lens

For each candidate capture three things: the location (`file:line`, route, component, or selector) and what the markup or style actually produces, what it does now, and why that is a problem and how big its blast radius is. Do not score yet. Skip a conditional lens whose surface is absent (say so), and calibrate every lens to the paradigm from Phase 0. Respect the ownership map: emit each finding once.

**Accessibility and Inclusive Markup** (A11Y) - the dominant correctness and legal-exposure surface. *Owns whether the rendered UI is operable and understandable by assistive technology and keyboard users as written: programmatic names, roles and states, keyboard operability, focus management, and color-independence at the code level.*
- **Fake interactive elements:** a `div`/`span` with an `onClick` (or `@click`, `on:click`) that lacks `role`, `tabindex="0"`, and an Enter/Space `keydown` handler. All three missing is a keyboard lockout (WCAG 2.1.1, 4.1.2). Flag the cluster, not each instance, and prefer the native element fix.
- **Missing accessible names:** every button, link, and icon-only control has a name source (visible text, `aria-label`, `aria-labelledby`, or wrapping `<label>`); icon-only controls whose only child is an `<svg>`/icon with no label are flagged (WCAG 4.1.2, 1.1.1).
- **Form labeling:** every `input`/`select`/`textarea` has a programmatic label via `for`/`id`, a wrapping `<label>`, `aria-label`, or `aria-labelledby`; placeholder-only fields and **title-attribute-only or hover-tooltip-only labels** are flagged (a placeholder is not a label, and `title`/tooltip text is unreachable by touch and many AT setups; WCAG 1.3.1, 3.3.2, 4.1.2); related controls use `fieldset`/`legend` or `role="group"` with a name.
- **Input purpose:** the correct semantic input type (`email`/`tel`/`url`/`number`/`search` rather than a bare `type="text"`), `autocomplete` tokens on identifiable fields (WCAG 1.3.5), and `inputmode` for the right mobile keyboard. A field labeled Email rendered as `type="text"` with no `autocomplete="email"` is a defect.
- **Image and media alternatives:** every `img`/framework image has an `alt` attribute present (missing `alt` is not empty `alt`); informative images with `alt=""` are flagged; image-role SVGs carry `role="img"` + a name while decorative ones are `aria-hidden`; load-bearing audio/video has captions, a transcript, or a text alternative (WCAG 1.1.1, 1.2.x).
- **ARIA validity and the four rules:** invalid or misspelled roles; redundant roles on native elements (`role="button"` on a `<button>`); widget roles missing their mandatory states (`role="tab"` without `aria-selected`/`aria-controls`, `role="checkbox"` without `aria-checked`); ID references (`aria-labelledby`, `aria-controls`, `aria-describedby`) that do not resolve; `aria-hidden="true"` on or wrapping a focusable element (stripped from the tree but still tab-reachable). No ARIA is better than bad ARIA.
- **Keyboard operability and tab order:** positive `tabindex` (`> 0`) anywhere; custom widgets implementing the APG keyboard model (arrow keys, Home/End, Escape) rather than mouse-only handlers; a skip link as the first focusable element; `overflow:auto`/`scroll` regions with no focusable child and no `tabindex="0"` (keyboard-unreachable); native `disabled` used where the control's purpose must stay discoverable (where `aria-disabled` plus intercepted activation is the correct pattern).
- **Focus management for overlays:** dialogs/drawers/popovers set initial focus on open, trap focus while open, restore focus to the trigger on close, and use `role="dialog"` + `aria-modal` or native `<dialog>`; SPA route changes move focus to the new view.
- **Focus visibility:** `outline:none`/`outline:0` or `box-shadow:none` on `:focus` with no compensating `:focus-visible` or alternative indicator, and global resets that kill focus styling (WCAG 2.4.7).
- **Motion and auto-updating content:** animations, transitions, and JS-driven motion gated by `prefers-reduced-motion` (WCAG 2.3.3); auto-advancing carousels/tickers, `marquee`, `<meta http-equiv="refresh">`, and auto-dismissing toasts that offer no pause/stop/extend control (WCAG 2.2.1, 2.2.2).
- **Color, contrast, and forced colors:** meaning conveyed by color alone (an error shown only as red text, no icon or text); statically computable token pairs flagged as known-low (real pixel contrast is Suspected, verify with a contrast tool, WCAG 1.4.1/1.4.3); forced-colors / Windows High Contrast handling, including borders/outlines or background-image-only icons that vanish under `forced-colors`.
- **Status messaging and zoom:** form errors tied to the field via `aria-describedby` with `aria-invalid`, and `aria-live`/`role="status"` regions present where the code programmatically updates status text (toasts, validation, async results); `<html lang>` set; the viewport meta does not block zoom.
- Paper controls to hunt: an `aria-label` that does not contain the visible text (breaks voice control, WCAG 2.5.3); `alt="image"`/`alt="icon"`/filename-as-alt; a `:focus-visible` ring defeated by a later global `outline:none`; an `aria-live` region nothing writes to; a focus trap with no Escape; a skip link that targets a missing id; a third-party `<iframe>` with no `title`; `aria-hidden` on the app root.

**Semantic HTML and Document Structure** (SEM) - *Owns the correctness and meaningfulness of the markup itself: the right element for the job, valid nesting, native controls over div-soup, and document/metadata structure, independent of whether AT can use it (that consequence is A11Y).*
- **Right element for the job:** native `button`/`a[href]`/`input`/`select`/`details`/`dialog` used instead of generic `div`/`span` reconstructions; `a` vs `button` chosen by navigation-vs-action; lists as `ul`/`ol`/`li`; tabular data as `table` with `th`/`scope`, not a grid of `div`s.
- **Heading and landmark structure:** one `h1` per page/route, no skipped levels, headings used for structure not font size; a single `main`, plus `header`/`nav`/`footer` (or role equivalents), with no content stranded outside a landmark and repeated `nav`s distinguished by name.
- **Valid nesting and structure:** no interactive element nested in another (`button` inside `a`), no block elements inside inline-only parents, no duplicate `id`s, `<li>` only inside list parents, `<td>`/`<th>` only inside tables.
- **Document shell and metadata:** `<title>`, `<meta charset>`, the viewport meta, and `<html lang>` present and correct (or set through the framework metadata API); favicon and web app manifest referenced; descriptive `<title>` per route. (SEO depth beyond document structure is out of scope.)
- **Native dialog and disclosure correctness:** a `<dialog>` opened with `showModal()` (top layer, `::backdrop`, modal semantics) rather than `show()`; `<details>`/`<summary>` used for disclosure instead of a div reimplementation; popovers using the platform popover where available.
- **Web Components semantics (when shadow DOM is present):** `<slot>` wiring with fallback content, slotted light-DOM content kept semantic, and custom elements not wrapping interactive content in non-semantic hosts.
- Paper controls to hunt: a `<table>` used purely for layout; a heading whose level is chosen for size; a `role="main"` on a second main alongside a real `<main>`; a `<dialog>` rendered always-open with `show()` and no modal behavior; a clickable card that is a `div` wrapping a real link plus four more click targets.

**Styling Architecture and CSS Correctness** (STYLE) - *Owns how styles are authored and whether they are correct and maintainable as code: the cascade and specificity model, dead and duplicated CSS, layout-primitive correctness, directionality hygiene, and runtime-style sanity. The system-level token/consistency story is DS; viewport adaptation is RESP.*
- **Cascade and specificity:** `!important` overuse and `!important` wars, ID selectors and deep descendant chains used for specificity, inline `style` overriding the system, and overrides that fight the framework or library. (`@layer`, modules, or scoped styles are the healthy patterns to credit.)
- **Dead and duplicated styles:** unused classes/selectors, duplicated declarations, and `@media` queries whose breakpoint can never match the element's own constraints (cascade-level analysis `codeauditor` does not do; dead JS/TS remains `codeauditor`).
- **Layout-primitive correctness:** Flexbox/Grid used where appropriate rather than float hacks and absolute-position scaffolding; magic-number offsets and fixed heights that clip content; brittle `100vh` on mobile; `z-index` magic numbers with no scale or `isolation`.
- **Directionality and logical properties:** physical `left`/`right`/`margin-left` where logical properties (`inline-start`, `margin-inline`) are needed for RTL safety, and hardcoded directional assumptions (deep RTL formatting and mirroring is I18N when active; the CSS hygiene is owned here).
- **Animation and runtime-style hygiene:** animating layout-triggering properties (`width`, `top`, `margin`) instead of `transform`/`opacity`; `will-change` overuse; CSS-in-JS that generates a new class per render (style thrash) or constructs styles in the render path.
- **Print and conditional styles (when document/report surfaces exist):** absent or broken `@media print`, missing `break-inside`/page-break control, and `print-color-adjust` where a report or invoice UI needs it.
- Paper controls to hunt: a `:focus-visible` rule overridden by a later more-specific selector; a "reset" that strips list and focus semantics globally; a utility class duplicated by an inline style that wins; a `z-index: 99999` stack with no ordering; an `@media (min-width: 600px)` guarding content whose container is fixed at 800px.

**Component Implementation and UI State** (COMP) - *Owns the correctness of UI behavior as built in component code: every interaction state is rendered, controlled/uncontrolled and event wiring is correct, and lists/keys/effects do not produce visible UI bugs. Pure non-visual code quality is `codeauditor`; the security of any sink is `secauditor`.*
- **The state matrix:** components that fetch or mutate render loading, empty, error, and success states; flag a state branch the code begins to handle (a declared `isLoading`/`isEmpty`/`error`) but never renders, a control whose `disabled`/`active`/`selected` styling is wired in some instances and missing in others, or a data view that can only paint the happy path because no other branch exists.
- **Controlled-input correctness:** a controlled input (`value` set) with no `onChange` (frozen, uncompletable); `value` and `defaultValue` both set; a form `submit` that reloads the page and loses input; validation state that has no rendered surface.
- **List keys:** array index used as a React/Vue/Svelte key on a reorderable or filterable list (state attaches to the wrong row on reorder), or a missing key warning pattern; a visible remount that drops local state.
- **Rendering artifacts (cite the symptom):** a hydration mismatch that paints different SSR vs client markup; a layout flash from conditional rendering before data resolves; a remount that loses scroll or input. Claim these only when the defect is observably a rendered artifact; the abstract effect/leak/stale-closure bug is `codeauditor`.
- **Overlays and portals:** modals/menus rendered inline where a portal is needed (clipped by `overflow:hidden` or stacked under a sibling), and `z-index`/portal stacking that hides interactive content.
- **Error boundaries:** a tree of data-driven components with no error boundary, so one render throw blanks the whole view.
- **Hydration strategy (SSR/islands):** an Astro island with `client:load` on below-the-fold content where `client:visible`/`idle` fits, an interactive island shipped with no client directive (renders as dead controls), or a `use client` boundary placed at a route root that opts the whole subtree out of server rendering.
- Paper controls to hunt: a spinner that is shown but never tied to a real pending state (spins forever); an empty state that renders a bare blank; an error toast wired to a `catch` that never sets the state it reads; a `key={index}` on a list with add/remove.

**Responsive and Adaptive Layout** (RESP) - *Owns whether the UI adapts correctly across viewports and conditions as written: viewport setup, fluid/responsive technique, breakpoint coherence, and reflow without overflow. The per-rule CSS correctness is STYLE; native-platform adaptation is NATIVE.*
- **Viewport and reflow:** the viewport meta present and not blocking zoom (the zoom-block itself is an A11Y finding); content reflows to a single column with no horizontal scroll at 320 CSS px and at 400% zoom (WCAG 1.4.10).
- **Fixed vs fluid:** fixed pixel widths/heights on containers that should be fluid, `width: 1200px` instead of `max-width` + fluid, fixed-position elements that cover content on short viewports, and `100vw` overflow from scrollbar math.
- **Breakpoint coherence:** breakpoints that conflict or leave a gap (a layout that breaks between two declared breakpoints), `@media` breakpoints below the content's own min-width, and a desktop-first cascade that never resets for small screens.
- **Layout-shift reservation:** images, iframes, embeds, and ad/late-injected slots without `width`/`height` or `aspect-ratio`, so layout shifts when they load (PERF cross-references the CLS framing; RESP owns the missing reservation).
- **Pointer and target adaptation:** hover-only affordances (a menu that opens on `:hover` with no focus/click/touch equivalent), interactive targets below 24x24 CSS px with no spacing exception (WCAG 2.5.8), and drag-only interactions with no click/keyboard alternative (WCAG 2.5.7).
- **Robustness:** relative units (`rem`/`em`) where fixed `px` would break text resize (WCAG 1.4.4), `text-spacing` overrides that clip, container queries vs media queries used appropriately, and safe-area insets on notched devices.
- Paper controls to hunt: a responsive grid whose children have a fixed `min-width` larger than the mobile breakpoint (overflows anyway); a `@media` block that restyles a parent but not the overflowing child; a "mobile menu" that is only `display:none` on the desktop nav with no actual small-screen layout.

**Frontend Performance and Loading** (PERF) - *Owns the code-level risk factors for load and interaction performance, framed as Core Web Vitals (LCP, CLS, INP) risks readable from source. The numeric verdict needs a Lighthouse/CrUX run and is always Suspected.*
- **LCP risk:** the likely largest-contentful element (hero image, headline block) not prioritized (no `fetchpriority="high"`/`priority`, lazy-loaded above the fold), render-blocking CSS/JS in the head, and web fonts blocking first paint with no `font-display` or preload.
- **CLS risk:** images/iframes/embeds with no dimensions (RESP owns the reservation; PERF frames the CLS), late-injected banners/ads, and fonts that swap with a large metric mismatch (FOIT/FOUT) and no fallback metrics.
- **INP and main-thread risk:** heavy synchronous work in event handlers, long unvirtualized lists rendering thousands of nodes, expensive synchronous layout in scroll/resize handlers, and unmemoized expensive renders on the interaction path.
- **Render-path code-splitting:** a heavy library or component sitting on the LCP path, blocking first paint, or eagerly imported into a route chunk that defers below-the-fold work; no `loading="lazy"` on below-the-fold images. (Generic bundle weight, duplicate libs, and tree-shaking are `codeauditor`; PERF owns only the render-path linkage.)
- **Eager work:** above-the-fold data and assets fetched eagerly when they could stream or defer, and per-route code that ships globally.
- Paper controls to hunt: a `loading="lazy"` on the LCP hero image (delays the most important paint); a `next/image`/responsive-image setup bypassed by a raw `<img>` on the biggest asset; a route-root `"use client"` that ships the whole page as a client bundle; a "lazy" route whose component is still statically imported at the top.

**Design System Consistency and Theming** (DS) - *Owns whether the UI is built consistently against a single source of truth: design tokens, shared components, spacing/type/color scales, and theme/dark-mode wiring. The per-rule CSS mechanics are STYLE; whether the visual hierarchy serves the user is `uxauditor`.*
- **Token adherence:** raw hex/rgb, arbitrary `px` spacing, and one-off font sizes hardcoded where a token, theme value, or Tailwind scale exists; arbitrary Tailwind values (`w-[327px]`, `text-[#3a3a3a]`) bypassing the configured scale.
- **Component reuse:** one-off components or markup re-implementing a primitive the system already provides (a hand-rolled button next to the library `Button`), and variant sprawl (five near-identical card components).
- **Scale consistency:** spacing, type, and radius values off the defined scale; inconsistent breakpoints or color usage across surfaces.
- **Theming and dark mode:** hardcoded colors that break under a theme switch, missing `color-scheme`, tokens not actually swapped in the dark theme, and a theme provider that some subtrees bypass.
- **Token plumbing under shadow DOM (when present):** custom elements relying on global CSS variables that never cross the shadow boundary, so the tokens are inert inside the component.
- Paper controls to hunt: a `tokens.json`/`theme.ts`/`:root` token set declared while components hardcode the literal next to it (the token is decorative); a dark-theme class toggled but half the colors hardcoded so dark mode is half-broken; a design-system `Button` imported but restyled inline per use.

**Assets, Media, Icons and Fonts** (ASSET) - *Owns the correctness and weight of the UI's static media as authored or referenced: image formats and dimensions, SVG/icon strategy, font loading, and favicon/app-icon/manifest assets. The performance consequence is PERF; the alt-text/AT meaning is A11Y.*
- **Images:** raster assets in heavy/legacy formats where modern formats fit, intrinsically huge images served at small sizes, no `srcset`/`sizes` for responsive serving, and broken or wrong-path asset references.
- **SVG and icons:** an entire icon library imported to use a handful of glyphs (per-icon imports or sprites are the fix); inline SVGs duplicated across components instead of a shared sprite/component; unoptimized SVG (editor cruft, embedded rasters).
- **Fonts:** self-hosted vs third-party tradeoff, missing `font-display`, no `preload` for a critical font, full family weights shipped where a subset is used, and variable-vs-static font choice.
- **Favicon, app icons, manifest:** missing favicon, incomplete app-icon set, an absent or malformed web app manifest where installability is intended.
- **Iframes and embeds:** a third-party `<iframe>` missing `title` (A11Y cross-reference), `sandbox`/`allow`, and `loading="lazy"`.
- Paper controls to hunt: a "logo.svg" that is a 2 MB embedded PNG; a favicon link to a missing file; a font preloaded but never used, or used but not preloaded; an icon component that imports the whole set per call site.

**Internationalization and Localization Readiness** (I18N) - *conditional; activate when an i18n runtime/message catalog is present or the project declares a multi-locale or RTL requirement. Owns whether the UI implementation is built to be localized correctly: externalized strings, locale-aware formatting, directionality, and translation-safe layout. The quality and tone of the source copy is `uxauditor`.*
- **String externalization:** user-facing strings hardcoded in markup instead of the message catalog, and strings assembled by concatenation (`"You have " + n + " items"`) that cannot translate or pluralize correctly.
- **Locale-aware formatting:** dates, numbers, and currency formatted by hand or with a fixed locale rather than `Intl.DateTimeFormat`/`NumberFormat`/`RelativeTimeFormat`, and pluralization done with `if (n === 1)` instead of `Intl.PluralRules`/ICU MessageFormat.
- **Directionality:** `dir` not set or not derived from the locale, physical CSS properties that do not mirror (STYLE owns the CSS hygiene; I18N owns the locale-driven correctness), and icons/chevrons that should mirror in RTL but do not.
- **Translation-safe layout:** fixed-width buttons and containers that clip expanded translations (German/Finnish run long), truncation that assumes English length, and text baked into images.
- **Language semantics:** `lang` on the root and on language-switched fragments (WCAG 3.1.1/3.1.2), and `alt`/`aria-label` text that is itself hardcoded and untranslated.
- Paper controls to hunt: a translation library installed while half the screens hardcode English; a locale switcher that changes strings but never `dir` or number formatting; a pluralization helper that handles only one and many (breaks for languages with more plural forms).

**Native and Cross-Platform UI Implementation** (NATIVE) - *conditional; activate when React Native / Expo / react-native-web or another native-mobile UI toolkit is detected. Owns the implementation concerns unique to native/cross-platform UI that web-oriented dimensions do not cover.*
- **Native primitives and styling:** semantic components (`Pressable`/`Button`/`TextInput`) rather than tap-handler `View`s; the platform `StyleSheet`/styling model used correctly; web-only assumptions (`div`, CSS hover, `px` units) not leaking into native.
- **Native accessibility:** `accessibilityLabel`, `accessibilityRole`, `accessibilityState`, and `accessible` set on custom controls; touch targets meeting platform minimums; focus and announcement handled with the native APIs.
- **List and scroll performance:** long lists using `FlatList`/`SectionList` (or equivalent virtualization) with stable `keyExtractor` rather than mapping into a `ScrollView`.
- **Platform divergence and safe areas:** `Platform.select`/`.ios`/`.android` branches where behavior genuinely differs, `SafeAreaView`/insets for notches and home indicators, and gesture handling that does not trap the system back gesture.
- **Cross-platform (react-native-web):** styles and components that resolve on both native and web without one silently breaking.
- Paper controls to hunt: a `TouchableOpacity` wrapping a `View` with no `accessibilityRole`/label; a `.map()` rendering hundreds of rows inside a `ScrollView`; a hardcoded status-bar offset instead of safe-area insets; a hover style that is dead on touch.

### Phase 3 - Verify adversarially and cluster

- For each candidate, try to refute it: is there a visually-hidden label, a native element already doing the job, a keyboard handler in a parent, a `:focus-visible` rule elsewhere, a token applied higher up the tree, a framework default, or a documented deliberate choice that neutralizes it? Is the surface actually load-bearing or a hidden/debug screen? Adjust or drop.
- Assign Severity, Confidence, and Effort (definitions below).
- Default to caution: if you could not confirm the rendered output, the real contrast, the runtime focus order, or the live performance by reading the code, mark it Suspected and say what would confirm it (an axe/Lighthouse scan, a keyboard walkthrough, a contrast check, a render at a given width).
- Cluster repeated instances of one root problem into a single systemic finding, keeping the instance IDs as members, and apply the ownership map so a single defect does not fire under three dimensions.

### Phase 4 - Score

First decide which dimensions are **active** vs **N/A** based on the surfaces found in Phase 0. Score each active dimension 0-100 on how adequate the implementation is for that lens (justified by its findings). The overall score is the weighted average of the active dimensions after conditional re-normalization.

| Dimension | Weight | Applies |
|---|---|---|
| Accessibility and Inclusive Markup (A11Y) | 22% | always |
| Semantic HTML and Document Structure (SEM) | 14% | always |
| Styling Architecture and CSS Correctness (STYLE) | 13% | always |
| Component Implementation and UI State (COMP) | 13% | always |
| Responsive and Adaptive Layout (RESP) | 12% | always |
| Frontend Performance and Loading (PERF) | 11% | always |
| Design System Consistency and Theming (DS) | 9% | always |
| Assets, Media, Icons and Fonts (ASSET) | 6% | always |
| Internationalization and Localization Readiness (I18N) | 8% (nominal) | if an i18n runtime, message catalog, or RTL/multi-locale requirement exists |
| Native and Cross-Platform UI Implementation (NATIVE) | 9% (nominal) | if React Native or another native-mobile UI toolkit exists |

The eight always-on dimensions sum to exactly 100. The two conditional dimensions carry nominal weights that sit outside the always-on pool. **Conditional re-normalization** works like `llmauditor`'s RAG/AGENT handling: when a conditional dimension is N/A, drop it entirely (do not zero-and-keep, which would deflate the score), and the always-on table already sums to 100, so nothing changes. When a conditional dimension is active, add its nominal weight and proportionally re-normalize all active dimensions so the total returns to 100 (with only I18N active, the raw total is 108, so multiply every active weight by 100/108; with both I18N and NATIVE active, multiply by 100/117). Accessibility stays the highest-weighted dimension under every combination. Report which dimensions were active vs N/A and show the re-normalized weights so the score is reproducible. Renormalized weights are displayed to one decimal and may not re-sum to exactly 100.0 due to rounding; the overall is computed from full-precision weights, and the displayed values are for reproducibility only.

Score bands (per dimension and overall): 90-100 = A (exemplary), 80-89 = B (solid, minor issues), 70-79 = C (adequate, real gaps), 60-69 = D (weak, systemic problems), 0-59 = F (failing, critical deficiencies).

**Risk does not average away.** A single Critical finding caps its owning dimension at 69 and caps the overall at 79 until resolved, independent of the weighted math. Two or more Critical findings (in any one dimension or across dimensions) cap the overall at 69 (D), not 79, and hold each multi-Critical dimension in the F band (0-59). Caps are applied after the weighted average; when multiple caps apply, take the lowest; dimension caps and the overall cap are computed independently. A finding marked Suspected (its severity depends on a runtime fact static code cannot confirm, such as real pixel contrast, actual CWV numbers, or runtime focus order) does not trigger a cap until confirmed; route it to "Verify first" instead.

**Accessibility floor.** Because accessibility is both the dominant correctness surface and the primary legal-exposure surface, any Critical owned by A11Y (or the A11Y side of a split) caps the overall at 69 (D), one band below the generic single-Critical cap of 79, so a beautiful, fast, perfectly tokenized interface that locks out keyboard or screen-reader users on a core flow cannot score in the A/B/C range. The following are **Critical regardless of the numeric score**:
- A keyboard-only user is locked out of a load-bearing control or flow: an interactive element operable by mouse/touch only, or a custom widget with no keyboard path (WCAG 2.1.1). [A11Y]
- A core interactive control has no accessible name at all (icon-only button/link/input with no label), making it unusable to screen-reader users on a primary task (WCAG 4.1.2 / 1.1.1 / 3.3.2). [A11Y]
- A modal/menu/combobox traps focus with no keyboard escape, or a non-dismissable overlay blocks the entire page with no keyboard or visible close affordance (WCAG 2.1.2). [A11Y/COMP]
- Zoom is disabled on a responsive surface (`user-scalable=no` or `maximum-scale=1`), blocking low-vision users (WCAG 1.4.4). [A11Y, RESP cross-reference]
- Load-bearing audio or video ships with no captions, transcript, or text alternative (WCAG 1.2.1/1.2.2/1.2.3). [ASSET, A11Y cross-reference, routed to the A11Y floor]
- An accessibility "control" is pure theater on a load-bearing surface: a focus-visible style, live region, focus trap, or skip link present in code but never wired, so the protection is announced but absent. [A11Y]
- Content cannot reflow and forces horizontal scrolling at 320 CSS px because of fixed-width layout, breaking small-screen and 400%-zoom use (WCAG 1.4.10). [RESP]
- A form on a load-bearing flow is broken at the implementation level: a controlled input with no `onChange` (frozen), or a submit that reloads and loses all input. [COMP]

### Phase 5 - Prioritize

Definitions:
- **Severity** - Critical (a keyboard/screen-reader lockout, a reflow or zoom failure, a broken load-bearing form, or theater on a core surface; act immediately) / High (a serious accessibility, correctness, responsive, or performance defect on a reachable or load-bearing surface; act this cycle) / Medium (a real weakness with preconditions or on a lower-value surface; schedule it) / Low (a minor best-practice or hygiene gap; batch it).
- **Confidence** - Confirmed (the defect is reproducible from the cited markup/style) / Likely (strong evidence resting on a stated assumption about the rendered surface or its reach) / Suspected (inferred without confirming the rendered output, real contrast, runtime focus order, or live performance; verify before acting, often needs a scan, a keyboard pass, a contrast check, or a render at a given width).
- **Effort** - S (a localized markup/attribute/selector change, under ~1 hour: add a label, set `width`/`height`, swap a `div` for a `button`) / M (a few files: a focus-managed dialog, a state-matrix pass on a view, a token migration of one surface, ~half a day) / L (an architectural change: a design-system token migration, a keyboard-interaction model for a custom widget set, an i18n externalization pass, a responsive rebuild, multiple days).

Bucket every finding: **Quick wins** (High/Critical, Confirmed, S), **Plan now** (High/Critical, M or L), **Verify first** (any Suspected, especially anything whose severity depends on real contrast, runtime behavior, or a CWV measurement), **Backlog** (Low). Order the "What to fix first" list as the union of Quick wins and Plan now, Critical before High, breaking ties toward findings that also close a systemic pattern or sit on a load-bearing surface.

### Phase 6 - Write uiaudit.md

Write to `<codebase-root>/uiaudit.md` with these sections in order. Keep finding IDs stable using a dimension prefix and number: A11Y, SEM, STYLE, COMP, RESP, PERF, DS, ASSET, I18N, NATIVE (for example `A11Y-001`).

1. **Title and banner** - project name; a line stating this is a read-only UI-implementation audit of the code as written, the date, that the app was not run and no browser, scanner, or build was used, and that the report is self-contained.
2. **Snapshot** - project, state (commit or branch), framework and rendering model, styling model, design system/library, Web Components presence, i18n and native surfaces, the UI paradigm and maturity, size (routes, components, stylesheets), audit coverage (exhaustive or sampled, with what was sampled), and exclusions.
3. **UI surface map** - the half-page map from Phase 1: surfaces and load-bearing screens, the document shell and globals, the interactive inventory, the render-cost shape, the adaptation surface, and the highest-risk paths traced.
4. **Overall score** - `NN/100 - Grade X (label)`, a two-to-four sentence specific verdict, and a one-line calibration note (paradigm and maturity). Then a scorecard table: Dimension, Score, Grade, Weight (after re-normalization), Active/N-A, one-line specific verdict; final row is the weighted overall. State which conditional dimensions were dropped and how weights were re-normalized.
5. **What to fix first** - the ordered priority list. Each line: `[ID] title - severity, effort - one-line why`.
6. **Strengths (preserve these)** - what the UI gets right, each with evidence. The acting agent must not remove these while fixing other issues.
7. **Systemic patterns (root causes)** - one entry per recurring root cause (placeholder-as-label everywhere, no focus state on any custom control, raw hex instead of tokens, no loading/empty/error states, fixed pixel widths throughout), with the member finding IDs and the one root fix.
8. **Findings** - sorted by severity then dimension. Each finding is a self-contained block in this exact shape:

   ```
   ### [A11Y-001] <title>
   - Severity: <Critical/High/Medium/Low> | Confidence: <Confirmed/Likely/Suspected> | Effort: <S/M/L> | Dimension: <name> | Owner: <dimension or "this">
   - Location: `file:line` (element/control/selector/token/asset/route, and other locations)
   - Evidence: <what the markup or style produces now, precisely>
   - Impact: <the concrete consequence: keyboard lockout, missing name, layout shift, overflow, slow paint, inconsistent UI; and the blast radius / which surface>
   - Recommendation: <the specific change and the safe pattern in this project's framework and styling model; not a platitude>
   - Verify the fix: <a markup shape to inspect, a scan to run (axe/Lighthouse), a keyboard pass, a contrast check, a render at a width, or a count that should now be zero>
   - References: <WCAG 2.2 SC (e.g. 4.1.2), WAI-ARIA APG pattern, Core Web Vitals metric, or MDN/framework doc>
   - Related: <systemic pattern or finding IDs, or "none">
   ```

9. **Dimension notes** - one short subsection per active dimension tying the score to its findings, and a line for each N/A dimension saying why it was skipped.
10. **Remediation plan** - the four buckets (Quick wins, Plan now, Verify first, Backlog) listed by ID, with Plan now in suggested order.
11. **Scope and limitations** - what was and was not examined, sampling decisions, and which findings need a running app, a browser, an assistive-technology pass, or a Lighthouse/axe run to confirm; plus the assumptions (paradigm, maturity, reach) that would change conclusions if untrue.
12. **How to use this report (for the acting agent)** - include this protocol verbatim:
    1. Triage by severity and confidence. Confirmed Critical and High are safe to act on now, in the order in "What to fix first". Re-verify any Suspected finding (and the rendered behavior) before changing anything.
    2. Fix root causes first; prefer the systemic pattern (one accessible primitive, one token source, one state-matrix convention, one responsive layout primitive) over individual leaves.
    3. Preserve the strengths; do not remove a working label, focus style, token, or state branch while fixing another issue.
    4. Fix accessibility at the markup and the control, not by adding ARIA over a wrong element; prefer the native element and a real label over a `role` patch.
    5. One finding, one change, verified: after each fix run its "Verify the fix" step (a scan, a keyboard pass, a render); keep changes atomic and traceable to the finding ID.
    6. Do not widen scope silently; note adjacent issues rather than sprawling into a redesign (which is `uxauditor`'s and the team's call).
    7. Re-run the audit to measure progress; confirm findings are resolved, not relocated, and watch for regressions in the strengths.

### Phase 7 - Report in chat

After the file is written, print a concise summary to the chat so the user sees the result without opening the file. Include, in this order:
- One headline line: `UI implementation audit complete: NN/100 (Grade X)` followed by the one-line verdict.
- The scorecard table (active dimensions plus the weighted overall; note any N/A dimensions).
- "What to fix first": the top three to five items, each `[ID] title - severity, effort`.
- Counts: number of findings by severity (for example `Critical 2, High 6, Medium 9, Low 7`).
- The path to the full report: `Full report: ./uiaudit.md`.
Keep it tight. The file holds the detail; the chat holds the verdict and the next actions.

---

## Quality gates (self-check before declaring done)

- Every finding cites at least one `file:line` and names the element, control, selector, token, asset, or route. Run the substitution test on each title and impact line; rewrite anything that would read true for a different repo.
- Every finding states a concrete consequence and its blast radius (which surface, who hits it), not just the presence of a pattern.
- Each finding is emitted by exactly one dimension per the ownership map; the same defect (a `div` button, an undimensioned image, a hardcoded hex) does not appear and re-score under three lenses, and the artifact/root dimension owns it while the consequence dimension only cross-references.
- Claims are verified against the markup the code produces and the styles that apply, not a component name or a comment; a name-level "control" (an `<AccessibleX>` that is not) is reported as such.
- Paper controls were actively hunted, not just absences (an `aria-label` that mismatches visible text, a `:focus-visible` defeated in the cascade, a token declared but bypassed, a live region nothing writes to, a `loading="lazy"` on the LCP image, a `<dialog>` opened with `show()`).
- Every dimension score has a justification tied to specific findings, conditional re-normalization is shown, and the risk caps and the accessibility floor were applied.
- Every finding has Severity, Confidence, and Effort set, and a reference (WCAG 2.2 SC, ARIA APG pattern, Core Web Vitals metric, or MDN/framework doc).
- Every recommendation says what to change, the safe pattern in the project's own framework and styling model, and how to verify it (a scan, a keyboard pass, a contrast check, a render at a width, a count that should be zero). No platitudes.
- Repeated issues are clustered into systemic patterns; there are not many near-identical findings left loose.
- Suspected findings are clearly marked with what would confirm them (a scanner run, a browser, an AT pass, a contrast tool, a CWV measurement).
- The UI surface map and the Strengths section are present and evidence-backed; the paradigm and maturity calibration is stated.
- The report is at the codebase root, named exactly `uiaudit.md`, the app was not run, no browser/scanner/build was used, no source was changed, and the chat summary was printed.

## Notes

- Read-only and non-destructive. Use search and read tools to investigate, and shell commands only for inspection (listing files, counting components and stylesheets, reading manifests and config, checking version-control state). Do not run the application, start a dev server, open a browser, take screenshots, run a build or bundler, or execute an accessibility/performance scanner.
- Reason about the rendered UI, contrast, and performance from the code; never render it or measure a live system and never claim you did. Where a verdict depends on real pixels, runtime focus order, screen-reader output, or a Core Web Vital, mark it Suspected and say what would confirm it.
- Verify against the produced markup and the applied styles. A component name, a prop, and a comment state intent; the rendered element, the resolved class, and the actual attribute state reality. When they disagree, the gap is the finding.
- Calibrate to the paradigm, the stack, and the maturity. A static page is not held to a transactional SPA's bar; a Tailwind config is the token source, not its absence; a React Native screen is judged on native primitives, not semantic HTML. Spend the most effort on load-bearing surfaces, the accessibility of primary flows, and the render path of the landing page.
- Keep guidance standard-anchored: cite the WCAG 2.2 success criterion, the WAI-ARIA Authoring Practices pattern, or the Core Web Vitals metric that grounds the fix, and prefer the native element and a real label over an ARIA patch.
- For a large codebase, sample deliberately (the document shell and globals, the design-token and theme source, the primitive and form components, the custom interactive widgets, the largest assets, and the load-bearing routes) and declare exactly what you sampled.
- Cite the standard references where they help: WCAG 2.2 (W3C Recommendation) and its success criteria, the WAI-ARIA Authoring Practices Guide and ARIA-in-HTML, the Core Web Vitals guidance on web.dev (LCP, CLS, INP), MDN for HTML/CSS semantics and behavior, the ECMAScript Internationalization API (ECMA-402) for locale-aware formatting, and the project's own framework UI documentation (React, Vue, Svelte, Angular, Next.js, Astro, React Native), since many teams reference them directly. EN 301 549 and ADA/Section 508 frame the accessibility legal exposure used for calibration.
