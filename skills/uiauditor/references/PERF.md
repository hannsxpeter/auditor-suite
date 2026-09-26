# PERF: Frontend Performance and Loading

Weight 11. Always active.
Owns: code-level risks to Core Web Vitals that can be read from source: what delays the largest paint (LCP), what shifts late content (CLS), and what blocks interactions (INP); heavy code on the initial render path; work done eagerly that could wait.
Not here: bundle and dependency weight, duplicate libraries, tree-shaking, and polyfills with no render-path link (codeauditor); image format and weight, icon imports, and `@font-face` settings (ASSET); missing image dimensions (RESP-R4); lifecycle bugs with no render cost (codeauditor).
Standards: Core Web Vitals (LCP, CLS, INP; INP replaced FID in March 2024; thresholds in facts.md), web.dev performance guides.
Read first: the document head, the landing route and its first-view components, the router and code-splitting setup, and the list and search components.
Every PERF finding is a risk read from code, not a measurement: use Likely or Suspected, and name the Lighthouse, WebPageTest, or field-data (CrUX) check that would confirm it.

## Cards

### PERF-R1 Largest paint delayed: the first-view image is lazy, low priority, or found late
- Leads: `scan.sh PERF-R1` lists `loading="lazy"`, `fetchpriority`, `priority` props, image preloads, and CSS background images.
- Confirm: the likely LCP element (the hero or first large image, or the headline block) has `loading="lazy"`; lacks `fetchpriority="high"` (or the framework's `priority` prop); is a CSS `background-image` the browser finds only after the CSS loads; or renders only after client-side data fetching.
- Not a finding if: the image is below the first view; the page sits behind sign-in and is not a first-visit page (lower the severity instead).
- Severity: High when the LCP image of a load-bearing landing or product page is lazy-loaded or rendered only after a client fetch; Medium when it only lacks `fetchpriority`.
- Fix: remove `loading="lazy"` from the first-view image, add `fetchpriority="high"` (or `priority` on `next/image`), render it in the server HTML, and use an `<img>` rather than a CSS background for the hero.
- Verify the fix: a Lighthouse run shows the LCP image requested early at high priority and no lazy-loaded LCP warning.
- Refs: Core Web Vitals LCP; web.dev "Optimize Largest Contentful Paint"

### PERF-R2 Render-blocking scripts and styles in the head
- Leads: `scan.sh PERF-R2` lists script tags with `src`, CSS `@import`, stylesheet links, and `beforeInteractive` scripts.
- Confirm: a classic `<script src>` in `<head>` without `defer`, `async`, or `type="module"`; third-party tags (tag managers, chat, A/B testing) loaded synchronously before content; CSS `@import` chains (each import waits for the file before it); large non-critical stylesheets in the head of every route.
- Not a finding if: the script is tiny and inline on purpose (a theme-flash guard); it is `type="module"` (deferred by default).
- Severity: High when a synchronous third-party script or an `@import` chain blocks the first paint of a load-bearing page; Medium otherwise.
- Fix: `defer` or `async`; load third-party tags after load or on interaction; replace `@import` with `<link>` or bundler imports.
- Verify the fix: the head has no blocking script tags; Lighthouse lists no render-blocking resources.
- Refs: Core Web Vitals LCP; web.dev "Eliminate render-blocking resources"

### PERF-R3 Heavy work on the interaction path
- Leads: `scan.sh PERF-R3` lists scroll and resize listeners and layout reads; read the search, filter, and list components.
- Confirm: a keystroke, click, or scroll handler does heavy synchronous work (filters or sorts a large array on every keystroke with no debounce or transition); a list renders hundreds or thousands of rows with no virtualization; a scroll or resize handler reads layout (`getBoundingClientRect`, `offsetHeight`) and writes styles in the same loop; touch and wheel listeners are not `passive`.
- Not a finding if: the data is small by construction (say how you know); the work runs through `useDeferredValue`, `startTransition`, a worker, or a debounce.
- Severity: High when a load-bearing input (search, filter, checkout) recomputes or re-renders a large list on every keystroke; Medium otherwise. The data size usually comes from an API you cannot see, so this is often Suspected.
- Fix: debounce input, wrap the update in `startTransition`, memoize the derived list, virtualize long lists (`react-window`, `@tanstack/react-virtual`), and batch layout reads before writes.
- Verify the fix: a performance profile of typing in the field shows no task over 50 ms; field INP at the 75th percentile is 200 ms or less.
- Refs: Core Web Vitals INP; web.dev "Optimize Interaction to Next Paint"

### PERF-R4 Heavy code or a client boundary on the initial render path
- Leads: `scan.sh PERF-R4` lists top-level imports of chart, map, editor, 3D, PDF, and spreadsheet libraries, lazy-loading calls, `"use client"` directives, and `client:load` islands.
- Confirm: a heavy library is imported at the top of a module that renders the first view (a chart library in the landing route); a `lazy()` or `defineAsyncComponent` split is defeated because another module imports the same component statically; `"use client"` at a route root or layout turns the whole page into client JavaScript; an Astro island below the fold uses `client:load`.
- Not a finding if: the heavy component is itself in the first view and needed for the first paint; the split loads on interaction.
- Severity: High when the route chunk of a load-bearing landing page carries a heavy library it does not need for the first view; Medium otherwise. "This dependency is large" with no render-path link belongs to codeauditor.
- Fix: dynamic `import()` behind interaction or visibility; move `"use client"` down to the interactive leaves; `client:visible` or `client:idle` below the fold.
- Verify the fix: the bundle analyzer shows the library in a separate chunk loaded after the first paint.
- Refs: Core Web Vitals LCP and INP; web.dev "Reduce JavaScript payloads with code splitting"

### PERF-R5 First-view data or assets fetched late in a waterfall
- Leads: `scan.sh PERF-R5` lists data-fetching calls; read how the landing route loads its data.
- Confirm: first-view content is fetched in a client effect after hydration (`useEffect`, `onMounted`) when the framework could fetch it on the server or in a route loader; the server waits for every query, including below-the-fold data, before sending any HTML where the framework can stream (`Suspense`, deferred loader data); requests that do not depend on each other run one after another; below-the-fold images lack `loading="lazy"`; code for every route ships in the main bundle.
- Not a finding if: the data is user-specific and the app is client-rendered by design (then check its skeleton under COMP-R2).
- Severity: Medium when the waterfall delays the first view of a load-bearing page; Low otherwise.
- Fix: fetch in the route loader or server component; start independent requests together; add `loading="lazy"` below the fold; split code by route.
- Verify the fix: the network waterfall of the first view shows parallel requests that start with the document.
- Refs: Core Web Vitals LCP; web.dev "Optimize Largest Contentful Paint" (resource load delay)

### PERF-R6 Late content or font swaps that shift the layout
- Leads: `scan.sh PERF-R6` lists banners, consent and cookie notices, ad slots, and font metric overrides.
- Confirm: a banner, consent bar, promo strip, or ad is inserted above existing content after load and pushes it down; a web font swaps in with very different metrics and has no fallback overrides (`size-adjust`, `ascent-override`) or framework font optimization.
- Not a finding if: the late element overlays content (fixed or absolute) instead of pushing it; space is reserved for it.
- Severity: Medium when the shift happens in the first view of a load-bearing page; Low otherwise.
- Fix: reserve the space, render the banner in the server HTML, or overlay it; use `next/font` or a fallback `@font-face` with metric overrides.
- Verify the fix: a Lighthouse run lists neither the banner nor the font swap among the layout-shift culprits.
- Refs: Core Web Vitals CLS; web.dev "Optimize Cumulative Layout Shift"

## Also check
- A responsive image setup (`next/image`, `<picture>`) bypassed by a raw `<img>` on the largest asset.
- Expensive renders on the interaction path, such as a context value object rebuilt on every render so every consumer re-renders.

## Paper controls (look protective, protect nothing)
- `loading="lazy"` on the LCP hero image, which delays the most important paint.
- A route-root `"use client"` that ships the whole page as client code.
- A "lazy" route whose component is still imported statically at the top of another module.
- A preload for an image or font that the page never uses, or preloads under a different URL than it renders.
