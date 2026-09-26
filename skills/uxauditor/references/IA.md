# IA: Information Architecture and Navigation

Weight 8. Always active.
Owns: navigation and section labels in the user's vocabulary, information scent, the navigation model (global, local, and utility navigation, breadcrumbs, the current location), findability and discoverability, search and its zero-results state, and category integrity.
Not here: one term per concept across screen copy (CNT-R3); links that point at missing routes on a core journey (JRN-R1); dead-end error and expired states (JRN-R2).
Standards: information foraging theory (information scent); card sorting and tree testing (the checks that would confirm an IA finding); Jakob's Law for navigation placement.
Read first: the route table, the navigation components (header, sidebar, tabs, breadcrumbs, footer, command palette), and the search handler.

## Cards

### IA-R1 Navigation labels use internal names or jargon that give no scent
- Leads: list the labels in the navigation components and compare each with the page it opens; there is no search pattern.
- Confirm: a navigation label is an internal code name, a team name, or a clever brand word ("Nexus", "Ops Hub", "Flows") whose page a first-time user could not predict, or the label differs from the title of the page it opens.
- Not a finding if: the term is the users' own word for the thing (it appears in the README, onboarding, or the domain's vocabulary).
- Severity: Medium; High when the entry point to the core task is unrecognizable.
- Fix: rename to the users' words for the task ("Invoices", "Team members") and make the label match the page title.
- Verify the fix: a first-click or tree test with five target users finds the core task from the navigation (Suspected until run); every label equals its page title.
- Refs: information foraging (scent); Nielsen heuristic 2

### IA-R2 Users cannot tell where they are
- Leads: `scan.sh IA-R2` lists active-link logic, `aria-current`, and breadcrumb components.
- Confirm: the navigation marks no current item (no active style and no `aria-current`), or pages three or more levels deep have no breadcrumb or back link, or several routes share one generic page title.
- Not a finding if: the router's link component applies an active class that the stylesheet styles (read both).
- Severity: Medium; Low on a product with one level of navigation.
- Fix: mark the current item visually and with `aria-current="page"`, add breadcrumbs on deep pages, and give each route a specific title.
- Verify the fix: on every route, one navigation item is marked current and the title names the page.
- Refs: Nielsen heuristic 1; WCAG 2.4.2 and 2.4.8

### IA-R3 A core feature is reachable only by URL
- Leads: compare the route table with the links in the navigation and pages; a route that nothing links to is a lead. There is no search pattern.
- Confirm: a route that serves a core, paid, or advertised feature has no link from the navigation, a page, search, or a command palette, so users reach it only from an email or a typed URL.
- Not a finding if: a contextual entry reaches it (a button on a detail page), or it is intentionally hidden (admin, deprecated) and documented.
- Severity: High when a paid or advertised feature is undiscoverable; Medium otherwise.
- Fix: link it from where users look for it (the section of the related task) and from search.
- Verify the fix: the feature is reachable from the navigation in the Map's journey.
- Refs: discoverability; information scent

### IA-R4 Search finds only exact matches, or zero results leave users stuck
- Leads: `scan.sh IA-R4` lists in-memory matching on the search term and zero-results renders.
- Confirm: search compares the raw term exactly (`===`, `includes`, `indexOf` on unnormalized input: case, accents, extra spaces, plurals, synonyms, typos), or the zero-results state offers nothing (no suggestion, no spelling help, no clear-filters action, no browse link).
- Not a finding if: a search engine with fuzzy matching handles it (Algolia, Elasticsearch or OpenSearch with fuzziness, Postgres trigram or full-text search); the content set is small enough to browse and search is absent by design.
- Severity: Medium; High when search is the main way to reach the core content.
- Fix: normalize case, accents, and whitespace, add typo tolerance and synonyms, and give zero results a way forward (suggestions, clear filters, browse).
- Verify the fix: a misspelled and a differently cased query both find the item; zero results show at least one action.
- Refs: findability; Nielsen heuristic 9

### IA-R5 Categories overlap or leave common items with no home
- Leads: read the category, section, and settings-group definitions (enums, navigation config); there is no search pattern.
- Confirm: two sections plausibly hold the same thing ("Settings" and "Preferences", "Billing" and "Account > Plan"), or a common item fits no section, so users must guess.
- Not a finding if: the overlap is a deliberate shortcut that leads to one canonical place.
- Severity: Medium; Low when the item is rarely used.
- Fix: merge overlapping sections or define each by the user's task, and give every common item one home.
- Verify the fix: a card sort or tree test places the items where the navigation does (Suspected until run).
- Refs: category integrity (mutually exclusive, collectively exhaustive); card sorting

## Also check
- The navigation model: global, local, and utility navigation are distinct; the structure follows the users' mental model, not the org chart.
- Judge by scent strength, not click count: the three-click rule is a myth, and users keep clicking while the scent stays strong.
- Discoverability: whether users learn that key features exist at all, not only whether they can find known items.
- Search present where the content volume warrants it.
- Run several realistic "find X" tasks against the navigation in the Map and record where the scent breaks.

## Paper controls (look protective, protect nothing)
- A breadcrumb that renders route segments (ids and slugs) instead of names.
- An active-link style that compares the wrong path, so nothing or everything is marked current.
- A search box that filters only the rows already loaded on the page, so paginated results are never found.
