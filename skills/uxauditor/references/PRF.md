# PRF: Performance and Responsiveness

Weight 6. Always active.
Owns: how fast and stable the core screens feel, judged from code-level risk factors for Core Web Vitals (LCP, INP, CLS): request waterfalls, missing skeletons, layout shift under the pointer, long tasks on input, and the mobile layout (viewport, horizontal scroll, reflow, hover-only actions).
Not here: bundle size and dependency weight (codeauditor and uiauditor); the pending state of a single action (USE-R2); zoom blocking and touch-target size (ACC); animation length (IXD-R5).
Standards: Core Web Vitals thresholds and the RAIL budget in references/facts.md; Doherty threshold; WCAG 1.4.10 reflow.
Read first: the document head and root layout, the data loading of the core screens, the image and embed components, and the global CSS for widths and breakpoints.

Never state a metric value from static code. Name the code-level risk, mark the finding Likely or Suspected, and put the Lighthouse, WebPageTest, or CrUX check in Verify the fix.

## Cards

### PRF-R1 A core screen waits on a chain of requests before showing anything
- Leads: `scan.sh PRF-R1` lists awaited fetches and full-screen loading returns.
- Confirm: a core screen renders nothing or a full-page spinner until several requests finish one after another (a child fetches after its parent's fetch resolves, or awaits run in series that could run in parallel), and no skeleton or partial content shows meanwhile.
- Not a finding if: the requests run in parallel (`Promise.all`, a route loader), the data is server-rendered, or a skeleton that matches the final layout shows while loading.
- Severity: Medium; High on the first screen after sign-in or in checkout.
- Fix: fetch in parallel, move loading into the route loader or the server, and show a skeleton that matches the final layout.
- Verify the fix: a Lighthouse or WebPageTest trace of the screen shows one round of parallel requests; field LCP at the 75th percentile is 2.5 s or less.
- Refs: Core Web Vitals (LCP); RAIL

### PRF-R2 Late content shifts the layout under the user's pointer
- Leads: `scan.sh PRF-R2` lists images, iframes, videos, and embeds; check each for width and height or aspect-ratio.
- Confirm: media on a core screen has no `width` and `height` or `aspect-ratio`, or a banner, cookie bar, or promo is inserted above existing content after load with no reserved space, so buttons move as the user reaches for them.
- Not a finding if: the image component or its container reserves the space (framework image components with dimensions, a CSS aspect-ratio box); the banner overlays without pushing content.
- Severity: Medium; High when a shift can turn a click into the wrong action (buy, delete) on a core journey.
- Fix: set width and height or aspect-ratio on media and reserve space for content that arrives late.
- Verify the fix: Lighthouse CLS is 0.1 or less for the screen, and a trace shows no layout-shift entries near the primary action.
- Refs: Core Web Vitals (CLS)

### PRF-R3 Typing or clicking triggers heavy work that blocks the page
- Leads: `scan.sh PRF-R3` lists filtering and sorting in input handlers and any debounce, deferral, or virtualization.
- Confirm: a keystroke or click on a core screen runs work proportional to the whole data set on the main thread (filtering or sorting thousands of rows per keystroke, re-rendering a full long list) with no debounce, deferral, virtualization, or worker.
- Not a finding if: the data set is small and bounded (cite the limit); the work is debounced or deferred (`useDeferredValue`, `startTransition`).
- Severity: Medium; High on the main task's primary input.
- Fix: debounce input, virtualize long lists, and defer or move heavy work off the main thread.
- Verify the fix: a performance trace of the interaction shows no task over 50 ms; field INP at the 75th percentile is 200 ms or less.
- Refs: Core Web Vitals (INP); RAIL (respond within 100 ms)

### PRF-R4 The mobile layout breaks: no viewport meta, forced horizontal scroll, or hover-only actions
- Leads: `scan.sh PRF-R4` lists the viewport meta, wide fixed widths, and hover-only reveals.
- Confirm: the document has no `<meta name="viewport" content="width=device-width, initial-scale=1">`; a container on a core screen has a fixed width or min-width wider than 320 CSS px with no breakpoint, forcing horizontal scroll; or a critical action appears only on hover (a `:hover` reveal, a mouse-enter menu) with no tap path.
- Not a finding if: the wide element scrolls inside its own region by design (a data table); a breakpoint resets the width; the action is also reachable by tap.
- Severity: High when a core journey cannot be completed on a phone; Medium otherwise.
- Fix: add the viewport meta, replace fixed widths with max-width and fluid units, add breakpoints for 320 to 414 px, and give hover-only actions a visible or tap path.
- Verify the fix: at 320 CSS px wide, the core journey has no horizontal scroll and every action is reachable by tap.
- Refs: WCAG 1.4.10 (reflow); responsive design

## Also check
- Render-blocking resources in the head: synchronous scripts and web fonts with no `font-display`.
- Optimistic UI for frequent low-risk actions (a like, a toggle) instead of waiting on the server.
- Skeleton screens for unavoidable waits; a screen that freezes or goes silent under load.
- Jank: animating layout properties (top, left, width, height) instead of transform and opacity.
- Long main-thread tasks during page load on core screens.

## Paper controls (look protective, protect nothing)
- `loading="lazy"` on the hero image that is the LCP element, which delays it.
- A skeleton that renders at a different size than the content, so the layout shifts when data arrives.
- A debounce helper imported, but the handler passed to the input is the undebounced one.
