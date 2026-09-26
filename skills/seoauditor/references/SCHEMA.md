# SCHEMA: Structured Data and Rich Results

Weight 10. Always active.
Owns: JSON-LD, Microdata, and RDFa correctness: types and required properties, values that match the visible page, dates and enums, entity identity (Organization, Person, sameAs, @id), duplicate or conflicting blocks, and markup kept for rich results Google retired.
Not here: whether the JSON-LD is in the server HTML (RENDER-R2); visible bylines and dates (CONTENT-R7); `<time>` elements and answer structure for AI engines (AIVIS-R5); licensing that contradicts ai.txt or robots rules (AIVIS-R4).
Standards: schema.org, Google Search Central (structured data general guidelines and spam policies, review snippet, Product, Article, Organization, BreadcrumbList, Event docs), facts.md (Structured data).
Read first: every component or template that emits `application/ld+json`, `itemscope`, or RDFa attributes, and the SEO plugin config.

## Cards

### SCHEMA-R1 Rating or review markup the page does not show, or invented values (quick)
- Leads: `scan.sh SCHEMA-R1` lists aggregateRating, Review, ratingValue, ratingCount, and reviewCount.
- Confirm: rating or review markup holds hardcoded, sample, or placeholder values (`"ratingValue": "4.9"`, `"name": "Product Name"`), or values with no visible reviews on the same page; or it rates the site's own Organization or LocalBusiness (self-serving); or it states other facts the page does not show.
- Not a finding if: the values come from real user reviews in the data layer and the same reviews render visibly on that page.
- Severity: Critical when the invented or invisible rating is emitted on many pages or on the main product or pricing templates, because a manual action can remove rich results for the whole site; High when it is on one page.
- Fix: remove the rating markup, or feed it from real reviews that render on the same page.
- Verify the fix: the count of pages whose built HTML contains `AggregateRating` equals the count of pages that visibly show reviews.
- Refs: Google Search Central (structured data spam policies; review snippet guidelines), facts.md (Structured data: self-serving reviews)

### SCHEMA-R2 Required properties missing, or values in the wrong format
- Leads: `scan.sh SCHEMA-R2` lists JSON-LD blocks and `@type` values.
- Confirm: a type lacks what its rich result requires (Product or Offer: `price`, `priceCurrency`, `availability`; Article: `headline`, `image`, `datePublished`, `author`; BreadcrumbList: `itemListElement` with `position`, `name`, `item`; Event: `name`, `startDate`, `location`); or `@context` is not `https://schema.org`, a type is miscased, dates are not ISO 8601, `availability` is not a schema.org URL, or `priceCurrency` is not an ISO 4217 code.
- Not a finding if: the type has no rich result and serves only entity grounding; a plugin you have read adds the missing value.
- Severity: High on product and other revenue templates; Medium elsewhere. Either way the item cannot get its rich result.
- Fix: fill the required properties from page data, with ISO 8601 dates and schema.org enum URLs.
- Verify the fix: the Rich Results Test on a deployed URL reports no errors for the type.
- Refs: schema.org, Google Search Central (structured data docs for each type)

### SCHEMA-R3 One entity described twice with different values
- Leads: `scan.sh SCHEMA-R3` lists JSON-LD, Microdata, and RDFa emitters.
- Confirm: a page emits the same entity in two blocks or formats with conflicting values (a plugin's Product plus a theme's Product, JSON-LD plus Microdata with different prices), or `@id` references point at ids no block defines. Google may read either block, so results are unpredictable.
- Not a finding if: the blocks share `@id` values and agree; one block extends the other on purpose inside one `@graph`.
- Severity: Medium; High when prices or availability conflict on product pages.
- Fix: keep one emitter per entity (prefer JSON-LD in one `@graph`) and disable the other.
- Verify the fix: each built page has one block per entity.
- Refs: Google Search Central (structured data general guidelines)

### SCHEMA-R4 Entity identity is weak or ungrounded
- Leads: `scan.sh SCHEMA-R4` lists `sameAs`, `@id`, `author`, and `publisher` values.
- Confirm: the site has no Organization or Person entity; or it has no `sameAs` links to profiles it controls; a profile URL sits in `@id` instead of `sameAs`; `author` is a bare string such as "admin" instead of a Person; `publisher` has no `logo`; or `sameAs` points at profiles the entity does not control.
- Not a finding if: the site is not an entity people search for (a small internal tool).
- Severity: Low; Medium for publishers and brands whose knowledge panel or AI attribution matters.
- Fix: publish one Organization (or Person) with a stable `@id`, `logo`, and `sameAs` links to official profiles (Wikipedia, Wikidata, LinkedIn), and reference that `@id` from Article `publisher` and `author`.
- Verify the fix: the built home page contains the Organization block with its `@id`, and article blocks reference it.
- Refs: schema.org (Organization, Person), Google Search Central (Organization structured data)

### SCHEMA-R5 Markup kept for rich results Google retired or restricted
- Leads: `scan.sh SCHEMA-R5` lists FAQPage, HowTo, SearchAction, and the types retired in June 2025.
- Confirm: code or comments treat FAQPage, HowTo, a `WebSite` `SearchAction` for the sitelinks search box, or a feature retired in June 2025 as a way to win a search feature (facts.md, Structured data).
- Not a finding if: the markup is kept only as an accurate description of the content and nobody expects a search feature from it.
- Severity: Low: it parses and produces no rich result, so it is inert. Say that, and do not call it broken.
- Fix: stop investing in it; delete it if it costs upkeep, keep it if it describes the content accurately.
- Verify the fix: no comment, test, or task still expects a search feature from these types.
- Refs: facts.md (FAQ and HowTo 2023; sitelinks search box 2024; June 2025 retirements)

### SCHEMA-R6 No structured data where the content has a matching rich-result type
- Leads: no pattern proves absence; if `scan.sh SCHEMA-R2` finds no JSON-LD, Microdata, or RDFa, read the product, article, recipe, event, job, and breadcrumb templates.
- Confirm: templates for products, articles, recipes, events, jobs, or breadcrumbs emit no structured data, or only Microdata or RDFa (note a move to JSON-LD, Google's preferred format).
- Not a finding if: the site's content types have no rich result and entity data is present.
- Severity: Medium on product, recipe, event, and job templates; Low elsewhere.
- Fix: emit JSON-LD for the type from the same data that renders the page.
- Verify the fix: the built template contains a valid block for the type.
- Refs: Google Search Central (structured data search gallery)

## Also check
- data-vocabulary.org markup: no rich results since April 2020 (inert, Low; facts.md).
- A `license` or `usageInfo` property whose value is not a URL (contradictions with ai.txt belong to AIVIS-R4).
- JSON-LD written with `JSON.stringify` and no escaping of `<`: a `</script>` in the data breaks the page (mention it; secauditor owns the injection risk).

## Paper controls (look protective, protect nothing)
- A fabricated or inflated AggregateRating (SCHEMA-R1).
- FAQPage or HowTo markup expected to produce accordions in search (SCHEMA-R5).
- A "schema validation" step that only checks that `JSON.parse` succeeds, never that the values match the page.
- JSON-LD injected only by client code (RENDER-R2).
- `sameAs` links to profiles the entity does not control (SCHEMA-R4).
