# Changelog

All notable changes to seoauditor are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [auditor-suite 1.1.0] - 2026-09-26

Rebuilt for small and local models as well as frontier models: a short spine,
rule cards read on demand, and shared scripts that do the mechanical work. The
domain knowledge of 1.0.0 is kept; it now lives in cards, stacks.md, and
facts.md.

### Changed
- `SKILL.md` is now a spine of about 11 KB (was about 72 KB): contract, modes,
  an eight-step workflow, the dimension table, and judgment notes. The
  checklists moved into twelve card files, `references/<DIM>.md`, with 74
  rule cards.
- The ownership map became card placement: each defect has one card in its
  owning dimension, and each file's "Not here" line points to the owner of
  nearby defects (for example the environment noindex guard is CRAWL-R1 in
  page metadata and URLARCH-R4 in header config; soft 404s are URLARCH-R1 on
  the server and RENDER-R5 in a client-rendered app).
- Findings use the suite's shared format and protocol; the separate "Owner"
  field is gone because the dimension is the owner.
- Scoring is computed by `score.sh`. The visibility floor is now the floor
  dimensions CRAWL, RENDER, CANON, AIVIS, URLARCH, OBSV, and I18N: one
  Critical finding in any of them holds the overall score at 69.
- The Critical-class list is now the set of `(quick)` cards, each with
  explicit severity conditions.

### Added
- Modes: `quick` (Critical-class triage without a score), `only=DIM,DIM`
  (partial score), and path scoping.
- Shared read-only scripts: `inventory.sh`, `scan.sh`, `new-report.sh`,
  `score.sh`, and `check-report.sh`, plus `assets/skill.conf`,
  `dimensions.tsv`, `patterns.tsv` (79 lead patterns for 72 of the 74 cards,
  valid in both grep and ripgrep), and `surfaces.tsv` (probes for the site
  surface, I18N, and FEEDS).
- `references/stacks.md`: where Next.js (App and Pages Router), Nuxt, Astro,
  SvelteKit, Remix and React Router 7, Gatsby, Angular, plain SPAs,
  WordPress, Hugo, Jekyll, Eleventy, Docusaurus, Django, Rails, Laravel,
  hosted platforms, and common hosts put each visibility signal.
- `references/facts.md`: dated facts with sources and a last-reviewed date
  (robots and sitemap rules, FAQ and HowTo changes in 2023, the sitelinks
  search box retirement in November 2024, the June 2025 structured-data
  retirements, AI crawler user agents, llms.txt status, Google-Extended,
  IndexNow, analytics sunsets).
- `references/example-report.md`, a finished report of the Astro fixture in
  `tests/fixtures/seoauditor/`, and an eval case in
  `evals/seoauditor/full-audit/` (a Next.js App Router site with nine planted
  defects and two decoys).

### Fixed
- RENDER no longer treats `'use client'` as proof of client-only content;
  client components still render on the server, and the card asks what the
  server HTML contains.
- Soft 404 ownership was split two ways in 1.0.0 (the SPA fallback appeared
  under both RENDER and URLARCH); each case now has one card.
- Viewport, apple-touch-icon, licensing, and date checks each had two owners;
  each now has one (SOCIAL-R6, SOCIAL-R4, AIVIS-R4, and AIVIS-R5 with SCHEMA-R2).
- The X card check no longer claims that `property=` makes twitter tags inert;
  it asks for the documented `name=` attribute.
- Claims that could not be confirmed at review time, such as the widely cited
  share of llms.txt files with no AI fetches, are marked "verify" in
  facts.md instead of being stated as fact.

## [auditor-suite 1.0.0] - 2026-07-14

Moved into the [auditor-suite](https://github.com/hannsxpeter/auditor-suite)
monorepo as `skills/seoauditor/`, with the standalone repo's full git history
preserved. Standalone versioning is retired; the skill now follows the
auditor-suite release train.

### Changed
- The standalone `.claude-plugin/plugin.json` manifest is retired; plugin
  packaging now lives in the hub under `plugins/seoauditor/`.
- The audit content in `SKILL.md` is unchanged from standalone 0.1.0.

## [0.1.0] - 2026-06-19

First release.

### Added
- The `seoauditor` skill: a read-only audit of how a codebase makes its website
  discoverable to search engines and AI answer engines that writes a scored,
  prioritized `seoaudit.md` and then prints the verdict in chat. Dual-compatible:
  the same `SKILL.md` runs in Claude Code (`/seoauditor`) and Codex
  (`$seoauditor`).
- Twelve analysis dimensions, two of them conditional on the project's surface:
  Crawlability and Indexation Control (CRAWL); Rendering and Content-in-HTML
  (RENDER); On-Page Content, Headings and Semantic HTML (CONTENT);
  Canonicalization and Duplicate Content (CANON); Structured Data and Rich
  Results (SCHEMA); AI and Generative-Engine Visibility (AIVIS); URL Architecture
  and Technical Configuration (URLARCH); Performance and Core Web Vitals (PERF);
  Social and Sharing Metadata (SOCIAL); Analytics, Verification and SEO
  Observability (OBSV); Internationalization and hreflang (I18N, conditional);
  and Feeds, Syndication, Installability and Fast-Indexing (FEEDS, conditional).
- A dual mandate covering both classic technical/on-page SEO and the AI /
  generative-engine visibility (GEO/AEO) layer: AI-crawler policy with the
  training-vs-citation bot distinction, server-rendered content for the no-JS AI
  fetchers, structured data for entity grounding, content licensing, and the
  honest treatment of llms.txt / ai.txt as aspirational rather than load-bearing.
- Explicit scoring rubric with per-dimension weights, conditional
  re-normalization, score bands, and a rule that a single Critical finding caps
  the dimension and the overall score, plus a visibility floor (sitewide
  deindexing, CSR-invisibility to AI crawlers, cloaking, canonical collapse,
  self-defeating AI block) that caps the overall grade outright.
- An ownership map that assigns each cross-lens defect (a client-rendered page, an
  X-Robots-Tag noindex, a sitemap, a cross-language canonical, a WAF crawler
  block) to exactly one dimension so findings are not triple-counted.
- An eight-phase method: orient and detect the stack, rendering mode, site type,
  and conditional surfaces; map the visibility and crawl surface; analyze across
  every lens with `file:line` evidence and the signal path to the crawler; verify
  adversarially and cluster; score; prioritize into Quick wins / Plan now /
  Verify first / Backlog; and write the report, then summarize in chat.
- Self-contained findings (Severity, Confidence, Effort, Location, Evidence,
  Impact, Recommendation, Verify-the-fix, References, Related) grounded in Google
  Search Central, schema.org, RFC 9309, RFC 6596, web.dev Core Web Vitals, the
  Open Graph protocol, the AI-crawler docs, the llms.txt proposal, IndexNow, and
  the framework SEO docs, written so another agent can act on them with no prior
  context.
- A paper-control discipline that distinguishes inert theater to remove
  (`rel=next/prev`, `<priority>`/`<changefreq>`, `noindex:` in robots.txt,
  deprecated FAQ/HowTo rich-result markup) from actively harmful controls that
  defeat the intended outcome (a homepage canonical on every page, hreflang with
  no return tags, a robots-blocked noindex), and an explicit static-blind-spot
  discipline that marks runtime-dependent findings Suspected.
- Project documentation: README, LICENSE, this changelog, and a
  `.claude-plugin/plugin.json` manifest.

[0.1.0]: https://github.com/hannsxpeter/seoauditor/releases/tag/v0.1.0
