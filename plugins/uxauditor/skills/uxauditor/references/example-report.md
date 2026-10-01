# UX audit: uxauditor

> Read-only UX audit of the code as written, 2026-09-26. The product was not run; findings about runtime behavior are marked Likely or Suspected. Mode: full. Scope: whole project.
> Self-contained: every finding cites the file and line it is about, so an agent holding only this report and the code can act on it. Written with uxauditor (auditor-suite 1.2.0).

## Snapshot

- Project: Stillwater Studio booking site (example fixture)
- Stack: Python, Flask, Jinja templates; no JavaScript framework, stylesheet, or images in the repository
- Size and coverage: 5 source files, about 130 lines, read exhaustively
- Maturity and exposure: public booking site of a small yoga studio; primary actor is a visitor on a phone (README.md:5) with a few spare minutes
- Active dimensions: USE, ACC, JRN, PROC, IXD, IA, CNT, CNV, FRM, PRF, TRU
- Not applicable: none
- Not assessed: none
- Excluded: none

## Map

Primary actor: a visitor on a phone. Top jobs: hold a place in a class this week; manage the monthly membership without calling the studio.

Journey 1, browse to booking (load-bearing, every visitor):
1. Browse (`app.py:17`, `templates/classes.html:11`). High: the week fits on one page. Low: "Hurry! Only N spots left" on every card (`templates/classes.html:17`).
2. Switch weeks; the select reloads on change (`templates/classes.html:6`).
3. Book with name and email (`templates/book.html:5`). Low: a typo empties the form (`app.py:41`).
4. Finish on the class list (`app.py:43`). Worst friction moment: no confirmation, though the form promises one (`templates/book.html:9`).

Journey 2, cancel or resume the membership (guards money): account page (`templates/account.html:10`), one POST (`app.py:52`), status and Resume (`templates/account.html:5`). No low point.

Handoffs: a promised confirmation email (`templates/book.html:9`) that no code sends.

## Overall score

<!-- BEGIN GENERATED: score (score.sh --write fills this block; do not edit it by hand) -->
**Overall: 79/100, Grade C (adequate, real gaps)**

| Dimension | Score | Grade | Weight | Critical | High | Medium | Low | Suspected |
|---|---:|---|---:|---:|---:|---:|---:|---:|
| USE Usability and Heuristics | 100 | A | 13.0% | 0 | 0 | 0 | 0 | 0 |
| ACC Accessibility and Inclusive Design | 97 | A | 13.0% | 0 | 0 | 1 | 0 | 0 |
| JRN User Journeys and Flows | 90 | A | 11.0% | 0 | 1 | 0 | 0 | 0 |
| PROC Process and Workflow Efficiency | 100 | A | 11.0% | 0 | 0 | 0 | 0 | 0 |
| IXD Interaction and Visual Design | 100 | A | 9.0% | 0 | 0 | 0 | 0 | 0 |
| IA Information Architecture and Navigation | 100 | A | 8.0% | 0 | 0 | 0 | 0 | 0 |
| CNT Content and UX Writing | 100 | A | 8.0% | 0 | 0 | 0 | 0 | 0 |
| CNV Onboarding, Conversion and Engagement | 100 | A | 8.0% | 0 | 0 | 0 | 0 | 0 |
| FRM Forms and Input | 90 | A | 7.0% | 0 | 1 | 0 | 0 | 0 |
| PRF Performance and Responsiveness | 98 | A | 6.0% | 0 | 0 | 0 | 0 | 1 |
| TRU Trust, Ethics and Transparency | 69 | D | 6.0% | 1 | 0 | 0 | 0 | 0 |
| **Overall** | **79** | **C** | 100% | 1 | 2 | 1 | 0 | 1 |

Caps applied: TRU held at 69 (one Critical finding); overall held at 79 (one Critical finding).
Findings: Critical 1, High 2, Medium 1, Low 0 (Suspected, not yet confirmed: 1).
Computed by score.sh from the findings below (rules: references/protocol.md, Scoring).
<!-- END GENERATED: score -->

Verdict: Booking takes two short steps and leaving the membership is honest, but the class list invents its scarcity with `random.randint`, which alone holds the score at 79. The booking handler fails visitors at both ends: a typo empties the form, and success lands on the list with no confirmation.

Calibration: a public consumer site that takes bookings and recurring payments, used mostly on phones; accessibility target WCAG 2.2 AA.

## What to fix first

<!-- BEGIN GENERATED: fix-first (score.sh --write) -->
1. [TRU-001] Class list shows an invented "Only N spots left" on every class - Critical, effort S. every visitor is told each class is nearly full by a random number, a fake scarcity and urgency pattern; a reload changes it, and a visitor who not...
2. [FRM-001] Booking form comes back empty after a validation error - High, effort S. a visitor who mistypes the email on a phone must retype the name as well, on the flow every visitor uses.
3. [JRN-001] A booking ends on the class list with no confirmation the form promises - High, effort M. the visitor lands where they started with no sign the place is held and no reference, so they may book twice or arrive unsure.
<!-- END GENERATED: fix-first -->

## Strengths (preserve these)

- Cancelling is one POST from the account page, states the consequence beside the button, and can be undone (`templates/account.html:12`, `templates/account.html:7`).
- Booking errors are specific, sit under their field, and are tied to it (`templates/book.html:7`, `app.py:37`).
- Navigation marks the current page with `aria-current`; a skip link leads to the content (`templates/base.html:12`, `templates/base.html:9`).

## Systemic patterns (root causes)

- SYS-1: `book()` has no result path for the visitor: it drops the posted values on error and says nothing on success. Members: FRM-001, JRN-001. Root fix: re-render with the posted values on failure and redirect to a confirmation page on success.

## Findings

### [TRU-001] Class list shows an invented "Only N spots left" on every class
- Severity: Critical | Confidence: Confirmed | Effort: S | Dimension: TRU
- Location: `app.py:21` (also `templates/classes.html:17`)
- Evidence: `spots_left = random.randint(1, 3)` runs for each class on every load and renders as `Hurry! Only {{ cls.spots_left }} spots left`; no code counts capacity or bookings.
- Impact: every visitor is told each class is nearly full by a random number, a fake scarcity and urgency pattern; a reload changes it, and a visitor who notices stops trusting the studio.
- Recommendation: delete the random count in `classes()`; if availability matters, show capacity minus the class's `BOOKINGS` entries only when it is low and real, without "Hurry!".
- Verify the fix: reload the list several times; the count changes only when a booking is added.
- References: deceptive.design fake scarcity and fake urgency; EU Unfair Commercial Practices Directive 2005/29/EC (misleading actions)
- Related: none

### [FRM-001] Booking form comes back empty after a validation error
- Severity: High | Confidence: Confirmed | Effort: S | Dimension: FRM
- Location: `app.py:41` (also `templates/book.html:7`, `templates/book.html:10`)
- Evidence: on a failed field `book()` runs `return render_template("book.html", cls=cls, errors=errors)` without the posted values, and neither input sets a `value`.
- Impact: a visitor who mistypes the email on a phone must retype the name as well, on the flow every visitor uses.
- Recommendation: pass `form=request.form` from `book()` and render it in the `value` attribute of both inputs in `templates/book.html`.
- Verify the fix: submit a valid name with an invalid email; the name stays filled.
- References: Baymard form usability research; Nielsen heuristic 9
- Related: SYS-1

### [JRN-001] A booking ends on the class list with no confirmation the form promises
- Severity: High | Confidence: Confirmed | Effort: M | Dimension: JRN
- Location: `app.py:43` (also `templates/book.html:9`, `README.md:8`)
- Evidence: after a valid booking `book()` runs `return redirect(url_for("classes"))`; no page, message, or email confirms it, while the label reads `Email for your booking confirmation`.
- Impact: the visitor lands where they started with no sign the place is held and no reference, so they may book twice or arrive unsure.
- Recommendation: redirect to a confirmation page that names the class, time, and name and says what happens next; send the promised email or change the label.
- Verify the fix: book a class; the next page names it and shows a reference.
- References: Peak-End rule; Nielsen heuristic 1
- Related: SYS-1

### [ACC-001] Week select reloads the class list as soon as its value changes
- Severity: Medium | Confidence: Likely | Effort: S | Dimension: ACC
- Location: `templates/classes.html:6`
- Evidence: the select has `onchange="this.form.submit()"` and its form has no submit button. Assumes a browser that fires change while arrowing a closed select, as Chrome and Edge on Windows do.
- Impact: a keyboard user arrowing toward "Next week" is sent to a reloaded page before choosing.
- Recommendation: remove the `onchange` handler and add a "Show classes" submit button to the form.
- Verify the fix: arrow through the options; nothing reloads until the button is pressed.
- References: WCAG 3.2.2
- Related: none

### [PRF-001] Class photos have no size, so the Book links may shift as images load
- Severity: Medium | Confidence: Suspected | Effort: S | Dimension: PRF
- Location: `templates/classes.html:14`
- Evidence: each card renders `<img src="{{ url_for('static', filename=cls.photo) }}" alt="">` with no `width`, `height`, or aspect-ratio, and no stylesheet here reserves the space.
- Impact: on a slow phone the "Book this class" link may move under the visitor's thumb; the styles and images that decide it are not in this repository.
- Recommendation: add `width` and `height` matching the photo ratio to the `img`, or an aspect-ratio on its container.
- Verify the fix: Lighthouse on the class list with real photos reports CLS of 0.1 or less.
- References: Core Web Vitals (CLS)
- Related: none

## Dimension notes

### USE: Usability and Heuristics
- Checked: USE-R1, USE-R2, USE-R3, USE-R4, USE-R5
- Note: Clean: cancel can be resumed (`templates/account.html:7`) and the booking button disables on submit (`templates/book.html:5`).

### ACC: Accessibility and Inclusive Design
- Checked: ACC-R1, ACC-R2, ACC-R3, ACC-R4, ACC-R5
- Note: ACC-001; otherwise native controls with labels and tied errors, and no sign-in or drag.

### JRN: User Journeys and Flows
- Checked: JRN-R1, JRN-R2, JRN-R3, JRN-R4, JRN-R5
- Note: JRN-001; every redirect targets a defined route.

### PROC: Process and Workflow Efficiency
- Checked: PROC-R1, PROC-R2, PROC-R3, PROC-R4, PROC-R5, PROC-R6
- Note: Clean: booking is one self-service step with no approval or queue.

### IXD: Interaction and Visual Design
- Checked: IXD-R1, IXD-R2, IXD-R3, IXD-R4, IXD-R5
- Note: Clean: one action per screen; no stylesheet exists to judge states.

### IA: Information Architecture and Navigation
- Checked: IA-R1, IA-R2, IA-R3, IA-R4, IA-R5
- Note: Clean: two navigation items in the visitor's words, current page marked.

### CNT: Content and UX Writing
- Checked: CNT-R1, CNT-R2, CNT-R3, CNT-R4, CNT-R5
- Note: Clean: buttons name their outcome and errors say what to enter.

### CNV: Onboarding, Conversion and Engagement
- Checked: CNV-R1, CNV-R2, CNV-R3, CNV-R4
- Note: Clean: no account, card, or verification before booking; no analytics to measure.

### FRM: Forms and Input
- Checked: FRM-R1, FRM-R2, FRM-R3, FRM-R4, FRM-R5, FRM-R6
- Note: FRM-001; both fields carry `type` and `autocomplete` tokens.

### PRF: Performance and Responsiveness
- Checked: PRF-R1, PRF-R2, PRF-R3, PRF-R4
- Note: PRF-001; server-rendered pages and a viewport meta (`templates/base.html:5`).

### TRU: Trust, Ethics and Transparency
- Checked: TRU-R1, TRU-R2, TRU-R3, TRU-R4, TRU-R5, TRU-R6
- Note: TRU-001; prices and renewal show up front (`templates/account.html:10`) and leaving takes one step.

## Remediation plan

<!-- BEGIN GENERATED: plan (score.sh --write) -->
- Quick wins (Critical or High, not Suspected, effort S): TRU-001, FRM-001
- Plan now (Critical or High, not Suspected, effort M or L), in this order: JRN-001
- Verify first (Suspected; confirm against the code before acting): PRF-001
- Schedule (Medium): ACC-001
- Backlog (Low): none
<!-- END GENERATED: plan -->

## Scope and limitations

All six files were read; the product was not run. With no stylesheet, images, or email service in the repository, contrast, states, and layout shift (PRF-001) need the deployed site and Lighthouse, and a confirmation email may exist elsewhere (JRN-001 would shrink to the on-screen gap). The phone-first actor comes from the README; a desktop-heavy audience would weigh ACC-001 and PRF-001 lower.

## How to use this report (for the acting agent)

1. Triage by severity and confidence. Confirmed Critical and High findings are safe to act on now, in the order under "What to fix first". Re-verify every Suspected finding against the cited code before changing anything.
2. Confirm the stated assumption on Likely findings before acting.
3. Fix root causes first: prefer a systemic pattern's root fix over its individual members.
4. Preserve the strengths; do not refactor them away while fixing something else.
5. Fix the core journeys first and keep deliberate safeguards: a confirmation before an irreversible action stays, a deceptive pattern is removed rather than softened, and a Likely or Suspected finding is confirmed in the running product, with analytics, or with users before anyone redesigns around it.
6. One finding, one change, verified: after each fix, run its "Verify the fix" step and keep the change traceable to the finding ID.
7. Do not widen scope silently; note adjacent issues instead of sprawling into a rewrite.
8. Re-run the audit to measure progress: confirm findings are resolved, not relocated, and that the strengths did not regress.
