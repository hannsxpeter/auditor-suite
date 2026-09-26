# URLARCH: URL Architecture and Technical Configuration

Weight 8. Always active. Floor dimension.
Owns: HTTP status for missing and retired pages, redirect status codes and chains, the one redirect layer that enforces host, scheme, and trailing slash, URL design and slug changes, X-Robots-Tag and robots headers set in server, platform, or middleware config, and server or edge rules that block or break crawlers (CSP, WAF, rate limits, mixed content).
Not here: the canonical tag (CANON); noindex set in page metadata or robots.txt (CRAWL); rules that target AI crawlers (AIVIS-R1); the not-found view of a client-rendered app (RENDER-R5); client-side redirects (RENDER-R2); locale redirects (I18N-R4).
Standards: RFC 9110 (status codes), Google Search Central (redirects and Google Search, soft 404 errors, HTTP status codes, URL structure), facts.md (Frameworks; Hosting).
Read first: the section of stacks.md for the stack and the host, the redirect map (framework config, vercel.json, netlify.toml, `_redirects`, `.htaccess`, nginx config), middleware, header config, catch-all routes, and the 404 page.

## Cards

### URLARCH-R1 Missing pages answer 200 (soft 404)
- Leads: `scan.sh URLARCH-R1` lists "not found" renders, 404 helpers, and rewrites of every path to one page.
- Confirm: a catch-all or detail route renders a "not found" message without setting 404 (no `notFound()`, `{ notFound: true }`, `error(404)`, `Http404`, `abort(404)`, or `status = 404` on that branch); or host config rewrites every path to `index.html` with 200 (`/* /index.html 200`, `try_files ... /index.html`, `error_page 404 =200`, CloudFront error responses mapped to 200); or dead URLs redirect to the home page; or Apache `ErrorDocument 404` names a full URL (Apache then redirects instead of answering 404).
- Not a finding if: that branch calls the framework's not-found helper (read it); the file is the framework's own 404 page (Next.js `not-found`, `pages/404`, `404.astro`, `+error.svelte`), which the framework serves with 404; the rewrite serves a client-rendered app whose not-found view is covered by RENDER-R5.
- Severity: High when a catch-all or detail template serves many URLs; Medium for one route. Use 410 for content removed on purpose.
- Fix: answer 404 (or 410) on the missing-data branch, for example `if (!doc) notFound()` in Next.js.
- Verify the fix: `curl -sI https://<host>/docs/no-such-page` returns 404.
- Refs: Google Search Central (soft 404 errors; HTTP status codes), RFC 9110

### URLARCH-R2 Host, scheme, or trailing slash is not enforced by one redirect layer (quick)
- Leads: `scan.sh URLARCH-R2` lists force-HTTPS settings, host redirects, trailing-slash settings, and HSTS headers.
- Confirm: www and the bare host, http and https, or `/page` and `/page/` both answer 200 with no redirect in any layer you can read; or two layers disagree (the CDN forces the bare host while the app forces www) and loop; or the redirect takes several hops (http to https, then to www).
- Not a finding if: one layer sends every variant to the canonical form in one hop. If host redirects live in platform settings outside the repo, report Suspected and say what to check.
- Severity: Critical when a loop makes the canonical host uncrawlable, or the site answers only on duplicate hosts whose canonical contradicts them; High when variants answer 200 with no redirect; Medium for multi-hop chains.
- Fix: choose one layer (edge or app) to 301 or 308 every variant to `https://<canonical host>/<path>` in one hop, and match the trailing-slash setting to the canonicals and the sitemap.
- Verify the fix: `curl -sIL http://<bare host>/pricing/` shows one redirect to the canonical URL, then 200.
- Refs: Google Search Central (redirects and Google Search; consolidate duplicate URLs)

### URLARCH-R3 Redirects use temporary codes for permanent moves, or chain through several hops
- Leads: `scan.sh URLARCH-R3` lists redirect calls, `permanent:` flags, and status codes in redirect maps.
- Confirm: a permanent move uses 302 or 307 (Express `res.redirect()` defaults to 302; Next.js `redirect()` sends 307, as does `permanent: false`; Rails `redirect_to` and Laravel `redirect()` default to 302); or a test or temporary state uses 301; or the map sends A to B and B to C.
- Not a finding if: the move is temporary by design (a sale page, maintenance) and the code says so.
- Severity: Medium; High when a whole section moved with temporary codes.
- Fix: use 301 or 308 for permanent moves and point every rule at the final destination.
- Verify the fix: `curl -sI` on each moved URL shows 301 or 308 and a Location that answers 200.
- Refs: Google Search Central (redirects and Google Search), facts.md (Frameworks)

### URLARCH-R4 Noindex set at the header layer reaches production (quick)
- Leads: `scan.sh URLARCH-R4` lists every X-Robots-Tag in code and config.
- Confirm: framework header config (`next.config` `headers()`), vercel.json, netlify.toml, `_headers`, nginx `add_header`, or middleware sends `X-Robots-Tag: noindex` (or `none`) on all or most paths, and its environment gate is inverted, missing, or reads a variable production does not set.
- Not a finding if: the header targets only non-production hosts or private paths (read the host or path match); the platform adds it to preview URLs only.
- Severity: Critical when it reaches production sitewide; High for a whole indexable section.
- Fix: scope the header to non-production hosts or private paths, keyed off a variable production sets.
- Verify the fix: `curl -sI https://<production host>/` shows no X-Robots-Tag with noindex.
- Refs: Google Search Central (robots meta tag, data-nosnippet, and X-Robots-Tag specifications)

### URLARCH-R5 Server or edge rules block or break crawlers (quick)
- Leads: `scan.sh URLARCH-R5` lists CSP headers, rate limits, bot rules, and `http://` asset URLs.
- Confirm: a WAF, rate-limit, or bot rule in the repo answers 403 or 429 to Googlebot or Bingbot; a Content-Security-Policy blocks the site's own scripts or styles; pages load `http://` scripts, styles, or images on an https site (mixed content).
- Not a finding if: the rule verifies bots and lets the real ones through; the CSP allows every origin the built HTML uses.
- Severity: Critical when Googlebot or Bingbot is blocked sitewide; High for a CSP that blanks pages; Medium for mixed content.
- Fix: allow verified search crawlers (reverse DNS or the published IP ranges), fix the CSP source list, and load every asset over https.
- Verify the fix: a request with a Googlebot user agent to a public path answers 200, and the browser console shows no CSP or mixed-content errors.
- Refs: Google Search Central (verifying Googlebot and other Google crawlers; HTTP status codes)

### URLARCH-R6 URLs are unstable or ambiguous
- Leads: `scan.sh URLARCH-R6` lists slug builders, redirect-from lists, and aliases.
- Confirm: a slug or route change drops old URLs with no 301 from the old slug; URLs differ only by case (`/Apple` and `/apple` both answer; URLs are case-sensitive); IDs or query strings are used where readable slugs exist; paths nest deeper than the content hierarchy.
- Not a finding if: old slugs are stored and redirected; the server lowercases or redirects mixed-case paths.
- Severity: Medium when slug changes lose linked URLs; Low for style issues.
- Fix: keep a redirect map keyed by old slug, and generate lowercase, hyphenated slugs.
- Verify the fix: an old slug from git history redirects with 301 to the new URL.
- Refs: Google Search Central (URL structure best practices)

## Also check
- The trailing-slash setting (`trailingSlash`, Astro `build.format`, Docusaurus `trailingSlash`) agrees with the canonicals, the sitemap, and internal links (stacks.md; file under URLARCH-R2).
- Redirects or headers written in `next.config` while `output: 'export'` is set: a static export does not run them (stacks.md).
- Query-parameter URLs redirected in config while templates still link to them.
- Preview-deployment noindex headers must not reach the production domain alias (file under URLARCH-R4).

## Paper controls (look protective, protect nothing)
- A friendly 404 page that answers 200 (URLARCH-R1).
- An inverted environment guard on X-Robots-Tag (URLARCH-R4).
- An HSTS header with no http to https redirect: it protects returning browsers only, and crawlers still reach the http copy (file the missing redirect under URLARCH-R2).
- A redirect map full of chains (URLARCH-R3).
- Two canonicalization layers that loop (URLARCH-R2).
- A strict CSP that renders the page blank for crawlers (URLARCH-R5).
