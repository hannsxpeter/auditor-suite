# CNV: Onboarding, Conversion and Engagement

Weight 8. Always active.
Owns: activation and time to value, hard gates before first value, the first-run experience (doing, not touring; templates and sample data; progressive disclosure), plan limits and paywalls inside tasks, measurement of the funnel (AARRR), and the reasons to come back (retention and re-engagement).
Not here: empty-state copy (CNT-R2); the fields on the sign-up form (FRM-R4); a charge the user was not told about, preselected add-ons, and nagging (TRU); dead ends on the way (JRN-R2); whether product events, including the activation event and funnel steps, fire once at the true outcome, carry user and account identity, match the tracking plan, and capture revenue (productauditor MET).
Standards: AARRR (acquisition, activation, retention, referral, revenue); activation event and time to value; the Hooked model (trigger, action, reward, investment).
Read first: the sign-up and onboarding routes, the first screen after sign-up, the plan, trial, and limit checks, the analytics calls, and the email or notification jobs.

## Cards

### CNV-R1 A hard gate stands between sign-up and first value
- Leads: `scan.sh CNV-R1` lists payment-card, billing, verification, and book-a-demo steps; read where each sits in the sign-up and onboarding flow.
- Confirm: before the user can do the core action once, the flow requires a payment card, email or phone verification, a sales call, an account for a task that could be tried without one, or a team invite, and the product does not need it yet (a free plan or trial exists, or the first core action costs little to serve).
- Not a finding if: the gate is essential now and the code or docs say why (paid-only product with no trial, a regulated identity check, abuse controls on a costly resource); verification is deferred to the first action that needs it (the first external send).
- Severity: High when it blocks every new user before activation; Medium when it blocks a subset.
- Fix: let users reach the activation event first; ask for the card at upgrade or trial end, and verify the email before the first action that needs it.
- Verify the fix: a new account reaches the activation event with no card and no verification step.
- Refs: AARRR activation; time to value

### CNV-R2 The first run tours features or shows a blank canvas instead of leading to the core action
- Leads: `scan.sh CNV-R2` lists product-tour libraries, onboarding slides, and welcome modals.
- Confirm: after sign-up the user lands on a multi-slide tour, or on an empty workspace with no guided first action, template, or sample data that leads to the activation event.
- Not a finding if: the tour is skippable and ends on the core action; templates or sample data are offered on first run.
- Severity: Medium; High when the core action is not visible on the first screen at all.
- Fix: replace the tour with one guided first action, seed templates or sample data, and hide advanced features until the first success.
- Verify the fix: a new account reaches the core action from the first screen in one or two steps.
- Refs: activation; progressive disclosure

### CNV-R3 A plan limit or paywall interrupts the task and throws away the user's work
- Leads: `scan.sh CNV-R3` lists plan, quota, limit, upgrade, and paywall checks.
- Confirm: a limit check runs after the user has entered work and before it is saved, and the upgrade prompt discards the input (the save never runs, the form resets, or closing the prompt loses the draft).
- Not a finding if: the work is saved as a draft before the prompt, or the limit is shown before the user starts.
- Severity: High when users lose work they entered; Medium when the prompt only interrupts.
- Fix: check the limit before the user starts, or save a draft first and let them upgrade and continue where they were.
- Verify the fix: hit the limit mid-task, dismiss the prompt, and find the work intact.
- Refs: AARRR revenue; Nielsen heuristic 3

### CNV-R4 The activation event and funnel steps are not measured
- Leads: `scan.sh CNV-R4` lists analytics calls; check which funnel steps fire an event.
- Confirm: analytics is present, but no event fires at the activation event (the first hands-on experience of core value) or at the funnel steps (sign-up started, sign-up finished, first core action), so nobody can see where users drop off.
- Not a finding if: the product has no analytics by a documented privacy choice (note it in Scope and limitations instead); a server-side funnel records the same steps; an event for the step exists but fires at the wrong moment, more than once, or without user and account identity (productauditor MET-R2, MET-R3).
- Severity: Medium; Low for an internal tool.
- Fix: name the activation event, then fire one event per funnel step with the same user or session id.
- Verify the fix: a test run through sign-up and the first core action emits each named event once.
- Refs: AARRR; activation metrics

## Also check
- Time to value: count the steps and screens from sign-up to the activation event in the Map and name the count; fewer is better.
- Funnel leaks: walk acquisition, activation, retention, and revenue; name the step with the largest likely drop-off (Suspected without analytics); long forms, missing progress, and dead ends on the way file under FRM, JRN, and CNT.
- Retention: a reason to come back (saved work, teammates, fresh content, a habit loop of trigger, action, reward, and investment); re-engagement tied to something the user values, not generic reminders (repeated nagging is TRU-R4).
- Data asked before it is needed in onboarding files under FRM-R4.
- Anxiety reducers on the sign-up page ("no card required", a guarantee, cancel anytime) that are true; a false one is TRU; a guarantee or trial whose number the code contradicts (a 30-day refund checked at 14 days, a 14-day trial set to 7) is productauditor CLM-R5.

## Paper controls (look protective, protect nothing)
- An onboarding checklist that marks items done when viewed, not when completed.
- A "Skip tour" button that restarts the tour on the next page.
- Sample data seeded in development fixtures but never for new accounts in production.
