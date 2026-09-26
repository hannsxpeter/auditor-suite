# CANON: Canonicalization and Duplicate Content

Weight 11. Always active. Floor dimension.
Owns: the rel=canonical tag (presence, absolute URL, self-reference, conflicts) and how it consolidates duplicates: query parameters, facets, pagination, syndicated copies.
Not here: the redirects that enforce host, scheme, and trailing slash (URLARCH-R2); canonicals across languages (I18N-R1); canonicals written by client JavaScript (RENDER-R2); which URLs the sitemap lists (CRAWL-R6); crawl traps from facet links (CRAWL-R8).
Standards: RFC 6596, Google Search Central (consolidate duplicate URLs; troubleshoot canonicalization), facts.md (Canonicals).
Read first: every place a canonical is emitted (layouts, SEO helpers, head components, plugins), the base URL setting (`metadataBase`, `site`, `baseURL`, `url`), and the route parameters.

## Cards

### CANON-R1 Every page canonicalizes to the same URL (quick)
- Leads: `scan.sh CANON-R1` lists canonicals set to a literal URL, to `/`, or to a site-wide constant.
- Confirm: a shared layout, SEO helper, head component, or plugin setting emits one fixed canonical (usually the home page) for every page that uses it, instead of each page's own URL. Read the helper's call sites to count the pages.
- Not a finding if: the helper receives the page path and builds the canonical from it; the constant is used only on the home page.
- Severity: Critical, because every page tells Google it duplicates one URL, and Google may drop the rest from the index.
- Fix: build the canonical from each page's own path, for example `alternates: { canonical: path }` under a `metadataBase`, or `new URL(Astro.url.pathname, Astro.site)`.
- Verify the fix: the served canonical of three different pages equals each page's own absolute URL.
- Refs: RFC 6596, Google Search Central (consolidate duplicate URLs)

### CANON-R2 Canonical is relative or resolves against the wrong base URL
- Leads: `scan.sh CANON-R2` lists relative canonicals and base URL settings such as `metadataBase`.
- Confirm: the canonical is a relative path in raw HTML, or a framework resolves it against a base that is unset or wrong: Next.js `alternates.canonical` with no `metadataBase` in the root layout, Astro without `site`, Hugo with `baseURL = "/"`, Jekyll with an empty `url`. A relative canonical copies whatever host served the page, so www, http, and preview copies each canonicalize to themselves.
- Not a finding if: a base URL is set to the production origin where the framework reads it (stacks.md).
- Severity: High when the canonical resolves to localhost, a preview host, or any non-production host; Medium for plain relative canonicals.
- Fix: set the base URL once to the production origin and emit absolute canonicals.
- Verify the fix: the served canonical starts with `https://<production host>/`.
- Refs: RFC 6596, Google Search Central (use absolute URLs in rel=canonical), facts.md (Frameworks)

### CANON-R3 Canonical missing on indexable templates, or several canonicals that disagree
- Leads: `scan.sh CANON-R3` lists every canonical emitter.
- Confirm: an indexable template emits no canonical; or two layers each emit one (theme and plugin, layout and page, framework and a hand-written tag) with different values; or the canonical sits in `<body>` or after an element that closes `<head>` early.
- Not a finding if: the framework merges to one tag (Next.js metadata replaces the parent's value); the page is noindexed.
- Severity: High when primary templates emit canonicals that disagree (Google then ignores them all); Medium when they are missing.
- Fix: emit exactly one self-referencing absolute canonical per indexable page, from one place.
- Verify the fix: the served HTML of each template has exactly one `rel="canonical"`, inside `<head>`.
- Refs: Google Search Central (consolidate duplicate URLs)

### CANON-R4 Canonical copies the request URL, including query parameters
- Leads: `scan.sh CANON-R4` lists canonicals built from `req.originalUrl`, `build_absolute_uri()`, `REQUEST_URI`, `fullUrl`, `Astro.url.href`, or `asPath`.
- Confirm: the canonical is built from the full request URL, so tracking, sort, session, and filter parameters each produce a self-canonical duplicate; or each filter combination canonicalizes to itself instead of the clean listing.
- Not a finding if: the builder strips the query or keeps only an allowlist of meaningful parameters (for example `page`).
- Severity: High on catalogs and listings with many parameters; Medium otherwise.
- Fix: build the canonical from the path plus an explicit allowlist of parameters.
- Verify the fix: the served canonical of `/shoes?utm_source=x&sort=price` is `https://<host>/shoes`.
- Refs: Google Search Central (consolidate duplicate URLs), facts.md (Canonicals: URL Parameters tool removed)

### CANON-R5 Canonical contradicts the page's other signals
- Leads: `scan.sh CANON-R5` lists pagination links and canonicals that mention a page number.
- Confirm: a page has a canonical to another URL and also noindex; a canonical points at a URL that redirects, returns 404, or is noindexed; page 2 and later canonicalize to page 1, so their items drop out; the canonical's host or trailing slash disagrees with the redirect rules or the sitemap.
- Not a finding if: the target returns 200 and canonicalizes to itself (check the route and the redirect map).
- Severity: High when it hits a primary template or every paginated listing; Medium otherwise.
- Fix: point every canonical at a 200, indexable, self-canonical URL; let paginated pages canonicalize to themselves; never combine noindex with a canonical to another URL.
- Verify the fix: for each template, the canonical target is in the sitemap and returns 200 with the same canonical.
- Refs: Google Search Central (consolidate duplicate URLs; pagination best practices)

## Also check
- Cross-domain canonicals used to deduplicate syndicated copies: Google no longer recommends this; the partner should noindex its copy (Low; file under CANON-R5; facts.md).
- `/` and `/index.html` both linked internally (the linking is CANON-R5; the missing redirect is URLARCH-R2).

## Paper controls (look protective, protect nothing)
- A hardcoded home page canonical on every page (CANON-R1).
- A per-locale constant canonical that voids every hreflang cluster (I18N-R1).
- A self-canonical with no redirect behind it, so www, http, and slash variants still answer 200 (URLARCH-R2).
- A canonical normalized in code but never enforced on the served URL (URLARCH-R2).
- A canonical injected by client JavaScript (RENDER-R2).
- Theme and plugin both emitting canonicals (CANON-R3).
