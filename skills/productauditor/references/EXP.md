# EXP: Experimentation

Weight 7. Active when experiment, A/B test, holdout, or variant-assignment code or config exists.
Owns: whether experiments can be trusted to decide: assignment that is stable and keyed to the right unit; exposure logged where the variant renders; splits that are valid by construction (weights, filters, targeting); and the experiment lifecycle (an end, a decision rule, and removal of the losing variant).
Not here: flag defaults, kill switches, and release flags (SHIP); a pricing experiment whose charge does not follow the variant shown (ENT-R1); the metric an experiment names with nothing to measure it (MET-R7); A/B tests that change what crawlers see (seoauditor OBSV-R2); dead branches of ended experiments (codeauditor QUAL-R4).
Standards: Kohavi, Tang, and Xu, Trustworthy Online Controlled Experiments (2020): ch. 14 (randomization unit), ch. 20 (triggering), ch. 21 (sample ratio mismatch); OpenFeature hooks; Hodgson (experiment toggles).
Read first: the experiment or flag SDK setup and wrapper; experiment definitions and registries; every variant read on the Map's journeys; and the exposure and tracking callbacks.

## Cards

### EXP-R1 Variant assignment is random per request or render, or keyed to the wrong unit
- Leads: `scan.sh EXP-R1` lists random calls on the same line as variant, bucket, cohort, experiment, or rollout code.
- Confirm: a user's variant is chosen with `Math.random()`, `random.random()`, or similar at render, per request, or per session and is not stored, so one user sees both variants; or assignment hashes the session or the device while the metric and the change are per user or per account (teammates in one account see different prices or flows).
- Not a finding if: the value is drawn once and persisted on the user or account before first exposure and reused (read where it persists); the SDK assigns by hashing a stable id passed as the targeting key; the random call is retry jitter or log sampling.
- Severity: High when the experiment changes pricing, checkout, sign-up, or onboarding, or its results are reported; Medium otherwise.
- Fix: assign by a deterministic hash of the stable user or account id and the experiment key, in one helper or through the SDK with that id as the targeting key.
- Verify the fix: assigning one user twice returns the same variant; users in one account share a variant when the unit is the account; a thousand ids split near the configured ratio.
- Refs: Kohavi et al. ch. 14 and ch. 21

### EXP-R2 Exposure is not logged where the variant renders, or is logged for users who never saw it
- Leads: `scan.sh EXP-R2` lists variant reads, exposure events, and tracking callbacks.
- Confirm: the code reads a variant and changes behavior, and either no exposure event (with the experiment key and variant) is sent where the variant first renders and the variant is not a property on later outcome events, so results cannot be joined; or exposure is sent at assignment for every user (in middleware, or on page load for a change deeper in the flow), so the analysis includes users the change never touched.
- Not a finding if: the SDK logs exposure on evaluation and evaluation happens where the variant renders (read the call site and the tracking callback, for example a GrowthBook `trackingCallback` or PostHog `$feature_flag_called`); the experiment config defines an explicit trigger event.
- Severity: High when the experiment is running and changes pricing, checkout, or sign-up, or a doc names the launch decision it decides; Medium otherwise.
- Fix: send one exposure event per user per experiment where the variant first renders, with the experiment key, the variant, and the user and account ids.
- Verify the fix: a test that never reaches the variant sends no exposure; reaching it sends exactly one.
- Refs: Kohavi et al. ch. 20; OpenFeature hooks

### EXP-R3 The split is invalid by construction
- Leads: `scan.sh EXP-R3` lists variant weights, traffic allocations, and targeting rules in experiment definitions. Read the filters applied after assignment.
- Confirm: variant weights do not sum to the stated allocation (`[50, 30]`); a variant is assigned and then filtered, redirected, or dropped by later code for some users, so the groups are no longer comparable; or a targeting rule uses an attribute the code never sends in the evaluation context, so one variant never matches.
- Not a finding if: the SDK normalizes weights and the definition states the intended unequal split; the eligibility filter runs before assignment for every variant alike (read the order).
- Severity: High when the experiment changes pricing, checkout, or sign-up; Medium otherwise.
- Fix: make the weights sum to the allocation, apply eligibility filters before assignment for every variant, and send every attribute the targeting rules use.
- Verify the fix: a test assigns a thousand eligible ids and finds each variant near its weight with no variant missing.
- Refs: Kohavi et al. ch. 21 (sample ratio mismatch)

### EXP-R4 An ended experiment still splits traffic, or a running one has no end or decision rule
- Leads: `scan.sh EXP-R4` lists end dates, winners, rollout percentages, and status fields in experiment definitions and registries.
- Confirm: an experiment's end date has passed (compare it with the audit date) or a doc records its decision, and code still assigns users to the losing variant; or, where an experiment registry or config exists in the repository, a running experiment has no end date, sample size, primary metric, or decision rule there.
- Not a finding if: the holdout is deliberate and documented with an owner (a long-term holdback); experiments are defined only in a remote service you cannot read (say so in Scope and limitations).
- Severity: High when the losing variant is a price, a removed safeguard, or a flow the recorded decision says converts worse; Medium otherwise.
- Fix: ship the winner to everyone, remove the losing branch and the experiment, record the decision with its date, and give every new experiment an end date, a primary metric, and a decision rule in its config.
- Verify the fix: the ended experiment's key no longer appears in assignment code, and every running experiment has an end date and a decision rule.
- Refs: Kohavi et al. (experiment lifecycle, holdouts); Hodgson (experiment toggles)

## Also check
- Experiments with no guardrail metric (errors, refunds, latency) beside the primary metric, where a registry exists.
- One user in several experiments that change the same screen with no layer or exclusion rule.
- Experiment results computed from client events that ad blockers drop (MET-R4).

## Paper controls (look protective, protect nothing)
- An exposure event in the tracking plan that is never sent.
- A "percentage rollout" implemented with `Math.random` (EXP-R1).
- An experiment dashboard config naming a metric no event emits (MET-R7).
