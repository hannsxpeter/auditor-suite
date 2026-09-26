# Dated facts

Last reviewed: 2026-09-26

Search and AI platforms change often. Cite these facts instead of memory, with their date. A line marked "(verify)" could not be confirmed when this file was last reviewed: check its source before relying on it, and write "verify" in any finding that uses it. If the Last reviewed date is more than a year before the audit date, say so in Scope and limitations.

## Robots and sitemaps

- robots.txt `noindex:`, `nofollow:`, and `crawl-delay:` rules: Google stopped supporting them on 2019-09-01 (announced 2019-07-02). Verify at: https://developers.google.com/search/blog/2019/07/a-note-on-unsupported-rules-in-robotstxt
- RFC 9309, the Robots Exclusion Protocol, was published in September 2022. Google applies the longest matching rule and, on a tie, the least restrictive one (Allow); a group that names a crawler replaces the `*` group for that crawler; Google reads the first 500 KiB of the file. Verify at: https://www.rfc-editor.org/rfc/rfc9309 and https://developers.google.com/search/docs/crawling-indexing/robots/robots_txt
- robots.txt status codes (Google): a 4xx other than 429 counts as "no rules"; a 5xx or 429 counts as "disallow everything" until the file loads again; after about 30 days of errors Google uses the last cached copy, or crawls without rules if it has none. Verify at: https://developers.google.com/search/docs/crawling-indexing/robots/robots_txt
- noindex works only on a page Google can crawl; a URL blocked by robots.txt can still be indexed without its content when other pages link to it. Verify at: https://developers.google.com/search/docs/crawling-indexing/block-indexing
- `rel="next"` and `rel="prev"`: Google said on 2019-03-21 that it had not used them for indexing for years. Verify at: https://developers.google.com/search/docs/specialty/ecommerce/pagination-and-incremental-page-loading
- Sitemaps: Google ignores `<priority>` and `<changefreq>`, and uses `<lastmod>` only when it is consistently and verifiably accurate. Limits per file: 50,000 URLs or 50 MB uncompressed. Verify at: https://developers.google.com/search/docs/crawling-indexing/sitemaps/build-sitemap
- The Google sitemap ping endpoint was deprecated on 2023-06-26 and stopped working about six months later. Verify at: https://developers.google.com/search/blog/2023/06/sitemaps-lastmod-ping
- Faceted navigation: Google's guidance (December 2024) is to keep unneeded facet URLs out of the crawl with robots.txt rules or URL fragments (verify the date). Verify at: https://developers.google.com/search/docs/crawling-indexing/crawling-managing-faceted-navigation

## Rendering

- Google renders JavaScript with an evergreen Chromium, often some time after the first crawl. When Google finds noindex in the initial HTML it skips rendering, so JavaScript cannot remove that noindex. Verify at: https://developers.google.com/search/docs/crawling-indexing/javascript/javascript-seo-basics
- Single-page apps: to avoid soft 404s, Google advises a JavaScript redirect to a URL the server answers with 404, or adding a noindex robots meta to the error view with JavaScript. Verify at: https://developers.google.com/search/docs/crawling-indexing/javascript/javascript-seo-basics
- Dynamic rendering: Google calls it a workaround, not a recommended solution (documentation updated in 2022). Verify at: https://developers.google.com/search/docs/crawling-indexing/javascript/dynamic-rendering
- AI crawlers and JavaScript: a December 2024 Vercel and MERJ analysis found that the major AI crawlers (OpenAI, Anthropic, Meta, ByteDance, Perplexity) fetch JavaScript files but do not run them; Google's AI surfaces use Googlebot's rendering. Verify at: https://vercel.com/blog/the-rise-of-the-ai-crawler
- Mobile-first indexing covers the whole web: Google crawls with its smartphone agent and indexes the mobile rendering; the last desktop-crawled sites moved by 2024-07-05 (verify the date). Verify at: https://developers.google.com/search/docs/crawling-indexing/mobile/mobile-sites-mobile-first-indexing

## Canonicals

- Google asks for absolute URLs in rel=canonical (relative ones are supported but cause problems), treats several disagreeing canonicals as no canonical, and wants redirects, canonicals, and sitemaps to agree. Verify at: https://developers.google.com/search/docs/crawling-indexing/consolidate-duplicate-urls
- Syndication: since May 2023 Google no longer recommends cross-domain canonicals for syndicated copies; the partner should block indexing of its copy (verify the date). Verify at: https://developers.google.com/search/docs/crawling-indexing/consolidate-duplicate-urls
- Redirects: Google treats 301 and 308 as strong canonical signals and 302 and 307 as weak ones; Googlebot follows up to 10 redirect hops. Verify at: https://developers.google.com/search/docs/crawling-indexing/301-redirects and https://developers.google.com/search/docs/crawling-indexing/http-network-errors
- Search Console's URL Parameters tool was removed on 2022-04-26 (announced 2022-03-28); parameter handling now depends only on the site (canonicals, robots rules, linking). Verify at: https://developers.google.com/search/blog/2022/03/url-parameters-tool-deprecated

## On-page

- Meta keywords: Google said in September 2009 that it does not use the keywords meta tag for ranking. Verify at: https://developers.google.com/search/blog/2009/09/google-does-not-use-keywords-meta-tag

## Structured data

- FAQ and HowTo: on 2023-08-08 Google limited FAQ rich results to well-known, authoritative government and health sites and HowTo rich results to desktop; HowTo rich results were removed entirely in September 2023. Verify at: https://developers.google.com/search/blog/2023/08/howto-faq-changes
- Sitelinks search box: retirement announced 2024-10-21, removed from results worldwide from 2024-11-21. `WebSite` `SearchAction` markup does no harm but produces nothing. Verify at: https://developers.google.com/search/blog/2024/10/sitelinks-search-box
- June 2025 simplification: Google phased out seven features: Book Actions, Course Info, Claim Review, Estimated Salary, Learning Video, Special Announcement, and Vehicle Listing (announced 2025-06-12). The markup still parses. Verify at: https://developers.google.com/search/blog/2025/06/simplifying-search-results
- Self-serving reviews: since 2019-09-16 Google shows no review rich results for LocalBusiness or Organization entities that review themselves. Verify at: https://developers.google.com/search/blog/2019/09/making-review-rich-results-more-helpful
- data-vocabulary.org markup stopped qualifying for rich results on 2020-04-06. Verify at: https://developers.google.com/search/blog/2020/01/data-vocabulary
- Structured data must describe content visible on the page; markup for hidden, invented, or misleading content can bring a manual action. Verify at: https://developers.google.com/search/docs/appearance/structured-data/sd-policies

## AI crawlers

Classify each bot by what blocking it controls. Names change often: check the provider's page before relying on a line.

- OpenAI: GPTBot is for training. OAI-SearchBot feeds ChatGPT search results and citations; a site that blocks it stops appearing in ChatGPT search answers. ChatGPT-User fetches pages a user asks for in ChatGPT and custom GPTs (verify whether OpenAI still applies robots.txt to it). Verify at: https://platform.openai.com/docs/bots
- Anthropic: ClaudeBot is for training; Claude-SearchBot builds the search index behind Claude's answers; Claude-User fetches pages a user asks for. The older anthropic-ai and Claude-Web tokens are retired (verify). Verify at: https://support.anthropic.com (article on how site owners can block the crawler)
- Perplexity: PerplexityBot builds Perplexity's search index (Perplexity says it does not train on it); Perplexity-User fetches pages a user asks for, and Perplexity documents that it generally ignores robots.txt. Verify at: https://docs.perplexity.ai/guides/bots
- Google: Google-Extended is a robots.txt token, not a crawler. It controls use of content for Gemini training and grounding in Gemini apps and Vertex AI, and does not affect Google Search, AI Overviews, or AI Mode, which use Googlebot. Limit AI Overviews and AI Mode with nosnippet, data-nosnippet, max-snippet, or noindex. Verify at: https://developers.google.com/search/docs/crawling-indexing/google-common-crawlers and https://developers.google.com/search/docs/appearance/ai-features
- Apple: Applebot powers Siri, Spotlight, and Safari suggestions, and Apple's answer features; Applebot-Extended (introduced June 2024) is a token that controls training of Apple's models and crawls nothing itself. Verify at: https://support.apple.com/en-us/119829
- Meta: Meta-ExternalAgent crawls for AI training; Meta-ExternalFetcher fetches pages a user asks for and may bypass robots.txt. Verify at: https://developers.facebook.com/docs/sharing/webmasters/web-crawlers
- Common Crawl: CCBot builds the open web archive that many models train on. Verify at: https://commoncrawl.org/ccbot
- ByteDance: Bytespider crawls for training and is widely reported to ignore robots.txt (verify).
- Amazon: Amazonbot serves Alexa answers and other Amazon services (verify its current scope). Verify at: https://developer.amazon.com/amazonbot
- Microsoft: Bing and Copilot use Bingbot, with no separate AI token; Bing said in 2023 that `nocache` limits and `noarchive` removes a page's use in chat answers (verify). Verify at: https://blogs.bing.com/webmaster
- DuckDuckGo: DuckAssistBot fetches pages for DuckAssist answers (verify). Verify at: https://duckduckgo.com/duckduckgo-help-pages/results/duckassistbot
- Enforcement: robots.txt binds only crawlers that choose to obey it, and some AI traffic arrives under undeclared user agents.

## llms.txt and AI files

- llms.txt: proposed by Jeremy Howard (Answer.AI) on 2024-09-03 as a Markdown file at `/llms.txt`: one H1, an optional blockquote, then H2 sections of links. As of the last review no major search or AI engine documents using it for ranking or citation, and Google staff have compared it to the keywords meta tag (verify). Server-log studies in 2025 reported that most llms.txt files get few or no AI-crawler requests; one widely cited figure is about 97% with zero (verify the source before quoting any number). Verify at: https://llmstxt.org
- ai.txt: a 2023 proposal from Spawning for AI training permissions; not a standard, and no major crawler documents honoring it (verify). Verify at: https://site.spawning.ai/spawning-ai-txt
- `noai` and `noimageai` robots values: introduced by DeviantArt in November 2022; not a standard, and no major crawler documents honoring them (verify).
- Creative Commons: CC licenses state reuse terms, and Creative Commons has said it is unsettled whether they govern AI training, so a restrictive CC license is not a dependable training block (verify). Verify at: https://creativecommons.org
- TDMRep, a W3C community protocol, expresses text-and-data-mining reservations under the EU copyright directive (verify). Verify at: https://www.w3.org/community/tdmrep/

## Analytics and verification

- Universal Analytics stopped processing data on 2023-07-01 (Analytics 360 properties on 2024-07-01). Verify at: https://support.google.com/analytics/answer/11583528
- Google Optimize and Optimize 360 were sunset on 2023-09-30. Verify at: https://support.google.com/optimize/answer/12979939
- Consent Mode v2 added `ad_user_data` and `ad_personalization`; Google required them for EEA ad measurement and personalization from March 2024. Verify at: https://developers.google.com/tag-platform/security/guides/consent
- A verified Search Console owner can hide URLs with the Removals tool and add other owners. Verify at: https://support.google.com/webmasters/answer/9689846

## Performance

- Core Web Vitals: INP replaced FID on 2024-03-12. Good at the 75th percentile: LCP 2.5 s or less, INP 200 ms or less, CLS 0.1 or less. Verify at: https://web.dev/articles/vitals
- Lazy-loading the LCP image delays it; web.dev advises eager loading and `fetchpriority="high"` for that image. Verify at: https://web.dev/articles/optimize-lcp

## Social

- Open Graph requires og:title, og:type, og:image, and og:url, with absolute image URLs. Facebook recommends about 1200x630 and rejects share images over 8 MB (verify the limits). Verify at: https://ogp.me and https://developers.facebook.com/docs/sharing/webmasters/images
- X cards: `twitter:card` picks the card type; X falls back to Open Graph for title, description, and image when twitter tags are absent; the documented attribute for twitter tags is `name`. Verify at: https://developer.x.com/en/docs/x-for-websites/cards/overview/markup
- Google favicons: square, a multiple of 48px, at a stable crawlable URL, one per host name (verify the size wording). Verify at: https://developers.google.com/search/docs/appearance/favicon-in-search

## Feeds and fast indexing

- IndexNow launched in October 2021 (Microsoft Bing and Yandex); Bing, Yandex, Naver, Seznam, and Yep take part, and Google does not use it. The key file sits at the site root as `<key>.txt` or at the `keyLocation` URL. Verify at: https://www.indexnow.org
- News sitemaps: list only articles published in the last two days, at most 1,000 `news:news` entries per sitemap. Verify at: https://developers.google.com/search/docs/crawling-indexing/sitemaps/news-sitemap
- Image sitemaps: Google deprecated `image:caption`, `image:title`, `image:license`, and `image:geo_location` in May 2022; `image:loc` remains. Verify at: https://developers.google.com/search/docs/crawling-indexing/sitemaps/image-sitemaps
- JSON Feed 1.1 was published in August 2020. Verify at: https://www.jsonfeed.org/version/1.1/
- WebSub became a W3C Recommendation on 2018-01-23. Verify at: https://www.w3.org/TR/websub/
- Installability (a web app manifest) is not a Google ranking factor (verify; no single official page states it).

## Frameworks

- Next.js App Router: `metadataBase` resolves relative URL metadata. Without it, relative values resolve against a default: `http://localhost:3000` when self-hosted, a Vercel deployment URL on Vercel; `next build` warns about it for social images (verify the fallback for the version in use). Verify at: https://nextjs.org/docs/app/api-reference/functions/generate-metadata#metadatabase
- Next.js redirects: `redirect()` sends 307 (303 in server actions); `permanentRedirect()` sends 308; `next.config` redirects send 308 with `permanent: true` and 307 with `permanent: false`. Verify at: https://nextjs.org/docs/app/api-reference/functions/redirect
- Next.js static export: `redirects()`, `rewrites()`, and `headers()` in `next.config` do not run with `output: 'export'`. Verify at: https://nextjs.org/docs/app/guides/static-exports
- Next.js streaming: once streaming has started the status code cannot change, so `notFound()` inside a streamed boundary keeps 200 and Next.js adds a noindex robots meta (verify for the version in use). Verify at: https://nextjs.org/docs/app/api-reference/file-conventions/loading
- Next.js `next/image` lazy-loads by default; the LCP image needs `priority` (newer versions may rename this option; verify for the version in use). Verify at: https://nextjs.org/docs/app/api-reference/components/image
- Express `res.redirect()` defaults to 302. Verify at: https://expressjs.com/en/api.html#res.redirect
- Apache: an `ErrorDocument 404` that names a full URL makes Apache send a redirect instead of a 404. Verify at: https://httpd.apache.org/docs/2.4/mod/core.html#errordocument

## Hosting

- Vercel adds `X-Robots-Tag: noindex` to preview deployments but not to the production domain (verify). Verify at: https://vercel.com/docs
- Netlify adds `X-Robots-Tag: noindex` to deploy previews and branch deploys (verify). Verify at: https://docs.netlify.com
- Cloudflare: since 2025-07-01, new domains on Cloudflare block known AI crawlers by default unless the owner allows them, and Cloudflare can manage robots.txt content signals for a site (verify). These settings live outside the repo. Verify at: https://blog.cloudflare.com
