# seoauditor

A read-only **SEO and AI-visibility audit** skill for AI coding agents. It audits how the codebase in the current working directory makes its website discoverable to search engines and AI answer engines end to end (crawlability and indexation, rendering and content-in-HTML, on-page content and semantics, canonicalization, structured data, AI/generative-engine visibility, URL architecture and technical config, Core Web Vitals code signals, social and sharing metadata, internationalization, feeds and syndication, and SEO observability), writes a scored, prioritized, self-contained `seoaudit.md` at the repo root, then prints the verdict in chat. It works from the templates and components, the framework metadata APIs, the `robots.txt` / `llms.txt` / `ai.txt` / sitemap / feed / manifest generators, the head and structured-data markup, and the routing, rendering, redirect, and header config in the repo: it never crawls the live site, never runs Lighthouse, never calls Search Console or the Rich Results Test, and never calls a model.

It is the visibility-layer counterpart to `codeauditor` (code quality), `secauditor` (security), `dbauditor` (database), `uxauditor` (user experience), and `llmauditor` (LLM integration), and it is **dual-compatible**: the same `SKILL.md` runs in both Claude Code and Codex.

- In **Claude Code**: invoke with `/seoauditor`
- In **Codex**: invoke with `$seoauditor`

It is built for the 2026 reality that visibility is now two audiences at once: classic search engines that crawl, render, and rank, and AI answer engines (Google AI Overviews / AI Mode, ChatGPT Search, Perplexity, Bing Copilot, Claude) that crawl, extract, and cite. The dominant fact the audit encodes is that the majority of AI crawlers execute no JavaScript (per the 2024 Vercel/MERJ analysis; Google's AI surfaces are the main exception, since they render via Googlebot), so the primary content, title, canonical, robots directives, and structured data must be in the initial server HTML or they are invisible to AI search regardless of how a site ranks on Google.

## What it audits

The audit is grounded in current technical-SEO and AI-search guidance: Google Search Central (robots.txt and the rule that it is not an indexing control, consolidate duplicate URLs, redirects and soft 404s, JavaScript SEO, URL structure, the structured-data spam/content-match policy, hreflang, page experience), RFC 9309 (robots) and RFC 6596 (rel=canonical), schema.org, web.dev Core Web Vitals (LCP, INP, CLS), the Open Graph protocol (ogp.me), the AI-crawler documentation from OpenAI, Anthropic, and Google (the training-vs-citation bot distinction, Google-Extended), the llms.txt proposal (llmstxt.org, treated as aspirational and not yet consumed by major engines), IndexNow, and the Web App Manifest. It scores twelve dimensions, two of which are conditional on the project's surface:

| Dimension | Weight | Applies |
|---|---|---|
| Crawlability and Indexation Control | 14% | always |
| Rendering and Content-in-HTML | 13% | always |
| On-Page Content, Headings and Semantic HTML | 12% | always |
| Canonicalization and Duplicate Content | 11% | always |
| Structured Data and Rich Results | 10% | always |
| AI and Generative-Engine Visibility (GEO/AEO) | 9% | always |
| URL Architecture and Technical Configuration | 8% | always |
| Performance and Core Web Vitals (code signals) | 6% | always |
| Social and Sharing Metadata | 5% | always |
| Analytics, Verification and SEO Observability | 3% | always |
| Internationalization and hreflang | 5% | if more than one locale exists |
| Feeds, Syndication, Installability and Fast-Indexing | 4% | if a content stream or installable surface exists |

Conditional dimensions (I18N and FEEDS) are dropped and the remaining weights re-normalized when their surface is absent, so the score stays meaningful for a single-language marketing site and a multi-locale news publisher alike.

These dimensions map onto the things teams ask when they want a site to be found: can it be crawled and indexed at all, does its content actually reach crawlers and AI fetchers, is the on-page and structured-data layer right, is there one canonical URL per page, is it set up to be cited by AI answer engines, is the URL and technical config sound, is it fast and stable, do its link previews work, is it correctly internationalized, is its content syndicated, and is any of it measured and protected from regression.

## How it works

The method runs in phases: orient and detect the stack, rendering mode, site type, and conditional surfaces; map the visibility and crawl surface; analyze across every lens with `file:line` evidence and the signal path to the crawler; verify each candidate adversarially and cluster duplicates into systemic patterns; score with conditional re-normalization (a single Critical caps the dimension at 69 and the overall at 79, and a visibility-floor critical caps the overall grade outright); prioritize into Quick wins / Plan now / Verify first / Backlog; write `seoaudit.md`; and report the verdict in chat.

Two principles make it different from a generic SEO checklist:

- **It verifies against what reaches the crawler, not the intent.** A `react-helmet` `<title>` in a client-only SPA reaches no non-JS crawler; a Next.js `alternates.canonical` with no `metadataBase` resolves to `localhost` in production; a `<meta name="robots" content="noindex">` on a URL that is `Disallow`-ed in robots.txt is never seen. The gap between the markup's apparent intent and what is actually served and crawlable is itself a finding, and often the most serious one.
- **It actively hunts paper controls and refuses theater.** A `noindex:` line in robots.txt (ignored since 2019), `<priority>`/`<changefreq>` on every sitemap entry (ignored by Google), `rel=next/prev` pagination tags (unused since 2019), a hardcoded homepage canonical on every page (collapses the whole site to one URL), hreflang with no return tags (the entire cluster is discarded), a relative `og:image` (a blank social card), a fabricated `AggregateRating` (a manual-action trigger), and an `llms.txt` shipped as an "AI SEO" control (aspirational, roughly 97% of files get zero AI fetches): each looks like SEO and holds nothing. The audit distinguishes inert theater to remove from actively harmful controls that defeat the intended outcome.

Every finding is self-contained: an exact `file:line` and the signal path (and, for rendering and canonical findings, whether the signal reaches the crawler at all), the concrete visibility consequence and its blast radius, a specific fix in the project's own stack, a way to verify the fix against the served output, and a reference (Google Search Central, schema.org, RFC 9309, web.dev, the OGP or llms.txt spec, or the framework SEO doc). An ownership map ensures each defect is scored by exactly one dimension instead of triple-counting across lenses.

Because it is a static, read-only code audit, it is explicit about what it cannot see: the live HTTP status and headers, whether environment-gated guards resolve correctly in the deployed environment, the rendered DOM a crawler or AI bot actually receives, real Core Web Vitals field data, index coverage and rankings, whether AI engines actually fetch or cite the site, and off-repo CDN/WAF behavior. Findings that depend on these are marked Suspected with what would confirm them (a live fetch, Lighthouse, the Rich Results Test, or Search Console).

## Install

The skill is a single `skills/seoauditor/SKILL.md`. Install it into whichever tool you use.

### Claude Code

As a personal skill:

```sh
mkdir -p ~/.claude/skills/seoauditor
cp skills/seoauditor/SKILL.md ~/.claude/skills/seoauditor/SKILL.md
```

Or install the whole repo as a Claude Code plugin (it ships a `.claude-plugin/plugin.json` manifest) via your plugin workflow, then invoke `/seoauditor`.

### Codex

```sh
mkdir -p ~/.codex/skills/seoauditor
cp skills/seoauditor/SKILL.md ~/.codex/skills/seoauditor/SKILL.md
```

Codex also reads skills from `~/.agents/skills/` and `.agents/skills/` (repo-local); any of these works. Invoke with `$seoauditor`, or run `/skills` to list.

## Usage

From the root of the project you want to audit:

- Claude Code: `/seoauditor` (optionally pass a subpath, a single template or route group, or one locale to scope the audit)
- Codex: `$seoauditor`

The skill writes `seoaudit.md` to the audited project's root and prints the score, scorecard, and top fixes in chat.

## Output

`seoaudit.md` is written for a reader with no memory of the audit (typically another agent that will fix the findings). It contains the snapshot, the visibility and crawl map, the overall score and scorecard, "what to fix first", strengths to preserve, systemic root causes, the full findings, a remediation plan, scope and limitations, and a "how to use this report" protocol.

## License

MIT. See [LICENSE](LICENSE).
