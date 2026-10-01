# Product audit: duebook

> Read-only product audit of the code as written, 2026-10-01. The product was not run, and no analytics, billing, feature-flag, or CRM service was queried; findings that depend on real usage or provider settings are marked Likely or Suspected. Mode: full. Scope: whole project.
> Self-contained: every finding cites the file and line it is about, so an agent holding only this report and the code can act on it. Written with productauditor (auditor-suite 1.2.0).

## Snapshot

- Project: duebook (commit 1430a15 on main)
- Stack: Python 3, Flask 3 (SQLAlchemy, Login, Mail), Lemon Squeezy REST checkout, PostHog server SDK (inventory.sh).
- Size and coverage: 6 files, about 250 lines; read exhaustively.
- Maturity and exposure: growth-stage public SaaS; B2C freemium for solo freelancers, 14-day no-card Pro trial; Lemon Squeezy is merchant of record (`README.md:10`).
- Active dimensions: CLM, ENT, BILL, MET, SHIP
- Not applicable: CUST (no match for: team memberships, invites, or member roles; admin, support, or back-office tooling), KPI (no match for: business metric computation; dbt models or a semantic layer), EXP (no match for: experiment, A/B test, or variant-assignment code), VOC (no match for: feedback, survey, support, or contact code; waitlist or demand capture)
- Not assessed: none
- Excluded: none

## Map

- **For and job:** "Invoicing for solo freelancers: create a clean invoice and email it to your client in a minute" `README.md:3`
- **Stage:** growth: open sign-up `app/main.py:63`, live checkout `app/billing.py:41`, PostHog `app/main.py:20`
- **Business model:** B2C freemium with a no-card Pro trial, charged in USD; Lemon Squeezy is merchant of record and handles tax `README.md:10`

**Promise inventory**
- Free, 2 clients and 5 invoices a month in US dollars: claim `README.md:7`, delivered `app/main.py:86`, `app/main.py:114`, `app/main.py:98`
- Pro, unlimited clients: claim `templates/pricing.html:21`, capped at 50 (ENT-001) `app/plans.py:15`
- Pro, unlimited invoices: claim `templates/pricing.html:22`, delivered `app/plans.py:15`
- Pro, invoices in any currency: claim `templates/pricing.html:23`, delivered `app/main.py:98`
- 14-day trial, no card: claim `templates/pricing.html:25`, 7-day default (CLM-001) `app/plans.py:5`
- Cancel anytime in the portal: claim `README.md:10`, portal `app/billing.py:46`, cancellation never applied (BILL-001) `app/billing.py:63`

**Money path**

| Plan | Shown | Charged | Catalog | Enforced | Defined in |
|---|---|---|---|---|---|
| Free | $0 `templates/pricing.html:11` | none | 2 clients, 5 invoices a month, USD `app/plans.py:10` | `app/main.py:86`, `app/main.py:114`, `app/main.py:98` | 3 (page, README, catalog) |
| Pro | $9/month `templates/pricing.html:19` | `LS_PRO_VARIANT_ID` `app/plans.py:14` | 50 clients, unlimited invoices, any currency `app/plans.py:15` | clients `app/main.py:86`; currency `app/main.py:98` | 3 |

- Checkout sends the Pro variant with the account id `app/billing.py:34` and refuses a second subscription `app/billing.py:28`
- Webhook handles only `subscription_created`; other events get 200 and no change `app/billing.py:68`
- Cancel only in the Lemon Squeezy portal `app/billing.py:53`; no seats or usage; entitlements read from the account `app/plans.py:26`

**Lifecycle:** trial `app/main.py:65` to free at `trial_ends_at` `app/plans.py:24`; free to pro on `subscription_created` `app/billing.py:65`; cancelled, expired, past due, and refunded are not handled `app/billing.py:68`

**Value and measurement:** core action "send an invoice" and activation "first invoice sent", both inferred, counted by `invoice_sent` `app/main.py:120` and `Invoice.sent_at` `app/main.py:45`; north star: not stated; PostHog server SDK, 2 event names, off without a key `app/main.py:21`; tracking plan, revenue events, and business metrics: not found

**Rollout and learning:** runtime switches and experiments: not found

**Signal loops:** feedback, support, and demand channels: not found

**Product docs read:** `README.md` (last changed 2026-10-01); PRDs, specs, and tracking plan: none checked in

**Load-bearing paths**
1. Checkout to access: `app/billing.py:41` to Lemon Squeezy to `subscription_created` `app/billing.py:63` to `plan_for` `app/plans.py:26`
2. Cancel to access: portal `app/billing.py:53` to Lemon Squeezy to the webhook, which drops the cancel and expiry events `app/billing.py:68`

**Widest gap:** "Unlimited clients" for Pro `templates/pricing.html:21` against a 50-client cap (ENT-001) `app/plans.py:15`

## Overall score

<!-- BEGIN GENERATED: score (score.sh --write fills this block; do not edit it by hand) -->
**Overall: 69/100, Grade D (weak, systemic problems)**

| Dimension | Score | Grade | Weight | Critical | High | Medium | Low | Suspected |
|---|---:|---|---:|---:|---:|---:|---:|---:|
| CLM Claims and Delivery | 98 | A | 21.7% | 0 | 0 | 0 | 0 | 1 |
| ENT Plans, Pricing and Entitlements | 69 | D | 23.2% | 1 | 0 | 0 | 0 | 0 |
| BILL Billing and Subscription Lifecycle | 90 | A | 23.2% | 0 | 1 | 0 | 0 | 0 |
| MET Product Metrics and Instrumentation | 97 | A | 17.4% | 0 | 0 | 1 | 0 | 0 |
| SHIP Release, Rollout and Sunset | 100 | A | 14.5% | 0 | 0 | 0 | 0 | 0 |
| **Overall** | **69** | **D** | 100% | 1 | 1 | 1 | 0 | 1 |

Caps applied: ENT held at 69 (one Critical finding); overall held at 69 (a Critical finding in a floor dimension).
Not applicable (not scored): CUST (no match for: team memberships, invites, or member roles; admin, support, or back-office tooling), KPI (no match for: business metric computation; dbt models or a semantic layer), EXP (no match for: experiment, A/B test, or variant-assignment code), VOC (no match for: feedback, survey, support, or contact code; waitlist or demand capture).
Findings: Critical 1, High 1, Medium 1, Low 0 (Suspected, not yet confirmed: 1).
Computed by score.sh from the findings below (rules: references/protocol.md, Scoring).
<!-- END GENERATED: score -->

Verdict: Duebook takes money cleanly, granting Pro only from the signed Lemon Squeezy webhook, but it does not enforce the plan it sells: Pro stops at 50 clients under an "Unlimited clients" promise, and anyone who cancels keeps Pro for good because the webhook ignores every later event. Fix ENT-001 today and BILL-001 this cycle; the trial length and the PostHog id are small fixes.

Calibration: growth stage, from open sign-up (`app/main.py:63`), a live Lemon Squeezy checkout (`app/billing.py:41`), and PostHog in production (`app/main.py:20`); graded as a product that takes money, and ENT is a floor dimension, so its Critical holds the overall score at 69.

## What to fix first

<!-- BEGIN GENERATED: fix-first (score.sh --write) -->
1. [ENT-001] Pro is sold with unlimited clients, but `PLANS["pro"]` stops it at 50 - Critical, effort S. Pro customers and trial users are refused their 51st client with "upgrade required" on the top plan, so they cannot add clients at all.
2. [BILL-001] Webhook handles only `subscription_created`, so cancelled and expired subscriptions keep Pro - High, effort M. Customers who cancel, stop paying, or are refunded keep Pro with no end.
<!-- END GENERATED: fix-first -->

## Strengths (preserve these)

- `plan_for` falls back to the free plan for a missing or unknown plan value: `app/plans.py:26`.
- Pro is granted only by the signed webhook, keyed by the account id from checkout, never by the redirect: `app/billing.py:60-65`.
- Plan gates run on the server: the currency gate (`app/main.py:98`), and the free invoice cap, which counts this month's `sent_at` rows (`app/main.py:113`).

## Systemic patterns (root causes)

- SYS-1: `templates/pricing.html` is written by hand and reads nothing from the catalog in `app/plans.py`, so copy and code drift apart. Members: ENT-001, CLM-001. Root fix: render the plan list and trial sentence from `PLANS` and `TRIAL_DAYS` in `pricing()` (`app/main.py:59`), with a test that the page states each limit.

## Findings

<!-- One block per finding in the exact format of references/protocol.md (Finding format). -->

### [ENT-001] Pro is sold with unlimited clients, but `PLANS["pro"]` stops it at 50
- Severity: Critical | Confidence: Confirmed | Effort: S | Dimension: ENT
- Location: `app/plans.py:15` (also `templates/pricing.html:21`, `app/main.py:86`)
- Evidence: the catalog sets `"limits": {"clients": 50, "invoices_per_month": None}` for Pro and `create_client` returns 402 once `count >= limit`, while the pricing page lists `<li>Unlimited clients</li>` under Pro.
- Impact: Pro customers and trial users are refused their 51st client with "upgrade required" on the top plan, so they cannot add clients at all. Pro is on sale, with its copy and checkout in this repository.
- Recommendation: set the Pro client limit to `None` at `app/plans.py:15`; if 50 is intended, change the copy for new buyers only and keep current Pro accounts unlimited under a legacy plan key. Render the pricing list from `PLANS` (SYS-1).
- Verify the fix: a test on a Pro account creates 51 clients and gets 201 each time; a free account still gets 402 on the third.
- References: UCPD 2005/29/EC Article 6; FTC Act Section 5
- Related: SYS-1

### [BILL-001] Webhook handles only `subscription_created`, so cancelled and expired subscriptions keep Pro
- Severity: High | Confidence: Confirmed | Effort: M | Dimension: BILL
- Location: `app/billing.py:63` (also `app/billing.py:68`, `app/plans.py:26`)
- Evidence: the handler acts only `if event["meta"]["event_name"] == "subscription_created":` and runs `return "", 200` for every other event; nothing else resets `account.plan`, and no job reconciles with Lemon Squeezy.
- Impact: Customers who cancel, stop paying, or are refunded keep Pro with no end. Cancelling in the portal is the path `README.md:10` promises; High, not Critical, because payers get what they paid for.
- Recommendation: in `webhook()`, handle `subscription_updated`, `subscription_cancelled` (Pro until `ends_at`), `subscription_expired` (back to free), and the payment-failed, recovered, and refund events; store the status and `ends_at` for `plan_for` to read; reconcile daily with the Lemon Squeezy API.
- Verify the fix: tests replay each event and assert what `plan_for` returns; the Lemon Squeezy webhook settings (a dashboard check) send each handled event.
- References: Lemon Squeezy webhooks (subscription events)
- Related: none

### [MET-001] PostHog identifies people by their editable email, so one freelancer becomes two
- Severity: Medium | Confidence: Confirmed | Effort: S | Dimension: MET
- Location: `app/main.py:69` (also `app/main.py:120`, `app/main.py:76`)
- Evidence: `posthog.capture(distinct_id=account.email, event="signed_up")` and the `invoice_sent` call use the email as the person id, and `change_email` sets `current_user.email = request.form["email"]`.
- Impact: After an email change, later `invoice_sent` events land on a new PostHog person, so activation and repeat invoicing are split and undercounted. The email also reaches PostHog as the id; secauditor owns that privacy review.
- Recommendation: send `distinct_id=str(account.id)` in both calls through one `track(account, event, properties)` helper in `app/main.py`.
- Verify the fix: a test signs up, changes the email, and sends an invoice; both events carry the account id.
- References: Segment Spec (identify)
- Related: none

### [CLM-001] Pricing promises a 14-day trial, but the code gives 7 days unless production sets `TRIAL_DAYS`
- Severity: Medium | Confidence: Suspected | Effort: S | Dimension: CLM
- Location: `app/plans.py:5` (also `templates/pricing.html:25`, `app/main.py:65`)
- Evidence: `TRIAL_DAYS = int(os.environ.get("TRIAL_DAYS", "7"))` sets the sign-up trial, while the pricing page says "Start with a 14-day free trial of Pro" and the README's production settings (`README.md:14`) omit `TRIAL_DAYS`.
- Impact: If production leaves it unset, every new account loses Pro on day 8, half the promised trial. Suspected: the production environment is not in the repository. Medium: the trial is free, so customers lose time, not money.
- Recommendation: define the trial length once in `app/plans.py` with a default of 14 and render the pricing sentence from it (SYS-1).
- Verify the fix: the hosting settings show `TRIAL_DAYS` unset or 14; a test finds a new account's `trial_ends_at` 14 days ahead.
- References: FTC Advertising Substantiation policy; UCPD 2005/29/EC Article 6
- Related: SYS-1

## Dimension notes

### CLM: Claims and Delivery
- Checked: CLM-R1, CLM-R2, CLM-R3, CLM-R4, CLM-R5, CLM-R6, CLM-R7, CLM-R8
- Note: Every promise in the inventory has code behind it; the trial length is the one committed number that disagrees (CLM-001), and the client cap is a plan limit (ENT-001). With no release notes, help pages, flags, invented results, or product docs, CLM-R3, CLM-R4, CLM-R6, CLM-R7, and CLM-R8 had no candidates.

### ENT: Plans, Pricing and Entitlements
- Checked: ENT-R1, ENT-R2, ENT-R3, ENT-R4, ENT-R5, ENT-R6, ENT-R7, ENT-R8
- Note: The Pro client cap contradicts the pricing page (ENT-001). The one variant matches the one price shown (ENT-R1), the webhook writes `"pro"`, the key `plan_for` reads (ENT-R2), and every gate runs on the server (ENT-R5, ENT-R6). Plan facts live in two places that already disagree, so ENT-R8 is SYS-1; one commit gives ENT-R7 nothing to compare.

### BILL: Billing and Subscription Lifecycle
- Checked: BILL-R1, BILL-R2, BILL-R3, BILL-R4, BILL-R5, BILL-R6, BILL-R7, BILL-R8
- Note: BILL-R3's leads were the webhook route and the one event the handler names (`subscription_created`); reading the handler found BILL-001. BILL-R1 and BILL-R4 hold (Strengths, Map), and `plan_for` ends the trial (BILL-R5); no key or sandbox mode is committed (BILL-R2); there are no seats, usage, or downgrade deletes (BILL-R7, BILL-R8); a failed payment changes nothing in the app (BILL-R6, see Scope).

### MET: Product Metrics and Instrumentation
- Checked: MET-R1, MET-R2, MET-R3, MET-R4, MET-R5, MET-R6, MET-R7
- Note: The core action is counted on the server after the commit (MET-R1, MET-R2), but the person id is the editable email (MET-001). No revenue events, tracking plan, or product docs exist (MET-R4, MET-R5, MET-R7), and the PostHog key comes from the environment (MET-R6).

### SHIP: Release, Rollout and Sunset
- Checked: SHIP-R1, SHIP-R2, SHIP-R3, SHIP-R4, SHIP-R5, SHIP-R6
- Note: No flags, kill switches, or deprecations exist, and there is no public contract (the JSON routes serve Duebook's own pages; no SDK, export, or outgoing webhook), so SHIP-R6 had nothing to check. No findings.

## Remediation plan

<!-- BEGIN GENERATED: plan (score.sh --write) -->
- Quick wins (Critical or High, not Suspected, effort S): ENT-001
- Plan now (Critical or High, not Suspected, effort M or L), in this order: BILL-001
- Verify first (Suspected; confirm against the code before acting): CLM-001
- Schedule (Medium): MET-001
- Backlog (Low): none
<!-- END GENERATED: plan -->

## Scope and limitations

Read all six files (a JSON API and the pricing page); nothing was run, and no Lemon Squeezy, PostHog, or hosting setting was seen. Questions for the team:
- Which events does the Lemon Squeezy webhook send, and what retries and emails follow a failed payment (BILL-001, BILL-R6)?
- Is the price behind `LS_PRO_VARIANT_ID` $9 a month (ENT-R1)?
- What is `TRIAL_DAYS` in production (CLM-001)?
- Does PostHog filter internal and test accounts (MET-R6)?
- Checkout, pricing, sign-up, and invoice sending all changed in the one commit of 2026-10-01, with no runtime switch: how are changes to them rolled out?

Tax is left to Lemon Squeezy as merchant of record and was not judged. CUST, KPI, EXP, and VOC are not applicable: accounts are single-user, and there is no metric, experiment, or feedback code.

## How to use this report (for the acting agent)

1. Triage by severity and confidence. Confirmed Critical and High findings are safe to act on now, in the order under "What to fix first". Re-verify every Suspected finding against the cited code before changing anything.
2. Confirm the stated assumption on Likely findings before acting.
3. Fix root causes first: prefer a systemic pattern's root fix over its individual members.
4. Preserve the strengths; do not refactor them away while fixing something else.
5. Fix money, access, and customer data first: make what customers are charged and granted match what they were shown and sold before tuning metrics or experiments, make a false claim true or remove it rather than soften it, change prices, plans, and limits in one catalog, and never close a revenue leak by deleting customer data or cutting off paying customers without notice. Confirm each Likely or Suspected finding in the billing provider's records, the analytics data, the flag service, or with the owner of the promise before changing pricing, plans, or customer-facing copy.
6. One finding, one change, verified: after each fix, run its "Verify the fix" step and keep the change traceable to the finding ID.
7. Do not widen scope silently; note adjacent issues instead of sprawling into a rewrite.
8. Re-run the audit to measure progress: confirm findings are resolved, not relocated, and that the strengths did not regress.
