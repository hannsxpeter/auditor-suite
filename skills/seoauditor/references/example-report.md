# SEO and AI visibility audit: tidewater-bikes

> Read-only SEO and AI-visibility audit of the code as written, 2026-09-26. The live site was not crawled, and no Lighthouse, Search Console, validator, or model was called. Mode: full. Scope: whole project.
> Self-contained: every finding cites the file and line it is about, so an agent holding only this report and the code can act on it. Written with seoauditor (auditor-suite 1.1.0).

## Snapshot

- Project: tidewater-bikes (the example fixture in tests/fixtures/seoauditor)
- Stack: Astro 5 static output with `@astrojs/sitemap`; both routes prerender to HTML at build; no client islands.
- Size and coverage: 4 source files, robots.txt, and 3 image assets; exhaustive.
- Maturity and exposure: public marketing site for one local bike repair shop; indexable pages `/` and `/services`; no signed-in area.
- Active dimensions: CRAWL, RENDER, CONTENT, CANON, SCHEMA, AIVIS, URLARCH, PERF, SOCIAL, OBSV
- Not applicable: I18N (one language), FEEDS (no content stream, feed, or manifest)
- Not assessed: none
- Excluded: none

## Map

- Indexation: `public/robots.txt` has one `*` group with `Disallow: /_astro/` and an absolute Sitemap line; no meta robots, X-Robots-Tag, or environment guard exists.
- Rendering: static output (`astro.config.mjs:4`); both routes ship text, head tags, and JSON-LD in the built HTML.
- URLs and canonicals: the origin is set once in `site` (`astro.config.mjs:5`); canonicals come only from `src/layouts/Base.astro:18` and are relative; the repo holds no redirect or header config.
- Content and entities: title template in `src/layouts/Base.astro:16`, fed by page props; BicycleStore JSON-LD on the home page (`src/pages/index.astro:34`).
- AI surface: no AI-crawler rules, llms.txt, or ai.txt; all content is static HTML.
- Discovery: `@astrojs/sitemap` (`astro.config.mjs:6`), referenced at `public/robots.txt:4`; no feeds or hreflang.
- Flow traced: `src/pages/services.astro:11` passes title and description to `src/layouts/Base.astro:7`, which prints the title (16), a relative canonical (18), and a relative og:image (23). The style block at `src/layouts/Base.astro:44` is emitted under `/_astro/` because `astro.config.mjs:8` turns off inlining, and `public/robots.txt:2` blocks that folder.

## Overall score

<!-- BEGIN GENERATED: score (score.sh --write fills this block; do not edit it by hand) -->
**Overall: 97/100, Grade A (exemplary)**

| Dimension | Score | Grade | Weight | Critical | High | Medium | Low | Suspected |
|---|---:|---|---:|---:|---:|---:|---:|---:|
| CRAWL Crawlability and Indexation Control | 90 | A | 15.4% | 0 | 1 | 0 | 0 | 0 |
| RENDER Rendering and Content-in-HTML | 100 | A | 14.3% | 0 | 0 | 0 | 0 | 0 |
| CONTENT On-Page Content, Headings and Semantic HTML | 100 | A | 13.2% | 0 | 0 | 0 | 0 | 0 |
| CANON Canonicalization and Duplicate Content | 97 | A | 12.1% | 0 | 0 | 1 | 0 | 0 |
| SCHEMA Structured Data and Rich Results | 100 | A | 11.0% | 0 | 0 | 0 | 0 | 0 |
| AIVIS AI and Generative-Engine Visibility | 100 | A | 9.9% | 0 | 0 | 0 | 0 | 0 |
| URLARCH URL Architecture and Technical Configuration | 98 | A | 8.8% | 0 | 0 | 0 | 0 | 1 |
| PERF Performance and Core Web Vitals | 100 | A | 6.6% | 0 | 0 | 0 | 0 | 0 |
| SOCIAL Social and Sharing Metadata | 90 | A | 5.5% | 0 | 1 | 0 | 0 | 0 |
| OBSV Analytics, Verification and SEO Observability | 99 | A | 3.3% | 0 | 0 | 0 | 1 | 0 |
| **Overall** | **97** | **A** | 100% | 0 | 2 | 1 | 1 | 1 |

Caps applied: none.
Not applicable (not scored): I18N (one language), FEEDS (no content stream, feed, or manifest).
Findings: Critical 0, High 2, Medium 1, Low 1 (Suspected, not yet confirmed: 1).
Computed by score.sh from the findings below (rules: references/protocol.md, Scoring).
<!-- END GENERATED: score -->

Verdict: A small static Astro site whose text, titles, and local-business markup all reach crawlers as plain HTML. Its defects sit in two files: robots.txt blocks the `/_astro/` stylesheet, and `Base.astro` writes the canonical and share image as bare paths although `site` is set. Every fix is small.

Calibration: a two-page local business site on static hosting, graded as a public marketing site that depends on local search.

## What to fix first

<!-- BEGIN GENERATED: fix-first (score.sh --write) -->
1. [SOCIAL-001] Every page shares a relative og:image, so link previews lose their image - High, effort S. Open Graph needs an absolute image URL, so Facebook, LinkedIn, Slack, and chat apps show the home and services pages with no image.
2. [CRAWL-001] robots.txt blocks /_astro/, where the site's only stylesheet is built - High, effort S. Googlebot will not fetch the stylesheet, so it renders `/` and `/services` unstyled and cannot judge their mobile layout.
<!-- END GENERATED: fix-first -->

## Strengths (preserve these)

- Both pages are static HTML with no islands, so every crawler, including AI crawlers that run no JavaScript, gets the full text (`src/pages/services.astro:15`).
- The origin is set once and the sitemap integration uses it for absolute URLs (`astro.config.mjs:5`).
- Each page passes its own title and description to the layout (`src/pages/index.astro:22`).
- The BicycleStore JSON-LD renders on the server and matches the name, address, and phone in the footer (`src/pages/index.astro:34`, `src/layouts/Base.astro:39`).

## Systemic patterns (root causes)

- SYS-1: `src/layouts/Base.astro` writes site URLs as bare paths; only og:url goes through `Astro.site`. Members: CANON-001, SOCIAL-001. Root fix: build every head URL from `Astro.site`, reusing `pageUrl` (line 8) for the canonical and `new URL(path, Astro.site)` for the image.

## Findings

### [CRAWL-001] robots.txt blocks /_astro/, where the site's only stylesheet is built
- Severity: High | Confidence: Confirmed | Effort: S | Dimension: CRAWL
- Location: `public/robots.txt:2` (also `astro.config.mjs:8`)
- Evidence: robots.txt has `Disallow: /_astro/` under `User-agent: *`, and `inlineStylesheets: 'never'` makes the layout's styles a file under `/_astro/` on every page.
- Impact: Googlebot will not fetch the stylesheet, so it renders `/` and `/services` unstyled and cannot judge their mobile layout. The text still indexes because the pages are static HTML.
- Recommendation: delete line 2 of `public/robots.txt` and keep the Sitemap line.
- Verify the fix: after deploy, a robots.txt tester allows `/_astro/` for Googlebot, and URL Inspection shows the page with its styles.
- References: Google Search Central (JavaScript SEO basics; robots.txt), RFC 9309
- Related: OBSV-001

### [SOCIAL-001] Every page shares a relative og:image, so link previews lose their image
- Severity: High | Confidence: Confirmed | Effort: S | Dimension: SOCIAL
- Location: `src/layouts/Base.astro:23`
- Evidence: the layout prints `<meta property="og:image" content="/images/og-default.png" />` as written, although line 8 already builds `pageUrl` from `Astro.site`.
- Impact: Open Graph needs an absolute image URL, so Facebook, LinkedIn, Slack, and chat apps show the home and services pages with no image.
- Recommendation: print `content={new URL('/images/og-default.png', Astro.site)}` and add `og:image:width` (1200), `og:image:height` (630), and `og:image:alt`.
- Verify the fix: the og:image in the built `dist/index.html` starts with `https://www.tidewaterbikes.example/`.
- References: ogp.me
- Related: SYS-1

### [CANON-001] Canonical is the bare path, so duplicate hosts canonicalize to themselves
- Severity: Medium | Confidence: Confirmed | Effort: S | Dimension: CANON
- Location: `src/layouts/Base.astro:18`
- Evidence: every page gets `<link rel="canonical" href={Astro.url.pathname} />`, a relative URL such as `/services`.
- Impact: a relative canonical resolves against whichever host served the page, so a copy on the bare domain or on http names itself canonical instead of `https://www.tidewaterbikes.example`.
- Recommendation: use the absolute URL from line 8: `<link rel="canonical" href={pageUrl} />`.
- Verify the fix: the canonical in the built services page starts with `https://www.tidewaterbikes.example/services`.
- References: RFC 6596, Google Search Central (consolidate duplicate URLs)
- Related: SYS-1, URLARCH-001

### [URLARCH-001] No redirect in the repo sends http and the bare domain to https://www
- Severity: Medium | Confidence: Suspected | Effort: S | Dimension: URLARCH
- Location: `astro.config.mjs:5`
- Evidence: the host is declared only as `site: 'https://www.tidewaterbikes.example'`; the repo has no `_redirects`, `netlify.toml`, `vercel.json`, or server config, so any redirects live in host settings this audit cannot see.
- Impact: if http and the bare domain answer 200, each page exists up to four times, and with CANON-001 each copy names itself canonical. Medium, not High, because the host may already redirect.
- Recommendation: in the host settings (or `public/_redirects` if the host reads it), 301 `http://` and the bare domain to `https://www.tidewaterbikes.example` in one hop.
- Verify the fix: `curl -sI http://tidewaterbikes.example/services` returns 301 to the https www URL, which returns 200.
- References: Google Search Central (redirects and Google Search)
- Related: CANON-001

### [OBSV-001] Nothing checks robots.txt or the head tags before deploy
- Severity: Low | Confidence: Confirmed | Effort: S | Dimension: OBSV
- Location: `package.json:8`
- Evidence: the only scripts are `dev`, `"build": "astro build"`, and `preview`; there are no tests and no CI workflow.
- Impact: the `/_astro/` block in CRAWL-001 shipped unnoticed, and nothing would catch a changed canonical or a stray noindex.
- Recommendation: add a post-build CI check that fails when `dist/robots.txt` disallows `/` or `/_astro/`, or a page in `dist/` lacks an absolute canonical.
- Verify the fix: restoring `Disallow: /_astro/` in a branch makes the check fail.
- References: Google Search Central (SEO starter guide)
- Related: CRAWL-001

## Dimension notes

### CRAWL: Crawlability and Indexation Control
- Checked: CRAWL-R1, CRAWL-R2, CRAWL-R3, CRAWL-R4, CRAWL-R5, CRAWL-R6, CRAWL-R7, CRAWL-R8
- Note: CRAWL-001 is the only defect; there is no noindex, the Sitemap line is absolute, the sitemap sets no lastmod, and there are no parameter URLs.

### RENDER: Rendering and Content-in-HTML
- Checked: RENDER-R1, RENDER-R2, RENDER-R3, RENDER-R4, RENDER-R5, RENDER-R6, RENDER-R7
- Note: Clean: static pages, no islands, plain `<a href>` navigation.

### CONTENT: On-Page Content, Headings and Semantic HTML
- Checked: CONTENT-R1, CONTENT-R2, CONTENT-R3, CONTENT-R4, CONTENT-R5, CONTENT-R6, CONTENT-R7
- Note: Clean: per-page titles and descriptions, one `<h1>` each, a layout `<main>`, descriptive links; bylines do not apply to a shop site.

### CANON: Canonicalization and Duplicate Content
- Checked: CANON-R1, CANON-R2, CANON-R3, CANON-R4, CANON-R5
- Note: One canonical per page, built from the path without query strings, but relative (CANON-001).

### SCHEMA: Structured Data and Rich Results
- Checked: SCHEMA-R1, SCHEMA-R2, SCHEMA-R3, SCHEMA-R4, SCHEMA-R5, SCHEMA-R6
- Note: Clean: the BicycleStore block has no ratings and matches the footer; the repo names no profiles for `sameAs`.

### AIVIS: AI and Generative-Engine Visibility
- Checked: AIVIS-R1, AIVIS-R2, AIVIS-R3, AIVIS-R4, AIVIS-R5
- Note: Clean: no AI rules or AI files, and nothing needs adding; the HTML uses real headings and lists.

### URLARCH: URL Architecture and Technical Configuration
- Checked: URLARCH-R1, URLARCH-R2, URLARCH-R3, URLARCH-R4, URLARCH-R5, URLARCH-R6
- Note: Host redirects are outside the repo (URLARCH-001, Suspected); unknown paths fall to the host's own 404.

### PERF: Performance and Core Web Vitals
- Checked: PERF-R1, PERF-R2, PERF-R3, PERF-R4, PERF-R5, PERF-R6
- Note: Clean: no content images, no scripts, one small stylesheet.

### SOCIAL: Social and Sharing Metadata
- Checked: SOCIAL-R1, SOCIAL-R2, SOCIAL-R3, SOCIAL-R4, SOCIAL-R5, SOCIAL-R6
- Note: Only the image is wrong (SOCIAL-001); og:url is absolute, `twitter:card` is set, the icons exist, and charset, viewport, and `lang` are correct.

### OBSV: Analytics, Verification and SEO Observability
- Checked: OBSV-R1, OBSV-R2, OBSV-R3, OBSV-R4, OBSV-R5, OBSV-R6
- Note: No analytics, consent, A/B, verification, or user-agent code exists; the gap is the missing check (OBSV-001).

## Remediation plan

<!-- BEGIN GENERATED: plan (score.sh --write) -->
- Quick wins (Critical or High, not Suspected, effort S): SOCIAL-001, CRAWL-001
- Plan now (Critical or High, not Suspected, effort M or L), in this order: none
- Verify first (Suspected; confirm against the code before acting): URLARCH-001
- Schedule (Medium): CANON-001
- Backlog (Low): OBSV-001
<!-- END GENERATED: plan -->

## Scope and limitations

Read every file. Not verified: the host's redirects (URLARCH-001 needs `curl -sI` against production), the built `dist/` output (no build was run), and field Core Web Vitals. The findings assume static hosting with no server of its own.

## How to use this report (for the acting agent)

1. Triage by severity and confidence. Confirmed Critical and High findings are safe to act on now, in the order under "What to fix first". Re-verify every Suspected finding against the cited code before changing anything.
2. Confirm the stated assumption on Likely findings before acting.
3. Fix root causes first: prefer a systemic pattern's root fix over its individual members.
4. Preserve the strengths; do not refactor them away while fixing something else.
5. Fix the visibility floor first: make the site crawlable, indexable, server-rendered, and consistently canonical before tuning anything downstream. Remove inert theater, repair controls that defeat their own purpose, and never add llms.txt or ai.txt as if they were load-bearing.
6. One finding, one change, verified: after each fix, run its "Verify the fix" step and keep the change traceable to the finding ID.
7. Do not widen scope silently; note adjacent issues instead of sprawling into a rewrite.
8. Re-run the audit to measure progress: confirm findings are resolved, not relocated, and that the strengths did not regress.
