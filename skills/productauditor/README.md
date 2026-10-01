# productauditor

A read-only **product audit** skill for AI coding agents, part of the [auditor-suite](../../README.md). It reads the product in the current directory the way a product manager and a head of product read it in their first week, from its code, config, copy, and checked-in product docs. It writes a scored, prioritized, self-contained `productaudit.md` at the project root and prints the verdict in chat. It never edits source, never runs the product, and never queries an analytics, billing, feature-flag, or CRM service or a model.

- Claude Code: `/productauditor`, or ask for "a product audit", "a PM review", "product due diligence", or "does the code enforce our pricing".
- Codex: `$productauditor`.
- Other Agent Skills harnesses: the harness's native skill invocation.

## What it audits

Six questions, each answered from what the repository can show:
- Does the product deliver what it tells customers?
- Does it charge and grant what it sells?
- Does it keep money, access, and data right at every lifecycle moment (trial, renewal, failed payment, downgrade, cancellation, member removal, closure)?
- Does it measure what the team decides with?
- Does it release and retire changes safely?
- Does it hear its customers?

Every finding is a gap between two things the report can cite: copy and code, plan and gate, provider state and app state, doc and behavior, or metric label and query. Strategy, market, pricing-level, and roadmap opinions leave no trace in a repository, so they are out of scope.

Nine dimensions, three always active and six conditional. The model reads 58 rule cards, 17 of them tagged quick.

| ID | Dimension | Weight | Active when | Cards |
|---|---|---|---|---|
| CLM | Claims and Delivery | 15 | always | 8 |
| ENT | Plans, Pricing and Entitlements | 16 | plans, tiers, prices, paywalls, or entitlement checks exist, or the pages show prices or a pricing route | 8 |
| BILL | Billing and Subscription Lifecycle | 16 | a billing provider SDK, a checkout, or subscription state or billing events exist | 8 |
| CUST | Customer Accounts and Operations | 9 | multi-member organizations, workspaces, or teams (a membership, invite, or role entity), or admin, support, or back-office tooling exist | 6 |
| MET | Product Metrics and Instrumentation | 12 | always | 7 |
| KPI | Business Metric Definitions | 8 | the code computes business metrics (MRR, churn, active users, retention, conversion, LTV), or the repository holds dbt models or a semantic layer | 6 |
| SHIP | Release, Rollout and Sunset | 10 | always | 6 |
| EXP | Experimentation | 7 | experiment, A/B test, holdout, or variant-assignment code or config exists | 4 |
| VOC | Customer Feedback and Demand Signals | 7 | feedback, survey, bug-report, contact, support-widget, cancellation-reason, waitlist, or contact-sales code exists | 5 |

The weights sum to 100 and re-normalize over the active dimensions, so a free product with no billing is scored only on what it has. ENT and BILL are floor dimensions: one Critical finding in either holds the overall score at 69 instead of 79, because a product that charges customers wrongly, withholds what they paid for, or gives the paid plan away cannot grade well however good the rest is.

Critical is a closed list of five classes, and the 17 quick cards cover exactly these: customers charged more than or other than what they were shown or chose, or after they cancelled; paying customers refused what their plan includes; customer data destroyed by a lifecycle event or product rule with no notice and no recovery window; the business model not enforced for anyone (sandbox checkout in production, paid access from the success redirect, unknown plans falling through to paid, a trial nothing ends); and customers paying for something that does not exist or is invented. Everything else is High at most.

Boundaries, in short: uxauditor owns how journeys feel, onboarding friction, whether activation and funnel events exist, and every deceptive pattern; codeauditor owns developer docs, dead code, non-plan guards, per-environment config other than analytics keys and billing mode, and operator telemetry; secauditor owns roles, tenants, client-set fields, webhook signatures, credentials, and personal data in events; dbauditor owns idempotency, transactions, cascades, cross-service references, and money types; llmauditor owns model spend limits with no plan term, failures turned into default answers, and model telemetry; seoauditor owns how analytics tags load, consent wiring, and A/B tests as crawlers see them. productauditor files the product consequence once, when its fix lives in product code (a plan gate, a billing sync, copy, an event, a flag, a metric definition, a feedback handler), and names the sibling. Each card file's "Not here" line names the sibling card. The suite map is in [SUITE.md](../../SUITE.md).

## Modes

- `/productauditor` or `/productauditor full`: every active dimension, every card.
- `/productauditor quick`: only the 17 Critical-class cards; no numeric score. A good first pass for small models or large repositories.
- `/productauditor only=ENT,BILL`: those dimensions only, every card; the score is labeled partial.
- `/productauditor apps/web` (or `quick apps/web`): audit only that part of the tree.

## How it works

1. `scripts/inventory.sh` maps the project and probes for a product surface: screens, a public API, a CLI, a published package, or product configuration (plans, billing, analytics, or feature flags). With none, the audit stops and writes nothing; internal scripts and infrastructure belong to codeauditor.
2. `scripts/new-report.sh` writes the `productaudit.md` skeleton and decides the conditional dimensions. The model fills the Snapshot (including the product stage and the business model) and the Map: the promise inventory, the money path from pricing copy to plan catalog to checkout to webhook to entitlement check, the lifecycle states, the core value action, the flag and experiment mechanism, the feedback channels, the product docs with their dates, and the single widest gap between promise and code.
3. For each dimension the model reads its rule cards and runs `scripts/scan.sh <DIM>`, which turns card patterns into `path:line` leads. Each card says how to confirm a defect, when it is not a finding, its severity, the fix, and how to verify the fix; each file ends with "Also check" items and the paper controls that look like product rigor and protect nothing (a pricing table no entitlement code reads, a cancel button that never calls the provider, a feedback widget wired to nothing).
4. `scripts/score.sh --write` computes every dimension score, the overall score and grade, the caps, "What to fix first", and the remediation buckets from the findings. No model does the arithmetic.
5. `scripts/check-report.sh` validates the report: sections, finding fields, that every cited `path:line` exists and that code quoted in Evidence appears within 6 lines of the first cited location, that every card was worked, and that the generated blocks match the findings.
6. `scripts/score.sh --chat` prints the verdict for the chat.

The scans skip tests, stories, fixtures, mocks, agent planning folders (`.planning/`, `.godplans/`, `.godpowers/`), archived docs, and lockfiles, through `SCAN_SKIP_RE` in `assets/skill.conf`; `inventory.sh` says how many files it skipped. The model still opens a test, CI, or setup file when a card names it.

## The read-only contract

- The only file the audit writes is `productaudit.md`. It never edits source, never runs the product, its tests, builds, or migrations, and never opens a browser.
- It never calls an analytics, billing, feature-flag, CRM, support, or warehouse service, a provider or vendor dashboard, or a model.
- A finding that depends on real usage, provider settings, a remote flag service, a vendor dashboard, or another repository is marked Likely or Suspected, and its Verify the fix line names the check that would confirm it: the provider's subscription list or webhook log, an analytics query, a flag-service export, or a customer interview. Critical needs Confirmed evidence from the repository.
- It never quotes a credential in the report; it cites the file and line and names secauditor.
- Law raises the stakes but never decides a finding: Impact says "exposure under", never "violates", and dated legal and provider facts come from `references/facts.md`.

## Files

```
skills/productauditor/
  SKILL.md                  the spine: contract, modes, workflow, dimensions, judgment
  references/
    protocol.md             shared finding format, severity, confidence, scoring (vendored)
    example-report.md       a finished report of tests/fixtures/productauditor that passes check-report.sh
    facts.md                dated billing-provider, app-store, consumer-law, analytics, and RFC facts,
                            last reviewed 2026-10-01
    CLM.md ... VOC.md       one rule-card file per dimension
  scripts/                  inventory.sh, scan.sh, new-report.sh, score.sh, check-report.sh (vendored, read-only)
  assets/
    report-template.md      the report skeleton (vendored)
    skill.conf              report name, headlines, banner, map instruction, domain rule, and SCAN_SKIP_RE
    dimensions.tsv          dimension IDs, weights, conditional and floor flags, and names
    patterns.tsv            search patterns that turn cards into leads (grep -E and ripgrep compatible)
    surfaces.tsv            probes for a product surface and for the six conditional dimensions
```

Vendored files come from the hub's `shared/` folder through `scripts/sync-shared.sh`; edit them there, never here. The eval case lives in `evals/productauditor/full-audit/`.

## Install

Use the hub installer or the plugin marketplace (`/plugin install productauditor@auditor-suite`); see the [suite README](../../README.md#install). A manual install must copy or link the whole skill directory (`SKILL.md`, `references/`, `scripts/`, `assets/`), not just `SKILL.md`.

## Output

`productaudit.md` is written for three readers. The product manager uses it as a work order and as the product's first promise inventory. The director, VP, or founder reads the verdict, the Critical list, and "What to fix first" before a pricing change, a launch, a growth push, a board metrics review, or due diligence. The engineering lead schedules the fixes from the `path:line` citations and the Verify the fix steps. It is self-contained, so another agent holding only the report and the code can act on it: snapshot, product map, score and scorecard, what to fix first, strengths to preserve, systemic root causes, findings with evidence and a way to verify each fix, dimension notes, a remediation plan, scope and limitations (including the questions that need usage, billing, or customer data before anyone decides), and a protocol for the acting agent.

## License

MIT. See [LICENSE](LICENSE).
