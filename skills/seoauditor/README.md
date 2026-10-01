# seoauditor

A read-only **SEO and AI-visibility audit** skill for AI coding agents. It audits how the codebase in the current working directory makes its website visible to search engines and AI answer engines (crawl and index controls, server rendering, on-page content, canonicals, structured data, AI-crawler rules and llms.txt, URLs and redirects, Core Web Vitals code signals, share previews, hreflang, feeds, and SEO monitoring), writes a scored, prioritized, self-contained `seoaudit.md` at the repo root, then prints the verdict in chat. It never crawls the live site, never runs Lighthouse, and never calls Search Console, the Rich Results Test, or a model.

It is part of the [auditor-suite](../../README.md), and the same skill runs in Claude Code (`/seoauditor`), Codex (`$seoauditor`), and any harness that reads Agent Skills.

The audit is built for two audiences at once: search engines that crawl, render, and rank, and AI answer engines that crawl, extract, and cite. Its central fact is that most AI crawlers run no JavaScript (the December 2024 Vercel and MERJ analysis; Google's AI surfaces are the exception because they use Googlebot), so content, titles, canonicals, robots directives, and structured data must be in the server HTML or AI search never sees them.

## What it audits

Twelve dimensions, two of them conditional. Weights re-normalize over the active dimensions. A Critical finding in a floor dimension holds the overall score at 69, because nothing else matters if the content cannot be crawled, rendered, indexed, or cited.

| ID | Dimension | Weight | Applies | Floor |
|---|---|---:|---|---|
| CRAWL | Crawlability and Indexation Control | 14 | always | yes |
| RENDER | Rendering and Content-in-HTML | 13 | always | yes |
| CONTENT | On-Page Content, Headings and Semantic HTML | 12 | always | no |
| CANON | Canonicalization and Duplicate Content | 11 | always | yes |
| SCHEMA | Structured Data and Rich Results | 10 | always | no |
| AIVIS | AI and Generative-Engine Visibility | 9 | always | yes |
| URLARCH | URL Architecture and Technical Configuration | 8 | always | yes |
| PERF | Performance and Core Web Vitals | 6 | always | no |
| SOCIAL | Social and Sharing Metadata | 5 | always | no |
| OBSV | Analytics, Verification and SEO Observability | 3 | always | yes |
| I18N | Internationalization and hreflang | 5 | more than one locale, language, or region | yes |
| FEEDS | Feeds, Syndication, Installability and Fast-Indexing | 4 | a content stream, feed, media sitemap need, IndexNow, or web app manifest | no |

Each dimension is a file of rule cards (`references/<DIM>.md`). A card names one defect and says how to find leads, how to confirm it by reading code, when it is not a finding, how severe it is, how to fix it, and how to verify the fix. Every defect has exactly one owning card, so a client-rendered page, an X-Robots-Tag, or a sitemap is never scored under three dimensions. The 14 cards tagged `(quick)` are the Critical-class checks: sitewide noindex or `Disallow: /` in production, set in markup or in a header; robots.txt rules that block pages meant to drop out of the index, or the scripts and styles pages need to render; content, head tags, or redirects that exist only after client JavaScript; HTML prerendered only for bots, and other content that branches on the crawler (cloaking); a home page canonical on every page; AI search bots blocked while the site courts AI citations; canonical collapse across languages; host, scheme, or trailing slash not enforced by one redirect layer; server or edge rules that block or break crawlers; and invented review markup.

Two principles set it apart from a generic SEO checklist:

- **It judges what reaches the crawler, not the intent.** A react-helmet title in a client-only app, a Next.js canonical resolved against a missing `metadataBase`, and a noindex on a URL that robots.txt blocks all look fine in source and fail in the served HTML.
- **It hunts paper controls.** `noindex:` in robots.txt (ignored since 2019), sitemap `<priority>` and `<changefreq>`, `rel=next/prev`, FAQ and HowTo markup expecting rich results, and an llms.txt presented as an AI ranking lever are inert theater to remove; a home page canonical on every page, hreflang without return links, a relative `og:image`, and an inverted environment guard are harmful controls to fix. AI-visibility findings name the engine and bot and say whether the effect is documented or aspirational; llms.txt and ai.txt are validated but never scored as load-bearing.

Boundaries: seoauditor owns how crawlers and answer engines discover and read the site; uiauditor owns what people interact with once there, and Core Web Vitals code signals appear in both, scoped to each concern. seoauditor keeps how analytics tags load, consent wiring, and A/B tests as crawlers see them; [productauditor](../productauditor) owns product event correctness, identity, and test traffic, and experiment assignment, exposure, split validity, and lifecycle. The suite map is in [SUITE.md](../../SUITE.md).

## How it works

The skill is a short `SKILL.md` spine plus reference files read on demand and shared, read-only scripts that do the mechanical work, so small and local models can follow it as well as frontier models.

1. `scripts/inventory.sh` detects the stack, the size, and which conditional dimensions have a surface, and stops the audit when there is no website to audit.
2. `scripts/new-report.sh` writes the `seoaudit.md` skeleton for the chosen mode.
3. For each active dimension the model reads its card file and runs `scripts/scan.sh <DIM>`, which prints leads (lines worth reading, never findings) from `assets/patterns.tsv`. It then confirms or refutes each lead by reading the code and records findings in the shared format.
4. `scripts/score.sh --write` computes the scores, caps, "What to fix first", and the remediation buckets, so no model does arithmetic.
5. `scripts/check-report.sh` validates the report: sections, finding fields, that every cited `path:line` exists and that code quoted in Evidence appears within 6 lines of the first cited location, and that every card of every active dimension was worked.
6. `scripts/score.sh --chat` prints the verdict for the chat.

## Modes

- `/seoauditor` or `/seoauditor full`: every active dimension, every card.
- `/seoauditor quick`: only the `(quick)` cards, a Critical-class triage without a numeric score.
- `/seoauditor only=CRAWL,RENDER`: only those dimensions; the score is labeled partial.
- `/seoauditor app/blog` (or `quick app/blog`): audit only part of the tree.

## Files

| Path | What it holds |
|---|---|
| `SKILL.md` | the spine: contract, modes, workflow, dimension table, judgment notes |
| `references/<DIM>.md` | the rule cards for each of the twelve dimensions |
| `references/stacks.md` | where each framework, CMS, static site generator, and host puts titles, canonicals, robots rules, sitemaps, JSON-LD, share tags, redirects, and 404s |
| `references/facts.md` | dated platform facts (robots and sitemap rules, retired rich results, AI crawler user agents, llms.txt status), each with a source to verify at and a last-reviewed date |
| `references/example-report.md` | a finished report of the fixture in `tests/fixtures/seoauditor/` that passes check-report.sh |
| `references/protocol.md` | the suite's shared evidence, format, severity, and scoring rules (vendored from `shared/`) |
| `scripts/` | the suite's shared read-only scripts (vendored from `shared/`) |
| `assets/skill.conf` | this skill's names and sentences used by the scripts |
| `assets/dimensions.tsv`, `patterns.tsv`, `surfaces.tsv` | dimensions and weights, lead patterns per card, and the probes that activate I18N and FEEDS |
| `assets/report-template.md` | the report skeleton (vendored from `shared/`) |

The eval case in `evals/seoauditor/full-audit/` audits a small Next.js App Router site with nine planted defects and two decoys.

## Install

Install the whole suite with the hub's installer or the Claude Code plugin marketplace (see the [hub README](../../README.md#install)). The installer links each skill from a clone of the hub, so `git pull` updates it, and it honors `CLAUDE_CONFIG_DIR` and `CODEX_HOME`. To install this skill alone by hand, copy the runtime payload, `SKILL.md` plus the `references/`, `scripts/`, and `assets/` folders, from the hub root into your harness's skills folder:

```sh
mkdir -p ~/.claude/skills/seoauditor
cp -R skills/seoauditor/SKILL.md skills/seoauditor/references skills/seoauditor/scripts skills/seoauditor/assets ~/.claude/skills/seoauditor/
```

Use `$CLAUDE_CONFIG_DIR/skills/seoauditor` when that variable is set, `~/.codex/skills/seoauditor` (or `$CODEX_HOME/skills/seoauditor`) for Codex, or `~/.agents/skills/seoauditor` for harnesses that read the neutral Agent Skills path. A copy does not follow `git pull`; if you run `install.sh` later, it moves the copied folder to `~/.auditor-suite-backups/` and links the skill instead. The scripts need only bash 3.2 or later and standard POSIX tools; ripgrep is used when present.

## Output

`seoaudit.md` is written for a reader with no memory of the audit, typically another agent that will fix the findings. It contains the snapshot, the visibility and crawl map, the overall score and scorecard, "What to fix first", strengths to preserve, systemic root causes, the findings, per-dimension notes, a remediation plan, scope and limitations, and a "how to use this report" protocol.

## License

MIT. See [LICENSE](LICENSE).
