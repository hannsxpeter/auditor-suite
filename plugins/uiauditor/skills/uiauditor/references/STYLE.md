# STYLE: Styling Architecture and CSS Correctness

Weight 13. Always active.
Owns: how styles are written and whether they are correct: the cascade and specificity, dead and duplicated CSS, layout primitives (flex and grid versus float and absolute scaffolding, fixed heights, `100vh`, z-index), physical versus logical properties, animation and runtime-style cost, print styles, and shadow DOM styling hooks.
Not here: a removed focus indicator, even when the cascade is what defeats it (A11Y-R6); literals used instead of tokens (DS-R1); breakpoints that leave content overflowing (RESP-R1, RESP-R3); component or styled-component types created during render (COMP-R4); reduced-motion handling (A11Y Also check); dead JS or TS (codeauditor).
Standards: CSS Cascading and Inheritance Level 5 (cascade layers), CSS Logical Properties and Values, CSS Values 4 (viewport units), MDN.
Read first: the global stylesheet and reset, the Tailwind or CSS-in-JS config, and the stylesheets of the primitive components.

## Cards

### STYLE-R1 Specificity fights: !important, ID selectors, and inline overrides
- Leads: `scan.sh STYLE-R1` lists `!important`, ID selectors that start a rule, and inline `style` attributes.
- Confirm: `!important` used to beat the project's own rules (count them); selectors chained or ID-based to win (`#app .page .card .title`); inline `style` that overrides the system's classes; overrides that fight a library's classes with higher specificity.
- Not a finding if: `!important` sits in a utility on purpose (a single Tailwind important modifier, a `.sr-only` helper, a reduced-motion override); the project orders the cascade with `@layer`, CSS Modules, or scoped styles (credit it under Strengths).
- Severity: Medium when an override blocks a state style (hover, disabled, selected) or the theme on a load-bearing component; Low otherwise.
- Fix: order styles with `@layer reset, base, components, utilities`; reduce selectors to one class; replace inline overrides with a variant.
- Verify the fix: the count of `!important` outside utilities falls; the state style shows in the computed styles.
- Refs: CSS Cascading and Inheritance Level 5 (cascade layers); MDN Specificity

### STYLE-R2 Dead, duplicated, or never-matching CSS
- Leads: `scan.sh STYLE-R2` lists compound media queries; search the markup for each class of the global stylesheets.
- Confirm: selectors that match nothing in the markup or templates (search for the class); declarations repeated in the same rule or file; a media or container query whose conditions can never all be true (`(min-width: 800px) and (max-width: 600px)`), or one that a later unconditional rule always overrides.
- Not a finding if: classes are built at runtime (`btn-${variant}`), set by a CMS or a library, or used by server templates you did not read (say so in Scope and limitations).
- Severity: Medium when dead or overridden rules hide a state or a fix the team believes is live; Low otherwise.
- Fix: delete dead rules, merge duplicates, and rewrite the impossible query.
- Verify the fix: a search for each removed selector finds no use; the stylesheet shrinks.
- Refs: MDN Using media queries

### STYLE-R3 Brittle layout primitives
- Leads: `scan.sh STYLE-R3` lists `100vh`, `h-screen`, floats, and large z-index values.
- Confirm: layout built from floats or absolute positioning where flex or grid fits; magic-number offsets and fixed heights on text containers that clip content (`height: 48px; overflow: hidden`); `100vh` on a mobile layout (the browser toolbar hides its bottom); z-index values with no scale (`z-index: 99999`) or stacking fights with no `isolation: isolate`.
- Not a finding if: the fixed height is on media or decoration; `100vh` is followed by a `100dvh` or `100svh` value for supporting browsers.
- Severity: High when clipping or `100vh` hides a load-bearing control (a submit button below a fixed-height panel on phones); Medium for z-index fights that hide menus behind content; Low for float scaffolding.
- Fix: flex or grid for layout; `min-height` instead of `height` on text containers; `100dvh` with `100vh` as a fallback; a z-index scale kept as tokens.
- Verify the fix: at 360x640 with the browser toolbar shown, the panel's controls are visible; z-index values come from the scale.
- Refs: CSS Values 4 (dvh, svh); MDN Stacking context

### STYLE-R4 Physical direction properties where logical ones are needed
- Leads: `scan.sh STYLE-R4` lists `margin-left`, `padding-right`, left and right borders, floats, and `text-align: left` or `right`. In Tailwind, `ml-`, `mr-`, `pl-`, `pr-`, `left-`, and `right-` are the physical forms; `ms-`, `me-`, `ps-`, `pe-`, `start-`, and `end-` are logical.
- Confirm: spacing, offsets, borders, or alignment use physical left and right where the meaning is the start or end of the line of text.
- Not a finding if: the direction is truly physical (a shadow offset, a chart axis, an icon that must not mirror).
- Severity: Medium when an RTL locale is supported or planned (I18N active); Low otherwise.
- Fix: `margin-inline-start`, `padding-inline`, `inset-inline-start`, `text-align: start`, or the Tailwind logical utilities.
- Verify the fix: with `dir="rtl"` on the root, the layout mirrors.
- Refs: CSS Logical Properties and Values

### STYLE-R5 Animation of layout properties and runtime style churn
- Leads: `scan.sh STYLE-R5` lists transitions of layout properties, `transition: all`, and `will-change`.
- Confirm: transitions or keyframes animate `width`, `height`, `top`, `left`, `margin`, or `padding` (every frame re-lays out the page) instead of `transform` and `opacity`; `transition: all` on elements whose layout changes; `will-change` on many elements or left on permanently; CSS-in-JS that creates a new class for each render or value (a `css` prop fed a value that changes per frame or per keystroke).
- Not a finding if: the animated element is small and isolated (`contain: layout`) or the animation runs once on load.
- Severity: Medium when the animation runs on a load-bearing interaction (menus, drawers, list reordering); Low otherwise.
- Fix: animate `transform` and `opacity`; name the transitioned properties; pass changing values through a CSS variable on the element (`style={{ '--progress': p }}`).
- Verify the fix: transitions name only transform and opacity; a performance profile of the interaction shows no layout work per frame.
- Refs: CSS Transitions; web.dev "Stick to compositor-only properties"

## Also check
- Print: invoices, receipts, tickets, and reports with no `@media print`, no `break-inside: avoid` on rows, or backgrounds that vanish without `print-color-adjust: exact` (Medium when users are expected to print them).
- Shadow DOM styling: components styled only through global classes that cannot reach inside a shadow root, and no `:host`, `::part()`, or `::slotted()` hooks for theming (token delivery is DS-R4).
- A global reset that strips list markers and focus styles (the focus loss is A11Y-R6; the lost list role is SEM-R6).

## Paper controls (look protective, protect nothing)
- A `@layer` order declared while the reset stays outside every layer: unlayered styles beat all layered ones, so the reset overrides the layers it was meant to sit under.
- A utility class duplicated by an inline style that always wins.
- `z-index: 99999` stacks with no ordering scale.
- An `@media (min-width: 600px)` block guarding content whose container is fixed at 800px.
