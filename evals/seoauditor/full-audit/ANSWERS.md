# Answer key: seoauditor full-audit

Never copied into the eval workspace. Lines refer to files under repo/. The fixture is a Next.js App Router marketing site and help center for "Brightdesk"; the README states that organic search is the main channel and that the team wants to be cited by ChatGPT, Perplexity, and Google AI Overviews. I18N and FEEDS are not applicable (one locale, no content stream, feed, or manifest).

## Planted defects

| Grader | Location | Card | Expected severity | Defect |
|---|---|---|---|---|
| finds-noindex-guard | app/layout.tsx:11 | CRAWL-R1 | Critical | `robots: process.env.VERCEL_ENV !== 'preview' ? { index: false, ... }` is inverted: production (and local) get noindex on every route, previews get index; the comment on line 10 states the opposite intent |
| finds-pricing-client-only | app/pricing/page.tsx:1, :14 | RENDER-R1 | Critical | the pricing page is `'use client'` and fetches its plans in `useEffect`, so the server HTML holds only "Loading plans..."; as a client file it also cannot export metadata, so it has no title, description, or canonical of its own |
| finds-homepage-canonical | lib/seo.ts:16 | CANON-R1 | Critical | `pageMetadata()` sets `alternates: { canonical: SITE_URL }` for every page (home, customers, all docs) while `og:url` uses the page path |
| finds-ai-search-bots-blocked | app/robots.ts:8 | AIVIS-R1 | Critical | the "Opt out of AI training" group also blocks OAI-SearchBot and PerplexityBot (search and citation bots) while the README and public/llms.txt court AI citations |
| finds-invented-rating | components/SoftwareSchema.tsx:9 | SCHEMA-R1 | High (Critical acceptable) | a hardcoded `AggregateRating` (4.9 from 1287) on the home page, which shows no reviews anywhere |
| finds-docs-soft-404 | app/docs/[...slug]/page.tsx:21 | URLARCH-R1 | High | the help-center catch-all renders "Article not found" for unknown slugs without calling `notFound()`, so every junk URL under /docs answers 200 |
| finds-lazy-hero | app/page.tsx:24 | PERF-R1 | High | the home page hero `next/image` sets `loading="lazy"` on the likely LCP element |
| finds-localhost-og-image | app/customers/page.tsx:13 | SOCIAL-R1 | Medium | the customer stories share image is `http://localhost:3000/og/customers.png`, an absolute URL that `metadataBase` does not rewrite |
| finds-sitemap-lastmod | app/sitemap.ts:6, :9, :13 | CRAWL-R7 | Medium (Low acceptable) | every URL gets `lastModified: now` (build or request time) although lib/docs.ts carries a real `updatedAt` per doc |

Five of the nine are Critical-class (CRAWL, RENDER, CANON, and AIVIS are floor dimensions, so the overall score should be held at 69 or lower).

## Decoys (safe; flagging them is a false positive)

| Grader | Location | Why it is safe |
|---|---|---|
| ignores-dashboard-noindex | app/dashboard/layout.tsx:9 | noindex on the signed-in dashboard is correct (CRAWL-R4 Not a finding if: signed-in only); the 307 `redirect()` to the login app is a temporary redirect by design (URLARCH-R3 Not a finding if) |
| ignores-analytics-bot-check | components/Analytics.tsx:7 | the user-agent check only skips loading analytics, in an effect after hydration; the HTML content is identical for bots and people (OBSV-R1 and RENDER-R3 Not a finding if) |

## Not defects, but likely leads

- app/not-found.tsx is the framework's own 404 page and is served with 404 (URLARCH-R1 Not a finding if).
- app/robots.ts:6 disallows only `/api/`, which nothing links to.
- next.config.mjs redirects use `permanent: true` (308) for renamed URLs.
- public/llms.txt is well formed and its links resolve to real routes; it is aspirational, so at most Low (AIVIS-R3), and never a reason to raise severity elsewhere.

## Strengths worth naming

- `metadataBase` is set to the production origin in the root layout (`app/layout.tsx:7`), so relative metadata URLs resolve correctly.
- Help-center articles render on the server with `<time dateTime>` and real headings (`app/docs/[...slug]/page.tsx:35`).
- Renamed URLs use permanent redirects (`next.config.mjs:9`).
- The sitemap is referenced from robots.txt with an absolute URL (`app/robots.ts:10`).
