# SOCIAL: Social and Sharing Metadata

Weight 5. Always active.
Owns: Open Graph and X (Twitter) card tags, share images and dynamic share-image routes, favicon and apple-touch-icon, and head hygiene: charset, viewport, and html lang on single-language sites.
Not here: whether these tags are in the server HTML (RENDER-R2); title quality (CONTENT-R1); the web app manifest (FEEDS-R6); html lang and og:locale per locale on multilingual sites (I18N-R6).
Standards: the Open Graph protocol (ogp.me), X cards markup docs, Google Search Central (favicon in search results), HTML Living Standard (charset, meta viewport), facts.md (Social).
Read first: the root layout or document head, the SEO helper, and one shareable template (home, product, article).

## Cards

### SOCIAL-R1 Share image URL is relative, http, or localhost
- Leads: `scan.sh SOCIAL-R1` lists og:image and twitter:image values, `images:` arrays, `metadataBase`, and `localhost` URLs.
- Confirm: `og:image` or `twitter:image` is written as a relative path in raw HTML (next/head, Astro, server templates), as an `http://` URL on an https site, or as a `localhost` or preview host; or a framework resolves a relative image against a base URL that is not set (stacks.md).
- Not a finding if: the framework resolves it against a production base URL you can see (Next.js `metadataBase` set in the root layout).
- Severity: High when every page, or the templates people share most (home, product, article), is affected, because each preview loses its image; Medium for one page.
- Fix: emit absolute https image URLs built from the production origin, about 1200x630, with `og:image:width`, `og:image:height`, and `og:image:alt`.
- Verify the fix: the served `og:image` starts with `https://<production host>/` and answers 200.
- Refs: ogp.me, facts.md (Social)

### SOCIAL-R2 Open Graph tags incomplete, duplicated, or one set for the whole site
- Leads: `scan.sh SOCIAL-R2` lists og:title, og:type, og:url, og:description, og:site_name, and `openGraph` objects.
- Confirm: a shareable template lacks `og:title`, `og:type`, `og:url`, or `og:image`; every page shares the root's `og:title` and image (in Next.js a page that sets no `openGraph` inherits the parent's whole object, and a page that sets part of it drops the rest); or two layers emit the same OG tags with different values.
- Not a finding if: each page builds its OG values from its own data (read two pages).
- Severity: Medium; Low for pages nobody shares.
- Fix: build per-page OG values (title, description, url, image) in one helper and emit each tag once.
- Verify the fix: two articles show different `og:title` and `og:url` values in their served HTML.
- Refs: ogp.me

### SOCIAL-R3 X card tags missing or defeating the Open Graph fallback
- Leads: `scan.sh SOCIAL-R3` lists `twitter:` tags and `twitter` metadata objects.
- Confirm: no `twitter:card` is set (X then shows a small summary card at best); an empty `twitter:image` or `twitter:title` overrides good OG values; or the tags use an attribute other than the documented `name=`.
- Not a finding if: `twitter:card` is set and the other values fall back to OG on purpose.
- Severity: Low; Medium on sites where X traffic matters (media, launches).
- Fix: set `twitter:card` to `summary_large_image` on pages with a hero image, add `twitter:site` (and `twitter:creator` on authored pages), and remove empty tags.
- Verify the fix: the served HTML has one `twitter:card` and no empty `twitter:` values.
- Refs: X developer docs (cards markup), facts.md (Social)

### SOCIAL-R4 Favicon does not meet search requirements
- Leads: `scan.sh SOCIAL-R4` lists icon and apple-touch-icon links and favicon files.
- Confirm: the only favicon is 16x16 or not square, sits at a URL robots.txt blocks, changes name on every build, or differs per host; no `apple-touch-icon` exists.
- Not a finding if: a square icon of at least 48x48 (Google asks for multiples of 48px) is linked from the home page at a stable, crawlable URL.
- Severity: Low.
- Fix: link a square SVG or 48px-multiple PNG favicon at a stable URL, plus a 180x180 `apple-touch-icon`.
- Verify the fix: the home page HTML links the icon and the icon URL answers 200.
- Refs: Google Search Central (define a favicon to show in search results), facts.md (Social)

### SOCIAL-R5 Dynamic share-image route is misconfigured
- Leads: `scan.sh SOCIAL-R5` lists `ImageResponse`, `next/og`, `@vercel/og`, satori, and `opengraph-image` routes.
- Confirm: the route declares a content type other than PNG or JPEG or no `size`; embeds WebP images or relies on system fonts (none exist there; load fonts explicitly); imports Node built-ins while running on the edge runtime; or renders fresh on every request with no caching, so scrapers time out.
- Not a finding if: the image is generated once at build and served as PNG.
- Severity: Medium when the route serves every share image; Low otherwise.
- Fix: return PNG at 1200x630, load fonts from files, avoid Node built-ins on the edge, and cache or prerender the images.
- Verify the fix: a second request for the image URL returns `image/png` quickly with a cache header.
- Refs: Next.js docs (opengraph-image and twitter-image; ImageResponse), facts.md (Social)

### SOCIAL-R6 Head hygiene: charset, viewport, or html lang
- Leads: `scan.sh SOCIAL-R6` lists charset metas, `<html>` tags, and viewport settings.
- Confirm: `<meta charset="utf-8">` is missing or not within the first 1024 bytes; the viewport meta is missing or wrong; `<html>` has no `lang`, or the wrong one, on a single-language site.
- Not a finding if: the framework adds charset and viewport itself (Next.js App Router does) and the root layout sets `lang`.
- Severity: Medium for a missing viewport (Google indexes the mobile rendering); Low for lang and charset issues.
- Fix: put the charset first in `<head>`, add `<meta name="viewport" content="width=device-width, initial-scale=1">`, and set `<html lang>` to the content's language.
- Verify the fix: the first bytes of the served HTML contain the charset meta, and `<html lang>` is set.
- Refs: HTML Living Standard (character encoding declaration; meta viewport), Google Search Central (mobile-first indexing)

## Also check
- An `og:image` that 404s or is very large (Facebook rejects share images over 8 MB; facts.md).
- An oEmbed discovery link with no endpoint behind it.

## Paper controls (look protective, protect nothing)
- A relative or localhost `og:image` (SOCIAL-R1).
- OG tags injected by client code: scrapers run no JavaScript (RENDER-R2).
- One share image and title for every page (SOCIAL-R2).
- `twitter:image=""` (SOCIAL-R3).
- A dynamic share-image route that returns WebP or crashes on fonts (SOCIAL-R5).
- Duplicate OG tags from two layers (SOCIAL-R2).
