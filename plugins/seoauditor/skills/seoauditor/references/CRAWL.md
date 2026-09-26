# CRAWL: Crawlability and Indexation Control

Weight 14. Always active. Floor dimension.
Owns: robots.txt rules for search crawlers, meta robots index and snippet directives, environment guards in the metadata or robots layer, the base XML sitemap as discovery, crawl traps and parameter URL spaces.
Not here: X-Robots-Tag and noindex set in server, platform, or middleware header config (URLARCH-R4); robots rules for AI user agents, llms.txt, ai.txt (AIVIS); whether the robots meta reaches the server HTML (RENDER-R2); canonical tags, including pagination canonicals (CANON); news, image, and video sitemaps and IndexNow (FEEDS); hreflang in sitemaps (I18N); soft 404s and redirects (URLARCH).
Standards: RFC 9309, Google Search Central (robots.txt, robots meta tag, block indexing with noindex, build and submit a sitemap), sitemaps.org, facts.md (Robots and sitemaps).
Read first: the robots.txt file or generator, the root layout or shared head, every place that sets robots or noindex, the sitemap generator, and the deploy config that sets environment variables (vercel.json, netlify.toml, .env.production, CI deploy steps).

## Cards

### CRAWL-R1 Sitewide noindex or `Disallow: /` reaches production (quick)
- Leads: `scan.sh CRAWL-R1` lists noindex values, `index: false`, `Disallow: /` lines, and `blog_public`.
- Confirm: the served robots.txt has `Disallow: /` under `User-agent: *`, or a root layout, shared head, or SEO plugin setting emits noindex on every route, and production takes that branch. Trace the guard to its variable: it is inverted (`env === 'production'` picks noindex), missing, or reads a variable no production config sets, so it falls into noindex. Check the opposite failure too: a guard that leaves a public staging copy of the site indexable.
- Not a finding if: the branch keys off a variable production sets (cite where) and production gets index; the site is private by design (the README says so); the host adds noindex to preview URLs only (facts.md, Hosting).
- Severity: Critical when production is noindexed or blocked sitewide, or a public staging copy is indexable because the guard fails open. Use Likely when the outcome depends on an environment value you cannot see, and name the missing config.
- Fix: gate on one production signal and default production to indexable, for example `robots: process.env.VERCEL_ENV === 'production' ? { index: true, follow: true } : { index: false, follow: false }`.
- Verify the fix: after deploy, `curl -s https://<host>/robots.txt` shows no `Disallow: /` for `*`, and the production home page has no noindex in its HTML.
- Refs: Google Search Central (block indexing with noindex; introduction to robots.txt), RFC 9309

### CRAWL-R2 robots.txt blocks pages that are meant to drop out of the index (quick)
- Leads: `scan.sh CRAWL-R2` lists every Disallow rule; compare them with the routes that set noindex (CRAWL-R1 leads).
- Confirm: a path is disallowed in robots.txt and also expected to leave the index (it carries or needs noindex, or a comment says "hide from Google"). Google never fetches a disallowed URL, so it never sees the noindex, and it can still index the bare URL when other pages link to it.
- Not a finding if: the goal is only to save crawl budget and nothing links to the URLs publicly; the paths are API or asset endpoints nobody links to.
- Severity: Critical when this is the site's main way to deindex many linked URLs; High for a whole section; Medium for a few pages.
- Fix: remove the Disallow for those paths and serve noindex (meta or header) until they drop out; keep Disallow for crawl control only.
- Verify the fix: robots.txt no longer matches the path, and the page's HTML or headers carry noindex.
- Refs: Google Search Central (block indexing with noindex: the page must not be blocked by robots.txt)

### CRAWL-R3 robots.txt blocks the scripts and styles pages need to render (quick)
- Leads: `scan.sh CRAWL-R3` lists Disallow rules on asset folders and file types.
- Confirm: a Disallow matches the built assets: `/_next/`, `/_nuxt/`, `/_astro/`, `/_app/`, `/static/`, `/assets/`, `/build/`, `/wp-includes/`, `/wp-content/`, or `*.js` and `*.css`. stacks.md says where each stack puts its bundles.
- Not a finding if: the rule targets a folder pages do not load from; a longer `Allow` re-opens the assets (the longest matching path wins, and Allow wins a tie).
- Severity: Critical when pages are client-rendered, because Googlebot then renders an empty page; otherwise High, because Google cannot render the layout and mobile view.
- Fix: delete the asset Disallow rules and block only private or endless paths.
- Verify the fix: every script and stylesheet URL in the built HTML is allowed by robots.txt (check with an RFC 9309 parser, or the Search Console robots.txt report after deploy).
- Refs: Google Search Central (JavaScript SEO basics; robots.txt), RFC 9309

### CRAWL-R4 noindex or snippet limits on pages that should rank
- Leads: `scan.sh CRAWL-R4` lists page-level noindex, nosnippet, max-snippet, and max-image-preview values.
- Confirm: a public, valuable template (product, article, docs, pricing, category) sets noindex, or sets `nosnippet`, `max-snippet:0`, or `data-nosnippet` on its main content. Snippet limits also remove the text AI Overviews and other answer engines quote.
- Not a finding if: the route is signed-in only, a checkout or thank-you step, internal search results, or a thin filter page kept out on purpose; the limit is a written legal or licensing choice.
- Severity: High on a primary template; Medium on a secondary one; Low for a missing `max-image-preview:large` where image results matter.
- Fix: remove the directive from indexable routes and scope it to the private routes by path.
- Verify the fix: the template's served HTML and headers carry no noindex or snippet limit.
- Refs: Google Search Central (robots meta tag; AI features and your website)

### CRAWL-R5 robots.txt groups and directives do not do what they appear to do
- Leads: `scan.sh CRAWL-R5` lists user-agent groups, Sitemap lines, and unsupported directives.
- Confirm: one of these holds. A group for a named crawler (`User-agent: Googlebot`) leaves out rules from the `*` group, and that crawler then ignores the `*` group entirely. An `Allow` meant to win is shorter than the Disallow it fights. The file relies on `noindex:`, `crawl-delay` (Google ignores it), `host:`, or `clean-param:`. The `Sitemap:` line is missing or relative. The file is not at the host root or not plain UTF-8.
- Not a finding if: each named group repeats every rule it needs; the directive targets a crawler that honors it (Bing honors crawl-delay).
- Severity: High when a named group opens or closes a large section by accident; Medium for a missing or relative Sitemap line; Low for dead directives (inert, remove them).
- Fix: repeat the needed rules inside each named group, lengthen Allow paths, and write an absolute `Sitemap: https://...` line.
- Verify the fix: test each important URL against each group with an RFC 9309 parser.
- Refs: RFC 9309, Google Search Central (how Google interprets the robots.txt specification)

### CRAWL-R6 Sitemap missing, unreferenced, or listing URLs that should not be indexed
- Leads: `scan.sh CRAWL-R6` lists sitemap generators, plugins, and `changefreq` values.
- Confirm: a site with more than a handful of pages has no sitemap; or the sitemap lists redirected, noindexed, canonicalized-away, parameter, or error URLs; or it leaves out a primary content type; or one file passes 50,000 URLs or 50 MB with no sitemap index; or `<loc>` values are relative.
- Not a finding if: the site has a few pages, all linked from the home page; the generator filters by the same indexable flag the pages use (read it).
- Severity: Medium when primary content is missing or many listed URLs are not canonical; Low otherwise. `<priority>` and `<changefreq>` are ignored by Google: call them inert, never a defect on their own.
- Fix: build the sitemap from the same source as the routes, list only indexable canonical 200 URLs with absolute `<loc>`, and split with a sitemap index above the limits.
- Verify the fix: spot check five `<loc>` URLs from the built sitemap after deploy: each returns 200 and canonicalizes to itself.
- Refs: Google Search Central (build and submit a sitemap), sitemaps.org

### CRAWL-R7 Sitemap lastmod is the build time, not the content's change time
- Leads: `scan.sh CRAWL-R7` lists lastmod and lastModified values in generators.
- Confirm: every URL gets the same lastmod from `new Date()`, `Date.now()`, `now()`, `site.time`, or a build timestamp, while the content has its own updated date or none.
- Not a finding if: lastmod comes from the item's updated field, git history, or the CMS modified date; lastmod is left out (better than wrong).
- Severity: Medium on sites whose content changes and needs recrawling (docs, news, blogs, catalogs); Low otherwise. Google ignores lastmod values that are not consistently accurate, so the field becomes inert.
- Fix: set lastmod from each item's real modification date, for example `lastModified: doc.updatedAt`, or drop the field.
- Verify the fix: two URLs edited on different days show different lastmod values in the built sitemap.
- Refs: Google Search Central (build and submit a sitemap: lastmod), facts.md (Robots and sitemaps)

### CRAWL-R8 Unbounded crawl space from filters, sort orders, sessions, or calendars
- Leads: `scan.sh CRAWL-R8` lists links built with sort, filter, session, and tracking parameters.
- Confirm: crawlable `<a href>` links generate combinations of facets, sort orders, session IDs, or endless calendar or date pages, and nothing limits them: no Disallow for the parameter pattern and no noindex on thin combinations. (A canonical that copies the parameters is CANON-R4.)
- Not a finding if: filters use form controls or client state that crawlers do not follow and produce no linked URLs; the parameter space is small and each page is valuable.
- Severity: High on large catalogs where the traps outnumber the real pages; Medium otherwise.
- Fix: stop linking non-canonical combinations, Disallow the parameter patterns that should not be crawled, and keep a small set of valuable filter pages indexable.
- Verify the fix: the built HTML of one category page links only the intended filter URLs.
- Refs: Google Search Central (managing crawling of faceted navigation URLs; crawl budget)

## Also check
- A robots.txt route that can fail: Google treats a 5xx robots.txt as "crawl nothing" for a while and a 4xx as "no rules" (facts.md, Robots and sitemaps). File under CRAWL-R5.
- Code that still pings the retired Google sitemap ping endpoint (inert, Low; file under CRAWL-R6).
- A sitemap that lists URLs a noindex or robots rule excludes (file under CRAWL-R6).

## Paper controls (look protective, protect nothing)
- `noindex:` in robots.txt (Google stopped honoring it in 2019).
- `<priority>` and `<changefreq>` tuned on every sitemap entry (Google ignores both).
- `rel="next"` and `rel="prev"` added as a pagination fix (Google stopped using them in 2019).
- An environment-gated noindex whose production value you cannot find (report it Likely under CRAWL-R1 and name the missing config).
- A disallowed URL that carries noindex (never fetched, so the noindex never works; CRAWL-R2).
- Dead URLs redirected to the home page (a soft 404; URLARCH-R1).
