# ENT: Plans, Pricing and Entitlements

Weight 16. Active when plans, tiers, prices, paywalls, or entitlement checks exist, or the pages show prices or a pricing route. Floor dimension.
Owns: whether what customers are shown, charged, and granted agree: displayed against charged prices, discounts, currencies, intervals, and seats; the plan catalog and every copy of it; the billing-to-entitlement mapping, its scope (account or member), and its default; server-side enforcement of paid features and limits, including plan gates that are defined but not mounted; plan quotas; and price or limit changes for existing customers.
Not here: fees shown late, hidden renewal terms, and preselected extras (uxauditor TRU-R1, TRU-R3); a paywall that discards work (uxauditor CNV-R3); a client-sent price, plan, role, owner, count, or balance field (secauditor AUTHZ-R3); role, ownership, and tenant checks (secauditor AUTHZ; codeauditor SEC-R1, SEC-R2 for non-plan guards); abuse rate limits (secauditor APISEC-R1); model token or spend limits with no plan term behind them (llmauditor COST-R3); counter races (dbauditor TXN-R1); float money (dbauditor TYPES-R1); a plan or status column with no CHECK or enum (dbauditor SCHEMA-R5); duplicated logic that is not plan data (codeauditor QUAL-R2, ARC-R6); provider state and lifecycle events (BILL); usage reported to the provider (BILL-R7); capabilities no plan has (CLM-R1); arrangements hardcoded for one named customer (CUST-R6).
Standards: Stripe Billing (prices, lookup keys, Entitlements, meters) and the Paddle, App Store, or Google Play docs where used; UCPD 2005/29/EC Articles 6 and 7; Consumer Rights Directive 2011/83/EU Article 6(1)(e) (the Price Indication Directive 98/6/EC covers goods only; facts.md); ISO 4217; CWE-602, CWE-636, CWE-840; Ramanujam and Tacke, Monetizing Innovation (2016). Dates are in references/facts.md.
Read first: the pricing page and plan comparison; the plan catalog (plans module, pricing JSON, seed, provider price ids in env examples); checkout and upgrade handlers; the entitlement helper and its callers; limit and quota checks; and what the billing webhook writes.

## Cards

### ENT-R1 The price a customer is charged differs from the price shown or chosen (quick)
- Leads: `scan.sh ENT-R1` lists displayed prices, price ids, unit amounts, checkout-session creation, displayed-currency handling, exchange rates, and discounts. For each plan and interval, follow the displayed amount and the charged price id to their sources.
- Confirm: the amount, currency, interval, plan, or seat count shown or chosen in the product (pricing page, plan picker, upgrade dialog, or in-app order summary) and the item sent to checkout or charged come from different sources and disagree: monthly shown and the annual price id sent; a coupon shown but never passed to the charge; the visitor's currency shown while checkout charges one fixed currency or converts at a hardcoded rate; a pricing experiment shows the variant and charges the control; the seats billed differ from the seats shown. When the amount behind a price id lives only in the provider, judge which id is sent for which displayed choice, and record an amount mismatch as Likely.
- Not a finding if: display and charge read the same catalog entry (read the import); the difference is tax the summary labels as added at payment; only the currency or tax differs, the provider's hosted checkout shows the charged amount before payment, and the in-app price is labeled "from" or states the charge currency (a different plan, interval, or seat count is never excused by the hosted page); each displayed currency has its own provider price.
- Severity: Critical when Confirmed that customers can be charged more than shown, in a currency other than shown with no notice, on another interval, or for another plan or seat count; High when they are charged less (revenue leak), or when the mismatch depends on a provider price you cannot see (Likely).
- Fix: render every displayed price from the catalog entry the charge uses (price id, amount, currency, interval), pass the applied discount and the shown currency into the checkout call, and assert their agreement in a test.
- Verify the fix: for each plan, interval, and currency, with and without a coupon, a test compares the displayed amount with the amount in the checkout request and finds them equal.
- Refs: UCPD 2005/29/EC Article 6; Consumer Rights Directive 2011/83/EU Article 6(1)(e); FTC Act Section 5; ISO 4217; Stripe Billing (prices)

### ENT-R2 The entitlement check reads a plan value or scope that billing never writes, so paying customers are refused (quick)
- Leads: `scan.sh ENT-R2` lists entitlement helpers, plan comparisons, feature-key checks, and subscription field reads. For each, find what the checkout handler and the billing webhook write, and on which record.
- Confirm: the code that grants paid features compares against a value billing never stores or a key the catalog does not define (`plan === "pro"` while the webhook writes a price id or `"professional"`; `"Pro"` against `pro`; `status === "active"` while trials are sold with full access; a field nothing updates); or a plan the catalog, seed, env example, or a migration shows customers can buy or still hold (a new tier, an annual variant, a legacy or regional price) is missing from the entitlement map and falls to the free default; or the plan is bought for a workspace or team and written there, while the check reads the acting member's own plan field (`user.plan`), so teammates on a paid team plan are refused.
- Not a finding if: one mapping layer translates every catalog price id to a plan key (compare it with the seed or env example); entitlements are read live from the provider or a subscription SDK; the comparison normalizes case first; a doc or migration shows the unmapped plan's customers were moved; the only gap is a free-text plan or status column with no CHECK or enum (dbauditor SCHEMA-R5).
- Severity: Critical when Confirmed that customers on a paid plan, a paid trial, or a paid team plan are refused features their plan includes; High when only a rare or legacy plan is unmapped, or when the provider's price ids live outside the repository (Likely).
- Fix: map every catalog price id to a plan key in one place, derive entitlements only from that map through constants or an enum generated from the catalog, read them from the record the purchase was made for (the workspace for team plans), and alert on an unmapped price instead of falling back.
- Verify the fix: a table-driven test feeds each catalog price id through the webhook and asserts the entitlement set of its plan for the buyer and for a second member of the same workspace; the type checker rejects an undefined plan or feature key.
- Refs: Stripe Billing (Entitlements; subscription statuses); CWE-840

### ENT-R3 An unknown, missing, or null plan falls through to paid access (quick)
- Leads: `scan.sh ENT-R3` lists plan defaults, fallbacks, `default:` branches over plans, and plan lookups with a fallback. Read the sign-up handler or the column default to see what new accounts carry.
- Confirm: the helper that decides plan access returns a paid plan or every feature when the account has no plan, a null or unknown plan, or no subscription row: `plan ?? "pro"`, `default_plan = "business"`, a `default:` branch that returns true or `ALL_FEATURES`, `LIMITS[plan] ?? LIMITS.enterprise`, or a missing plan treated as unlimited.
- Not a finding if: the fallback is the free plan or no access; the paid default is a documented trial whose end the code enforces (BILL-R5 judges trials that never end); unknown values are logged and denied.
- Severity: Critical when Confirmed that every account with no subscription record (new sign-ups, free users) gets paid access; High when only accounts with an unrecognized or legacy plan do. Grandfathered payers falling to no access is ENT-R2.
- Fix: default to the free plan, list every legacy plan explicitly, deny unknown keys, and log unknown plan values.
- Verify the fix: tests with a null plan, an unknown plan, and a new sign-up get the free plan's features only.
- Refs: CWE-636; CWE-1188

### ENT-R4 A plan feature or limit sold on the pricing page is enforced differently (quick)
- Leads: `scan.sh ENT-R4` lists limits and plan features in pricing pages and plan config, and the limit constants and checks in code. Pair each copy claim with its enforcement for the same plan.
- Confirm: for one plan, the pricing page, plan comparison, upgrade prompt, or billing email states a feature or a limit (10 seats, 5 projects, 100 GB, 10,000 API calls, "Unlimited projects"), and the code enforces a different number or grants the feature only to a higher plan.
- Not a finding if: the copy and the enforcement read the same constant (read the import); the copy calls the limit soft or fair use and the code notifies or bills overage as the copy says; the copy is for a retired plan and existing customers keep their terms through a branch you can cite; nothing on the server checks the limit or feature (ENT-R5); the counter's unit, scope, or period differs from the copy (ENT-R6).
- Severity: Critical when Confirmed that customers on a paid plan still on sale are refused a feature or capacity the plan's copy includes (the enforced limit is lower than sold); High when the enforced limit is higher on a plan whose main upgrade reason is that limit (revenue leak); Medium otherwise. Name llmauditor in Impact when the limit is a model-call quota.
- Fix: define each plan's features and limits once in the catalog, render the pricing copy from it, and check the limit on the server before every create, counting the unit the copy sells.
- Verify the fix: on each plan, a test creates items up to the sold limit and one more, and gets the upgrade response only on the last; a test renders the pricing table from the catalog.
- Refs: UCPD Article 6; FTC Act Section 5; Stripe Billing (Entitlements)

### ENT-R5 A paid feature or limit is enforced only in the client, only when it is set up, or not at all
- Leads: `scan.sh ENT-R5` lists plan checks, paywalls, and upgrade prompts in UI code. For each paid feature in the plan catalog, open the server route, mutation, or job that performs it, and the job that keeps serving it.
- Confirm: the UI hides, disables, or paywalls a paid feature or counts a limit, but the server route, mutation, or job that performs the feature or creates the counted object runs for any plan, so a free account gets it through the API; or no code in the UI or on the server checks a paid feature or limit the plan catalog or pricing copy defines, so every plan gets it; or a plan gate helper exists and is not mounted on the routes of the feature it names; or the plan is checked only when a paid configuration is created (a custom domain, a scheduled report, an integration, an automation), and the request or job that serves it never rechecks, so it keeps running after a downgrade or lapse.
- Not a finding if: a middleware, policy, or service-layer entitlement check runs before the handler (read where it is mounted); a database constraint or the provider enforces the limit; a doc says the fence is deliberately soft for a feature that costs nothing to serve; the downgrade or lapse handler disables the paid configurations (read it); a missing ownership or tenant check on the same route is secauditor AUTHZ-R1, and a missing role check is AUTHZ-R2 (file only the plan gate here).
- Severity: High when it is the plan's headline paid feature or it costs money per use (model calls, SMS, storage, compute); Medium otherwise. Name secauditor in Impact when the route also lacks a role or ownership check, and llmauditor when the unchecked limit is a model-call quota.
- Fix: enforce entitlements on the server in one helper that every route and job of the feature calls (`requireFeature(account, "export")`), reading the plan from the session's account; recheck the plan in each job run that serves a paid configuration; keep the UI check for display only.
- Verify the fix: a test calls the route as a free account and gets 402 or 403 with no side effect; a test downgrades an account and the next job run skips its paid configuration.
- Refs: CWE-602; CWE-840; Stripe Billing (Entitlements)

### ENT-R6 A plan quota counts the wrong unit, scope, or period, or skips a consuming path
- Leads: `scan.sh ENT-R6` lists usage counters, increments, quota fields, reset jobs, and period keys. Search each counter for its reset and for every path that consumes the resource.
- Confirm: a plan quota counter (credits, requests, messages, exports, storage) counts per user where the copy sells per workspace; never resets, or resets on the calendar month while billing runs per subscription period; or is incremented on one consuming path while another (the API, an import, a background job) skips it.
- Not a finding if: the counter is keyed by period (`usage:{account}:{yyyy-mm}`) or computed from timestamped rows in the window; a registered job resets it on the subscription period (cite the schedule); the quota is lifetime by design and the copy says so; every consuming path calls the one function that counts; a count or balance the client sends is secauditor AUTHZ-R3, and a quota checked only in the client is ENT-R5; a model token or spend limit with no plan term behind it is llmauditor COST-R3 (when the plan copy sells a model-call quota, file here and name llmauditor in Impact).
- Severity: High when paying customers are blocked early or locked out after their first period, or when all but one consuming path is unmetered; Medium when only the period or unit differs from the copy.
- Fix: count in the plan's unit and scope inside the one server function every consuming path calls, and reset on the subscription period.
- Verify the fix: a test consumes the resource through each path and sees one counter move; a test that crosses the period boundary sees the quota available again.
- Refs: CWE-840; Monetizing Innovation (value metric)

### ENT-R7 A price or limit change reaches existing customers mid-term with no grandfathering
- Leads: no pattern. Run `git log -p --since=12.months -- <file>` on the plan catalog, limit constants, and price ids that ENT-R2 and ENT-R4 found, and read the migrations or scripts that move subscriptions.
- Confirm: a commit, migration, or script raised a price, lowered a limit, removed a feature from a plan, or moved existing subscriptions to a new price, and the code applies it to existing subscribers at once, before their next renewal: no legacy plan key, no effective date, no grandfathering branch, or a provider update with immediate proration.
- Not a finding if: the change applies only to new subscriptions (old price ids stay mapped, or a legacy plan key exists); an effective date lands the change at the first renewal after a stated notice period (read it); only free accounts are affected and the copy allows it.
- Severity: High when paying customers are charged more, or lose features or capacity, mid-term; Medium when only free accounts are affected. Never Critical: whether a mid-term change breaks the customer's terms depends on terms and notices outside the repository, so never record a missing notice as Confirmed; name the CRM or email tool that would hold it in Verify the fix. If items become locked or deleted, file BILL-R8. If `git rev-parse --is-shallow-repository` prints true, record at most Suspected and say so in Scope and limitations.
- Fix: keep the old terms under a legacy plan key for existing subscribers, apply new terms at renewal after notice, schedule the notice in the same change, and record grandfathered cohorts in the catalog.
- Verify the fix: a test with a subscriber on the old price keeps the old price and limits after the change; the script's dry run lists affected subscribers with their effective dates; the CRM or email tool shows the notice sent before the first effective date.
- Refs: Stripe Billing (changing prices); California Automatic Renewal Law (material change notice; facts.md)

### ENT-R8 Prices, plans, and limits are defined in several places with nothing keeping them in step
- Leads: `scan.sh ENT-R8` lists provider price ids, lookup keys, and plan objects. Group them by plan and count where each plan's price, features, and limits are written.
- Confirm: one plan's price, feature list, limits, or provider ids are written separately in two or more places (pricing copy, an in-app plan component, the entitlement map, the limit checks, the billing seed or env ids) with no shared import, generation step, or test that they agree.
- Not a finding if: one catalog generates, or is imported by, every copy (read the build step or the imports); a test asserts that they agree; the duplicate is logic rather than plan data (codeauditor QUAL-R2, ARC-R6).
- Severity: Medium; Low when only two copies exist and both sit in one module. When the copies already disagree, file each disagreement under ENT-R1, ENT-R2, or ENT-R4 instead, and when two or more share this root, write it as a systemic pattern (protocol section 6).
- Fix: move the plan catalog into one module (plans, prices, features, limits, provider ids per environment) that the copy, the entitlements, the limits, and the billing code import; add a test that the provider ids in config match it.
- Verify the fix: changing one plan's limit in the catalog changes both the pricing copy and the enforcement with no other edit.
- Refs: Stripe Billing (products, prices, lookup keys); Monetizing Innovation (packaging)

## Also check
- Upgrade or checkout calls that name a plan or price key the catalog does not define, so nobody can pay: file under ENT-R2 as High (a missing route on that path is uxauditor JRN-R1).
- A trial grants exactly the plan the trial copy names; monthly and annual variants of a plan map to the same entitlements.
- Upgrades take effect at once: entitlements read fresh plan data, not a session claim cached until sign-out.
- Add-ons bought for one workspace do not unlock another; mobile and web purchases merge into one entitlement set per account, with store receipts verified on the server.
- Custom enterprise deals stored as hand-set flags or JSON on the account with no record of what was sold (link to CUST-R5; a literal branch for one customer is CUST-R6).
- A free plan that can do everything the paid plan does: file under ENT-R5 when no server check exists, or ENT-R4 when the check grants the paid plan's limits.

## Paper controls (look protective, protect nothing)
- An `entitlements` table or map that the webhook writes and no check reads.
- A `requirePlan()` or `hasFeature()` helper written and tested but never mounted on the API routes that do the work (ENT-R5).
- Limit constants in a config file that the create handlers do not import.
- A plan matrix the pricing page reads beside a separate hardcoded matrix in the server.
- A currency dropdown that changes only the display.
