# SEM: Semantic HTML and Document Structure

Weight 14. Always active.
Owns: the markup itself: the right element for the job, headings and landmarks, valid nesting and unique ids, the document shell (`<html lang>`, `<title>`, charset), native dialog, disclosure, and popover use, lists and tables, and slots in Web Components.
Not here: a pointer-only control with no keyboard path (A11Y-R1); accessible names (A11Y-R2); a viewport meta that blocks zoom (A11Y-R4); a missing viewport meta (RESP-R2); favicon and manifest files (ASSET-R4); `lang` that must follow the active locale (I18N-R4); SEO metadata beyond the document shell (seoauditor); HTML sinks such as `dangerouslySetInnerHTML`, `v-html`, and `[innerHTML]` (secauditor: note one line in Scope and limitations, never score it).
Standards: HTML Living Standard (content models), WCAG 2.2 (1.3.1, 2.4.1, 2.4.2, 2.4.6, 3.1.1), ARIA in HTML.
Read first: the document shell or root layout, the page or route components, and the layout components (header, nav, footer).

## Cards

### SEM-R1 Generic element rebuilt as a control, or the wrong native element
- Leads: `scan.sh SEM-R1` lists `href="#"` and `javascript:` links, `role="button"`, anchors with click handlers, and buttons whose handler navigates.
- Confirm: a `div` or `span` rebuilt as a button or link with ARIA and key handlers; an `<a href="#">` or `javascript:` link that performs an action (Space does not activate it and it is announced as a link); a `<button>` whose handler only navigates (no URL to open in a new tab, copy, or bookmark); a clickable card `div` that wraps a real link plus other click targets.
- Not a finding if: no native element exists for the pattern (tabs, listbox, tree, grid) and it follows the APG pattern; the button submits a form that then redirects.
- Severity: Medium when a load-bearing action or navigation uses the wrong element; Low for complete ARIA rebuilds elsewhere.
- Fix: actions are `<button type="button">`; navigation is `<a href="/path">`; make a card clickable by stretching its one link (`::after` with `inset: 0`), not with a click handler on the card.
- Verify the fix: `scan.sh SEM-R1` lists no `href="#"` actions; navigation links open in a new tab.
- Refs: WCAG 4.1.2, 1.3.1; ARIA in HTML (first rule of ARIA use)

### SEM-R2 Heading and landmark structure that misleads navigation
- Leads: `scan.sh SEM-R2` lists `h1` elements, `main`, and landmark roles; read each route's headings in order.
- Confirm: a route has no `h1`, or its headings skip levels (h2 to h4); headings are picked for their size, or text is styled as a heading with no heading element; there is no `<main>`, or there are two; content sits outside every landmark; several `nav` elements have no `aria-label` to tell them apart.
- Not a finding if: the layout supplies the `h1` or `main` (read it); the heading level comes from a prop that the call sites set correctly.
- Severity: Medium on load-bearing routes (screen-reader users move by headings and landmarks); Low elsewhere. Several `h1` elements are not a failure by themselves; the HTML outline algorithm was never implemented, so an `h1` inside a `section` is still level 1.
- Fix: one `h1` per route that names the page, levels nested without gaps, one `main`, and an `aria-label` on each extra `nav`.
- Verify the fix: each route's heading list shows one `h1` and no skipped levels; the layout renders exactly one `main`.
- Refs: WCAG 1.3.1, 2.4.1, 2.4.6

### SEM-R3 Invalid nesting or duplicate ids
- Leads: `scan.sh SEM-R3` lists controls nested in controls and block elements inside phrasing-only parents on one line; read repeated components for hardcoded ids.
- Confirm: an interactive element inside another (`button` in `a`, `a` in `button`, an input in a `summary`); block content inside a phrasing-only parent (`div` in `p`, `button`, `label`, `span`, or a heading); `li` outside `ul`, `ol`, or `menu`; `td` or `th` outside a table row; the same `id` rendered twice on one view (a repeated component with a hardcoded id).
- Not a finding if: the parent is an `a` (its content model is transparent, so block content inside it is valid while nothing inside is interactive).
- Severity: High when the nesting or a duplicate id breaks a load-bearing control's label, name, or activation (the inner control is unreachable, or `for` and `aria-labelledby` point at the wrong element); Medium otherwise. WCAG 2.2 removed 4.1.1 Parsing, so cite the broken label or name (1.3.1, 4.1.2), not parsing.
- Fix: make nested controls siblings; generate ids per instance (`useId()` in React); change the parent or the child to a valid pair.
- Verify the fix: an HTML validator or axe run on the rendered view reports no nested-interactive or duplicate-id violations.
- Refs: HTML content models; WCAG 1.3.1, 4.1.2

### SEM-R4 Document shell missing lang, title, or charset
- Leads: `scan.sh SEM-R4` lists the `html` element, title tags, charset metas, and framework metadata APIs.
- Confirm: the served document has no `lang` on `<html>` (or an empty one); no `<meta charset>` within the first 1024 bytes; no `<title>`, or one title for every route of a multi-route app (route changes never update `document.title` or the framework metadata).
- Not a finding if: the framework sets these (Next.js `metadata` and the root layout's `<html lang>`, Nuxt `useHead`, SvelteKit `app.html`, the Angular `Title` service); read where.
- Severity: Medium when `lang` is missing (screen readers guess the voice) or every route shares one title on a public app; Low for a missing charset when the server sends one.
- Fix: `<html lang="en">` (from the active locale when I18N is active), `<meta charset="utf-8">` first in `<head>`, and a descriptive title per route (`Page name - Site`).
- Verify the fix: each route's rendered head has its own title; the root has a valid `lang`.
- Refs: WCAG 3.1.1, 2.4.2

### SEM-R5 Native dialog, disclosure, or popover used wrongly
- Leads: `scan.sh SEM-R5` lists `<dialog>`, `.show()` and `.showModal()` calls, `popover` attributes, `<details>`, and `aria-expanded` toggles.
- Confirm: a `<dialog>` used as a modal is opened with `show()` or rendered with the `open` attribute (no top layer, no `::backdrop`, the page behind stays usable, Escape does nothing); a `<dialog open>` that is always rendered; a disclosure rebuilt from divs where `<details>` and `<summary>` fit; a hand-built popover where the `popover` attribute fits the supported browsers (facts.md).
- Not a finding if: the dialog is non-modal on purpose (a toolbar or inline panel) and the page behind is meant to stay usable.
- Severity: High when a modal flow uses `show()` or `open`, so keyboard and screen-reader users reach the page behind it; Medium for rebuilt disclosures on load-bearing views; Low for hand-built popovers.
- Fix: open modals with `dialog.showModal()` and close them with `dialog.close()`; use `<details>` for show and hide; use `popover` and `popovertarget` for menus and tips when the supported browsers allow.
- Verify the fix: opening the modal makes the page behind inert (clicks and Tab do not reach it), and Escape closes it.
- Refs: HTML dialog element; WCAG 2.4.3, 4.1.2

### SEM-R6 Lists and tables without their semantics
- Leads: `scan.sh SEM-R6` lists tables, table, grid, and list roles, and `list-style: none` resets.
- Confirm: tabular data drawn as a `div` grid with no table or grid roles; a data `<table>` with no `<th>` (or `scope`) for its headers; a layout `<table>` without `role="presentation"`; a list of items rendered as sibling divs; a list styled with `list-style: none` (Safari with VoiceOver then drops the list role).
- Not a finding if: the list keeps `role="list"`; the layout table is marked `role="presentation"`.
- Severity: Medium when a data table on a load-bearing view has no header cells (cells are read without their column); Low otherwise.
- Fix: `table`, `thead`, and `th scope="col"`; `role="list"` on lists whose markers are removed.
- Verify the fix: each data table has header cells; each unstyled list has `role="list"`.
- Refs: WCAG 1.3.1

## Also check
- Web Components: `<slot>` wiring with fallback content, slotted light-DOM content that stays semantic, and custom elements that wrap interactive content in a host with no role.
- Data tables whose rows are clickable with no link or button in the row (file under SEM-R1; the keyboard lockout is A11Y-R1).

## Paper controls (look protective, protect nothing)
- A `<table>` used for layout with no `role="presentation"`.
- A heading level chosen for its font size.
- `role="main"` on a second main beside a real `<main>`.
- A `<dialog>` rendered always open with `show()` and no modal behavior.
- A clickable card that is a `div` wrapping a real link plus four more click targets.
