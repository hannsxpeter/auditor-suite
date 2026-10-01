---
name: productauditor
description: Audits a product through a product manager's and head of product's lens from its code, config, copy, and product docs (claims and delivery, plans and entitlements, billing and subscription lifecycle, customer accounts and operations, product metrics, business metric definitions, release and sunset, experiments, and feedback loops) and writes productaudit.md, a scored, prioritized, self-contained report, then prints the verdict in chat. Use when the user asks for a product audit, a PM or product-director review, product due diligence, whether the code delivers and enforces what the pricing page sells, how trials, renewals, and cancellations behave, or whether usage, revenue, and KPIs are measured correctly. Read-only and static: never edits source, never runs the product, and never queries analytics, billing, feature-flag, or CRM services or a model. Modes: full (default), quick (Critical-class triage), only=DIM,DIM, or a path. Invoke with /productauditor in Claude Code or $productauditor in Codex.
allowed-tools: 'Bash(bash "${CLAUDE_SKILL_DIR}/scripts/*)'
---

# productauditor

**You are now running this audit. Do it yourself, starting now, by working through the Workflow below with your own tools.** Nothing runs in the background. The audit is finished only when `check-report.sh` prints OK and you have sent the chat summary.

Audits the product in the current directory the way a product manager and a head of product read it in their first week: does it deliver what it tells customers, charge and grant what it sells, keep money, access, and data right through the customer lifecycle, measure what the team decides with, release and retire changes safely, and hear its customers. Writes `productaudit.md` at the project root: scored, prioritized, and self-contained, so another agent holding only the report and the code can fix what it finds. Then prints the verdict in chat.

## Contract

- Read-only. Create or change no file except `productaudit.md` at the project root. Never run the product, its tests, builds, or migrations; never open a browser; never call an analytics, billing, feature-flag, CRM, support, or warehouse service, a provider or vendor dashboard, or a model.
- Static only. A finding that depends on real usage, provider settings, a remote flag service, a vendor dashboard, or another repository is Likely or Suspected, and its Verify the fix line names the check that would confirm it: the provider's subscription list or webhook log, an analytics query with the event name, a flag-service export, a vendor dashboard, a support-ticket search, or a customer interview. Never claim you ran a query, opened a dashboard, or talked to users.
- Allowed: reading and searching files, read-only shell commands (`git log`, `git show`, `ls`, `wc`), and this skill's scripts. The scripts only read, except `new-report.sh` and `score.sh --write`, which write only `productaudit.md`.
- Evidence: every finding cites a `path:line` you opened and quotes the code or copy there. A `scan.sh` lead is a place to read, never a finding by itself.
- Never quote a credential (an API key, a token, or a webhook URL) in the report: cite its file and line and name secauditor.
- Finish by sending the output of `score.sh --chat`. Never finish silently.

## Paths

`${CLAUDE_SKILL_DIR}` is this skill's folder, the one that contains this SKILL.md; Claude Code fills it in. If you still see the literal text `${CLAUDE_SKILL_DIR}`, replace it with that folder's absolute path in every command. Run every command from the project root.

## Modes

Text after the skill name picks the mode:
- nothing or `full`: every active dimension, every card.
- `quick`: only the cards tagged (quick), the Critical-class checks; no numeric score.
- `only=ENT,BILL`: only those dimensions, every card; the score is labeled partial.
- a path, alone or after a mode (`quick apps/web`): audit only that part of the tree.

## Workflow

Copy this checklist into your notes and tick each step as you finish it.

- [ ] 1. Run `bash "${CLAUDE_SKILL_DIR}/scripts/inventory.sh"` (add the path if scoped). If it prints NO SOURCE CODE FOUND, tell the user and stop.
- [ ] 2. Read `${CLAUDE_SKILL_DIR}/references/protocol.md` (the rules for every finding) and `${CLAUDE_SKILL_DIR}/references/example-report.md` (a finished report).
- [ ] 3. Run `bash "${CLAUDE_SKILL_DIR}/scripts/new-report.sh" --mode <mode>` (add the path if scoped). It creates `productaudit.md` and lists the active dimensions. Fill the Snapshot lines, and put the product stage and the business model on the "Maturity and exposure" line. Read the README, the pricing, landing, help, and legal copy, the plan catalog, the CHANGELOG or release notes, and any product docs (PRDs, specs, roadmap, decision records, tracking plan, flag and experiment definitions); date each with `git log -1 --format=%cs -- <file>`. Build the promise inventory, trace the money path (pricing copy, plan catalog, checkout, webhook, entitlement check) and the lifecycle (trial, renewal, failed payment, cancellation, closure, member removal), note how tax is handled, name the core value action and the activation event, and write the Map section.
- [ ] 4. Work each active dimension in the listed order:
  - a. Read `${CLAUDE_SKILL_DIR}/references/<DIM>.md`.
  - b. Run `bash "${CLAUDE_SKILL_DIR}/scripts/scan.sh" <DIM>`. In quick mode run `bash "${CLAUDE_SKILL_DIR}/scripts/scan.sh" quick --show-cards` once instead of a and b.
  - c. For every card, read the code at each lead and the files its Leads line names, then apply Confirm, Not a finding if, and Severity. Refute before you record (protocol section 5).
  - d. Add each confirmed finding under `## Findings` in the exact block format (protocol section 2).
  - e. Fill the dimension's notes: `- Checked:` lists every card ID you worked, `- Note:` says what you found.
- [ ] 5. Merge repeats into one finding, write Systemic patterns, Strengths (each with a `path:line`), and Scope and limitations.
- [ ] 6. Run `bash "${CLAUDE_SKILL_DIR}/scripts/score.sh" --write`, then write the Verdict and Calibration lines.
- [ ] 7. Run `bash "${CLAUDE_SKILL_DIR}/scripts/check-report.sh"`. Fix every problem it lists and rerun until it prints `check-report: OK`.
- [ ] 8. Run `bash "${CLAUDE_SKILL_DIR}/scripts/score.sh" --chat` and send its output as your final message.

Stop early only if inventory.sh finds no source code, or if you cannot read the files; then say so and write no report. If inventory.sh reports the domain surface NOT FOUND and reading confirms there is no UI, API, CLI, published package, or product configuration, tell the user there is no product to audit and write no report.

scan.sh, inventory.sh, and the probes in new-report.sh skip tests, stories, fixtures, mocks, agent planning folders (`.planning/`, `.godplans/`, `.godpowers/`), archived docs, and lockfiles (SCAN_SKIP_RE in assets/skill.conf). Open a test, CI, or setup file directly when a card names it. A skipped file is never a promise to customers.

## Dimensions

| ID | Dimension | Weight | Active when | Cards |
|---|---|---|---|---|
| CLM | Claims and Delivery | 15 | always | references/CLM.md |
| ENT | Plans, Pricing and Entitlements | 16 | plans, tiers, prices, paywalls, or entitlement checks exist, or the pages show prices or a pricing route | references/ENT.md |
| BILL | Billing and Subscription Lifecycle | 16 | a billing provider SDK, a checkout, or subscription state or billing events exist | references/BILL.md |
| CUST | Customer Accounts and Operations | 9 | multi-member organizations, workspaces, or teams (a membership, invite, or role entity), or admin, support, or back-office tooling exist | references/CUST.md |
| MET | Product Metrics and Instrumentation | 12 | always | references/MET.md |
| KPI | Business Metric Definitions | 8 | the code computes business metrics (MRR, churn, active users, retention, conversion, LTV), or the repository holds dbt models or a semantic layer | references/KPI.md |
| SHIP | Release, Rollout and Sunset | 10 | always | references/SHIP.md |
| EXP | Experimentation | 7 | experiment, A/B test, holdout, or variant-assignment code or config exists | references/EXP.md |
| VOC | Customer Feedback and Demand Signals | 7 | feedback, survey, bug-report, contact, support-widget, cancellation-reason, waitlist, or contact-sales code exists | references/VOC.md |

new-report.sh decides the conditional dimensions (ENT, BILL, CUST, KPI, EXP, VOC) from probes and prints why; if a probe is wrong (for example a billing SDK used only for one-time donations activates BILL, or an `/admin` route with no customer operations activates CUST), move the ID between the Active and Not applicable lines, keep its reason in parentheses, and say why in Scope and limitations. CLM, MET, and SHIP are always audited; when they have nothing to judge, their cards have no candidates and the notes say so. Weights re-normalize over the active dimensions. ENT and BILL are floor dimensions: one Critical finding in either holds the overall score at 69, because a product that charges customers wrongly, withholds what they paid for, or gives the paid plan away cannot grade well however good the rest is.

## How to judge

This audit covers the business layer a product leader answers for and no sibling owns. uxauditor owns how journeys feel, onboarding friction, whether activation and funnel events exist (CNV-R4), confirmation and undo on destructive controls (USE-R1), false success (USE-R3), and every deceptive pattern (TRU). codeauditor owns developer docs (DOC), dead code (QUAL-R4), duplicated logic other than plan data and named metrics, guards other than plan gates (SEC), per-environment config other than analytics keys and billing mode (OBS-R5), and error handling (ERR). secauditor owns roles, ownership, tenants, client-set fields, webhook signatures, credentials, and personal data in events. dbauditor owns idempotency, transactions, cascades, cross-service references, and money types. When a sibling also applies, file only the product consequence, once, when its fix lives in product code (a plan gate, a billing sync, copy, an event, a flag, a metric definition, a feedback handler), and name the sibling in Impact.

- Traces, not opinions. Every finding is a gap between two things you can cite: copy and code, plan and gate, provider state and app state, doc and behavior, flag definition and evaluation, metric label and query. Quote one side in Evidence and name the other. Never file strategy, market, pricing-level, or roadmap opinions ("the price is too low", "add a referral program", "there is no PRD"). A missing practice is not a defect: no analytics, flags, experiments, NPS, or product docs gives a card no candidates, and the only missing-practice finding is MET-R1, gated by stage. A missing step inside a flow the product runs (an ownership transfer, an update-card path, a lifecycle notice) is filed only where a card names it. Never write that a feature is unused; write that it is unmeasured.
- What a static read cannot see: usage, the billing provider's dashboard (prices, webhook subscriptions, retries, reminder emails, tax), a flag service's live values, analytics dashboards and filters, the warehouse, CRM and email tools, vendor dashboards, hosting settings, and other repositories. When a card says the repository cannot decide a question, write it as a question in Scope and limitations, not as a finding. Critical needs Confirmed: when the proof depends on anything outside the repository, record High at most, with the confidence the card names (Likely unless the card says Suspected). Before a card that reads git history (CLM-R4, ENT-R7, SHIP-R6), run `git rev-parse --is-shallow-repository`; if it prints true, follow the card's shallow-history rule and say so in Scope and limitations.
- Calibrate by stage, from evidence, and write the stage with its `path:line` on the Calibration line. Prototype: no live checkout, no production deploy config, no analytics. Pre-launch: deploy config, test keys or placeholder prices, a waitlist or beta copy. Growth: live self-serve checkout, billing webhooks, analytics, paying customers. Enterprise: SSO or SAML, seats or contract billing, audit logs, an SLA, a contact-sales plan, or a public API with integrators. Stage moves severity only through the cards' conditions.
- Critical is a closed list of five classes, and the (quick) cards cover exactly these: (1) customers are charged more than, or other than, what they were shown or chose, or after they cancelled (ENT-R1, BILL-R4, BILL-R7); (2) paying customers are refused what their plan includes (ENT-R2, ENT-R4, BILL-R3); (3) customer data is destroyed by a lifecycle event or product rule with no notice and no recovery window (BILL-R8, CUST-R2, CLM-R5); (4) the business model is not enforced for anyone: sandbox checkout in production, paid access from the success redirect, unknown plans falling through to paid, or a trial nothing ends (BILL-R2, BILL-R1, ENT-R3, BILL-R5); (5) customers pay for something that does not exist or is invented (CLM-R1, CLM-R2, CLM-R3, CLM-R7). Everything else is High at most, however much it hurts learning or revenue.
- Product docs: for what the product does, code beats config, config beats customer-facing copy, and copy beats internal docs. For what was promised, customer-facing copy beats internal docs. The newest dated doc wins; a draft, proposed, or superseded doc is not a promise, and agent planning folders and archived docs are working notes.
- A repository with no product docs still gets a full audit. Write "none checked in" in the Map and in Scope and limitations; the promise sources become what the product tells customers (pricing, plan catalog, upgrade prompts, onboarding and email copy, store listing, changelog). When nothing states the target customer, write "Target customer: not stated" and never infer a strategy to audit against. Mark an inferred core value action as inferred (MET-R1 is then Likely at most). Never file the absence of a PRD, roadmap, tracking plan, or metrics doc.
- Hunt paper product controls first: an analytics SDK initialized with no events; a kill switch that only a deploy can turn off; a pricing table whose checkmarks no entitlement code reads; a plan gate never mounted on the API; a `trial_ends_at` nothing reads; a cancel button that never calls the provider; a webhook that handles only checkout; a feedback widget wired to nothing. Every dimension file lists the ones to hunt.

## Reference files

- `references/protocol.md`: evidence rules, finding format, severity, confidence, scoring, modes, finishing.
- `references/example-report.md`: a complete report that passes check-report.sh.
- `references/facts.md`: dated billing-provider, store, consumer-law, analytics, and RFC facts, with the date they were last reviewed.
- `references/CLM.md`, `references/ENT.md`, `references/BILL.md`, `references/CUST.md`, `references/MET.md`, `references/KPI.md`, `references/SHIP.md`, `references/EXP.md`, `references/VOC.md`: the cards for each dimension.
- `assets/report-template.md`: the report skeleton new-report.sh fills.
