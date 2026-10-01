# OBSV: Analytics, Verification and SEO Observability

Weight 3. Always active. Floor dimension.
Owns: code that serves crawlers different content (cloaking), A/B tests as crawlers see them, analytics tag correctness (loading, duplicates, ids) and consent wiring, search engine verification tokens, and the safety net against SEO regressions (tests and CI checks).
Not here: prerendering or dynamic rendering for bots as a rendering strategy (RENDER-R6); how analytics scripts load (PERF-R2); user-agent blocks aimed at AI bots (AIVIS-R1); rules that block search crawlers (URLARCH-R5); product event correctness, identity, and test traffic (productauditor MET); experiment assignment, exposure, split validity, and lifecycle (productauditor EXP).
Standards: Google Search spam policies (cloaking), Google Search Central (website testing and Google Search), Google tag and Consent Mode docs, facts.md (Analytics and verification).
Read first: middleware and server code that reads the user agent, analytics and tag components, the consent banner, verification meta tags and files, the test folders, and the CI workflows.

## Cards

### OBSV-R1 Content branches on the crawler's user agent (quick)
- Leads: `scan.sh OBSV-R1` lists user-agent reads, `isbot` checks, and bot names in code.
- Confirm: server code, middleware, or an experiment framework gives crawlers different, empty, or stale content than people get: a user-agent regex that changes the HTML, `isBot()` gating content, a "special version for Googlebot" branch, or a bot-only cache that is never refreshed.
- Not a finding if: the branch changes only analytics, logging, rate limits, or consent, and the HTML stays the same (read both branches).
- Severity: Critical when crawlers get materially different, empty, or stale content: cloaking breaks Google's spam policies and can demote or remove the site; Medium when the difference is small (a hidden promo).
- Fix: serve everyone the same HTML, and keep bot checks for analytics or rate limiting only.
- Verify the fix: HTML fetched with a Googlebot user agent matches HTML fetched with a browser user agent.
- Refs: Google Search spam policies (cloaking)

### OBSV-R2 A/B tests hide content from crawlers or send the wrong redirect and canonical signals
- Leads: `scan.sh OBSV-R2` lists experiment frameworks, variant code, and Google Optimize snippets.
- Confirm: variant URLs lack a canonical to the original; test redirects use 301 instead of 302; the crawler never sees the real content because a variant swaps it on the client; or dead Google Optimize snippets remain (the product ended in 2023).
- Not a finding if: variants render on the server at the same URL and the test is short-lived.
- Severity: Medium; Low for dead snippets (inert, remove them).
- Fix: canonicalize variants to the original, use 302 for test redirects, and delete retired snippets.
- Verify the fix: variant pages carry the original's canonical, and no Optimize script loads.
- Refs: Google Search Central (minimize A/B testing impact in Google Search), facts.md (Analytics and verification)

### OBSV-R3 Analytics tags fire twice, use dead IDs, or never load
- Leads: `scan.sh OBSV-R3` lists gtag calls, Google Tag Manager containers, and measurement IDs.
- Confirm: a hardcoded `gtag.js` and the same GA4 property through Tag Manager both load; a container is included twice; IDs are placeholders (`G-XXXX`) or Universal Analytics `UA-` IDs, which stopped collecting in 2023.
- Not a finding if: each property loads once, and IDs come from environment config with production values.
- Severity: Medium when double firing inflates every metric; Low otherwise.
- Fix: load each property once, from one place, with a real ID.
- Verify the fix: the built HTML loads one gtag or GTM script per property.
- Refs: Google Analytics help (set up GA4), facts.md (Analytics and verification)

### OBSV-R4 The consent banner never updates consent, or tags load before the default
- Leads: `scan.sh OBSV-R4` lists Consent Mode calls and consent platform code.
- Confirm: `gtag('consent', 'default', ...)` runs after the tags load or never; the banner blocks tags but never calls `gtag('consent', 'update', ...)` when the user accepts; Consent Mode v2 fields (`ad_user_data`, `ad_personalization`) are missing where EEA ad measurement is used.
- Not a finding if: the site has no EEA or UK audience and no consent duty; a consent platform integration makes these calls (read its config).
- Severity: Medium, because most EEA and UK measurement is lost; Low when analytics drives no decisions.
- Fix: set the consent default before any tag loads, and call the update from the banner's accept handler.
- Verify the fix: in the built HTML the consent default precedes the tag script, and the accept handler calls the consent update.
- Refs: Google tag docs (Consent Mode), facts.md (Analytics and verification)

### OBSV-R5 Search engine verification tokens are unowned or conflicting
- Leads: `scan.sh OBSV-R5` lists google-site-verification, msvalidate.01, and other verification tokens and files.
- Confirm: several different `google-site-verification` tokens are present, or a token or `google*.html` file belongs to a property nobody on the team owns (a copied template, an agency that left). A verified owner can read search data and request URL removals.
- Not a finding if: each token maps to a property the team documents (README, environment names).
- Severity: High when a token plausibly belongs to an outside party (use Suspected, because ownership cannot be read from code); Low for stale duplicates.
- Fix: keep only the tokens of properties the team owns, and remove old owners in Search Console.
- Verify the fix: the built HTML carries one token per search engine, each mapped to a documented property.
- Refs: Search Console Help (verify your site ownership; manage owners and users)

### OBSV-R6 No safety net against SEO regressions
- Leads: `scan.sh OBSV-R6` lists tests and CI steps that mention titles, canonicals, robots, sitemaps, or links.
- Confirm: nothing asserts the title, canonical, robots, hreflang, or JSON-LD of key templates; nothing checks that the production robots.txt and sitemap build correctly; no CI job checks broken links or redirect chains.
- Not a finding if: such tests exist and run in CI on the dynamic templates, not one static page.
- Severity: Medium where search traffic matters; Low for small sites. The absence is the finding: cite the CI workflow or test folder where the check belongs.
- Fix: add a test that renders the home page and one page per template and asserts robots, canonical, title, and JSON-LD, plus a check of the production robots.txt.
- Verify the fix: a branch that breaks the canonical fails CI.
- Refs: Google Search Central (SEO starter guide)

## Also check
- An SEO test that snapshots one static page and never the dynamic templates (file under OBSV-R6).

## Paper controls (look protective, protect nothing)
- A verification meta tag for someone else's property, or several conflicting tokens (OBSV-R5).
- A cookie banner that never sends a consent signal (OBSV-R4).
- Analytics installed twice (OBSV-R3).
- A user-agent branch that "serves a hydrated DOM to Googlebot": cloaking dressed as a fix (OBSV-R1).
- A README badge with no CI job behind it.
