# BILL: Billing and Subscription Lifecycle

Weight 16. Active when a billing provider SDK, a checkout, or subscription state or billing events exist. Floor dimension.
Owns: whether money and access follow each other: access on a confirmed payment; live mode in production; app state kept in step with the provider; one subscription per plan, and cancel, downgrade, and upgrade on both sides at the right time; trial and grace ends; failed payments; billed seats and metered usage; and customer data when a plan is lowered or lapses.
Not here: webhook signatures (secauditor APISEC-R5); duplicate effects of a retried or redelivered event with no idempotency key (dbauditor TXN-R3; the retry loop itself is codeauditor ERR-R4 or llmauditor RELIABILITY-R4); a provider call and a database write that diverge only on a crash or outage between them (dbauditor TXN-R4, codeauditor ERR-R5); swallowed webhook or provider errors (codeauditor ERR-R1); a per-environment value hardcoded in code while production is right (codeauditor OBS-R5); references to other services that are not subscriptions (dbauditor INTEGRITY-R8); cancellation effort and renewal disclosure (uxauditor TRU-R2, TRU-R3); a failed payment at checkout shown as success, or a checkout payment-error screen with no retry (uxauditor USE-R3, JRN-R2); a client-sent plan or price field on any request but the checkout success or return (secauditor AUTHZ-R3); committed billing keys (secauditor SECRET-R1); abuse of checkout, coupons, or trials at machine speed (secauditor APISEC-R3); plan contents and the entitlement map (ENT); user-requested deletion and erasure (uxauditor USE-R1, secauditor LOGPRIV-R5).
Standards: Stripe Billing (statuses, webhooks, Checkout fulfillment, test and live mode, meters); Paddle Billing; App Store Server Notifications V2; Google Play RTDN; ROSCA (15 U.S.C. 8401-8405); California Automatic Renewal Law as amended by AB 2863; Consumer Rights Directive 2011/83/EU. The FTC Negative Option Rule was vacated in July 2025: never cite it as law. Dates are in references/facts.md.
Read first: checkout creation and its success URL; the billing webhook and its event switch; the subscription, trial, and seat fields and their writers; the cancel, downgrade, upgrade, and delete-account handlers; scheduled billing jobs; and the production config and deploy files.

## Cards

### BILL-R1 Paid access is granted by the checkout redirect or a client call, not by a confirmed payment (quick)
- Leads: `scan.sh BILL-R1` lists success URLs, success-page handlers, query flags, and payment-confirmed event handlers. Read the code that sets the plan, credits, or paid flag.
- Confirm: the code that sets the account's plan, credits, or paid flag runs on the success page, on a query parameter (`?success=true`, `?plan=pro`, `?session_id=`), or on a client request made after checkout, and does not first retrieve the checkout session or payment from the provider on the server and check that it is paid and belongs to this account.
- Not a finding if: the success handler retrieves the session server-side and checks its payment or subscription status and customer id before granting; access is granted only by the provider's confirmed webhook event; the server stores a plan or price the client sends on a request other than the checkout success or return (secauditor AUTHZ-R3; file it there).
- Severity: Critical when Confirmed that opening the success URL or calling the endpoint grants paid access with no verified payment; High when the grant is verified but runs only on the redirect, so payers who close the tab never get access. Name secauditor in Impact for the forgery.
- Fix: grant access in the webhook handler for the provider's confirmed payment event, keyed by the provider's customer and subscription ids; let the success page only show status.
- Verify the fix: a test that opens the success URL with a forged or unpaid session id grants nothing; a paid webhook event grants the plan once.
- Refs: Stripe Checkout (fulfill orders with webhooks); CWE-345; CWE-840

### BILL-R2 Production billing runs in the provider's test or sandbox mode while checkout is live (quick)
- Leads: `scan.sh BILL-R2` lists test-mode key prefixes, sandbox hosts, and billing sandbox or live-mode settings in config, code, deploy, and CI files.
- Confirm: production selects the provider's test or sandbox mode through something committed: a sandbox host or `environment: "sandbox"` written into the billing client with no environment switch, `livemode: false` or a test key prefix in `.env.production`, a production block of a config file, a deploy manifest, or a production CI job; and the Map shows checkout live (a mounted checkout route and pricing copy that sells paid plans with no beta or waitlist label), so production checkout takes no real money.
- Not a finding if: the file is for development, staging, or preview (read how it is selected); an environment variable or deploy variable chooses the mode and no committed file sets its production value (record nothing; if a deploy file you cannot fully read may override a committed value, record Likely); the product does not charge yet (no checkout route or paid-plan copy; say so in the Map); production is correct and the only defect is a per-environment literal in code (codeauditor OBS-R5).
- Severity: Critical when Confirmed that committed production configuration or code selects test or sandbox mode and checkout is live; High when Likely.
- Fix: read billing keys and the provider environment from production secrets, and fail startup in production when the key is a test key or the environment is sandbox.
- Verify the fix: starting with production settings and a test key fails with a clear error.
- Refs: Stripe API keys (test and live mode); Paddle Billing sandbox

### BILL-R3 The app's subscription state does not follow the billing provider (quick)
- Leads: `scan.sh BILL-R3` lists the provider event types the webhook handler names and the webhook routes. List which events the handler switches on and what each writes, and compare them with that provider's lifecycle events (facts.md).
- Confirm: the app stores its own plan or status, and nothing updates it for one or more of: the subscription updated (including plan changes made in the provider's customer portal), ended or deleted, a payment failing or recovering, a refund, or a dispute; or the handler only logs these events; and there is no scheduled reconciliation or live read of the provider at entitlement time.
- Not a finding if: entitlement checks read the provider or a subscription SDK live or through a short-lived cache (read it); a registered job reconciles every subscription on a schedule (cite it); the only unhandled event is a plan change made in the provider's customer portal and the code never creates a portal session or link (record Likely at most and name the provider's portal settings as the check); ended, failed-payment, refund, and dispute events happen without any portal and are never excused this way.
- Severity: Critical when Confirmed that customers who pay, renew, or upgrade (including in the provider's portal) do not get the plan they paid for; High when customers who cancel, stop paying, or win a dispute keep paid access with no end; Medium when only refunds or disputes are unhandled.
- Fix: handle the provider's subscription-updated, subscription-deleted, payment-failed, payment-succeeded, refund, and dispute events (and the store notifications for mobile), write the status, plan, and period end from each, and reconcile against the provider daily.
- Verify the fix: tests replay each event type and assert the stored plan, status, and access; a reconciliation test corrects a drifted account; the provider's webhook endpoint settings (a dashboard check, unless committed CLI or infrastructure config lists them) send every handled event.
- Refs: Stripe Billing (subscription webhooks); App Store Server Notifications V2; Google Play RTDN

### BILL-R4 A subscription start or change takes effect on one side only, twice, or at the wrong time (quick)
- Leads: `scan.sh BILL-R4` lists checkout creation, cancel, downgrade, delete-account, and close-workspace handlers, provider customer, cancel, and update calls, period-end fields, and proration settings.
- Confirm: checkout starts a second subscription, or creates a new provider customer, for an account that already has an active subscription, because nothing checks for one; or a cancel or delete-account handler changes local state and reports success, but neither it nor a job it enqueues calls the provider, or it cancels the base plan and not add-ons or seats; or an upgrade creates a new subscription and leaves the old one active; or a downgrade switches entitlements while the provider keeps the old price, or the reverse; or cancelling removes access at once although the customer paid through the period end and the product says access lasts until then.
- Not a finding if: the provider call and the app change agree on timing (`cancel_at_period_end` with access until `current_period_end`); cancellation happens in the provider's portal and local state changes only from its webhook; a registered job makes the provider call (read it); an app store bills it and the flow sends the user there (uxauditor TRU-R2 judges that copy); the copy promises immediate cancellation with a prorated refund and the code refunds; the duplicate comes only from a retried request or a redelivered event with no idempotency key (dbauditor TXN-R3); the two sides diverge only on a crash or outage between the calls (dbauditor TXN-R4, codeauditor ERR-R5); the provider call exists and its error is caught and dropped (codeauditor ERR-R1).
- Severity: Critical when Confirmed that the base subscription keeps charging after a cancel or account deletion, or that the normal checkout or upgrade path leaves one account with two active subscriptions for one plan; High when only add-ons or secondary subscriptions keep charging, when paid-for time is cut short, or when a customer keeps a higher plan without paying for it.
- Fix: one function changes the subscription at the provider and the app state together, reuses the account's provider customer and refuses a second active subscription, cancels every subscription and add-on of the account on cancel or deletion, and uses the provider's period end and proration settings.
- Verify the fix: tests with a mocked provider for checkout twice, cancel, delete-account, downgrade, and upgrade assert one provider customer, one active subscription, the provider cancel or update call with the subscription ids, the expected charge, and access until the right date.
- Refs: ROSCA 15 U.S.C. 8403 (a simple mechanism to stop recurring charges); California Automatic Renewal Law; Stripe Billing (cancel_at_period_end, proration)

### BILL-R5 A trial or grace period has an end date that nothing enforces (quick)
- Leads: `scan.sh BILL-R5` lists trial and grace fields and trialing checks. Search each field name for its readers.
- Confirm: a trial or grace end date or status (`trial_ends_at`, `grace_until`, `trialing`) is written when the period starts, and no entitlement check, middleware, or registered scheduled job reads it to end access or convert the account, so the trial never ends; or trial end moves the account to a state with no reachable upgrade action.
- Not a finding if: the provider runs the trial and its event updates the app (that handler is BILL-R3); the entitlement check compares the end date with the current time (read it); a registered job ends trials (cite the schedule).
- Severity: Critical when Confirmed that every new sign-up gets a paid plan's access through a trial that no check, registered job, or provider event ever ends, on a product that sells that plan; High when only some sign-ups (a promotion, an invite path) get such a trial; Medium when only the grace period is unenforced or expired accounts have no upgrade path. If trial end deletes or locks data, file BILL-R8.
- Fix: decide the end behavior (convert, downgrade to free, or read-only with export), enforce it in the entitlement helper or a registered job, and keep an upgrade action on the expired state.
- Verify the fix: a test account whose trial ended yesterday gets free-plan access and sees an upgrade action.
- Refs: Stripe Billing (trial periods, trial_will_end); CWE-840

### BILL-R6 A failed payment cuts access at once or leaves no way to update the card
- Leads: `scan.sh BILL-R6` lists past-due, unpaid, payment-failed, grace, dunning, retry, and update-card code.
- Confirm: on the provider's payment-failed event or a past-due status, the app removes paid access at once, before the provider's retries end, with no grace period; or it moves the account to a past-due or locked state from which no update-payment action is reachable (no billing-portal link, no update-card route), so customers who would pay cannot.
- Not a finding if: the app leaves retries and reminder emails to the provider and changes nothing on a failed payment (provider retries and emails are dashboard settings: write their state as a question in Scope and limitations); the final cancellation or unpaid event is unhandled (that is BILL-R3); an update-payment action is reachable from the past-due state; the dead end is the checkout's own payment-error screen (uxauditor JRN-R2).
- Severity: High when paying customers lose access on the first failure; Medium when no update-payment path is reachable from the past-due state.
- Fix: keep access through a grace period, show a notice with a link to update the card on each failure, and end access only on the provider's final event.
- Verify the fix: tests replay payment failed then paid, and payment failed then canceled, and assert access, the notice, and the final state.
- Refs: Stripe Billing (revenue recovery, Smart Retries; past_due and unpaid statuses)

### BILL-R7 Billed seats or metered usage do not match what the customer used (quick)
- Leads: `scan.sh BILL-R7` lists seat updates, member add and remove paths (settings, invite acceptance, SCIM, admin scripts), usage records, meter events, and credit decrements.
- Confirm: the plan bills per seat or unit, and usage that drives a bill or credit balance is recorded before success, on failed or cancelled operations, or from client code or analytics events; or removing seats never lowers the provider quantity; or some add path (invite accepted by email, SCIM, an admin script, the API) never reaches the provider.
- Not a finding if: meter events are sent after success with a unique identifier the provider deduplicates (read the call); failed operations refund the credit in the same path; a registered job reconciles seats and usage with the provider (cite the schedule); the plan is flat-priced (a seat cap is ENT-R4); the only gap is duplicate records from retries or redelivery with no idempotency key (dbauditor TXN-R3; the retry loop is codeauditor ERR-R4 or llmauditor RELIABILITY-R4).
- Severity: Critical when Confirmed that customers are billed or charged credits for failed or unrequested usage, or keep paying for removed seats; High when added seats or usage are never reported (revenue leak); Medium when reporting lands after the billing period or only internal quotas are affected.
- Fix: update the provider quantity in the one function every membership change calls, record usage on the server after success once per operation, refund credits on failure, and reconcile daily.
- Verify the fix: a test adds and removes a member through each path and asserts one quantity update each; a failed metered operation records no usage.
- Refs: Stripe Billing (per-seat pricing; usage-based billing meter event identifiers); RFC 7644 (SCIM provisioning)

### BILL-R8 A downgrade, lapse, trial end, or failed payment deletes or locks customer data with no notice or recovery window (quick)
- Leads: `scan.sh BILL-R8` lists downgrade, plan-change, over-limit, trial-expiry, unpaid, and subscription-ended handlers and jobs, and bulk deletes of excess records. Read every delete, archive, or lock call inside them.
- Confirm: when an account moves to a lower plan, its subscription ends or goes unpaid, or its trial ends, a handler or job hard-deletes records above the new limit, removes members, or makes existing data unreadable with no export, at once or by a job, with no notice to the owner and no window to restore.
- Not a finding if: data above the limit becomes read-only and stays exportable; deletion follows a stated retention window, a notice job, and a recheck of the plan (read the job and its template); the data is derived and can be regenerated; the user requested and confirmed account deletion (uxauditor USE-R1, secauditor LOGPRIV-R5).
- Severity: Critical when Confirmed that customer-created records are hard-deleted or made unrecoverable on the triggering event with no notice and no recovery window; High when data is locked with no export, or the purge runs before the window the product states; Medium when notice and a window exist but there is no export.
- Fix: on a downgrade or lapse, keep the data, make what exceeds the plan read-only, notify the owner with an export link, and delete only after a stated window in a job that rechecks the plan.
- Verify the fix: a test downgrades an over-limit account and finds every record intact, read-only, and exportable, with a notice queued.
- Refs: Stripe Billing (canceled and unpaid statuses); protocol section 3 (data loss)

## Also check
- Lifecycle notices (trial ending, annual renewal, payment failed, cancellation) have a sender wired to the event; a template with no caller is a paper control. Disclosure beside the start button stays uxauditor TRU-R3; file a missing reminder on a paid consumer trial or annual renewal under BILL as Medium and cite the facts.md rule.
- Out-of-order events: an older subscription update overwriting a newer state (compare event timestamps or re-fetch the subscription).
- Upgrades that grant the higher plan before the prorated payment succeeds.
- Promotion codes with no expiry, redemption cap, or plan restriction, or 100 percent off forever (automated redemption is secauditor APISEC-R3).
- One-time purchases: a refund revokes what was bought (license keys, credits); app store refund and revocation notifications are handled.
- A returning customer gets their data back, not a new empty account; pause and resume, if sold, have defined access and billing.
- Store and web subscriptions on one account neither double-charge nor conflict.
- Tax: with a provider that is not the merchant of record, checkout passes automatic tax or a tax rate, and business plans collect a tax ID and send invoices or receipts. When neither code nor docs show how tax is handled, write it as a question in Scope and limitations; tax registration is outside the repository.
- Native apps that unlock digital features: purchases go through the store's billing, or through an external-purchase path facts.md lists as allowed for the storefronts the app ships to; when facts.md says the path is not allowed there, file it under BILL as High and name the storefront and the guideline.
- Usage-based plans: customers can see current-period usage and the projected charge. A spend cap or usage alert the copy promises and the code lacks is CLM-R1; with no promise, write the gap as a question in Scope and limitations.

## Paper controls (look protective, protect nothing)
- A webhook route whose event switch handles only `checkout.session.completed`.
- A `case "customer.subscription.deleted":` branch that only logs.
- A `trial_ends_at` column written at sign-up and read only by the banner that counts days.
- A "Cancel subscription" button that sets `status = "canceled"` locally and calls no provider API.
- A `syncSubscriptions` or reconciliation job defined and never scheduled; a grace-period constant no check reads.
