# CONTENT: On-Page Content, Headings and Semantic HTML

Weight 12. Always active.
Owns: title and meta description quality, headings, semantic landmarks, image alt text, anchor text, visible authorship and dates, About and Contact pages.
Not here: whether the title reaches the server HTML (RENDER-R2); crawlable links and click-handler navigation (RENDER-R4); author and Organization JSON-LD (SCHEMA-R4); URL slugs (URLARCH-R6); machine-readable dates and answer structure for AI engines (AIVIS-R5); charset, viewport, and html lang (SOCIAL-R6); content hidden on mobile (PERF).
Standards: Google Search Central (influencing title links, control your snippets, image SEO, link best practices, creating helpful content), HTML Living Standard (sections and headings).
Read first: the root layout or base template, the title template, and one template per page type (home, listing, detail, article).

## Cards

### CONTENT-R1 Titles missing, framework defaults, or the same on every page
- Leads: `scan.sh CONTENT-R1` lists title templates, default titles, and metadata exports.
- Confirm: a routable template resolves to no `<title>`, an empty one, a framework default (`React App`, `Create Next App`, `Vite App`, `Document`), or only the site name, because the title is set once in the root layout and pages never override it; or two templates produce one title for different content.
- Not a finding if: each page passes its own title into a template such as `%s | Site` (read two pages to be sure).
- Severity: High when the home page or a primary template is affected, or all pages share one title; Medium for a few pages.
- Fix: give each route a unique, descriptive title through the framework metadata API, built from the page's own data.
- Verify the fix: the served `<title>` of three different pages differs and names each page's subject.
- Refs: Google Search Central (influencing title links)

### CONTENT-R2 Meta descriptions missing or one value for the whole site
- Leads: `scan.sh CONTENT-R2` lists description tags and metadata description fields.
- Confirm: templates emit no meta description, or every page inherits one site-wide description.
- Not a finding if: the page type is not meant to rank (legal, sign-in); descriptions come from each item's data.
- Severity: Medium when primary templates share one value; Low otherwise. The description shapes the snippet and click rate, not ranking.
- Fix: write a description per page from the item's summary, about 150 characters.
- Verify the fix: two pages of one template show different descriptions in their served HTML.
- Refs: Google Search Central (control your snippets: meta descriptions)

### CONTENT-R3 Headings missing, repeated, or faked with styling
- Leads: `scan.sh CONTENT-R3` lists `<h1>` tags and elements styled to look like headings.
- Confirm: a template renders no `<h1>`, more than one (often a logo or a library card title), skips levels in the main content, or uses `<div class="title">` where a heading belongs.
- Not a finding if: a second `<h1>` lives in a separate landmark by design (a dialog) and the main content has one.
- Severity: Medium on primary templates; Low elsewhere.
- Fix: one `<h1>` that names the page subject, then `<h2>` and `<h3>` for sections; keep the look in CSS classes.
- Verify the fix: each served template has exactly one `<h1>` and no skipped levels in the main region.
- Refs: HTML Living Standard (headings), Google Search Central (SEO starter guide)

### CONTENT-R4 Main content has no semantic landmarks
- Leads: `scan.sh CONTENT-R4` lists `<main>`, `<article>`, `<nav>`, `<header>`, and `<footer>`; templates that have none are the candidates.
- Confirm: the main content region of a template is only `<div>` and `<span>` elements with zero `<main>` or `<article>`, so parsers and AI extractors cannot tell content from navigation and chrome.
- Not a finding if: the layout wraps every page in `<main>` (read it).
- Severity: Medium on article, docs, and product templates; Low elsewhere.
- Fix: wrap the page body in `<main>`, articles in `<article>`, and navigation in `<nav>`; use lists, and tables with header cells, for list and tabular data.
- Verify the fix: a grep of the built HTML for `<main` returns one hit per page.
- Refs: HTML Living Standard (sections), WAI-ARIA landmark roles

### CONTENT-R5 Images lack useful alt text, or text is baked into images
- Leads: `scan.sh CONTENT-R5` lists `<img>` and image component tags and placeholder alt values.
- Confirm: content images have no `alt`, a placeholder (`image`, `photo`, a file name), or keyword-stuffed alt; or headings, prices, or key facts exist only as pixels in an image.
- Not a finding if: the image is decorative and has `alt=""`; the text in the image is repeated in HTML nearby.
- Severity: Medium when product or article images, or text in images, carry key content; Low otherwise.
- Fix: describe what the image shows in `alt`; move text out of images into HTML.
- Verify the fix: no content `<img>` in the served HTML lacks a descriptive alt.
- Refs: Google Search Central (image SEO best practices), WCAG 2.2 SC 1.1.1

### CONTENT-R6 Anchor text says nothing about the target
- Leads: `scan.sh CONTENT-R6` lists links whose text is "click here", "here", "read more", "learn more", or "more".
- Confirm: internal links to indexable pages use generic text or a bare URL as their only text, so crawlers learn nothing about the target.
- Not a finding if: the card or list also links the target's title, or the link carries visually hidden text that names the target.
- Severity: Low; Medium when the main internal links (navigation, cards, related posts) all use generic text.
- Fix: use the destination's title or topic as the link text.
- Verify the fix: a grep of the built templates for `>read more<` and `>click here<` returns no hits.
- Refs: Google Search Central (link best practices: anchor text)

### CONTENT-R7 Visible authorship, dates, and About or Contact pages are missing
- Leads: no search pattern; read the article or post template, the footer, and the route list.
- Confirm: articles, guides, or reviews show no author byline or published and updated date, or the site has no About or Contact page, on a site where trust matters (health, finance, reviews, news, how-to).
- Not a finding if: the site is a product or marketing site whose pages are not authored advice; bylines exist in a component you have not read yet (read it).
- Severity: Medium on news, reviews, health, and finance content; Low elsewhere.
- Fix: render a byline linked to an author page, published and updated dates as text, and link About and Contact from the footer.
- Verify the fix: the served article HTML shows the author name and both dates as text.
- Refs: Google Search Central (creating helpful, reliable, people-first content)

## Also check
- A meta `keywords` tag: Google has ignored it since 2009 (inert, Low, remove; facts.md, On-page).
- Paginated listings that repeat one title on every page (add the page number; file under CONTENT-R1).

## Paper controls (look protective, protect nothing)
- A `<title>` set in a component that never renders on the server (RENDER-R2 owns the finding).
- Meta keywords stuffed with terms.
- Keyword-stuffed alt text on decorative images.
- Anchor text that is the URL itself.
