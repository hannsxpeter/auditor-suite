# uxauditor

Audit the user experience of the product in the current working directory end to end: its interface, user journeys, processes, and workflows. Then do two things:

1. **Write a report** named `uxaudit.md` at the root of that project.
2. **Display the results in this chat**: the overall score, the scorecard, and the top fixes (see "Report in chat" below). Do not finish silently.

This is **read-only analysis**. Do not modify any source file, design file, or config. The only file you create is `uxaudit.md`. If an optional path, flow, or scope was provided as an argument, audit that subset; otherwise audit the whole product rooted at the working directory.

The report is written for a reader who has **no memory of the audit**, typically an AI agent that will open `uxaudit.md` later and decide, on its own, what to fix. Every finding must therefore stand alone: cite a concrete location (a `file:line`, a route or screen, a component, or a named step in a flow), carry its own context, and say how to verify the fix. If a finding cannot be acted on by someone who only has the report and the product, it is not finished.

What "experience" means here is broad. It includes web and mobile UI, but also command-line interfaces, APIs and SDKs (developer experience), desktop apps, and the design of the processes and workflows behind a product (onboarding sequences, approval queues, admin flows, checkout, support paths). Calibrate the lenses to the surface the product actually has.

---

## Operating principles (non-negotiable)

These govern the whole audit. A report that violates any of them is not done.

1. **Evidence over assertion.** No claim without a concrete, checkable reference (a `file:line`, a route, a component, or a named step). Apply the substitution test to every sentence: if you could swap in a different product and it would read equally true, it is filler. Cut it or make it specific. "Onboarding is confusing" fails. "`SignupForm.tsx:42` asks for company size and team role before the user has seen any product value, adding two fields to the first screen" passes.
2. **Audit the experienced product, not the description of it.** Read the rendered behavior: components, routes, flows, copy, state handling, and config, not just names, comments, or marketing claims. Where a running instance, screenshots, or design artifacts (Figma, journey maps, copy decks, analytics) are available, use them. When a doc or label claims one experience and the implementation delivers another, that gap is itself a finding.
3. **Inference from static code is a prediction, not a verdict.** Much of UX lives in rendered behavior you may not be able to observe from source alone (real contrast, focus order at runtime, perceived speed, where users actually hesitate). When you cannot confirm the lived behavior, mark the finding Suspected and say what would confirm it: running the product, a Lighthouse or contrast check, or a usability test with real users.
4. **Refuse theater. Hunt for experience that looks designed but is not.** The most misleading defects look polished but do not serve the user: a loading spinner that never resolves a real status, an empty state that says only "No data," a confirmation dialog guarding nothing costly, a "Reject all" hidden behind low contrast, an accessibility label that describes the wrong thing, a progress bar that does not reflect progress, a form that clears itself on error. Flag anything that performs UX without doing its job.
5. **Find the root, not the leaves.** If the same mistake appears in twelve places (placeholder-as-label on every field, no focus state on any custom control), that is one systemic finding, not twelve. Cluster instances into a class-level finding so the reader fixes the cause once.
6. **Verify adversarially.** For every candidate finding, try to refute it before keeping it. Is there an accessible alternative elsewhere? A keyboard path you missed? Is the friction a deliberate, justified safeguard? Assign a confidence level. When you cannot confirm, mark it Suspected so the acting agent re-checks before changing anything.
7. **Calibrate to the product.** Grade against the product's evident ambition, audience, and maturity, not an absolute ideal. A weekend prototype is not held to the accessibility and conversion bar of a public commercial product. State your calibration, including the assumed primary user and context of use (ISO 9241-11: specified users, goals, and context).
8. **Be honest about scope.** Say what you examined and what you did not, and whether you ran the product or only read it. If you sampled flows instead of walking all of them, say so. Never imply a usability test happened when it did not.
9. **Score with reasons, not vibes.** Every dimension score is justified against its findings. No number appears without the evidence that produced it.
10. **Name the strengths.** Record what the experience does well, with evidence, so the acting agent preserves those patterns instead of flattening them while fixing something else.
11. **Recommendations are specific and actionable.** Banned: "improve usability," "make it more intuitive," "enhance the onboarding." Required: what to change, where, and how to confirm it worked (a check to run, a behavior to observe, or a usability task to test).

---

## Method

Run these phases in order. Use search to find candidates, then **read the cited implementation or walk the flow to confirm** before recording anything. A search hit is a lead, not a finding.

### Phase 0 - Orient
- Detect the product type and surface: web app, mobile app, desktop app, CLI, API/SDK, or a backend process/workflow. Identify the frontend framework, design system or component library, routing, and state management from manifests and config (for example `package.json`, framework configs, a design-tokens or theme file, a component directory).
- Locate the experience surface: routes and pages, screens, primary components, navigation, forms, the CLI command tree, or the API surface. Find any design artifacts, copy, content files, or analytics that reveal intended behavior.
- Measure size (number of screens, routes, or flows) and decide exhaustive vs. sampled review. Declare which in the report.
- Read the README, product copy, and docs to learn the intended audience, the jobs the product claims to do, and its evident maturity (prototype, internal tool, production product, public service). You will check the experience against these claims and calibrate scoring to this maturity.
- Note whether you can run the product. If you can, walk the core flows. If you cannot, say so and mark experiential findings Suspected accordingly.
- Identify what to exclude: vendored UI libraries, generated code, design fixtures, marketing pages outside scope. Record exclusions.
- If version control is present, record the current commit or branch.
- If the target has no human-facing or developer-facing surface and no process or workflow to evaluate (for example a pure internal library with no CLI, UI, API, or user flow), say so plainly in chat and stop. Do not invent experience findings.

### Phase 1 - Map the experience
- Identify the primary actor or persona and their top jobs-to-be-done, inferred from the product's own copy, onboarding, and flows. State them. Use one actor per traced journey to keep the narrative honest.
- Trace two to four primary journeys end to end (for example sign up to first value; the main recurring task; a recovery or upgrade path; the checkout or conversion path). For each, record the phases, the actions at each phase, and the likely emotional highs and lows (the emotion curve). Localize the single worst friction moment.
- Build a mental model: the navigation and information structure, where state and context live, where the product hands off to other channels (email, SMS, support, another device), and which flows are load-bearing (used by everyone, or guarding money, data, or trust).
- Note where the real experience contradicts what the docs, copy, or screen names imply. Spend effort proportional to how many users a flow touches.

### Phase 2 - Analyze across every lens
For each candidate issue capture three things: the location (`file:line`, route, component, or named step), what the experience does now, and why that is a problem for the user. Do not score yet.

**Usability and Heuristics** (Nielsen's 10)
- Visibility of system status: every async action has a loading, pending, or disabled state; state changes are confirmed; multi-step flows show where the user is; the UI is never silent after an action (acknowledge within roughly 400ms, the Doherty threshold).
- Match with the real world: user language, not internal jargon or raw system codes; icons and metaphors match real-world expectations; dates, numbers, and currency match the user's locale.
- User control and freedom: undo for destructive actions; a clearly marked exit (cancel, close, back) from every state; no traps (modals you cannot leave, wizards with no back); confirmation before irreversible actions.
- Consistency and standards (Jakob's Law): the same action looks and is worded the same everywhere; platform conventions respected; one term per concept (not "Sign in" on one screen and "Log in" on another).
- Error prevention: constrain input with pickers, dropdowns, and masks rather than free text where possible; disable submit until valid; guard against double submit; confirm ambiguous or costly actions.
- Recognition over recall (reduce memory load; Miller's Law on working-memory limits): keep options and previously entered data visible rather than forcing the user to remember across screens; show format hints and recently used items.
- Flexibility and efficiency: accelerators for frequent tasks (keyboard shortcuts, bulk actions, saved defaults and templates) that speed experts without blocking novices.
- Aesthetic and minimalist design: one clear primary action per screen; progressive disclosure of advanced options; remove clutter that competes with the task.
- Help users recognize, diagnose, and recover from errors: plain-language messages that state what went wrong and how to fix it, shown at the field, never a raw code or stack trace.
- Help and documentation: contextual, searchable, task-focused help at the point of need; empty states that teach the next step.

**Accessibility and Inclusive Design** (WCAG 2.2, target Level AA unless the project states otherwise; POUR)
- Perceivable: text contrast at least 4.5:1 (3:1 for large text, 24px or 18.5px bold and up); non-text and UI contrast at least 3:1 for borders, icons, focus rings, and component states; every informative image has a text alternative and decorative images use empty alt; meaning is never conveyed by color alone.
- Operable: all functionality works by keyboard alone with no keyboard trap; a visible focus indicator on every focusable element (never `outline: none` without a replacement); focus and tab order follow the visual reading order; the focused element is not hidden by sticky headers or overlays (2.2); any drag operation has a single-pointer alternative (2.2); pointer targets are at least 24x24 CSS px with adequate spacing, and 44 to 48px for primary actions.
- Understandable: a persistent, visible label on every input (not placeholder-only); errors identified in text and tied to the offending field; help mechanisms in a consistent location across pages (2.2); predictable behavior with no surprise context changes.
- Robust: semantic markup (headings in order, lists, tables with headers, native controls) so assistive tech can interpret it; name, role, and value exposed for custom widgets; status messages announced.
- Inclusive details: respect reduced-motion preferences; support zoom to 200% and reflow with no horizontal scroll; do not block password-manager paste or one-time-code autofill (2.2 Accessible Authentication); do not re-ask for information already provided (2.2 Redundant Entry).
- State the conformance target and what was and was not testable from static code (real contrast and runtime focus order often need the running product).

**User Journeys and Flows**
- State the primary actor and their top job, then walk the core journey end to end. For each phase record the action, the user's likely mindset, and the emotional high or low, and name the deepest dip.
- Friction inventory: every point of hesitation, backtracking, dead end, re-reading, error recovery, or forced context switch (leaving the product for email, SMS, or support to continue).
- Cross-channel handoffs: does state and context survive a switch (start on mobile, finish on desktop; web to email to app)? Are the seams smooth, or is progress lost?
- Goal completion: count the steps, screens, or clicks to complete each core goal; flag any flow longer than the job requires.
- Jobs-to-be-done fit: does the experience serve the functional, emotional, and social job, or only the functional? Does it reduce anxiety (guarantees, undo, "no card required") and inertia (import or migration from the incumbent)?
- Peak-End and Zeigarnik: is the ending (success, confirmation) satisfying rather than anticlimactic, and does a multi-step flow show how much remains?
- Dead ends: every error, empty, expired, or zero-result state offers a forward action and a way to recover.

**Process and Workflow Efficiency** (Lean, Theory of Constraints, task analysis)
- Step economy: count the steps, clicks, and keystrokes for each primary task; flag redundant steps, duplicate confirmations, and re-entry of data the system already has.
- Lean waste (TIMWOODS) in the flow: Transport (data shuffled between screens or systems, swivel-chair re-entry), Inventory (pending queues, abandoned drafts), Motion (excess clicks, scrolling, tab switching), Waiting (load times, async approvals), Overproduction (collecting data never used), Overprocessing (redundant confirmations and validation), Defects (error states forcing rework), Skills (a human doing rule-based work a machine could do). Cite a concrete instance for each waste you claim.
- Value classification: tag steps as value-added, necessary-but-non-value-added, or pure waste; recommend eliminating the waste and minimizing the necessary.
- Handoffs and approvals: count transitions between people, systems, or teams, and the approval gates; justify or flag each; flag serial approvals that could run in parallel or be removed.
- Automation opportunities: deterministic, rule-based human steps (status changes, routing, validation, re-keying between systems) flagged as automation or integration candidates.
- Bottleneck (Theory of Constraints): identify the single slowest or most-abandoned step and verify that any improvement effort targets the constraint, not the already-fast steps. Without analytics or a running instance, pick the bottleneck candidate from structural evidence (the longest serial chain, the most fields, the most external handoffs), mark it Suspected, and name funnel analytics or session data as what would confirm it.
- Happy path and rework: define the ideal flow, estimate (from analytics where available, otherwise marked Suspected) how often real use likely follows it versus detours and rework loops, and flag dead-end states and "are you sure" interstitials that add a step without preventing real, costly, irreversible harm.
- Workflow modeling smells (where a process is modeled as a state machine, wizard config, or BPMN): implicit or missing start and end states, decision branches with no matching join, missing exception or error paths, and unreachable or dead-end states.
- Multi-actor workflow integrity (approval queues, handoffs, and async work shared across roles): are role and permission boundaries enforced on each transition, so only the right actor can advance, approve, reject, or reopen a step, and is that check on the server rather than only hidden in the UI?
- Stalled-step handling: do async and approval steps have a timeout, escalation, or SLA path so an item cannot sit forever waiting on one person, and is there a reminder or notification that keeps the work moving?
- Concurrency and locking: when two actors can act on the same item, is there optimistic locking or a conflict path, or can one silently overwrite the other?
- Status visibility for waiting parties: can the person waiting on a step see where their item is, who holds it, and what happens next, rather than facing a black box?
- Recovery and reassignment: can a stuck or mis-routed item be reassigned, recalled, or rolled back through the product itself, without manual database surgery?

**Information Architecture and Navigation**
- Labels in the user's vocabulary, not internal jargon or clever brand names; consistent and unambiguous across the product.
- Information scent (information foraging): do navigation and link labels signal what is behind them? Run several realistic "find X" tasks and record where the scent breaks. Judge by scent strength, not click count (the three-click rule is a myth; users continue while the scent is strong).
- Navigation model fit: global, local, and utility navigation; breadcrumbs on deep pages; a clear current-location indicator; a structure that matches the user's mental model rather than the org chart.
- Findability and discoverability: can users locate known items, and do they realize features exist at all? Search present where the content volume warrants it, tolerant of typos and synonyms, with a useful zero-results state.
- Category integrity: categories mutually exclusive where possible; flag content that plausibly belongs in two places or in none.

**Interaction and Visual Design**
- Visual hierarchy: a single dominant primary action per screen; scannable headings; a consistent type scale and spacing system; size, weight, contrast, and position guide the eye to what matters.
- Gestalt grouping: proximity and common region match the real relationships (a label sits closer to its field than to neighbors; related controls share a container; unrelated items are not boxed together).
- Affordances and signifiers (Norman): interactive elements look interactive (cursor, styling, hover); non-interactive elements do not masquerade as buttons; controls map intuitively to their effect.
- Component states: distinct, visible hover, focus, active, disabled, loading, empty, and error states for every interactive element; feedback within the response budget; microinteractions that acknowledge actions without getting in the way.
- Consistency: shared components, icons, and patterns behave identically throughout; platform conventions respected.
- Motion: purposeful and fast, reduced-motion respected, no jank.

**Content and UX Writing**
- Plain language: short sentences, common words, active voice, second person; flag jargon and a reading level well above the audience (public-facing copy targets roughly an eighth-grade level; measure with Flesch-Kincaid where it matters).
- Microcopy and calls to action: buttons name the action or outcome ("Create account", "Send invoice"), not "Submit", "OK", or "Click here"; link text is descriptive; one label per action across the product.
- Error messages: human, specific, and recovery-oriented (what happened, why, how to fix it, what to do next), shown at the field, never a raw code, and they preserve the user's input.
- Empty states: explain what the area is for, why it is empty, and the next action (a clear call to action or a template), not a blank panel or a bare "No data".
- Tone and voice: documented and consistent; tone adapts to context (calmer and serious for errors and destructive actions, lighter for success and empty states) while the underlying voice stays constant.

**Forms and Input** (Baymard research)
- Labels: persistent and visible above the field; never placeholder-as-label, which vanishes on input and on validation error.
- Validation: inline on blur rather than red errors on every keystroke, with positive confirmation too; errors specific and adjacent to the field; never clear the whole form on error.
- Field economy: remove non-essential fields; do not split data that belongs in one field (a single full-name or card-number field); do not ask for what the system already holds or can derive (smart defaults, deriving city and state from a postal code).
- Mobile input: the correct `type` and `inputmode` to trigger the right keyboard (email, tel, numeric, url); large tap targets for inputs and the submit control.
- Autofill: standard `autocomplete` tokens present (name, email, tel, street-address, postal-code, cc-number, one-time-code) so browsers and password managers can fill them.
- Format tolerance (Postel's Law): accept varied formats and normalize them (spaces in card numbers, phone punctuation) rather than rejecting trivially fixable input; mark optional versus required fields explicitly.

**Onboarding, Conversion and Engagement** (AARRR, activation)
- Activation and time to value: identify the activation event (the first hands-on experience of core value) and estimate the time and number of steps from sign up to it; shorter is better.
- Value-blocking walls: flag hard gates before the user sees any value (forced account creation, email verification, a credit card, a mandatory sales call) where they are not essential.
- First-run experience: onboarding drives the user to do the core action rather than touring features; templates and sample data instead of a blank canvas; progressive disclosure of advanced features; no data requested before it is needed.
- Empty states (first run): answer where am I, why is this empty, what do I do next, and what it will look like when full, with a call to action.
- Funnel leaks (AARRR): walk acquisition to activation to retention to revenue; identify the step with the largest likely drop-off; flag long forms, a missing progress indicator, and dead ends along the way.
- Engagement and retention: is there a reason to come back (saved state, a habit loop of trigger, action, reward, and investment, fresh content, teammates)? Are re-engagement triggers value-driven rather than spammy?

**Performance and Responsiveness**
- Core Web Vitals (good thresholds at the 75th percentile): Largest Contentful Paint at most 2.5s, Interaction to Next Paint at most 200ms, Cumulative Layout Shift at most 0.1. Do not emit specific metric values from static code; instead name the concrete code-level risk factors (render-blocking resources, unsized media that will shift layout, large main-thread tasks, missing width and height or aspect-ratio) and defer the numeric verdict to a Lighthouse or CrUX run flagged under Verify first.
- Layout stability: explicit width and height or aspect-ratio on media, and reserved space for late-loading content (ads, embeds), to prevent shifts.
- Responsiveness budget (RAIL and Doherty): acknowledge input within about 100ms and complete or show progress within about 400ms; avoid long main-thread tasks that block interaction; use skeleton screens and optimistic UI for unavoidable waits.
- Responsive and mobile layout: a `viewport` meta tag present and zoom not disabled (no `user-scalable=no`); no horizontal scroll at common widths (320 to 414px and up); content reflows rather than overflowing; tap rather than hover for critical actions; comfortable touch targets.
- Perceived performance: a loading state for every async action so the UI is never frozen or silent under load.

**Trust, Ethics and Transparency** (deceptive design, web credibility)
- Deceptive design (the deceptive.design taxonomy): flag nagging, obstruction (hard to cancel, roach motel), sneaking (hidden costs revealed late, items auto-added to a cart), forced action (forced account creation or data sharing), interface interference (a greyed-out or low-contrast decline), confirmshaming, fake scarcity or urgency, fake social proof, preselection (pre-ticked opt-ins), misdirection, trick wording, disguised ads, and comparison prevention.
- Symmetry and consent: cancellation or unsubscribe at least as easy as sign up; "Reject all" as prominent and as few clicks as "Accept all"; consent opt-in, granular, and revocable with no pre-ticked boxes (GDPR and EDPB guidance, the FTC click-to-cancel rule, EU DSA Article 25).
- Pricing transparency: total cost and fees shown early rather than only at the final step; no surprise recurring billing; no pre-checked upsells.
- Credibility (Stanford web credibility guidelines): a real organization and contact path, named and credentialed people, sourced claims, fresh content, restraint with promotional content, and zero small errors (typos, broken links, and console errors erode trust out of proportion to their size).
- Honest social proof: testimonials attributed and plausible, reviews two-sided, and any "X people viewing" or "only N left" claim real rather than manufactured.
- Privacy: data collection minimized and explained at the point of collection, with defaults that favor the user.

### Phase 3 - Verify adversarially and cluster
- For each candidate, try to refute it. Is there an accessible or keyboard alternative elsewhere? A justified reason for the friction (a deliberate safeguard on a destructive action)? Adjust or drop.
- Assign Severity, Confidence, and Effort (definitions below).
- Default to caution: if you could not confirm the lived behavior (you read the code but did not run the product or test with users), mark it Suspected.
- Cluster repeated instances of one underlying problem into a single systemic pattern, keeping the instance IDs as members.

### Phase 4 - Score
Score each dimension 0-100. The overall score is the weighted average. These weights are defaults; re-weight only when the product type warrants it (for example a content site leans on IA and content; an internal tool leans on process and workflow efficiency), and state the change and reason.

| Dimension | Weight |
|---|---|
| Usability and Heuristics | 13% |
| Accessibility and Inclusive Design | 13% |
| User Journeys and Flows | 11% |
| Process and Workflow Efficiency | 11% |
| Interaction and Visual Design | 9% |
| Information Architecture and Navigation | 8% |
| Content and UX Writing | 8% |
| Onboarding, Conversion and Engagement | 8% |
| Forms and Input | 7% |
| Performance and Responsiveness | 6% |
| Trust, Ethics and Transparency | 6% |

Score bands (per dimension and overall): 90-100 = A (exemplary), 80-89 = B (solid, minor issues), 70-79 = C (adequate, real gaps), 60-69 = D (weak, systemic problems), 0-59 = F (failing, critical deficiencies).

Risk does not average away: a single Critical finding caps its dimension at 69 and caps the overall at 79 until resolved. A blocking accessibility failure or a confirmed deceptive pattern is a Critical, not a cosmetic note. Justify every dimension score against its specific findings. No number without a reason.

### Phase 5 - Prioritize
Definitions:
- **Severity** - Critical (a usability catastrophe, a blocking accessibility failure, or a deceptive or trust-breaking pattern that locks users out of a core task, deceives them, or exposes the product to legal risk; maps to Nielsen severity 4; act immediately) / High (a major problem that frequently blocks or seriously frustrates users on a core flow; Nielsen 3; act this cycle) / Medium (a real problem degrading the experience in common cases or on secondary flows; Nielsen 2; schedule it) / Low (minor or cosmetic; Nielsen 1; batch it).
- **Confidence** - Confirmed (verified by reading the rendered behavior, walking the flow, or running a check; reasoning reproducible from the cited evidence) / Likely (strong evidence resting on a stated assumption about runtime behavior or context) / Suspected (inferred from static code without confirming the experienced behavior; verify by running the product, running a tool, or testing with users before acting).
- **Effort** - S (localized, under about 1 hour) / M (a few files or one flow, about half a day) / L (cross-cutting, a redesign, or needs research, multiple days).

Bucket every finding: **Quick wins** (High/Critical, Confirmed, S), **Plan now** (High/Critical, M or L), **Verify first** (any Suspected, especially anything needing the running product or a usability test), **Backlog** (Low). Order the "What to fix first" list as the union of Quick wins and Plan now, Critical before High, breaking ties toward findings that also close a systemic pattern or sit on a load-bearing flow.

### Phase 6 - Write uxaudit.md
Write to `<project-root>/uxaudit.md` with these sections in order. Keep finding IDs stable using a dimension prefix and number: USE, ACC, JRN, PROC, IA, IXD, CNT, FRM, CNV, PRF, TRU (for example `ACC-001`).

1. **Title and banner** - product name; a line stating this is a read-only UX audit, the date, and that the report is self-contained.
2. **Snapshot** - product, state (commit or branch), surface and product type, frameworks and design system, primary actor and top jobs-to-be-done, evident maturity and assumed context of use, audit coverage (exhaustive or sampled, and whether the product was run or only read), exclusions.
3. **Overall score** - `NN/100 - Grade X (label)`, a two-to-four sentence specific experience verdict, and a one-line calibration note. Then a scorecard table: Dimension, Score, Grade, Weight, one-line specific verdict; final row is the weighted overall. A re-weighting note (default, or the change and why).
4. **What to fix first** - the ordered priority list. Each line: `[ID] title - severity, effort - one-line why`.
5. **Strengths (preserve these)** - what the experience does well, each with evidence. The acting agent must not flatten these away.
6. **Systemic patterns (root causes)** - one entry per recurring root cause: what it is, the member finding IDs, and the one root fix.
7. **Findings** - sorted by severity then dimension. Each finding is a self-contained block in this exact shape:

   ```
   ### [ACC-001] <title>
   - Severity: <Critical/High/Medium/Low> | Confidence: <Confirmed/Likely/Suspected> | Effort: <S/M/L> | Dimension: <name>
   - Location: `file:line`, route, component, or named step (and other locations)
   - Evidence: <what the experience does now, precisely>
   - Impact: <the concrete consequence for the user; why it matters>
   - Recommendation: <specific change and where; not a platitude>
   - Verify the fix: <a check to run, a behavior to observe, or a usability task to test>
   - Related: <systemic pattern or finding IDs, or "none">
   ```

8. **Dimension notes** - one short subsection per dimension tying the score to its findings.
9. **Remediation plan** - the four buckets (Quick wins, Plan now, Verify first, Backlog) listed by ID, with Plan now in suggested order.
10. **Scope and limitations** - what was and was not examined, whether the product was run, sampling decisions, and assumptions (the assumed persona and context) that would change conclusions if untrue.
11. **How to use this report (for the acting agent)** - include this protocol verbatim:
    1. Triage by severity and confidence. Confirmed Critical and High are safe to act on now, in the order in "What to fix first". Re-verify any Suspected finding (run the product, run the check, or test with users) before changing anything.
    2. Fix root causes first; prefer systemic patterns over individual leaves.
    3. Preserve the strengths; do not flatten them while fixing other issues.
    4. Confirm the stated assumption on Likely findings before acting.
    5. One finding, one change, verified: after each fix run its "Verify the fix" step; keep changes atomic and traceable to the finding ID.
    6. Do not widen scope silently; note adjacent issues rather than sprawling into a redesign.
    7. Re-run the audit to measure progress; confirm findings are resolved, not relocated, and watch for regressions in the strengths.

### Phase 7 - Report in chat
After the file is written, print a concise summary to the chat so the user sees the result without opening the file. Include, in this order:
- One headline line: `UX audit complete: NN/100 (Grade X)` followed by the one-line experience verdict.
- The scorecard table (all eleven dimensions plus the weighted overall).
- "What to fix first": the top three to five items, each `[ID] title - severity, effort`.
- Counts: number of findings by severity (for example `Critical 1, High 4, Medium 9, Low 7`).
- The path to the full report: `Full report: ./uxaudit.md`.
Keep it tight. The file holds the detail; the chat holds the verdict and the next actions.

---

## Quality gates (self-check before declaring done)

- Every finding cites at least one concrete location (`file:line`, route, component, or named step). Run the substitution test on each title and impact line; rewrite anything that would read true for a different product.
- Every dimension score has a justification tied to specific findings.
- Every finding has Severity, Confidence, and Effort set.
- Every recommendation says what to change and how to verify it. No platitudes.
- Repeated issues are clustered into systemic patterns; there are not many near-identical findings left loose.
- Findings that depend on rendered behavior you could not observe are marked Suspected, with what would confirm them.
- The assumed primary actor, top job, and context of use are stated, and scoring is calibrated to the product's maturity.
- Strengths section is present and evidence-backed.
- Scope and limitations are stated honestly, including whether the product was run or only read.
- The "How to use this report" protocol is present.
- The report is at the project root, named exactly `uxaudit.md`, no source or design files were changed, and the chat summary was printed.

## Notes
- Read-only. Use search and read tools to investigate, and shell commands only for inspection (manifests, route lists, line counts, version control state). Do not edit source, change copy, or run migrations as part of the audit. If a running instance is available to walk, observe it without changing its state.
- Scale effort to reach: spend the most time on the flows the most users depend on and the steps that guard money, data, or trust.
- For a large product, sample deliberately (the core journeys, the conversion path, the highest-traffic screens, the most error-prone forms) and declare exactly what you sampled.
- Much of UX is only visible at runtime. Prefer running the product where you can; where you cannot, be explicit that findings are inferred from code and mark them Suspected.
