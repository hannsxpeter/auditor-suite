# AIVIS: AI and Generative-Engine Visibility

Weight 9. Always active. Floor dimension.
Owns: rules for AI user agents in robots.txt, middleware, or edge config in the repo; the difference between training, search, and user-fetch bots; llms.txt and ai.txt correctness; AI licensing signals; how extractable content templates are for answer engines (structure, machine-readable dates).
Not here: server rendering for crawlers that run no JavaScript (RENDER); JSON-LD correctness (SCHEMA); robots rules for search crawlers (CRAWL); snippet directives such as nosnippet (CRAWL-R4); rules that block Googlebot or Bingbot (URLARCH-R5).
Standards: the providers' crawler docs (OpenAI, Anthropic, Perplexity, Google-Extended, Applebot), Google Search Central (AI features and your website), the llms.txt proposal (llmstxt.org, aspirational), facts.md (AI crawlers; llms.txt and AI files).
Read first: robots.txt or its generator, middleware and edge config that read the user agent, llms.txt, llms-full.txt, ai.txt, the README or docs that state AI goals, and one article or docs template.

Name the engine and the bot in every AIVIS finding, and say whether the effect is documented by the provider (confirmed) or only hoped for (aspirational).

## Cards

### AIVIS-R1 AI search or user-fetch bots are blocked while the site wants AI visibility (quick)
- Leads: `scan.sh AIVIS-R1` lists AI user agents in robots files, middleware, config, and docs.
- Confirm: robots.txt, middleware, or edge config in the repo blocks a search or citation bot (OAI-SearchBot, Claude-SearchBot, PerplexityBot) or a user-fetch bot (ChatGPT-User, Claude-User, Perplexity-User), and the project also courts AI visibility: an llms.txt, answer-focused content, or a README or comment that states the goal. Classify every named bot with facts.md; blocking training bots (GPTBot, ClaudeBot, CCBot, Google-Extended, Applebot-Extended) does not stop citation.
- Not a finding if: only training bots are blocked; the block is a documented licensing decision and nothing in the project courts AI visibility (then describe the trade-off in the Map instead).
- Severity: Critical when the project courts AI visibility, because an engine cannot cite a site it may not fetch; Medium when no goal is stated (record the trade-off for the owner).
- Fix: allow the search bot and the user-fetch bot of each engine the owner wants (both, per engine), and keep training-bot rules in their own groups.
- Verify the fix: robots.txt allows `/` for OAI-SearchBot, ChatGPT-User, PerplexityBot, Perplexity-User, Claude-SearchBot, and Claude-User, as the owner chose.
- Refs: facts.md (AI crawlers), OpenAI, Anthropic, and Perplexity crawler docs

### AIVIS-R2 A training-bot rule is expected to control AI answers
- Leads: `scan.sh AIVIS-R2` lists Google-Extended, Applebot-Extended, and mentions of AI Overviews or AI Mode.
- Confirm: code or comments expect a rule to change an answer surface it does not control: blocking Google-Extended to leave AI Overviews or AI Mode (those run on Googlebot and normal Search controls); blocking GPTBot to leave ChatGPT search (OAI-SearchBot governs it); blocking Applebot to stop training (Applebot also feeds Siri and Spotlight answers; Applebot-Extended is the training control).
- Not a finding if: each rule matches its documented purpose and the comment says so.
- Severity: Medium, because the owner's policy is not achieved; High when a mistaken block (Applebot, a search bot) removes the site from an answer surface the owner wants.
- Fix: map each goal to its documented control: limit AI Overviews with `nosnippet`, `data-nosnippet`, or `max-snippet`; limit training with the training tokens.
- Verify the fix: each AI rule in robots.txt carries a comment naming its documented purpose from facts.md.
- Refs: facts.md (Google-Extended; Applebot), Google Search Central (AI features and your website)

### AIVIS-R3 llms.txt or ai.txt is malformed, stale, or points at pages crawlers cannot use
- Leads: `scan.sh AIVIS-R3` lists the headings and links in llms.txt and code that generates these files.
- Confirm: llms.txt breaks the proposal's shape (one H1, an optional blockquote, H2 sections of Markdown links); links point at URLs that 404, redirect, are off-origin, or are disallowed in robots.txt; the file is hand-written and out of date with the routes; or ai.txt contradicts robots.txt.
- Not a finding if: the file is generated from the content source at build time and every link resolves.
- Severity: Low. These files are aspirational: no major engine documents using llms.txt for ranking or citation (facts.md). Never raise severity because one is missing, and never recommend adding one as a visibility fix.
- Fix: generate the file from the same source as the sitemap, or delete it; fix the robots rules it contradicts.
- Verify the fix: every link in the built llms.txt returns 200 and robots.txt allows it.
- Refs: llmstxt.org (proposal), facts.md (llms.txt and AI files)

### AIVIS-R4 AI licensing signals contradict each other or are treated as enforcement
- Leads: `scan.sh AIVIS-R4` lists `rel="license"`, Creative Commons links, `usageInfo`, `noai` and `noimageai` values, and TDM reservation tags.
- Confirm: the site declares conflicting reuse terms (CC BY in markup, "no training" in ai.txt or a meta tag); or code and docs treat `noai`, `noimageai`, a Creative Commons license, or ai.txt as a technical block on AI training.
- Not a finding if: the signals agree and the docs call them statements of intent.
- Severity: Low; Medium when the contradiction covers the whole site's licensing.
- Fix: pick one policy, state it the same way in markup and files, and enforce blocks with robots or edge rules, not meta tags.
- Verify the fix: markup, ai.txt, and robots.txt state the same policy.
- Refs: facts.md (llms.txt and AI files: noai, ai.txt, Creative Commons)

### AIVIS-R5 Content templates are hard for answer engines to extract
- Leads: `scan.sh AIVIS-R5` lists where dates are rendered and where `<time datetime>`, datePublished, or dateModified appear.
- Confirm: an article or docs template emits its body as plain `<p>` blocks with no `<h2>` or `<h3>`, lists, or tables; or it shows published and updated dates only as styled text, with no `<time datetime>` and no `datePublished` or `dateModified` in structured data.
- Not a finding if: the body comes from Markdown or a CMS that renders headings and lists (read a sample); the dates exist in JSON-LD.
- Severity: Low; Medium for publishers and docs sites that aim to be cited. Writing quality is out of scope for a static audit.
- Fix: render structure as real HTML elements, and add `<time datetime="2026-01-31">` plus `dateModified` in JSON-LD.
- Verify the fix: the served article HTML has `<h2>` sections and a `<time datetime>` element.
- Refs: HTML Living Standard (the time element), facts.md (AI crawlers)

## Also check
- A CDN or hosting setting outside the repo can block AI crawlers whatever robots.txt says (facts.md, Hosting); name it in Scope and limitations.
- robots.txt binds only crawlers that choose to obey it; code shows intent, never enforcement.
- For each engine the owner wants, its search bot and its user-fetch bot must both be allowed.
- A blanket `Disallow: /` under `*` also blocks every AI crawler that honors the wildcard (CRAWL-R1 owns it; mention the AI effect in its Impact).
- Openly shareable content with no license statement at all is a missed clarity signal, not a defect (Low, only when the owner wants reuse; file under AIVIS-R4).
- Keyword-stuffed llms.txt or markup written for AI engines (inert or spam; Low; file under AIVIS-R3).

## Paper controls (look protective, protect nothing)
- llms.txt presented as ranking magic, or a pristine llms.txt on a client-rendered site (RENDER-R1 owns the rendering).
- llms.txt links that 404 or point at disallowed pages (AIVIS-R3).
- ai.txt that contradicts robots.txt (AIVIS-R3).
- `noai` and `noimageai` meta values treated as enforcement (no standard; AIVIS-R4).
- A Creative Commons license chosen to "stop AI training" (AIVIS-R4).
- Citation bots blocked while the site courts AI visibility (AIVIS-R1).
