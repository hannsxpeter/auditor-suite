# Answer key: productauditor full-audit

Never copied into the eval workspace. Lines refer to files under repo/.

Fieldnote is a B2B SaaS for small agencies and freelancers: one board per client project, with cards that move from To do to Done. It sells Free (3 projects), Pro ($24 a month or $240 a year, 25 projects, CSV export), and Studio ($59 a month or $590 a year, unlimited projects, CSV export) through Paddle Billing, which is the merchant of record. Every sign-up gets a 14-day Pro trial with no card. The promises are in README.md:7-17, the pricing page (src/components/PricingTable.jsx), the plan catalog (lib/plans.js), the feedback dialog (src/App.jsx:307), and the help article (content/help/billing.md). Stage: growth (a mounted checkout at server/index.js:30, a Paddle webhook, PostHog analytics). The core value action is creating projects and cards; their rows carry the creator, the workspace, and created_at (server/db.js:26-41), so MET-R1 does not apply. No business metrics are computed, so KPI is not applicable; there are no flags, so SHIP has no candidates.

## Planted defects

| Grader | Location | Card | Expected severity | Defect |
|---|---|---|---|---|
| finds-annual-price-charged | src/components/PricingTable.jsx:43 | ENT-R1 | Critical | the price shown follows the Monthly or Yearly toggle (`plan.prices[interval]`, :41), but every checkout button sends `plan.prices.year.id`, so a customer who chooses Pro at $24 a month starts a $240 yearly subscription |
| finds-plan-key-mismatch | server/entitlements.js:6 | ENT-R2 | Critical | `planFor` grants Pro or Studio only when `workspace.plan` is `"pro"` or `"studio"`, but billing writes the Paddle price id into `plan` (server/billing.js:34, from the webhook at server/routes/webhooks.js:32 and the checkout return at server/routes/checkout.js:41), so every paying customer falls to Free: 3 projects (server/index.js:65-67) and no CSV export (server/index.js:99). `planKeyForPrice` exists in lib/plans.js:39 but nothing applies it to the stored plan |
| finds-cancel-skips-paddle | server/routes/subscription.js:35 | BILL-R4 | Critical | "Cancel subscription" sets `plan: "free"` and `subscription_status: "canceled"` locally and answers "You will not be charged again" (:36), but never calls Paddle, so the subscription keeps renewing and charging, and the next `subscription.updated` event puts the price id back (server/routes/webhooks.js:31-32). It also ends paid access at once, although README.md:15 and content/help/billing.md:15 promise access until the end of the paid period |
| finds-sandbox-in-production | config/production.json:4 | BILL-R2 | Critical | the production config sets `apiBase` to `https://sandbox-api.paddle.com` and `environment` to `sandbox` (:5); server/billing.js:11-14 loads it whenever `NODE_ENV` is production, which `npm start` sets (package.json:9), while checkout is mounted (server/index.js:30) and the pricing page sells Pro and Studio with no beta label, so production checkout takes no real money |
| finds-downgrade-deletes-projects | server/jobs/plan-limits.js:9 | BILL-R8 | Critical | after every subscription update and every cancellation (server/routes/webhooks.js:33, :40), the job hard-deletes the newest projects above the new plan's limit, and their cards by cascade (server/db.js:35), with no notice, export, read-only state, or recovery window; a cancellation drops a workspace to 3 projects |
| finds-trial-never-ends | server/routes/auth.js:38 | BILL-R5 | Critical | every sign-up gets `plan: "pro"` with `trial_ends_at` 14 days out (:37) and no payment method, but nothing reads `trial_ends_at` (only the schema at server/db.js:19 and the insert at server/db.js:68-69 name it), and server/entitlements.js:6 grants Pro to `"pro"` forever, so the Pro trial never ends |
| finds-purchase-event-on-click | src/components/CheckoutButton.jsx:12 | MET-R2 | High | `purchase_completed` is sent in the click handler before the checkout request (:14) and before any payment, so attempts, failures, and abandoned checkouts count as purchases; it is the primary metric of the pricing experiment (src/lib/experiments.js:10) |
| finds-random-variant | src/lib/experiments.js:21 | EXP-R1 | High | the pricing-page headline variant is drawn with `Math.random()` on every call, `getVariant` runs on every render of the pricing page (src/components/PricingTable.jsx:13), and the variant is never stored, so one visitor sees both variants and logs an exposure per render (:22) |
| finds-feedback-dropped | server/routes/feedback.js:10 | VOC-R1 | High | the only support path, the "Send feedback" dialog that promises a reply by email within one business day (src/App.jsx:307, README.md:17), posts to a route that only writes the message to the server log and returns `{ ok: true }`; no ticket, row, email, or event reaches the team |
| finds-help-missing-settings | content/help/billing.md:23 | CLM-R6 | High | the billing help article sends users to **Settings > Plan & usage** and **Download invoices**, but the settings navigation has only Workspace and Billing (src/App.jsx:262-263) and no invoice list or download exists anywhere |

Critical-class defects: ENT-R1, ENT-R2, BILL-R4, BILL-R2, BILL-R8, BILL-R5. ENT and BILL are floor dimensions, so any one of them Confirmed holds the overall score at 69. A report may rate the help article Medium and still be right; it should not rate any Critical row below High. CLM-R1 for the invoice claim at content/help/billing.md:23 is an acceptable filing of the same defect.

## Decoys (safe; flagging them is a false positive)

| Grader | Location | Why it is safe |
|---|---|---|
| ignores-checkout-success | server/routes/checkout.js:30 | the checkout return grants the plan only after it reads the transaction back from Paddle on the server (:33) and checks that it is paid or completed (:34), belongs to this workspace (:35) and customer (:36), and has a subscription; otherwise it grants nothing (:37-39). The webhook grants the same plan if the tab is closed. BILL-R1's Not a finding if applies. The checkout start in the same file is also sound: it validates the price id (:11), asks Paddle whether the current subscription is live before starting another (:13-18), and reuses the Paddle customer (:21) |
| ignores-export-paywall | src/components/ExportButton.jsx:7 | the paywall is display only: `features` comes from GET /api/me, which the server computes from the plan (server/index.js:46), and the export route itself runs `requireFeature("csv_export")` before the handler (server/index.js:99, server/entitlements.js:23-30). ENT-R5's Not a finding if applies. That paying customers also see this paywall is ENT-R2, filed at server/entitlements.js:6 |

## Strengths worth naming

- One plan catalog (lib/plans.js:3-34) feeds the pricing page, checkout validation, the change-plan options, the webhook, and entitlements; prices, limits, and features are defined once.
- Checkout validates the price id against the catalog, asks Paddle whether the workspace already has a live subscription, and reuses the Paddle customer (server/routes/checkout.js:11-21).
- The checkout return verifies the transaction on the server before granting anything (server/routes/checkout.js:33-41).
- Paid limits and features are enforced on the server: the project limit at creation (server/index.js:65-67) and CSV export through `requireFeature` (server/index.js:99).
- Plan changes go through Paddle with proration, and the webhook copies the result back (server/routes/subscription.js:15-24); customers can reach Paddle's update-payment page (server/routes/subscription.js:27-31).
- The webhook checks Paddle's HMAC signature with a timestamp window and a timing-safe compare (server/routes/webhooks.js:11-19).
- The change-plan options in Billing settings take the label, amount, and price id from the same catalog entry (src/App.jsx:196-199), the opposite of the pricing page defect.
- Analytics identify the user and group the workspace on load (src/App.jsx:38-39); the PostHog project comes from per-environment variables.

## Other findings a careful report may add

These are not graded. They are real but secondary, so a report that files them is not wrong:
- MET-R4 at src/components/CheckoutButton.jsx:12: the purchase event is client-only and carries no amount, currency, or interval.
- BILL-R3 (Medium) at server/routes/webhooks.js:29-44: refunds and adjustments are not handled.
- ENT-R3 at server/routes/auth.js:38: the paid default for new sign-ups; BILL-R5 is the better card, since the default is a trial that never ends.
