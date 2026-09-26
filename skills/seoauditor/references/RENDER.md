# RENDER: Rendering and Content-in-HTML

Weight 13. Always active. Floor dimension.
Owns: whether each route's main content and head signals (title, canonical, robots, JSON-LD, Open Graph) are in the initial server HTML; the rendering mode per route; head tags and redirects set only by client code; hydration that replaces server HTML; links crawlers can follow; the not-found view of a client-rendered app; content that appears only after interaction; prerendering served only to bots.
Not here: whether those tags hold correct values (CONTENT, CANON, SCHEMA, SOCIAL); server or route config that answers 200 for missing pages (URLARCH-R1); redirect status codes (URLARCH-R3); user-agent branches in app code that change content (OBSV-R1); bundle weight as a speed problem (PERF-R4).
Standards: Google Search Central (JavaScript SEO basics; dynamic rendering as a workaround; lazy-loaded content), the framework rendering docs (stacks.md), facts.md (Rendering).
Read first: the section of stacks.md for the detected stack, the router or route folders, the page and layout files of each primary template, and the data-loading code they call.

## Cards

### RENDER-R1 Main content exists only after client-side JavaScript runs (quick)
- Leads: `scan.sh RENDER-R1` lists page and layout files that start with `'use client'`, `ssr: false`, `client:only`, SPA entry points, and empty root shells.
- Confirm: on a route meant to rank, the server HTML lacks the main content because data is fetched in `useEffect`, `onMounted`, SWR, or React Query with no server data; the component loads with `ssr: false` or `client:only`; rendering waits for a `mounted` flag; or the app is an SPA whose HTML is an empty `<div id="root">`. `'use client'` alone proves nothing: client components still render on the server. Decide what the server HTML would contain.
- Not a finding if: the route is signed-in only or noindexed; a server loader, `getStaticProps`, `generateStaticParams`, `useAsyncData`, or a prerender step supplies the data; the client-only part is a widget, not the content (a chat bubble, a filter, a chart).
- Severity: Critical on primary templates (home, product, pricing, article, docs), because AI crawlers that run no JavaScript see an empty shell and Google must wait for its render queue; High on secondary pages.
- Fix: fetch on the server and pass the data down (server component, loader, `getStaticProps`, `useAsyncData`); keep only interactive leaves on the client.
- Verify the fix: `curl -s https://<host>/<route>` (or the built HTML file) contains the main text and headings.
- Refs: Google Search Central (JavaScript SEO basics), facts.md (Rendering: AI crawlers and JavaScript)

### RENDER-R2 Head tags or redirects are set only by client JavaScript (quick)
- Leads: `scan.sh RENDER-R2` lists `document.title`, meta and script tags created in the DOM, react-helmet, `window.location` redirects, and meta refresh.
- Confirm: the title, canonical, robots, JSON-LD, or Open Graph tags are written by client code (`document.title =`, `createElement('meta')`, react-helmet in an app with no server render step, JSON-LD injected by a tag manager); or a redirect for host, locale, or moved pages uses `window.location` or `<meta http-equiv="refresh">`.
- Not a finding if: the framework renders the helper on the server (Next.js metadata, Nuxt `useHead`, react-helmet with a server render and `HelmetProvider`); the client code only repeats a value the server already sent.
- Severity: Critical when the server sends noindex and client code is meant to remove it on indexable templates (Google does not render a page it sees as noindex, so the removal never runs); High when the canonical, robots, or title exist only on the client on primary templates; Medium for JSON-LD or Open Graph only, since social scrapers and most AI crawlers run no JavaScript.
- Fix: move each tag into the framework's server metadata API, and each redirect into a server 301 or 308 (URLARCH owns redirect mechanics).
- Verify the fix: the served HTML of the route contains the tag before any script runs.
- Refs: Google Search Central (JavaScript SEO basics: robots meta tags and JavaScript)

### RENDER-R3 Server and client render different content, so hydration replaces the server HTML
- Leads: `scan.sh RENDER-R3` lists `suppressHydrationWarning`, `typeof window` branches, `localStorage` reads, and `Math.random()`.
- Confirm: main content depends on values that differ between server and client during render (`window`, `localStorage`, `Date.now()`, `Math.random()`, the user agent), so the server sends one version and the client throws it away; or `suppressHydrationWarning` hides such a mismatch around main content.
- Not a finding if: the branch renders no indexable content (analytics, consent, ads, a theme toggle); the value is read in an effect after hydration. If the server branch renders nothing at all, file RENDER-R1 instead.
- Severity: Medium.
- Fix: compute the value on the server or pass it in as data; read browser-only values in an effect.
- Verify the fix: the route logs no hydration warning in development, and the served HTML text matches the rendered page.
- Refs: React docs (hydrateRoot: hydration mismatches)

### RENDER-R4 Links crawlers cannot follow
- Leads: `scan.sh RENDER-R4` lists `router.push`, `navigate(`, hash routes, hash routers, and `javascript:` links.
- Confirm: navigation to indexable pages (menus, category and pagination links, related items) uses click handlers on `div`, `span`, or `button`, `href="#"` plus JavaScript, hash URLs (`#/pricing`), or a hash router (`HashRouter`, `createWebHashHistory`), so no crawlable `<a href="/path">` exists.
- Not a finding if: a real `<a href>` exists for the same destination (framework Link components render one); the control is an in-page action, not navigation.
- Severity: High when main navigation or pagination is affected (pages become orphans); Medium for secondary links.
- Fix: render `<a href="/path">` (or the framework Link) for every destination; replace hash routing with history routing and server support.
- Verify the fix: the served HTML of the home and listing pages has an `<a href>` to every main section and to each pagination page.
- Refs: Google Search Central (link best practices: make links crawlable)

### RENDER-R5 A client-rendered app shows a not-found view while the server answers 200
- Leads: `scan.sh RENDER-R5` lists client catch-all routes (`path="*"`, `pathMatch(.*)`, `'**'`).
- Confirm: in a client-rendered app, unknown paths hit a client catch-all that renders "not found", and the host rewrites every path to `index.html` with 200, so each junk URL is a soft 404.
- Not a finding if: the app renders on the server and returns 404 for unknown routes (a server 200 there is URLARCH-R1); the not-found view adds noindex or redirects to a URL that returns 404.
- Severity: Medium; High on large catalogs where many dead URLs stay indexed.
- Fix: in a pure SPA, add noindex in the not-found view or send it to a URL the server answers with 404; where the server knows the route list, return 404 from the server.
- Verify the fix: `curl -sI https://<host>/no-such-page` returns 404, or the not-found HTML carries noindex after rendering.
- Refs: Google Search Central (JavaScript SEO basics: avoid soft 404 errors in single-page apps)

### RENDER-R6 Prerendered or dynamically rendered HTML is served only to bots (quick)
- Leads: `scan.sh RENDER-R6` lists prerender services, `react-snap`, and middleware that routes bots to a renderer.
- Confirm: middleware or server config detects crawler user agents and serves them HTML from a prerender service or cache (prerender.io, rendertron, a custom headless browser), while people get the client app.
- Not a finding if: everyone gets the same prerendered or server-rendered HTML (plain SSG or SSR).
- Severity: Critical when the bot cache can serve stale, empty, or different content than people see (no invalidation on publish, cached errors); otherwise Medium, as a legacy workaround Google no longer recommends that does nothing for AI crawlers it does not detect.
- Fix: serve server-rendered or static HTML to everyone and remove the bot branch.
- Verify the fix: HTML fetched with a Googlebot user agent and with a browser user agent is the same.
- Refs: Google Search Central (dynamic rendering as a workaround), facts.md (Rendering)

### RENDER-R7 Content appears only after scrolling, clicking, or a second request
- Leads: `scan.sh RENDER-R7` lists infinite scroll, load-more, and scroll handlers.
- Confirm: indexable content mounts only on interaction: a tab or accordion that renders its panel only when clicked, "load more" that fetches the rest, or infinite scroll with no paginated URLs.
- Not a finding if: the content is in the HTML and only hidden with CSS; each loaded chunk also has its own URL reachable by a crawlable link.
- Severity: High when most items of a listing are reachable only by scrolling; Medium otherwise.
- Fix: render the content in the HTML (hide it with CSS if needed); give each chunk of an endless list a paginated URL with an `<a href>`.
- Verify the fix: the served HTML contains the tab content, or page 2 has its own URL linked from page 1.
- Refs: Google Search Central (fix lazy-loaded content; pagination best practices)

## Also check
- The rendering mode of each route group: record in the Map which routes are static, server-rendered, or client-only (stacks.md names the switches).
- A catch-all for legacy or localized URLs that redirects in the browser instead of the server (file under RENDER-R2).

## Paper controls (look protective, protect nothing)
- react-helmet or another head manager in an app with no server render step (the tags never reach the fetched HTML).
- An app called "SSR" or "isomorphic" whose server HTML is an empty root element.
- A passing Rich Results Test or URL Inspection offered as proof that content is in the initial HTML (both run JavaScript).
- An llms.txt offered as a substitute for server-rendered content.
