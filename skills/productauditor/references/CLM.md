# CLM: Claims and Delivery

Weight 15. Always active.
Owns: whether what the product tells customers is built, reachable, and true: capabilities sold or advertised in pricing, plan, checkout, landing, onboarding, and store-listing copy; features announced in customer-facing release notes; end-user help; committed numbers (trial length, history, retention, limits, refund window, formats); technical guarantees the code can contradict (end-to-end encryption, card data never reaching the servers, the data region, no tracking); product docs marked done; and output presented as real.
Not here: developer docs and documented settings, endpoints, flags, and kill switches (codeauditor DOC-R1, DOC-R2); dead code, including code behind an always-off flag or an unregistered route that no copy sells (codeauditor QUAL-R4); TODO markers (codeauditor QUAL-R5); a model or service failure turned into a default answer (llmauditor RELIABILITY-R5, codeauditor ERR-R1); a feature reachable only by URL (uxauditor IA-R3); a journey that exists but breaks (uxauditor JRN-R1, JRN-R2); false success (uxauditor USE-R3); fees added late in checkout (uxauditor TRU-R3); fake urgency, scarcity, and social proof (uxauditor TRU-R4); plan prices and limits (ENT-R1, ENT-R4); whether a security control is sound (secauditor); promises to erase or stop keeping personal data (secauditor LOGPRIV-R5); certifications and attestations (SOC 2, ISO 27001, HIPAA, PCI DSS), accessibility conformance levels, and uptime percentages, which code cannot prove (list them in Scope and limitations).
Standards: FTC Act Section 5; FTC Policy Statements on Deception (1983) and Advertising Substantiation (1984); UCPD 2005/29/EC Articles 6 and 7; ISO/IEC/IEEE 29148:2018; ISO/IEC/IEEE 26514:2022; Keep a Changelog 1.1.0. Legal dates are in references/facts.md; Impact says "exposure under", never "violates".
Read first: the Map's promise inventory; the pricing page and plan catalog; landing, onboarding, and upgrade copy; release notes and what's-new sources; end-user help; the terms; and any PRD, spec, or roadmap under docs/.

## Cards

### CLM-R1 A capability sold or advertised has no implementation (quick)
- Leads: `scan.sh CLM-R1` lists plan feature lists and capability phrases in pages, copy, plan config, and docs. For each capability in the Map's promise inventory, search code, config, and dependency manifests for its route, handler, component, job, SDK, or integration client.
- Confirm: pricing, plan, checkout, upgrade, landing, onboarding, or store-listing copy says the product does something specific (an integration, an export format, SSO or SAML, an API, offline mode, custom domains, an audit log, a platform app), and the search finds no route, handler, component, job, integration client, or third-party configuration that does it. Evidence lists the terms and globs you searched.
- Not a finding if: the copy says coming soon, beta, on request, or contact us beside the claim; a third party configured in the repository, or a service or repository the code or docs reference, provides it (cite it and note it in Scope and limitations); an identity, integration, or platform vendor whose SDK or config is in the repository commonly provides it from its own dashboard (SSO or SAML through Clerk, Auth0, WorkOS, or Stytch; a Zapier, Make, or Slack app defined on that vendor's platform): record Suspected and name the vendor dashboard as the check; the page is not routed or is a draft; it is a README or API-reference claim (codeauditor DOC-R2) or a plan limit (ENT-R4).
- Severity: Critical only when Confirmed: the search covered code, config, and manifests, no vendor SDK or referenced service could provide it, and the capability is listed on a paid plan whose pricing copy and checkout or upgrade path are both in the repository; High when only Likely, when the pricing lives outside the repository (a CMS), or on landing, onboarding, or free-plan copy; Medium when only in-app copy shows it, or it holds for some platforms or plans and the copy does not say which.
- Fix: build it, or remove the claim from every surface that makes it in one change (or label it coming soon beside the claim); render plan feature lists from the plan catalog so a plan cannot list a capability no code implements; tell customers who bought on the claim.
- Verify the fix: every capability in the plan feature lists maps to a code path or a configured service; a search for a removed claim finds no customer-facing copy; for a vendor-provided capability, the vendor dashboard shows it enabled.
- Refs: FTC Act Section 5; FTC Advertising Substantiation policy; UCPD 2005/29/EC Article 6; ISO/IEC/IEEE 29148 (traceability)

### CLM-R2 A promised or reachable feature is a stub on the shipped path (quick)
- Leads: `scan.sh CLM-R2` lists not-implemented errors, coming-soon renders, mock and stub clients, and placeholder copy. Read only non-test code that production serves.
- Confirm: a feature named in customer-facing copy, linked from navigation, mounted on a public route, or exported from the public SDK throws not implemented on its production path, returns a hardcoded empty result or constant, renders "coming soon" to customers who were sold it, or selects a mock or stub client in production config.
- Not a finding if: the stub lives in tests, stories, fixtures, or a branch production does not take (read the condition and the production config); the entry point is behind an off flag or an unmounted route (cite it); the copy labels the feature preview or beta; the stub is an abstract method every concrete class overrides; the constant is a fallback returned when a model or service call fails (llmauditor RELIABILITY-R5, codeauditor ERR-R1); invented values shown as real results are CLM-R7.
- Severity: Critical when Confirmed that a capability listed on a paid plan customers can buy now (pricing copy and checkout in the repository) throws, returns a constant, or shows coming soon on the production path for every buyer; High when the feature is advertised, on a core journey from the Map, or only some buyers reach the stub; Medium otherwise.
- Fix: hide the entry point and remove the claim until the feature works, or implement the real path; never serve canned data on a sold feature.
- Verify the fix: with production config the handler reaches the real implementation, or the entry point is unreachable; a test asserts the mock client is not selected in production.
- Refs: ISO/IEC/IEEE 29148 (verifiability); FTC Act Section 5

### CLM-R3 A sold or announced feature exists but the customers it was sold to cannot reach it (quick)
- Leads: `scan.sh CLM-R3` lists flag values set to off in flag files and commented-out route registrations. Compare the promise inventory with the route table and the flag definitions.
- Confirm: the code for a sold or announced feature exists, but in production no customer on the plan that includes it can reach it, because its route or handler is not registered, its module is excluded from the build, its flag is off in the production definition with no rule that targets those customers, or its only entry point renders for a role or environment customers never have.
- Not a finding if: a targeting rule enables it for the customers who were sold it (read the rule); it works but is reachable only by URL (uxauditor IA-R3); the copy says rolling out and a percentage rollout exists; no customer-facing copy or release note names the feature (dead code behind an always-off flag or an unregistered route is codeauditor QUAL-R4); the flag's production state lives in a remote flag service you cannot read (record Suspected and name the flag service as the check).
- Severity: Critical when Confirmed that the route table or the production flag definition in the repository leaves the feature off for every account on a paid plan that lists it and that customers can buy now; High when the feature is sold on a paid plan or announced as available and only some buyers are cut off, or when the flag state is remote (with Suspected); Medium otherwise.
- Fix: register the route, or enable the flag for the plans and customers that were sold the feature, and add the entry point where the copy says it is.
- Verify the fix: with production config, an account on the plan that includes the feature reaches it from the place the copy names.
- Refs: ISO/IEC/IEEE 29148 (traceability)

### CLM-R4 Release notes or announcements present a feature as available that the code does not deliver as described
- Leads: `scan.sh CLM-R4` lists Added, New, and Launched entries in customer-facing release notes and in-app what's-new sources. Read the entries of the last two releases or the last 90 days (`git log --since=90.days --oneline`) and find each entry's code.
- Confirm: a customer-facing release note, what's-new entry, or in-app announcement says a feature is available, and the code has no implementation, keeps it behind a flag that is off in the production definition, or delivers less than announced (the note says CSV and Excel and the handler writes CSV only; the note says all plans and the check allows one).
- Not a finding if: the entry states a staged rollout or names the plans and the code matches; a later entry retracts it; the notes are a developer changelog of builds and dependencies or a library changelog (codeauditor DOC); the flag state lives in a remote service (record Suspected).
- Severity: High when paying customers were told the feature is available; Medium otherwise. If `git rev-parse --is-shallow-repository` prints true, judge only entries whose code you can read now and say so in Scope and limitations.
- Fix: announce only after the flag is on for the named audience, or state the rollout in the entry; finish the feature or publish a correction; link each entry to its flag key.
- Verify the fix: each entry in the latest release maps to code that is on for the audience the entry names.
- Refs: Keep a Changelog 1.1.0; FTC Act Section 5

### CLM-R5 A number or technical guarantee the product commits to differs from what the code does (quick)
- Leads: `scan.sh CLM-R5` lists committed numbers and technical guarantees in copy and terms, and the constants that set them (trial days, retention, history, upload size, refund window, polling interval, accepted formats).
- Confirm: customer-facing copy, help, or terms state a value or a technical guarantee that defines what the customer gets, and the implementing code does otherwise: "14-day trial" with `TRIAL_DAYS = 7`; "90 days of history" with a 30-day cleanup job; "uploads up to 100 MB" with a 10 MB limit; "30-day refund" with a 14-day check; "real-time sync" with a five-minute poll; "hosted in the EU" while every region in the committed deploy config is outside the EU; "end-to-end encrypted" while the server decrypts the content or stores it in plain text; "we never store your card" while card numbers reach the server; "no tracking" while a third-party analytics or ad script loads.
- Not a finding if: the copy is qualified beside the number ("up to", "at least", "fair use") and the code stays inside it; the code branches by plan or region and the production value matches (read it); the value comes from an environment variable with no committed production value (record Suspected and name the deploy settings as the check); no committed deploy config names a region (record nothing); the number is a plan limit (ENT-R4); it is a promise to erase or stop keeping personal data (secauditor LOGPRIV-R5); it is a certification, an accessibility conformance level, or an uptime percentage (list it in Scope and limitations).
- Severity: Critical when Confirmed that a job or query deletes customer data, or makes it unreadable, before the retention or history period the product publishes; High when customers get less than stated in money, data, or protection (charged sooner, a shorter refund window, fewer formats, another region, content readable on the server); Medium otherwise. Name secauditor in Impact for a false encryption or card-handling guarantee.
- Fix: define the value once in config and render the copy from it, or correct whichever side is wrong; for a retention gap, stop the deletion first, then align the job and the published period; for a false technical guarantee, correct the copy at once and plan the control.
- Verify the fix: the copy and the code read the same constant; a test asserts the cleanup job keeps data for the published period; no customer-facing guarantee is contradicted by the code path it describes.
- Refs: FTC Advertising Substantiation policy; UCPD 2005/29/EC Article 6; FTC Act Section 5

### CLM-R6 Help content describes screens, steps, or settings that do not exist
- Leads: `scan.sh CLM-R6` lists click paths ("Settings > Billing") in end-user help, FAQ, onboarding email, and tooltip content. Compare each label with the route table, the navigation labels, and the message catalogs.
- Confirm: end-user help, an FAQ, an onboarding email, or a tooltip tells users to go to a screen, menu item, button, or setting whose label and route appear nowhere in the UI code or message catalogs, or describes a step the flow no longer has.
- Not a finding if: the label exists under that name in navigation, a page, or a catalog (search all three); the content is for a platform this repository does not contain (a separate mobile app); it is developer documentation (codeauditor DOC).
- Severity: High when the stale steps cover billing, cancellation, data export, or account recovery; Medium otherwise.
- Fix: update the steps to the current labels and routes; where help lives in the repository, reference labels from the message catalog.
- Verify the fix: each label the help names appears in the UI code or a catalog.
- Refs: ISO/IEC/IEEE 26514:2022

### CLM-R7 The product shows invented results as real output (quick)
- Leads: `scan.sh CLM-R7` lists random values, fake-data libraries, and mock, sample, dummy, or hardcoded data in non-test code. Read how each file is mounted in production.
- Confirm: a screen, report, email, export, or API response that customers use as the product's output (a dashboard figure, a score, a savings amount, an analysis, a forecast, a model result) takes its value from `Math.random`, a fake-data library, a hardcoded literal, or a mock file on a route production mounts, with no label saying it is sample data.
- Not a finding if: the file is a test, story, fixture, development seed, or demo route production does not mount (read the router and the build); the screen labels the data as sample or example; the value shows only while loading, or only for an empty account under a visible sample label; the literal is the fallback returned when a model or service call fails (llmauditor RELIABILITY-R5, codeauditor ERR-R1); it is a pressure number (stock left, viewers, countdowns, reviews), which is uxauditor TRU-R4; it is a random variant or bucket assignment (EXP-R1).
- Severity: Critical when Confirmed on a production-mounted route and the output sits behind a paid plan in the plan catalog; High otherwise, including free output customers act on for money, health, legal, or safety decisions, and High with Likely when you cannot read the mount or a demo toggle.
- Fix: compute the value from real data, or remove the screen until it can; label sample data as sample.
- Verify the fix: a search finds no random or fake-data call on a production path; a test renders the screen from the real query.
- Refs: FTC Act Section 5; FTC Policy Statement on Deception

### CLM-R8 A product doc marks work done that misses a criterion the code can show
- Leads: `scan.sh CLM-R8` lists status lines, acceptance-criteria headings, and checked roadmap items. Read the PRD, spec, roadmap, or decision record each belongs to.
- Confirm: a PRD, spec, roadmap, or accepted decision record in the repository marks an item shipped, done, or accepted, and a verifiable criterion it lists (a state, a role, a limit, a notification, an empty state, a platform, "export includes archived items", "plan checks run on the server") is not implemented or is implemented differently.
- Not a finding if: the doc is draft, proposed, or superseded, or a later dated doc or decision changes it (cite it); the criterion cannot be decided from code ("users love it", "fast"); the doc says the work is delivered outside this repository; the checked box is a pull-request template or release checklist; the doc is developer documentation of a setting, endpoint, or flag (codeauditor DOC-R2); the repository has no product docs (write that in the notes; the card has no candidates).
- Severity: High when the missed criterion concerns money, access, permissions, or data retention, or the doc ties it to a named customer or a launch date that has passed; Medium otherwise.
- Fix: implement the criterion, or update the doc to record the decision to drop it, with the owner and the date; link each criterion to the test or path that proves it.
- Verify the fix: every criterion of each item marked done names a test or code path that exists, or the doc records the change.
- Refs: ISO/IEC/IEEE 29148:2018

## Also check
- Integrations, platforms, and apps listed on the landing page (Slack, Zapier, iOS, a browser extension) with no client, manifest, or app project in the repository or referenced from it: file under CLM-R1.
- A plan sold "for teams", "for agencies", or "for several locations" while every record is owned by one `user_id` and no organization, workspace, or membership entity exists: the team capability does not exist; file under CLM-R1.
- "Export your data anytime" or "no lock-in" with no owner-run export: CLM-R1. A partial export is CUST-R4.
- Store-listing text in the repository (fastlane metadata) and transactional email copy that lists features: CLM-R1.
- Placeholder copy (lorem ipsum, TBD, "[Product Name]", "Your Company") rendered on pricing, checkout, sign-up, legal pages, or a transactional email: file under CLM-R2 as unfinished scope; the quality of ordinary copy stays uxauditor CNT.
- Two live implementations of one customer job (a classic and a new editor, two export flows) with no flag that routes each user to one: record it in the dimension's Note line as a question for the team; when the two give different results for money or data, file under CLM-R5.

## Paper controls (look protective, protect nothing)
- A plan comparison table whose checkmarks come from a hardcoded array that no entitlement code reads.
- A what's-new modal that announces features behind flags that are off.
- A changelog generated from commit subjects, so internal refactors are announced as features.
- A PRD or roadmap whose every item reads "Shipped".
- A dashboard that renders fixture charts for a new account with no sample label, so the capability looks delivered.
- A security page that says "end-to-end encrypted" above an API that returns the content in plain text.
