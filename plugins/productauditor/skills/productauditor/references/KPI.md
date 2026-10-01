# KPI: Business Metric Definitions

Weight 8. Active when the code computes business metrics (MRR, churn, active users, retention, conversion, LTV) in queries, jobs, or dashboards, or the repository holds dbt models or a semantic layer.
Owns: whether the numbers leadership reads are computed as their labels say: recurring-revenue normalization and status filters; currency and unit handling; exclusion of internal, test, and demo accounts; the definition of active; one definition per named metric; and windows that match their labels.
Not here: event correctness in analytics tools (MET); query speed and indexes behind a metric (dbauditor QUERY, INDEX); money stored as floats (dbauditor TYPES-R1); who can open the admin dashboard (secauditor AUTHZ-R2); a metric computed by dead code (codeauditor QUAL-R4); duplicated logic that is not a named metric (codeauditor QUAL-R2, ARC-R6).
Standards: Stripe Billing analytics and ChartMogul MRR definitions; ISO 4217 (currency codes and minor units); ASC 606 and IFRS 15 (revenue is not bookings or cash); Skok, "SaaS Metrics 2.0"; dbt Semantic Layer (MetricFlow); ISO 8601 (time intervals).
Read first: admin and internal dashboard handlers; metric and report jobs; dbt models and SQL views; any metrics-definition doc; and the account and user models (test, internal, staff, or demo markers).
A reporting surface, in the cards below, is one you can cite: an admin or internal dashboard route that renders the number, a scheduled report job or email that sends it, an export of it, or a repository doc that names it as a company metric (north star, OKR, board or investor update). Who reads a surface outside the repository is not visible; never raise severity on a guess about the audience.

## Cards

### KPI-R1 Recurring revenue is summed without normalizing the interval or filtering the status
- Leads: `scan.sh KPI-R1` lists MRR, ARR, and revenue computations.
- Confirm: the computation adds plan prices without converting yearly, quarterly, or weekly prices to monthly; counts subscriptions that do not pay now (trialing, incomplete, canceled, paused, or past due beyond grace); adds one-time charges, setup fees, tax, or refunds; or ignores recurring discounts and quantity.
- Not a finding if: the number comes from the provider's own MRR or reporting API; the code normalizes by interval and filters to paying statuses (cite the lines); the metric is labeled bookings or cash collected and computed as such.
- Severity: High when the number appears on a reporting surface; Medium when it is computed only in a script or labeled as an estimate.
- Fix: compute MRR per subscription as price times quantity normalized to a month, net of recurring discounts, for paying statuses only, excluding one-time charges and tax, in one function.
- Verify the fix: a fixture with one monthly, one yearly, one trialing, one past-due, and one canceled subscription yields the expected MRR.
- Refs: Stripe Billing analytics (MRR); ChartMogul MRR; SaaS Metrics 2.0

### KPI-R2 Amounts in different currencies or units are added together
- Leads: `scan.sh KPI-R2` lists sums and reductions over revenue and amount fields in queries and metric code.
- Confirm: a revenue or payout total adds amounts from records that carry a currency field, or come from a multi-currency provider, without grouping by currency or converting at a recorded rate; or it adds minor-unit integers (cents) to major-unit decimals.
- Not a finding if: the product charges in one currency only (cite the single-currency config); the query groups by currency; amounts are converted with a stored rate before summing; the sum is a cart or order total for one customer, not a business metric.
- Severity: High when the mixed total is a revenue or payout figure; Medium otherwise.
- Fix: group by currency, or convert each amount at its transaction-time rate; keep amounts as integer minor units with the ISO 4217 code beside them.
- Verify the fix: a fixture with EUR and USD charges yields per-currency totals, or one converted total at the stated rates.
- Refs: ISO 4217

### KPI-R3 Internal, test, or demo accounts are counted as customers
- Leads: `scan.sh KPI-R3` lists internal, staff, demo, test-account, and live-mode markers. Then read the metric queries that KPI-R1 and KPI-R4 found for a filter on them.
- Confirm: the schema or code marks internal, staff, test, or demo accounts (a flag, a role, a company email domain, provider test mode), and a customer metric (revenue, active users, sign-ups, conversion, churn) does not exclude them.
- Not a finding if: the metric filters them (cite it); the marker exists only in test fixtures; the metric is labeled as including them.
- Severity: High when the metric drives billing or payouts, or appears on a reporting surface while a production seed or onboarding script creates staff or demo accounts (cite it); Medium otherwise.
- Fix: define one real-customer filter and apply it in every customer metric.
- Verify the fix: a fixture with one staff account and one customer counts only the customer.
- Refs: Lean Analytics

### KPI-R4 Active users counts accounts that did nothing
- Leads: `scan.sh KPI-R4` lists active-user, DAU, WAU, MAU, last-seen, and last-login code.
- Confirm: the active-user metric counts accounts by `created_at`, by a login or last-seen timestamp that token refreshes or background jobs update, by any request including automated ones, or by an `active` status flag, so it reports accounts rather than people who used the product.
- Not a finding if: activity is a user-initiated key action (the core value action from the Map) recorded with a timestamp, and the metric counts distinct users with that action in the window; the label states the narrower definition ("logins in the last 30 days").
- Severity: High when the metric is labeled north star or appears on a reporting surface; Medium otherwise.
- Fix: define active as the distinct users who performed a named key action in the window, recorded by that action's handler, excluding automated calls.
- Verify the fix: a fixture user who only refreshes a token is not counted; one who performs the key action is.
- Refs: Lean Analytics; AARRR (retention)

### KPI-R5 One named metric has several definitions
- Leads: no pattern of its own. Group the hits of `scan.sh KPI-R1` and `scan.sh KPI-R4` by metric name.
- Confirm: two or more places compute a metric with the same name (MRR, active users, churn, conversion) with different filters, windows, or formulas, so two reports disagree: a dashboard and an export, an API and a job, code and a dbt model.
- Not a finding if: the names differ and each definition is documented; one copy is dead code (codeauditor QUAL-R4).
- Severity: High when one copy feeds a reporting surface and the other feeds operations or billing; Medium otherwise.
- Fix: define each metric once (a function, a view, or a semantic-layer metric) and make every report read it.
- Verify the fix: a search for the metric's computation finds one definition, and every report reads it.
- Refs: dbt Semantic Layer (MetricFlow)

### KPI-R6 A metric's window or period does not match its label
- Leads: `scan.sh KPI-R6` lists date windows, intervals, and period truncation in metric code.
- Confirm: a metric labeled for a calendar period ("this month", "March MRR") uses a rolling window, or a rolling label uses a calendar period; the end bound is inclusive, so a boundary day counts in two adjacent periods; or periods are cut in server local time while the label implies UTC or the customer's time zone.
- Not a finding if: the label states the window and the code matches it.
- Severity: Medium when the number is compared period over period on a reporting surface; Low otherwise.
- Fix: name the window in the label, use half-open intervals (`>= start AND < end`), and truncate in one stated time zone.
- Verify the fix: a fixture event at a period boundary counts in exactly one period.
- Refs: ISO 8601 (time intervals)

## Also check
- Churn divided by the end-of-period count instead of the start, or revenue churn that ignores contraction.
- Conversion rates whose numerator and denominator come from different populations (trial starts from events, paid conversions from the billing table).
- Metrics computed from lossy client events where the database holds the truth (MET-R4).
- Deleted accounts dropped from history, so past cohorts shrink when customers leave.

## Paper controls (look protective, protect nothing)
- A metrics-definition document whose formulas no query follows.
- An `is_test` flag on the account model that no metric query reads.
- A "matches Stripe" comment over a query that ignores refunds and status.
- An admin MRR tile that sums every subscription's price regardless of status or interval.
