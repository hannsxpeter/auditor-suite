# PERF: Performance and Core Web Vitals

Weight 6. Always active.
Owns: code patterns that predict poor LCP, INP, and CLS: the LCP image and its priority, render-blocking resources, layout-shift sources, client JavaScript weight, image delivery, caching, compression, and server response time; content hidden on mobile.
Not here: the viewport meta tag (SOCIAL-R6); duplicate analytics tags (OBSV-R3); a CSP that blocks rendering (URLARCH-R5); content that renders only on the client (RENDER-R1).
Standards: web.dev Core Web Vitals (LCP, INP, CLS), Google Search Central (page experience), the framework image and script docs, facts.md (Performance).
Read first: the root layout or document head, the home page and one primary template, the image component usage, the build config (`next.config`, `nuxt.config`, `astro.config`), and cache header config.

Field results cannot be known from code. Confidence describes the code pattern; Impact must not claim a measured number. Say that CrUX field data or Lighthouse confirms the effect.

## Cards

### PERF-R1 The largest above-the-fold image is lazy-loaded or not prioritized
- Leads: `scan.sh PERF-R1` lists `loading="lazy"`, `priority`, `fetchpriority`, image preloads, and CSS background images.
- Confirm: the hero or first large image of a primary template has `loading="lazy"`, or uses an image component that lazy-loads by default (`next/image` without its priority option) with no `fetchpriority="high"` or preload; or the LCP element is a CSS `background-image` the browser's preload scanner cannot find.
- Not a finding if: the image sits below the fold on mobile and desktop; it already loads eagerly with high priority.
- Severity: High on the home page and primary templates; Medium elsewhere.
- Fix: load the hero eagerly with high priority: `<Image priority ...>` in Next.js (stacks.md for newer versions), `loading="eager" fetchpriority="high"` in HTML; move background heroes into an `<img>`.
- Verify the fix: the served HTML shows the hero `<img>` without `loading="lazy"` and with `fetchpriority="high"` or a matching preload; Lighthouse LCP improves.
- Refs: web.dev (optimize LCP; browser-level image lazy loading)

### PERF-R2 Render-blocking scripts and styles in the head
- Leads: `scan.sh PERF-R2` lists script tags with `src`, CSS `@import`, and `beforeInteractive` scripts.
- Confirm: a synchronous `<script src>` with no `async` or `defer` sits in `<head>`; third-party tags (tag managers, pixels, chat, A/B, consent) load synchronously in the critical path; CSS `@import` chains; one large global stylesheet with no critical CSS.
- Not a finding if: the script must run first (a consent default, an A/B anti-flicker snippet with a timeout) and is small.
- Severity: Medium; High when several third-party scripts block the first render of primary templates.
- Fix: add `defer` or `async`, load third parties with the framework's deferred strategy (`next/script` `afterInteractive` or `lazyOnload`), and bundle CSS instead of `@import`.
- Verify the fix: Lighthouse lists no render-blocking resources for the home page.
- Refs: web.dev (eliminate render-blocking resources; load third-party JavaScript efficiently)

### PERF-R3 Layout shifts from media without reserved space, fonts, or late content
- Leads: `scan.sh PERF-R3` lists `<img>`, `<iframe>`, `<video>`, `<embed>`, and `@font-face` rules.
- Confirm: images, video, iframes, ads, or embeds have no `width` and `height` or `aspect-ratio` (or CSS overrides them so no space is reserved); banners or promos are inserted above existing content after load; web fonts have no `font-display`, or use swap with no fallback metric overrides (`size-adjust`, `ascent-override`); animations change layout properties instead of `transform` or `opacity`.
- Not a finding if: a framework image component reserves the space from its width and height; the inserted element reserves its own space.
- Severity: Medium; Low for below-the-fold elements.
- Fix: give media explicit dimensions, reserve space for late elements, pair `font-display: swap` with metric overrides, and animate `transform` or `opacity`.
- Verify the fix: Lighthouse reports CLS under 0.1 for the template.
- Refs: web.dev (optimize CLS)

### PERF-R4 Too much client JavaScript for what the page does
- Leads: `scan.sh PERF-R4` lists `'use client'` files, dynamic imports, and imports of large libraries.
- Confirm: `'use client'` sits high in the tree around mostly static content; heavy widgets below the fold load eagerly with no `dynamic()` or lazy import; whole large libraries (moment, all of lodash, charting, icon packs) load on primary templates.
- Not a finding if: the page is an app screen behind sign-in; the library is tree-shaken or loaded only where used.
- Severity: Medium; Low on secondary pages.
- Fix: push `'use client'` down to the interactive leaves, lazy-load heavy widgets, and import only the functions used.
- Verify the fix: the build's route size report shows less first-load JavaScript for the template.
- Refs: web.dev (optimize INP; reduce JavaScript payloads)

### PERF-R5 Images are not delivered in modern, responsive forms
- Leads: `scan.sh PERF-R5` lists raw `<img>` tags pointing at PNG, JPEG, or GIF files, `unoptimized` flags, and `srcset` use.
- Confirm: primary templates use raw `<img>` with large PNG or JPEG files and no `srcset` or `sizes`, bypassing the framework image component; or config enables AVIF or WebP while templates hardcode the originals.
- Not a finding if: a CDN or image service converts formats and sizes (read its config).
- Severity: Medium; Low for small images.
- Fix: use the framework image component, or `srcset` and `sizes` with AVIF or WebP sources.
- Verify the fix: the served HTML offers `srcset` with modern formats for the hero and content images.
- Refs: web.dev (serve responsive images; use modern image formats)

### PERF-R6 Caching, compression, or server response time slow the first load
- Leads: `scan.sh PERF-R6` lists Cache-Control values, `immutable`, `force-dynamic`, `revalidate = 0`, and `no-store` fetches.
- Confirm: hashed static assets lack a long `Cache-Control` with `immutable`; non-hashed URLs are marked `immutable`, so visitors keep stale files; compression is off in a server you configure; pages that could be static re-render on every request (`force-dynamic`, `revalidate = 0`, `no-store` on content fetches) or wait on sequential data fetches.
- Not a finding if: the platform sets asset caching and compression (Vercel, Netlify, and Cloudflare Pages do for built assets); the page must be dynamic per request.
- Severity: Medium; High when primary templates render uncached behind slow sequential fetches.
- Fix: cache hashed assets for a year with `immutable`, keep non-hashed URLs revalidating, and make content pages static or revalidated, with parallel fetches.
- Verify the fix: `curl -sI` on a hashed asset shows `max-age=31536000, immutable`, and the template no longer opts out of caching.
- Refs: web.dev (optimize TTFB; HTTP cache)

## Also check
- `preconnect` to a font origin without `crossorigin`, `preload` without `as`, or many preloads competing (file under PERF-R2).
- `fetchpriority="high"` on many images, so it no longer means anything (file under PERF-R1).
- Main content hidden or removed at mobile breakpoints: Google indexes the mobile rendering (Medium; file under PERF-R3 or as its own finding under PERF).
- `user-scalable=no` in the viewport: an accessibility problem (mention it; uiauditor owns it).

## Paper controls (look protective, protect nothing)
- Lazy-loading the LCP image "for performance" (PERF-R1).
- Preloading a resource the page never uses.
- `width` and `height` present but overridden by CSS, so no space is reserved (PERF-R3).
- AVIF or WebP enabled in config while templates hardcode PNG (PERF-R5).
- `immutable` on non-hashed asset URLs (PERF-R6).
- A Core Web Vitals dashboard widget treated as a fix: measuring is not optimizing.
