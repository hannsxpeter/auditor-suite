# Changelog

All notable changes to productauditor are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/). The skill versions
with the auditor-suite release train named in the hub
[`VERSION`](../../VERSION) file.

## [auditor-suite 1.2.0] - 2026-10-01

First release. productauditor is the suite's eighth auditor: it audits a
product through a product manager's and head of product's lens from its code,
config, copy, and checked-in product docs, and writes `productaudit.md`. It
follows the suite's authoring guide (`docs/AUTHORING.md`) and the secauditor
reference shape.

### Added

- `SKILL.md`, a short spine: the contract (read-only and static; never runs
  the product or calls an analytics, billing, feature-flag, CRM, support, or
  warehouse service, a vendor dashboard, or a model; never quotes a
  credential), the modes, the eight-step workflow with a Map step that traces
  the promise inventory, the money path, and the customer lifecycle, the
  dimension table, and the judgment notes (traces, not opinions; what a
  static read cannot see; calibration by product stage; the closed list of
  Critical classes; how far to trust product docs).
- Nine dimensions, weights summing to 100: CLM Claims and Delivery (15), ENT
  Plans, Pricing and Entitlements (16), BILL Billing and Subscription
  Lifecycle (16), CUST Customer Accounts and Operations (9), MET Product
  Metrics and Instrumentation (12), KPI Business Metric Definitions (8), SHIP
  Release, Rollout and Sunset (10), EXP Experimentation (7), and VOC Customer
  Feedback and Demand Signals (7). CLM, MET, and SHIP are always active; the
  other six are conditional and decided by probes in `assets/surfaces.tsv`.
- 58 rule cards in `references/<DIM>.md`, 17 of them tagged quick (CLM 8 with
  5 quick, ENT 8 with 4, BILL 8 with 7, CUST 6 with 1, MET 7, KPI 6, SHIP 6,
  EXP 4, VOC 5), each with Leads, Confirm, Not a finding if, Severity, Fix,
  Verify the fix, and Refs, plus "Also check" and "Paper controls" lists and
  a "Not here" line that names the sibling card for every shared topic. The
  quick cards cover exactly the five Critical classes: customers charged more
  than or other than what they were shown or chose, or after they cancelled;
  paying customers refused what their plan includes; customer data destroyed
  by a lifecycle event or product rule with no notice and no recovery window;
  the business model not enforced for anyone; and customers paying for
  something that does not exist or is invented.
- Floor dimensions ENT and BILL: one Critical finding in either holds the
  overall score at 69 instead of 79.
- `SCAN_SKIP_RE` in `assets/skill.conf`, the first use of the suite's new
  optional per-skill scan skip: `scan.sh`, `inventory.sh`, and the probes in
  `new-report.sh` skip tests, stories, fixtures, mocks, agent planning folders
  (`.planning/`, `.godplans/`, `.godpowers/`), archived docs, and lockfiles
  for this auditor only, and `inventory.sh` reports how many files it
  skipped. `check-report.sh` lists no files, so a finding may still cite a
  skipped file the model opened on purpose.
- `assets/skill.conf`, `dimensions.tsv`, `patterns.tsv` (75 lead patterns
  for 55 cards, working in both `grep -E` and ripgrep; ENT-R7, KPI-R5, and
  SHIP-R6 have no pattern and name the files to read), and `surfaces.tsv`
  (18 probes: 7 for the product surface itself and 11 for the conditional
  dimensions; with no product surface, the audit stops). Product docs alone
  are not a product surface, and CUST activates on a membership, invite, or
  member-role entity or on admin tooling, never on a bare workspace or
  organization id.
- `references/facts.md`, last reviewed 2026-10-01, each fact with a link to
  verify it: US subscription law (the vacated FTC Negative Option Rule and
  the 2026 restart, ROSCA, the California Automatic Renewal Law as amended by
  AB 2863, the New York City cancellation rule from 1 October 2026), EU
  pricing and switching rules (UCPD, Consumer Rights Directive, Price
  Indication Directive, Data Act), Stripe Billing statuses, events, keys,
  prices, prorations, meters, entitlements, and MRR definitions, merchant of
  record and sandbox facts for Paddle, Lemon Squeezy, Polar, PayPal,
  Braintree, and Adyen, Paddle subscription, transaction, and adjustment
  (refund, credit, chargeback) events, App Store and Google Play notifications and purchase
  rules after Epic v. Apple and Epic v. Google, RevenueCat events, analytics
  deduplication ids, and the Deprecation and Sunset headers.
- `references/example-report.md`, a validated report of the small fixture in
  `tests/fixtures/productauditor/`, distinct from the eval fixture.
- An eval case in `evals/productauditor/full-audit/`: a small product with
  ten planted product defects (six of them Critical-class: a monthly price
  shown while checkout sends the annual price id, an entitlement check that
  compares against a value the webhook never writes, a cancel that never
  reaches the provider, sandbox billing in production, a downgrade job that
  deletes customer data, and a trial nothing ends), two decoys, and graders.
- The shared read-only scripts (`inventory.sh`, `scan.sh`, `new-report.sh`,
  `score.sh`, `check-report.sh`), `references/protocol.md`, and
  `assets/report-template.md`, vendored from the hub's `shared/` folder.
