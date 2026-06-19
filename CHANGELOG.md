# Changelog

All notable changes to seoauditor are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

[0.1.0]: https://github.com/aihxp/seoauditor/releases/tag/v0.1.0
