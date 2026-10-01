# SHIP: Release, Rollout and Sunset

Weight 10. Always active.
Owns: how changes reach customers and leave them: release-flag defaults and fallbacks; server-side enforcement of unreleased features; kill switches that actually switch; flag keys that match their definitions; deprecation of the product's own features, plans, and public API versions; and breaking changes to public contracts (API, SDK, webhook payloads, CLI, export formats).
Not here: dead branches behind old or always-off flags (codeauditor QUAL-R4); a kill switch or flag documented in the README that the code never reads (codeauditor DOC-R2); an API reference that still documents a removed endpoint or flag (codeauditor DOC-R2); build, deploy, and migration mechanics (codeauditor OBS-R6, OBS-R7; dbauditor MIGRATION); deprecated third-party APIs the code calls (codeauditor DEP-R3); old, shadow, debug, or internal routes as attack surface (secauditor APISEC-R4); A/B tests that confuse crawlers (seoauditor OBSV-R2); a flag that hides a sold feature (CLM-R3); plan gates (ENT-R5); experiment assignment and exposure (EXP); having no flag mechanism at all, which the Map records and which is never a finding.
Standards: Hodgson, "Feature Toggles (aka Feature Flags)", martinfowler.com (2017); OpenFeature specification (evaluation API, default values); Google SRE Workbook, ch. 16, "Canarying Releases"; RFC 9745 (Deprecation header); RFC 8594 (Sunset header); Semantic Versioning 2.0.0; Keep a Changelog 1.1.0.
Read first: the flag client setup and wrapper; the flag definition files in the repository; every flag evaluation on money, data, and access paths; the public API routers and their versions, the OpenAPI file, SDK exports, CLI commands, and webhook payload builders; deprecation markers; and the CHANGELOG and the package or API version.

## Cards

### SHIP-R1 A release flag's default or fallback turns on the unreleased side when the flag cannot be read
- Leads: `scan.sh SHIP-R1` lists flag evaluations whose default argument is true or a treatment, results followed by `?? true` or `|| true`, and true defaults in flag definition files.
- Confirm: a release or experiment flag is evaluated with a default of true, on, or the new variant (`variation("new-billing", ctx, true)`), or falls back to true when the flag service is unreachable, the key is missing, or the SDK has not initialized, and the flag guards a feature not yet released to everyone (a new flow, a paid feature, an outbound send, a data migration).
- Not a finding if: it is an ops or kill-switch flag whose true value means normal operation (read its name and use); the feature is fully launched and the flag awaits removal; the SDK serves stored values until it initializes (read the init).
- Severity: High when the guarded path charges, changes prices or permissions, sends messages, or changes stored data; Medium otherwise. When the rollout state lives only in a remote flag service, record Likely and name the flag-service export as the check in Verify the fix.
- Fix: default every release and experiment flag to current production behavior (off or control) in the flag wrapper so call sites cannot override it, and alert when evaluations fall back to defaults.
- Verify the fix: with the flag client unavailable in a test, the old behavior runs.
- Refs: OpenFeature specification (default values); Hodgson (release toggles)

### SHIP-R2 An unreleased feature is hidden only in the client while its API is live
- Leads: `scan.sh SHIP-R2` lists flag hooks and flag-gated rendering in UI code. For each, open the server route, mutation, or job the hidden feature calls.
- Confirm: the UI hides a feature behind a flag, and the server route, mutation, or job that performs it runs for any authenticated caller without evaluating the same flag, so anyone who finds the endpoint uses the feature before launch, outside the rollout, and outside the measurement.
- Not a finding if: the server evaluates the same flag with the same targeting context before acting; the route only reads data that is already public; a plan gate guards it (ENT-R5); a role check covers it (secauditor AUTHZ-R2); the route is an old version, a debug or internal route, or another route that no unreleased UI feature calls (secauditor APISEC-R4).
- Severity: High when the route charges, writes data, sends messages, or exposes an unannounced paid feature; Medium otherwise. Name secauditor in Impact when the route also lacks a role or ownership check.
- Fix: evaluate the flag on the server for every route the feature uses, with the client's targeting context, and return 404 when it is off; keep the client check for display.
- Verify the fix: a request from a user outside the rollout gets 404 or 403.
- Refs: CWE-602; Hodgson (release toggles)

### SHIP-R3 A kill switch cannot actually switch
- Leads: `scan.sh SHIP-R3` lists kill switches, emergency toggles, maintenance modes, and flags read from build-time variables. Read where each is read.
- Confirm: a flag or setting presented as a kill switch (named so, or listed as the off switch in a runbook) cannot stop the feature without a deploy or restart, because it is a literal in code, is read once at build or process start (a `NEXT_PUBLIC_` variable, a module-level read), is cached with no expiry, or the feature runs through a path that never checks it (a background job, the API, a webhook).
- Not a finding if: the value is read per request or refreshed by the SDK's streaming or polling (read the client config) and every path of the feature checks it; a documented kill switch that the code never reads at all is codeauditor DOC-R2.
- Severity: High when a runbook names it as the off switch for a payment, pricing, messaging, or data-changing feature; Medium otherwise.
- Fix: read the switch per request from the flag service or a settings table, check it on every path, and test that flipping it stops the feature.
- Verify the fix: a test flips the switch at runtime, and the next request and the next job run take the off path with no restart.
- Refs: Hodgson (ops toggles); SRE Workbook ch. 16

### SHIP-R4 Code reads a flag key that no flag definition declares
- Leads: `scan.sh SHIP-R4` lists flag reads with literal keys. Open the flag definition files named in the Map.
- Confirm: flag definitions live in the repository, and a read uses a key no definition declares (a typo, a rename, a different case), so it always returns its default; or a definition targets an attribute the code never sends in the evaluation context, so its rule never matches.
- Not a finding if: flags are defined only in a remote service you cannot read (say so in Scope and limitations; record nothing); the key is built from a documented prefix the definitions use; a definition that no code reads is dead configuration (codeauditor QUAL-R4).
- Severity: High when the missing key gates a paid, launched, or kill-switch feature that therefore never turns on or never turns off; Medium otherwise.
- Fix: generate key constants from the definitions or use a typed wrapper, and fail the build on unknown keys.
- Verify the fix: a test or type check compares every key read in code with the definitions and finds none missing.
- Refs: OpenFeature specification; Hodgson (managing toggles)

### SHIP-R5 A deprecated feature, plan, or public API version has no end date, signal, or replacement
- Leads: `scan.sh SHIP-R5` lists deprecated, legacy, sunset, and end-of-life markers in the product's own routes, SDK exports, CLI commands, OpenAPI files, and docs, and Deprecation or Sunset headers.
- Confirm: the product marks its own public API version, endpoint, SDK function, webhook payload, CLI command, plan, or customer-facing feature as deprecated or legacy, it is still reachable, and no signal in the repository tells its users when it ends or what replaces it: no `Deprecation` or `Sunset` response header, no SDK runtime warning, no in-product banner, and no changelog or docs entry with the date and the replacement.
- Not a finding if: the marker is on a third-party API the code calls (codeauditor DEP-R3); the date, a signal, and the replacement exist in the repository (cite them); the item is internal with no external users; an old version still mounted as an attack surface is secauditor APISEC-R4.
- Severity: High when external integrators depend on it (public API, SDK, webhook, export) and the code already blocks or removes it on a date (a date check, a sunset constant) or no replacement exists in the code; Medium otherwise. When the docs site, blog, or customer email lives outside the repository, record Likely at most and name that channel as the check in Verify the fix.
- Fix: publish the end date and the replacement in the changelog, send `Deprecation` and `Sunset` headers from deprecated endpoints with a link to the migration guide, count the remaining callers, and notify affected accounts in the product.
- Verify the fix: a request to the deprecated endpoint returns both headers, the changelog names the date and the replacement, and a counter tracks the remaining callers.
- Refs: RFC 9745; RFC 8594; Semantic Versioning 2.0.0

### SHIP-R6 A breaking change to a public contract shipped without notice or a version signal
- Leads: no pattern. Apply this card only when the product has a public API, SDK, CLI, webhook, or export format. Read the top CHANGELOG entries and the package or API version, run `git log --oneline -40 -- <public contract paths>`, and for each commit that removes or renames a public route, field, flag, command, or export column, run `git show --stat <commit>`.
- Confirm: in the history you read, a public route, response or webhook field, SDK export, CLI flag or command, or export column was removed, renamed, or changed type, and the changelog has no entry for it, or the version did not change the way the project's versioning policy requires (a major version under Semantic Versioning, a new API version). Cite the removal as `<commit>:path:line` (protocol section 1) or the current line of the versioned router.
- Not a finding if: it was deprecated earlier with notice (cite the entry); the project is at 0.y.z and says breaking changes may happen; the item was added and removed between two releases or sat behind an off flag; the change is additive; the changelog and version are right and only the API reference or README still documents the old shape (codeauditor DOC-R2); `git rev-parse --is-shallow-repository` prints true (write "history not available" in the notes and record nothing).
- Severity: High when external integrators break with no notice (public API, webhook, SDK, export); Medium for CLI flags and UI-only features.
- Fix: restore the old behavior for a deprecation period under the old version, or publish a major version with a migration note in the changelog; pin the public response shape with a contract test.
- Verify the fix: the changelog entry for the version names the breaking change and the migration; a contract test pins the public shape.
- Refs: Semantic Versioning 2.0.0 (rule 8); Keep a Changelog 1.1.0 ("Removed"); RFC 9745

## Also check
- Release flags with no owner, purpose, or expiry in their definition, and launched flags on for everyone for more than 90 days (removing the dead branch is codeauditor QUAL-R4).
- Several flag mechanisms in use (an SDK, environment flags, and a table) with no rule for which to use.
- Betas and previews served with no label or opt-in, or in beta for over a year with no graduation date.
- Staff allowlists hardcoded by email or user id in flag checks.
- Mobile apps have a minimum-version or forced-update switch in remote config, so a broken release can be retired.
- The launch checklist or runbook names a rollback step that exists in code or config.

## Paper controls (look protective, protect nothing)
- A kill switch whose only definition is a committed file or constant set on in every environment, so turning it off needs a deploy (SHIP-R3).
- A kill-switch environment variable read at module load.
- A flag checked in a component while the API route behind it runs for everyone (SHIP-R2).
- A `Sunset` header middleware mounted on a router that holds no deprecated route.
- A percentage-rollout field stored on each flag and ignored by the evaluation helper.
