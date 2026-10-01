# MET: Product Metrics and Instrumentation

Weight 12. Always active.
Owns: whether the events and records the team decides with are true: the core value action can be counted at all; outcome events, including the activation event and funnel steps, fire once at the outcome; identity ties events to a user and an account; revenue and subscription events agree with billing; the tracking plan and the code agree, with one name per action; analytics project keys per environment, so test, CI, and preview traffic stays out of production product data; and metrics named in product docs, launch notes, or experiment configs have an event or record behind them.
Not here: whether an activation event and funnel-step events exist at all (uxauditor CNV-R4); how analytics tags load, duplicate tags, and dead measurement ids (seoauditor OBSV-R3); consent before tracking and Consent Mode (seoauditor OBSV-R4); personal data sent in events (secauditor LOGPRIV, Also check); per-environment configuration other than analytics keys (codeauditor OBS-R5); operator logs, metrics, traces, and error reporting (codeauditor OBS-R2, OBS-R3); model-call telemetry and feedback on model outputs (llmauditor OBSERV); experiment assignment and exposure (EXP); KPIs computed from the database (KPI).
Standards: AARRR (McClure, 2007); Google HEART and Goals-Signals-Metrics (Rodden, Hutchinson, and Fu, CHI 2010); the North Star Framework (Amplitude North Star Playbook); the Segment Spec (identify, track, group, alias; object-action naming) and Segment Protocols tracking plans; Amplitude Data; Croll and Yoskovitz, Lean Analytics (2013).
Read first: the analytics client setup and any tracking wrapper; the tracking plan or event catalog; every track, identify, group, and reset call; the sign-up, sign-in, sign-out, checkout, and core-action handlers from the Map; the billing webhook; the success metrics in product docs; and the test and CI setup.

## Cards

### MET-R1 The core value action cannot be counted at all in a product with external users
- Leads: `scan.sh MET-R1` lists analytics initialization and track calls; no hits is itself a lead. Then open the core-action handler named in the Map and the table it writes.
- Confirm: the product serves external users (public sign-up, paying customers, or a public API), and the core value action from the Map (the one the product exists for) fires no event and writes no row that carries the actor, the account, and a timestamp, so nobody can count how many users perform it or come back to it. Cite the handler where the event or record belongs.
- Not a finding if: the core action writes a row with the actor, the account, and `created_at` (the metric can be derived); the product has no analytics by a documented privacy choice and keeps aggregate counters instead (note it in Scope and limitations); the project is a prototype, an internal tool, a library, or an SDK (say so on the Calibration line); the code sends at least one product event and only the activation, funnel-step, or first-core-action events are missing (uxauditor CNV-R4).
- Severity: High at growth or enterprise stage with paying customers; Medium for a free public product; Low at pre-launch. Record Likely, never Confirmed, when the Map marks the core value action as inferred.
- Fix: name the core value action in the tracking plan, and fire one server-side event, or write one row, at its success point with the user and account ids.
- Verify the fix: a test through the core action emits the event once, or writes the row once, with both ids, after the write succeeds.
- Refs: North Star Framework; HEART (adoption, retention); AARRR

### MET-R2 An outcome event fires before or regardless of the outcome, or more than once
- Leads: `scan.sh MET-R2` lists track calls whose event name states a result, and track calls inside click and submit handlers.
- Confirm: an event named for an outcome (completed, succeeded, created, sent, paid, purchased, subscribed, upgraded, converted, activated, signed up), including the activation event and the funnel steps, fires where attempts, failures, or duplicates count as successes: in a click or submit handler before the request resolves; in a `finally` block or after a `catch` that continues; on every render or retry; or from both the client and the server for one action.
- Not a finding if: the call runs only after the awaited success or a status check; it runs on the server after the write commits or in the provider's confirmed webhook; the name states an attempt (`checkout_started`); every call sends the same stable event id (`insert_id`, `messageId`, `$insert_id`) that the analytics tool deduplicates on (cite the property).
- Severity: High when the event feeds revenue, conversion, activation, a north-star metric, or a success metric named in a PRD or tracking plan; Medium otherwise.
- Fix: fire each outcome event once, after the confirmed result (server-side after commit, or in the webhook for payments), with an event id the analytics tool deduplicates on; rename attempt events so they say started.
- Verify the fix: a test where the request fails sends no outcome event; a successful request sends exactly one.
- Refs: Segment Spec (track; object-action naming); Lean Analytics

### MET-R3 Events cannot be tied to a stable user or account
- Leads: `scan.sh MET-R3` lists identify, alias, group, and reset calls. Read the sign-up, sign-in, and sign-out handlers and the tracking wrapper.
- Confirm: tracking calls exist, and one of: sign-up or sign-in never identifies the user, so one person counts as several; sign-out never resets, so the next person on the device inherits the last identity; the id sent changes over time (a session id, or an email the user can edit) instead of the stable internal user id; the id is a constant or placeholder, so every user merges into one person; or a product sold to teams (workspaces, organizations, seats) sends no account or group id, so account activation, retention, and expansion cannot be computed.
- Not a finding if: the SDK is initialized with the user id on every load after sign-in (read the init); server-side events carry the stable user and account ids and client events are not used for user-level metrics; one tracking wrapper adds the account id to every event; the product has no accounts by design.
- Severity: High when the product bills per account or seat and no event carries the account; Medium otherwise. Name secauditor in Impact when the id sent is an email address.
- Fix: in the tracking wrapper, identify with the stable internal user id after sign-up and sign-in, group with the account id, and reset on sign-out.
- Verify the fix: a test signs in, acts, signs out, and signs in as another user; each event carries the right user and account.
- Refs: Segment Spec (identify, group, alias, reset)

### MET-R4 Revenue and subscription events are sent only from the browser, or lack amount, currency, and plan
- Leads: `scan.sh MET-R4` lists purchase, checkout, subscription, upgrade, renewal, trial, and cancellation events. Check which run in client code and whether the billing webhook sends any.
- Confirm: purchases, subscription starts, upgrades, downgrades, renewals, or cancellations are tracked only from client code (a component, the success page), so blocked scripts, closed tabs, renewals, and provider-side cancellations never arrive; or the events carry no amount, currency, plan, and interval, so analytics revenue cannot be matched to billing.
- Not a finding if: the server sends the same events from the billing webhook with those properties; revenue reporting is computed from the provider or the database and the docs say analytics revenue is not used (note it in the Map); the same call is already filed as MET-R2 (merge it there: put the server-side revenue event in that finding's Recommendation and name MET-R4 in the MET Note line).
- Severity: High when renewals, refunds, or cancellations are tracked nowhere, or when a KPI query, experiment config, tracking plan, or product doc in the repository names these events as a revenue or conversion source; Medium otherwise. What dashboards in the analytics tool read is outside the repository: write it as a question in Scope and limitations.
- Fix: send revenue and subscription events from the billing webhook handler with amount, currency, plan, interval, and the account id; keep client events for intent only.
- Verify the fix: a test replays a payment, a renewal, a refund, and a cancellation webhook and sees one event each with all four properties.
- Refs: Segment Spec (e-commerce and B2B SaaS events; server-side sources)

### MET-R5 The tracking plan and the code disagree, or one action is sent under several names
- Leads: `scan.sh MET-R5` lists tracking-plan files, event-name registries, and every analytics call with a literal name. Sort the names.
- Confirm: a tracking plan or event registry in the repository lists events no code sends, the code sends events the plan does not list, or a property the plan marks required is never set; or one user action is sent under two or more names or casings (`signup_completed`, `Signed Up`, `user_signed_up`) in different files, so dashboards miss data.
- Not a finding if: the plan is generated from code, or CI or a typed wrapper accepts only plan events (read it); the names describe different actions (an attempt and a success); the plan marks the event deprecated or planned; a documented rename removed the old call; there is no tracking plan in the repository and all names follow one convention (a missing plan is not a finding).
- Severity: High when the drift or the split hits an event behind a north-star, revenue, or primary experiment metric named in the plan, a PRD, or a dashboard query; Medium otherwise; Low for a property mismatch on a minor event.
- Fix: keep one typed event catalog (typed functions generated from the plan, or a test that compares the names sent with the plan), send events only through it, and name events object-action in one casing.
- Verify the fix: a check that lists every name sent in code and every name in the plan finds no difference.
- Refs: Segment Protocols; Amplitude Data; Segment Spec (object-action naming)

### MET-R6 Test, CI, or preview runs send events into the production analytics project
- Leads: `scan.sh MET-R6` lists analytics SDK initialization and analytics keys. Read the environment handling, the CI workflows, and the end-to-end test setup.
- Confirm: a committed file makes non-production runs report into the production analytics project: the SDK is initialized with a literal production key and no environment check or disabled option, or a CI workflow, `.env.test`, or end-to-end setup sets the analytics key to the production value; and the end-to-end tests, CI jobs, or preview builds run paths that send sign-up, activation, or revenue events, so test runs count as customers in product metrics.
- Not a finding if: the key comes from an environment variable and no committed file sets it for tests, CI, or previews (record nothing and say in Scope and limitations that the per-environment values were not seen); init is skipped outside production; the test setup stubs the analytics client. Whether the analytics tool filters internal and test users is a setting in that tool: name it in Verify the fix, never require it in the repository.
- Severity: High when CI or end-to-end tests fire revenue or sign-up events into the production project; Medium when only local and preview runs can.
- Fix: initialize analytics only in production, or with a separate project key per environment set by the deploy, stub the client in tests, and mark internal and test accounts with a property the tool filters on.
- Verify the fix: running the test suite or a preview build sends no event to the production project; the analytics tool's settings filter the internal-account property.
- Refs: Amplitude Data (environments); Segment Spec (sources)

### MET-R7 A metric named in a product doc, launch note, or experiment config has nothing that measures it
- Leads: `scan.sh MET-R7` lists success-metric, north-star, KPI, OKR, and primary-metric mentions in docs and configs. Search the code for each metric's numerator and denominator.
- Confirm: a PRD, launch doc, roadmap, OKR file, or experiment config names a metric for a shipped feature or a running experiment (adoption of a feature, "teams that invite a member within 7 days", the north star, a primary metric), and no event, table, or query in the repository can compute its numerator or denominator.
- Not a finding if: data the product stores anyway computes it (name the table and its timestamp); the doc names a system outside the repository that computes it (a warehouse model, a BI tool; note it in Scope and limitations); the doc is draft or superseded; the feature has not shipped; there are no product docs (say so in the notes; the card has no candidates).
- Severity: High when it is the north-star metric, an experiment's primary metric, or a launch gate the doc says decides keep or kill; Medium otherwise.
- Fix: add the event or stored field that computes the numerator and denominator, with user and account ids, and link the metric definition in the doc to its event or query.
- Verify the fix: each metric in the doc names an event or query, and a search finds the code that sends or runs it.
- Refs: North Star Framework; HEART Goals-Signals-Metrics; Kohavi, Tang, and Xu, Trustworthy Online Controlled Experiments (2020), ch. 7

## Also check
- Events whose properties cannot segment the decisions the docs name (plan, platform, account size, acquisition source).
- Event names built from variables (`track("clicked_" + label)`) that explode into names nobody can query.
- Properties that change type or casing between calls (`plan: "Pro"` and `plan: "pro"`).
- Acquisition source (UTM) captured once at sign-up, so cohorts can be split by channel.
- Retention that cannot be computed because the recurring action has no timestamped event or row per user: file under MET-R1.

## Paper controls (look protective, protect nothing)
- An analytics SDK initialized with a key and no track call anywhere, or only page views (MET-R1).
- A tracking plan file that nothing imports and no test compares, while the code sends free-text names.
- `identify` called with a hardcoded or placeholder id (MET-R3).
- An event named "activated" or "signed_up" that fires before the account exists (MET-R2).
- An analytics wrapper that returns early in every environment (`enabled: false` hardcoded), so nothing is counted (MET-R1).
- Typed event functions generated from the plan while components call the raw SDK with other names.
