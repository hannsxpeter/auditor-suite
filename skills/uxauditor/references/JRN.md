# JRN: User Journeys and Flows

Weight 11. Always active.
Owns: the continuity of the core journeys from the Map: steps that link to nothing or loop, terminal states with no way forward, progress lost across channels and devices, where the user is in a multi-step flow, how a journey ends, and jobs-to-be-done fit (reassurance at anxious moments, inertia from the tool users leave).
Not here: counting steps and task waste (PROC-R5); walls before first value and the first run (CNV); empty collection states (CNT-R2); zero-result search (IA-R4); Back and refresh inside one browser tab (USE-R5).
Standards: journey mapping (phases, actions, emotion curve); jobs to be done (functional, emotional, social); Peak-End rule; Zeigarnik effect; goal-gradient effect.
Read first: the route table or screen list, every programmatic navigation and redirect on the core journeys, and the email, SMS, and push templates that hand users off.

## Cards

### JRN-R1 A core journey sends users to a step that does not exist, or loops (quick)
- Leads: `scan.sh JRN-R1` lists programmatic navigations and redirects; compare each target with the route table.
- Confirm: a navigation, redirect, or link on a core journey points to a path that no route defines, or two guards redirect to each other (sign-in to onboarding to sign-in), or a required step's next action returns to the same step.
- Not a finding if: the route exists elsewhere (file-based routing: check the pages or app folder; a catch-all that renders the right page; a server route); the link sits behind a flag that is off (cite the flag).
- Severity: Critical when every user on sign-up, sign-in, checkout, or the main task hits it; High on a secondary journey.
- Fix: point the navigation at the defined route or add the missing route; break a redirect loop by checking the target state before redirecting.
- Verify the fix: a route test follows each navigation on the journey and gets the intended page, not the not-found page.
- Refs: Nielsen heuristic 3; ISO 9241-110 suitability for the user's tasks

### JRN-R2 An error, expired, or failed state ends the journey with no way forward
- Leads: `scan.sh JRN-R2` lists not-found, error, expired-link, and failed-payment renders.
- Confirm: an error page, an expired or used link, a failed payment, or an invitation that no longer works renders a message with no action: no retry, no link back into the journey, no way to request a new link, no contact path.
- Not a finding if: the page keeps the navigation and names the next step; a retry or "send a new link" action is present (read the component).
- Severity: High when it strands users in sign-in, password reset, checkout, or invitation acceptance; Medium otherwise.
- Fix: give every terminal state a forward action: retry, request a new link, return to the last good step, or contact support with the context attached.
- Verify the fix: open each state (expired token, declined card, unknown route) and find a working forward action.
- Refs: Nielsen heuristic 9; ISO 9241-110 use error robustness

### JRN-R3 Progress is lost when the journey crosses a channel or device
- Leads: `scan.sh JRN-R3` lists magic-link, verification, invitation, and password-reset handlers, session-only storage, and return-path parameters.
- Confirm: the journey leaves the product (verify an email, open a magic link, accept an invite, continue on a phone) and the returning link lands on a generic page instead of the step the user left; or a cart, draft, or form lives only in `sessionStorage` or the browser, so it is gone on another device; or the link carries no destination (no `next` or `returnTo`).
- Not a finding if: the link carries the return path and the draft or cart is stored on the server for the account.
- Severity: High when it sits between sign-up and first value or inside checkout; Medium otherwise.
- Fix: carry the destination through every handoff (`?next=`), store drafts and carts against the account, and resume at the saved step.
- Verify the fix: start on one browser, finish through the email link on another, and land on the same step with the data intact.
- Refs: journey mapping (cross-channel handoffs)

### JRN-R4 A multi-step flow hides where the user is or how much remains
- Leads: `scan.sh JRN-R4` lists steppers, progress bars, and step counters.
- Confirm: a flow of three or more steps shows no step indicator or position ("Step 2 of 4"), or the indicator is wrong (a hardcoded position, a progress bar not tied to the step index).
- Not a finding if: every step's heading states its position; the flow has two steps.
- Severity: Medium; High when the flow has five or more steps on a core journey.
- Fix: show "Step N of M" bound to the real step index, name the steps, and allow going back to finished steps.
- Verify the fix: each step shows the right position and the total.
- Refs: Nielsen heuristic 1; Zeigarnik effect; goal-gradient effect

### JRN-R5 A core journey ends without a clear confirmation or next step
- Leads: `scan.sh JRN-R5` lists success, thank-you, and confirmation screens; read what each completion handler renders or redirects to.
- Confirm: after sign-up, a purchase, a booking, or a submission, the user lands on a generic page (home, a list) with no success message, no reference (order or booking number), and nothing about what happens next (an email coming, a review time, when they will be charged).
- Not a finding if: a confirmation view or message names what happened and what comes next.
- Severity: Medium; High for purchases, bookings, and applications, where users need proof.
- Fix: end each core journey on a confirmation that names the outcome, gives a reference, says what happens next, and offers the next useful action.
- Verify the fix: finish each core journey and see the confirmation with its reference.
- Refs: Peak-End rule; Nielsen heuristic 1

## Also check
- The Map's single worst friction moment appears as a finding in some dimension, or Scope and limitations says why not.
- Friction inventory: hesitation, backtracking, re-reading, error recovery, and forced context switches (leaving for email, SMS, or support to continue) along each core journey.
- Jobs to be done: the journey serves only the functional job; nothing reduces anxiety at the risky step (guarantees, undo, "no card required", a preview) or inertia (import or migration from the tool the user leaves).
- The README, marketing copy, or docs promise a journey that the code does not deliver (the gap is a finding; cite the code).
- Emotional low points in the Map (waiting, uncertainty, surprise costs) with nothing that eases them.

## Paper controls (look protective, protect nothing)
- A "Step 2 of 4" label or progress bar that is hardcoded and does not follow the real step.
- A "Continue where you left off" link that goes back to the start.
- A handoff email whose link drops the `next` parameter the sign-in page expects.
