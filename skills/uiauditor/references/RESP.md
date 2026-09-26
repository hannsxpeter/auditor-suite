# RESP: Responsive and Adaptive Layout

Weight 12. Always active.
Owns: whether the layout adapts as written: a viewport meta that is present, reflow at 320 CSS px, fixed versus fluid sizing, breakpoint gaps, space reserved for images and embeds, hover-only and drag-only interactions, target size, and text that survives resizing and re-spacing.
Not here: a viewport meta that blocks zoom (A11Y-R4); hover menus that keyboard users cannot open (A11Y-R1); per-rule CSS mechanics and `100vh` (STYLE-R3); impossible media queries (STYLE-R2); breakpoint values that differ across surfaces (DS Also check); the Core Web Vitals framing of layout shift (PERF; this dimension owns the missing reservation); native safe areas and touch targets (NATIVE-R4, NATIVE-R5).
Standards: WCAG 2.2 (1.4.4, 1.4.10, 1.4.12, 1.4.13, 2.5.7, 2.5.8), CSS Media Queries Level 4, CSS container queries, MDN.
Read first: the viewport meta in the document shell, the global layout and grid styles, the breakpoint config (Tailwind `screens` or Sass variables), and the widest components (tables, galleries, toolbars).

## Cards

### RESP-R1 Content cannot reflow at 320 CSS px (quick)
- Leads: `scan.sh RESP-R1` lists fixed widths and min-widths of 400px or more, wide fixed grid tracks, and large `minmax()` minimums.
- Confirm: a page container, grid, or component has a fixed `width` or `min-width` wider than 320 CSS px (`width: 1200px`, `min-w-[960px]`, `grid-template-columns: repeat(3, 300px)`, `minmax(400px, 1fr)`) and no media or container query removes it on small screens, so the page scrolls sideways at 320px and at 400% zoom.
- Not a finding if: the wide content needs two dimensions to be understood (data tables, maps, diagrams, editors) and scrolls inside its own container while the page reflows; the value is a `max-width`; a small-screen rule overrides it (read the media queries).
- Severity: Critical when a load-bearing page scrolls horizontally at 320 CSS px; High on secondary pages. Confirmed when the width is literal and unconditional; Likely when it depends on content length.
- Fix: fluid width with a cap (`width: 100%; max-width: 1200px`), `minmax(min(100%, 300px), 1fr)` for grid tracks, and an `overflow-x: auto` wrapper around wide tables.
- Verify the fix: render the page at 320 CSS px wide: the page has no horizontal scrollbar.
- Refs: WCAG 1.4.10

### RESP-R2 Viewport meta missing or wrong
- Leads: `scan.sh RESP-R2` lists viewport metas and framework viewport exports.
- Confirm: the served document has no `<meta name="viewport" content="width=device-width, initial-scale=1">` and no framework default adds one, so phones lay the page out about 980px wide and shrink it; or `width` is a fixed number.
- Not a finding if: the framework injects it (Next.js adds a default viewport; read the version).
- Severity: High on a public site (every page renders shrunken on phones); Low for a desktop-only internal tool whose README says so.
- Fix: add `<meta name="viewport" content="width=device-width, initial-scale=1">` to the document head.
- Verify the fix: the rendered head contains the meta; a phone renders the page at device width.
- Refs: MDN "Viewport meta tag"

### RESP-R3 Breakpoints that leave gaps or never adapt
- Leads: `scan.sh RESP-R3` lists media queries, container queries, and the breakpoint config.
- Confirm: a desktop-first layout has no rules for small screens; paired queries leave a gap or overlap (`max-width: 767px` with `min-width: 769px` leaves 768px unstyled); a query restyles a parent but not the child that overflows; a reusable component placed in containers of different widths is driven by viewport media queries where a container query fits.
- Not a finding if: the component is fluid without breakpoints (flex-wrap, auto-fit grids, `clamp()`).
- Severity: High when a load-bearing layout breaks inside a gap or never adapts; Medium otherwise.
- Fix: one breakpoint scale from the config; pair queries at the same value (`max-width: 767.98px` with `min-width: 768px`, or range syntax `width < 768px`); container queries for reusable components.
- Verify the fix: render the layout at each breakpoint and one pixel on each side of it.
- Refs: CSS Media Queries Level 4 (range syntax); CSS Containment Level 3 (container queries)

### RESP-R4 Images and embeds with no reserved space
- Leads: `scan.sh RESP-R4` lists images, iframes, videos, and embeds.
- Confirm: an image, iframe, video, embed, or ad slot in or near the first view has neither `width` and `height` attributes nor a CSS `aspect-ratio` or fixed-size container, so content jumps when it loads.
- Not a finding if: `width` and `height` attributes are set (browsers derive the aspect ratio from them even when CSS sets `width: 100%; height: auto`); the framework image component requires dimensions (`next/image` with `width` and `height`, or `fill` inside a sized parent); the element is absolutely positioned in a sized box.
- Severity: High for media in the first view of a load-bearing page (the page shifts under the user's tap); Medium below the fold; Low for small icons.
- Fix: set `width` and `height` to the intrinsic size, or `aspect-ratio: 16 / 9` on the container.
- Verify the fix: each listed element has dimensions or an aspect ratio; a Lighthouse run lists no media among the layout-shift culprits.
- Refs: Core Web Vitals CLS; web.dev "Optimize Cumulative Layout Shift"

### RESP-R5 Hover-only or drag-only interactions and small targets
- Leads: `scan.sh RESP-R5` lists hover selectors that reveal children, mouse-enter handlers, `group-hover` reveals, and drag-and-drop code.
- Confirm: content or actions appear only on `:hover` or `mouseenter`, with no tap path on touch screens; an operation works only by dragging (reordering, sliders, map panning) with no single-pointer alternative such as buttons; targets smaller than 24x24 CSS px without 24px of spacing to their neighbors.
- Not a finding if: the same content opens by tap (a click toggle, `:focus-within`, or a separate control); the target is a link inside a sentence; dragging is essential (freehand drawing).
- Severity: High when a load-bearing action is hover-only on touch or drag-only (2.5.7); Medium for targets under 24x24 CSS px on load-bearing controls (2.5.8); Low otherwise. When keyboard users cannot reach it either, file it under A11Y-R1 instead.
- Fix: toggle on click or tap as well as hover; put move-up and move-down buttons beside drag handles; pad small targets to 24x24 CSS px.
- Verify the fix: every action works with one tap and no hover on a touch device; target boxes measure at least 24x24 CSS px.
- Refs: WCAG 2.5.7 and 2.5.8 (both new in 2.2), 1.4.13

### RESP-R6 Text that clips when resized or re-spaced
- Leads: `scan.sh RESP-R6` lists fixed pixel heights and line clamps; read the root font size and type scale in the global stylesheet.
- Confirm: a container with a fixed pixel `height` and `overflow: hidden` (or a line clamp with no way to expand) holds text that grows at 200% text size or under the WCAG text-spacing overrides (line height 1.5, letter spacing 0.12em); or the root font size is set in px, which ignores the user's browser font-size setting.
- Not a finding if: the container uses `min-height` or grows with its content; the clamp has a "show more" control.
- Severity: High when clipping hides load-bearing text or controls; Medium for a px root font size on a public app; Low otherwise.
- Fix: `min-height` instead of `height`; `rem` for type and spacing; leave the root font size at 100%.
- Verify the fix: at a 200% browser font size with a text-spacing bookmarklet applied, no text is clipped.
- Refs: WCAG 1.4.4, 1.4.12

## Also check
- Fixed-position headers, footers, or banners that cover content on short viewports (phones in landscape).
- `100vw` widths that overflow by the scrollbar width on desktop.
- Fixed bars that ignore notches: no `viewport-fit=cover` with `env(safe-area-inset-*)` padding.
- Container queries where the viewport should drive the layout, or media queries where the component's own width should.

## Paper controls (look protective, protect nothing)
- A responsive grid whose children have a fixed `min-width` larger than the mobile breakpoint, so it overflows anyway.
- A `@media` block that restyles the parent but not the overflowing child.
- A "mobile menu" that is only `display: none` on the desktop nav, with no small-screen layout behind it.
