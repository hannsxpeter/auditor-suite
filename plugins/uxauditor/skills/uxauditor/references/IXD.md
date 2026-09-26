# IXD: Interaction and Visual Design

Weight 9. Always active.
Owns: visual hierarchy (one dominant primary action per screen, scannable headings, a type scale and spacing system), minimalist design and progressive disclosure, Gestalt grouping, affordances and signifiers, visible and distinct component states, consistency of shared patterns, and motion that serves the task.
Not here: whether a loading, empty, or error branch exists in code (uiauditor); feedback while an action runs (USE-R2); reduced motion (ACC); jank and layout shift (PRF); a decline option styled to be missed (TRU-R5); wording (CNT).
Standards: Gestalt principles (proximity, common region, similarity); Norman's affordances and signifiers; Fitts's Law; Hick's Law; Von Restorff effect; Nielsen heuristics 4 and 8.
Read first: the theme or design tokens, the shared button, link, card, and dialog components, and the screens of the core journeys.

## Cards

### IXD-R1 A core screen has no single primary action, or the destructive action looks primary
- Leads: `scan.sh IXD-R1` lists primary and danger button variants and classes.
- Confirm: a core screen renders two or more buttons in the primary style, or the primary style sits on a secondary or destructive action (Delete filled and prominent beside a plain Save), or the main action is a text link while a side action is a filled button.
- Not a finding if: the two primaries sit in separate regions with separate jobs (a page header action and a form submit) and the task stays clear.
- Severity: High when a destructive action carries the primary style on a core journey; Medium otherwise.
- Fix: one primary per view; the secondary style for alternatives; a distinct danger style, placed apart from the primary, for destructive actions.
- Verify the fix: each core screen renders exactly one primary variant; destructive actions use the danger variant.
- Refs: Von Restorff effect; Hick's Law; Nielsen heuristic 8

### IXD-R2 Interactive elements do not look interactive, or static elements look clickable
- Leads: `scan.sh IXD-R2` lists pointer cursors, removed underlines, and link and button utility classes.
- Confirm: a clickable element carries no signifier distinct from body text (no underline, color, border, or hover and focus change), or a non-interactive element is styled like a link or button (a badge shaped like a button, a heading styled as a link).
- Not a finding if: the pattern is a learned convention with a visible signifier (a whole card that lifts on hover and has a title link).
- Severity: Medium; High when the only way forward on a core step has no signifier.
- Fix: give links and buttons one consistent signifier product-wide; remove button styling from static elements.
- Verify the fix: every clickable element on the core screens shows a signifier at rest and on hover and focus.
- Refs: Norman (affordances and signifiers); Jakob's Law

### IXD-R3 Component states are missing or look alike
- Leads: `scan.sh IXD-R3` lists disabled, selected, active, and error style rules and attributes.
- Confirm: the theme or shared components give no visible difference between enabled and disabled, selected and unselected, or valid and error (read the rules for `:disabled`, `[aria-selected]`, `.is-error`), so users cannot tell which plan is chosen or why a button does nothing.
- Not a finding if: the design system's defaults provide the state (read the library theme); text also carries the state.
- Severity: Medium; High when users cannot tell which option is selected in a purchase or plan choice.
- Fix: define each state once in the shared component, with a visible difference beyond color.
- Verify the fix: render each state side by side in the component's story or test; each is distinct.
- Refs: Nielsen heuristic 1; WCAG 1.4.11 for the contrast of state indicators (the contrast line itself is uiauditor's)

### IXD-R4 The same pattern behaves differently from screen to screen
- Leads: `scan.sh IXD-R4` lists component definitions for modals, dialogs, date pickers, buttons, dropdowns, and toasts; look for more than one of a kind.
- Confirm: two or more implementations of one pattern behave differently: two modals with different close behavior, Cancel and Confirm swapping sides between dialogs, one icon meaning two things, two date pickers with different input rules.
- Not a finding if: one implementation wraps the other with the same behavior.
- Severity: Medium; Low when the difference is only visual.
- Fix: consolidate on one shared component and fix button order and icon meaning product-wide.
- Verify the fix: one implementation per pattern remains; dialogs share button order.
- Refs: Jakob's Law; Nielsen heuristic 4

### IXD-R5 Motion slows the task: long or blocking animation on frequent actions
- Leads: `scan.sh IXD-R5` lists transitions and animations of 500 ms or longer.
- Confirm: an animation on a frequent action (opening a menu, switching a tab, saving) runs longer than about 400 to 500 ms, or input is blocked until it finishes.
- Not a finding if: it plays once (a first-run illustration) or runs while input stays live.
- Severity: Low; Medium when it sits on the most frequent task.
- Fix: keep feedback motion to about 200 to 300 ms and never block input while it plays.
- Verify the fix: no transition on a frequent action exceeds 300 ms; the next click works during the animation.
- Refs: Doherty threshold; RAIL response budget

## Also check
- Type scale and spacing: one-off font sizes and margins per screen instead of a scale; headings that do not make the page scannable.
- Gestalt grouping: a label nearer the neighboring field than its own; related controls split across regions; unrelated actions boxed together (a destructive and a routine action in one group).
- Minimalist design: clutter that competes with the task; advanced options shown to everyone instead of disclosed progressively.
- Mapping: controls whose direction or icon does not match the effect (a toggle that reads on when off, a slider that runs backwards).
- Microinteractions: feedback that acknowledges an action within the response budget without getting in the way.

## Paper controls (look protective, protect nothing)
- A disabled style defined in the theme but never applied, because components pass `disabled` to a `div`.
- A design-system primary token overridden per screen, so every button is primary.
- A hover-only signifier on a touch interface.
