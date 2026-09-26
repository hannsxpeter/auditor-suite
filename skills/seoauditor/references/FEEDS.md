# FEEDS: Feeds, Syndication, Installability and Fast-Indexing

Weight 4. Active when a content stream (blog, news, changelog, podcast), a feed, a news, image, or video discovery need, an IndexNow integration, or a web app manifest exists.
Owns: RSS, Atom, and JSON feeds and their autodiscovery, WebSub, news, image, and video sitemaps, IndexNow, and the web app manifest.
Not here: the base XML sitemap (CRAWL-R6 and CRAWL-R7); favicon and apple-touch-icon (SOCIAL-R4).
Standards: RSS 2.0, RFC 4287 (Atom), JSON Feed 1.1, W3C WebSub, Google Search Central (news, image, and video sitemaps), indexnow.org, W3C Web Application Manifest, facts.md (Feeds and fast indexing).
Read first: the feed generators and the head links to them, the content source they read, any specialized sitemap generator, IndexNow code and key files, and the manifest.

## Cards

### FEEDS-R1 Feed autodiscovery missing, or pointing at a feed that is not there
- Leads: `scan.sh FEEDS-R1` lists feed links and feed routes.
- Confirm: the head links `rel="alternate"` with `application/rss+xml`, `application/atom+xml`, or `application/feed+json` to a URL no route or build step generates; or a feed exists with no autodiscovery link; or a blog or news stream has no feed at all.
- Not a finding if: the linked feed URL is generated (read the route or plugin).
- Severity: Medium for a broken link, or a blog or news stream with no feed; Low for missing autodiscovery.
- Fix: generate the feed from the content source and link it from the head of every content page.
- Verify the fix: the linked feed URL exists in the build output and parses.
- Refs: RSS 2.0 specification, RFC 4287

### FEEDS-R2 Feed content is invalid or re-announces old items
- Leads: `scan.sh FEEDS-R2` lists guid, id, pubDate, updated, and self-link code.
- Confirm: required elements are missing (the RSS channel's `title`, `link`, and `description`; each item's `title` or `description`); GUIDs come from the build time, an array index, or random values, so readers see old items as new; dates are not RFC 822 (RSS) or RFC 3339 (Atom, JSON Feed); no `atom:link rel="self"`; a JSON Feed lacks `version` or item `id`; the feed claims full content but ships excerpts, or the reverse; a podcast lacks the `itunes` namespace or `enclosure`.
- Not a finding if: a maintained library builds the feed from stable item IDs and dates.
- Severity: Medium for unstable GUIDs or broken dates; Low otherwise.
- Fix: use each item's permanent URL or ID as its GUID, its real publish date in the right format, and a self link.
- Verify the fix: the built feed validates, and two builds produce the same GUIDs.
- Refs: RSS 2.0 specification, RFC 4287, JSON Feed 1.1

### FEEDS-R3 WebSub hub advertised but never notified
- Leads: `scan.sh FEEDS-R3` lists `rel="hub"` links and hub publish calls.
- Confirm: the feed advertises a hub, but no code sends `hub.mode=publish` to it when content changes.
- Not a finding if: a publish hook or platform integration pings the hub (read it).
- Severity: Low (inert).
- Fix: ping the hub on publish, or remove the hub link.
- Verify the fix: the publish path contains the hub request.
- Refs: W3C WebSub

### FEEDS-R4 News, image, or video sitemap missing required tags or stale
- Leads: `scan.sh FEEDS-R4` lists news, image, and video sitemap namespaces and generators.
- Confirm: a news sitemap lacks `news:publication` (name and language), `news:publication_date`, or `news:title`, or lists articles older than two days; image or video entries lack their required children; a news publisher has no news sitemap.
- Not a finding if: the site has no news, image, or video discovery need.
- Severity: Medium. A missing news sitemap is Medium, never Critical: it helps but is not required, since Google also finds news by crawling.
- Fix: generate the specialized sitemap from the content source with the required tags and the two-day window.
- Verify the fix: the built news sitemap lists only items from the last two days, each with every required tag.
- Refs: Google Search Central (news sitemaps; image sitemaps; video sitemaps), facts.md (Feeds and fast indexing)

### FEEDS-R5 IndexNow key not hosted, or IndexNow expected to speed up Google
- Leads: `scan.sh FEEDS-R5` lists IndexNow code and key references.
- Confirm: code submits to IndexNow with a key whose `<key>.txt` file (or `keyLocation`) is missing from the build output or does not contain the key, so every submission fails; or docs and comments claim IndexNow speeds up Google indexing (Google does not use it).
- Not a finding if: the key file is generated and matches the key the code sends.
- Severity: Medium for a missing key file (Bing and the other participants reject the pings); Low for the misconception.
- Fix: host the key file at the site root with the exact key, and document that IndexNow reaches Bing and other participants, not Google.
- Verify the fix: the build output contains `<key>.txt` holding the key.
- Refs: indexnow.org, facts.md (Feeds and fast indexing)

### FEEDS-R6 Web app manifest broken or oversold
- Leads: `scan.sh FEEDS-R6` lists manifest links, manifest fields, and service worker registration.
- Confirm: the linked manifest lacks `name` or `short_name`; its `start_url` is out of scope or does not resolve; its icons lack the 192 and 512 sizes or a `maskable` purpose; or docs claim the manifest helps SEO (installability is not a ranking factor).
- Not a finding if: the site is not meant to be installable and links no manifest.
- Severity: Low; Medium when installability is a product goal.
- Fix: complete the manifest fields and icons, and drop the SEO claim.
- Verify the fix: the built manifest has `name`, `short_name`, a `start_url` that resolves, and 192, 512, and maskable icons.
- Refs: W3C Web Application Manifest, web.dev (installability criteria)

## Also check
- A service worker that answers navigations with a cached app shell: people can see stale pages, while Googlebot fetches pages statelessly; confirm the server also returns real HTML before filing (Low).

## Paper controls (look protective, protect nothing)
- An autodiscovery link whose feed 404s (FEEDS-R1).
- A feed that says full content but ships excerpts, or the reverse (FEEDS-R2).
- Build-time or random GUIDs (FEEDS-R2).
- A WebSub hub that is never pinged (FEEDS-R3).
- A news sitemap full of stale entries (FEEDS-R4).
- An IndexNow key with no hosted file, or IndexNow framed as a Google lever (FEEDS-R5).
- A manifest with empty `icons` or an out-of-scope `start_url` (FEEDS-R6).
