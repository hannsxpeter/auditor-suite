---
name: seoauditor
description: Audits how a codebase makes its website visible to search engines and AI answer engines (crawl and index controls, server rendering, on-page content, canonicals, structured data, AI-crawler rules and llms.txt, URLs and redirects, Core Web Vitals code signals, share previews, hreflang, feeds, and SEO monitoring) and writes seoaudit.md, a scored, prioritized, self-contained report, then prints the verdict in chat. Use when the user asks for an SEO audit, a technical SEO or AI visibility (GEO, AEO) review, why pages are not indexed or cited, or a pre-launch search readiness check. Read-only: never edits source, never crawls the live site, never runs Lighthouse, and never calls Search Console, a validator, or a model. Modes: full (default), quick (Critical-class triage), only=DIM,DIM, or a path. Invoke with /seoauditor in Claude Code or $seoauditor in Codex.
allowed-tools: 'Bash(bash "${CLAUDE_SKILL_DIR}/scripts/*)'
---

# seoauditor

**You are now running this audit. Do it yourself, starting now, by working through the Workflow below with your own tools.** Nothing runs in the background. The audit is finished only when `check-report.sh` prints OK and you have sent the chat summary.

Audits how the codebase in the current directory makes its website visible to search engines and AI answer engines, and writes `seoaudit.md` at its root: scored, prioritized, and self-contained, so another agent holding only the report and the code can fix what it finds. Then prints the verdict in chat.

## Contract

- Read-only. Create or change no file except `seoaudit.md` at the project root. Never run the project, its tests, builds, or dev server; never crawl or fetch the live site; never run Lighthouse or PageSpeed; never call Search Console, Bing Webmaster Tools, the Rich Results Test, or any model or AI engine.
- Allowed: reading and searching files, read-only shell commands (`git log`, `git show`, `ls`, `wc`), and this skill's scripts. The scripts only read, except `new-report.sh` and `score.sh --write`, which write only `seoaudit.md`.
- Evidence: every finding cites a `path:line` you opened and quotes the code there. A `scan.sh` lead is a place to read, never a finding by itself.
- Judge what reaches the crawler: a tag counts only if it is in the HTML the server sends for that route.
- Never claim you crawled, measured, validated, or checked rankings. Put the live check (curl, URL Inspection, Rich Results Test, Lighthouse, Search Console) in Verify the fix, for the acting agent to run after the fix.
- Finish by sending the output of `score.sh --chat`. Never finish silently.

## Paths

`${CLAUDE_SKILL_DIR}` is this skill's folder, the one that contains this SKILL.md; Claude Code fills it in. If you still see the literal text `${CLAUDE_SKILL_DIR}`, replace it with that folder's absolute path in every command. Run every command from the project root.

## Modes

Text after the skill name picks the mode:
- nothing or `full`: every active dimension, every card.
- `quick`: only the cards tagged (quick), the Critical-class checks; no numeric score.
- `only=CRAWL,RENDER`: only those dimensions, every card; the score is labeled partial.
- a path, alone or after a mode (`quick app/blog`): audit only that part of the tree.

## Workflow

Copy this checklist into your notes and tick each step as you finish it.

- [ ] 1. Run `bash "${CLAUDE_SKILL_DIR}/scripts/inventory.sh"` (add the path if scoped). If it prints NO SOURCE CODE FOUND, tell the user and stop. If it prints `domain surface: NOT FOUND`, look for templates, HTML, or a head or metadata layer; if there is none, tell the user there is no website to audit and stop.
- [ ] 2. Read `${CLAUDE_SKILL_DIR}/references/protocol.md` (the rules for every finding), `${CLAUDE_SKILL_DIR}/references/example-report.md` (a finished report), and `${CLAUDE_SKILL_DIR}/references/facts.md` (dated platform facts; cite them instead of memory).
- [ ] 3. Run `bash "${CLAUDE_SKILL_DIR}/scripts/new-report.sh" --mode <mode>` (add the path if scoped). It creates `seoaudit.md` and lists the active dimensions. Read the section of `${CLAUDE_SKILL_DIR}/references/stacks.md` for the detected stack and host. Fill the Snapshot lines: put the rendering mode of each route group on the Stack line, and the site type and the public versus signed-in split on the Maturity and exposure line. Trace the two or three highest-leverage flows (a primary template from route to served HTML and the signals it emits; the canonical host from config to redirect; an AI crawler reaching a key page) and write the Map section.
- [ ] 4. Work each active dimension in the listed order:
  - a. Read `${CLAUDE_SKILL_DIR}/references/<DIM>.md`.
  - b. Run `bash "${CLAUDE_SKILL_DIR}/scripts/scan.sh" <DIM>`. In quick mode run `bash "${CLAUDE_SKILL_DIR}/scripts/scan.sh" quick --show-cards` once instead of a and b.
  - c. For every card, read the code at each lead and the files its Leads line names, then apply Confirm, Not a finding if, and Severity. Refute before you record (protocol section 5).
  - d. Add each confirmed finding under `## Findings` in the exact block format (protocol section 2).
  - e. Fill the dimension's notes: `- Checked:` lists every card ID you worked, `- Note:` says what you found.
- [ ] 5. Merge repeats into one finding, write Systemic patterns, Strengths (each with a `path:line`), and Scope and limitations.
- [ ] 6. Run `bash "${CLAUDE_SKILL_DIR}/scripts/score.sh" --write`, then write the Verdict and Calibration lines.
- [ ] 7. Run `bash "${CLAUDE_SKILL_DIR}/scripts/check-report.sh"`. Fix every problem it lists and rerun until it prints `check-report: OK`.
- [ ] 8. Run `bash "${CLAUDE_SKILL_DIR}/scripts/score.sh" --chat` and send its output as your final message.

Stop early only if inventory.sh finds no source code or no website surface, or if you cannot read the files; then say so and write no report.

## Dimensions

| ID | Dimension | Weight | Active when | Cards |
|---|---|---|---|---|
| CRAWL | Crawlability and Indexation Control | 14 | always | references/CRAWL.md |
| RENDER | Rendering and Content-in-HTML | 13 | always | references/RENDER.md |
| CONTENT | On-Page Content, Headings and Semantic HTML | 12 | always | references/CONTENT.md |
| CANON | Canonicalization and Duplicate Content | 11 | always | references/CANON.md |
| SCHEMA | Structured Data and Rich Results | 10 | always | references/SCHEMA.md |
| AIVIS | AI and Generative-Engine Visibility | 9 | always | references/AIVIS.md |
| URLARCH | URL Architecture and Technical Configuration | 8 | always | references/URLARCH.md |
| PERF | Performance and Core Web Vitals | 6 | always | references/PERF.md |
| SOCIAL | Social and Sharing Metadata | 5 | always | references/SOCIAL.md |
| OBSV | Analytics, Verification and SEO Observability | 3 | always | references/OBSV.md |
| I18N | Internationalization and hreflang | 5 | more than one locale, language, or region exists | references/I18N.md |
| FEEDS | Feeds, Syndication, Installability and Fast-Indexing | 4 | a content stream, feed, media sitemap need, IndexNow, or web app manifest exists | references/FEEDS.md |

new-report.sh decides the conditional dimensions from probes and prints why; if a probe is wrong (for example an i18n library installed for a single locale), move the ID between the Active and Not applicable lines and say why in Scope and limitations. Weights re-normalize over the active dimensions. Floor dimensions: CRAWL, RENDER, CANON, AIVIS, URLARCH, OBSV, and I18N. One Critical finding in any of them holds the overall score at 69, because nothing else matters if the content cannot be crawled, rendered, indexed, or cited.

## How to judge

This audit covers whether content can be crawled, rendered, indexed, ranked, and cited: crawl and index controls, the rendering path, on-page and structured signals, URL and edge config, share previews, and the measurement around them. Code quality belongs to codeauditor, user journeys to uxauditor, the security surface to secauditor, visual and accessibility work to uiauditor, the database to dbauditor, and LLM integration internals to llmauditor. Where performance overlaps uxauditor and headers overlap secauditor, judge only whether the signal reaches the crawler and gets the page indexed or cited.

- What reaches the crawler is the truth. A react-helmet title in a client-only app, a canonical resolved against a missing base URL, and a noindex on a URL that robots.txt blocks all look fine in source and fail in the served HTML. Read the rendering mode and the metadata layer of the stack (references/stacks.md) before judging any tag. Comments, plugin names, and the README state intent; when they disagree with the code, the gap is the finding.
- Blast radius and site type set severity. Count the indexable, valuable URLs a defect touches: a sitewide noindex is not a missing description on one page. A noindex on a signed-in dashboard is correct. hreflang on a one-language site is not applicable, and recommending it is cargo cult. A static site that ships everything in HTML is a strength. Name the site type (marketing, publisher, e-commerce, docs, app with a marketing site, local business) on the Calibration line. Effort: S is a tag or config line; M is a metadata pass across templates, a redirect layer, a structured-data fix, or an environment guard; L is moving client-rendered routes to SSR or SSG, rebuilding canonicals or hreflang sitewide, or adding a regression harness.
- Static code cannot show the live status and headers, deployed environment values, the rendered DOM, field Core Web Vitals, index coverage, rankings, whether AI engines fetch or cite the site, or CDN and WAF rules outside the repo. When a verdict depends on one of these, use Likely or Suspected and name the check that confirms it.
- Be honest about AI visibility. Name the engine and bot in every AIVIS finding and say whether the effect is documented (confirmed) or hoped for (aspirational). Training bots, search bots, and user-fetch bots gate different things (facts.md). Google-Extended does not control AI Overviews. Validate llms.txt and ai.txt for correctness, but never score them as load-bearing and never recommend adding them as a fix. robots.txt shows intent, never enforcement. Never promise ranking or citation gains.
- Separate theater from harm. Inert theater (noindex in robots.txt, sitemap priority and changefreq, rel=next and prev, meta keywords, FAQ or HowTo markup expecting rich results) is Low: recommend removal. Controls that defeat their own purpose (a home page canonical on every page, hreflang without return links, a noindex on a robots-blocked URL, a relative og:image, an inverted environment guard) get the card's severity: recommend the fix.
- Dates matter in this domain. Take retirement dates, bot names, and platform behavior from references/facts.md, not memory, and carry its "verify" marks into the finding.
- Name the strengths so the acting agent keeps them: server-rendered content and metadata, per-route titles and canonicals, JSON-LD that matches the page, an environment guard that works, a deliberate AI-crawler policy, hreflang generated centrally and reciprocally, real 404 statuses, and an SEO check in CI.
- Coverage: on a large codebase, read the root and primary templates, the head or metadata layer, the robots, sitemap, and feed generators, the rendering config, the redirect and header config, the structured-data components, and the i18n and CI wiring, and name what you sampled in Snapshot. Hosted platforms (Shopify, Wix, Squarespace, Webflow, Ghost) keep templates and settings outside the repo: audit what the repo holds and mark the rest coverage-limited instead of filing "missing" findings.

## Reference files

- `references/protocol.md`: evidence rules, finding format, severity, confidence, scoring, modes, finishing.
- `references/example-report.md`: a complete report that passes check-report.sh.
- `references/facts.md`: dated platform facts (robots and sitemap rules, retired rich results, AI crawler user agents, llms.txt status, framework and host behavior), with the date they were last reviewed.
- `references/stacks.md`: where each framework, CMS, static site generator, and host puts titles, canonicals, robots rules, sitemaps, JSON-LD, share tags, redirects, and 404s, and how each renders; read only the section for the detected stack.
- `references/CRAWL.md`, `references/RENDER.md`, `references/CONTENT.md`, `references/CANON.md`, `references/SCHEMA.md`, `references/AIVIS.md`, `references/URLARCH.md`, `references/PERF.md`, `references/SOCIAL.md`, `references/OBSV.md`, `references/I18N.md`, `references/FEEDS.md`: the cards for each dimension.
- `assets/report-template.md`: the report skeleton new-report.sh fills.
