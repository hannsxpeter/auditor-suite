# PROC: Process and Workflow Efficiency

Weight 11. Always active.
Owns: the work inside tasks and behind the product: step economy, Lean waste (TIMWOODS), value classification, handoffs and approvals, automation candidates, the bottleneck, rework loops, workflow model smells (state machines, wizard config, BPMN), and multi-actor workflow integrity: who may move which step, stalled steps, concurrent edits, status for the people waiting, and recovery of stuck items.
Not here: links and continuity between screens (JRN); fields on user-facing forms, including redundant entry (FRM-R4); authorization depth beyond the workflow rule (secauditor): file here who may advance which step, and name secauditor in Impact for broader access control.
Standards: Lean TIMWOODS waste; Theory of Constraints; task analysis and the Keystroke-Level Model; BPMN 2.0 (ISO/IEC 19510); separation of duties.
Read first: the status enums and transition code (state machines, XState, BPMN, wizard config), the approval, review, and queue handlers, the scheduled jobs, and the notification senders.

## Cards

### PROC-R1 A workflow step can be moved by the wrong actor, or the check exists only in the UI (quick)
- Leads: `scan.sh PROC-R1` lists approve, reject, publish, payout, reopen, and status-transition handlers.
- Confirm: a server handler changes a workflow item's status (approve, reject, publish, pay out, reopen, reassign) without checking that the caller holds the role for that step, or lets the requester approve their own item, or the only guard is a button hidden in the UI.
- Not a finding if: a server-side policy or state-machine guard checks the actor on every transition (read it); self-approval is refused (`approverId !== requesterId`).
- Severity: Critical when money, access, or published content moves on the wrong actor's say; High otherwise.
- Fix: guard each transition on the server with the roles allowed for that step and a separation-of-duties rule, with the actor taken from the session.
- Verify the fix: a test where the requester calls approve on their own item gets 403 and the status does not change.
- Refs: separation of duties (NIST SP 800-53 AC-5); OWASP A01:2025 for access control depth (secauditor)

### PROC-R2 A waiting step has no timeout, reminder, escalation, or reassignment
- Leads: `scan.sh PROC-R2` lists waiting statuses (pending, awaiting, in review) and the scheduled jobs, deadlines, and reminders that act on them.
- Confirm: an item enters a waiting status (pending approval, awaiting review, queued for a person) and nothing in code moves it on: no due date or SLA, no reminder, no escalation to a backup approver, no reassign or recall action, so it can wait forever on one absent person.
- Not a finding if: a scheduled job escalates or reminds (read the job and where it is registered); the requester or an admin can reassign or recall in the product.
- Severity: High when money, access, or a customer waits on it; Medium for internal-only work.
- Fix: give each waiting status a due date, a reminder before it, escalation to a backup at the deadline, and reassign and recall actions.
- Verify the fix: a test that ages an item past its deadline sees it escalated and the requester notified.
- Refs: TIMWOODS waiting and inventory; Theory of Constraints

### PROC-R3 The workflow model has dead, unreachable, or exit-less states
- Leads: `scan.sh PROC-R3` lists status enums, transition tables, and state-machine definitions.
- Confirm: a status is defined but no transition reaches it, or a non-terminal status has no way out; there is no terminal state (items can never be closed); a decision has only one handled branch (a rejected item can be neither revised nor closed); an error or cancelled status has no retry or close path.
- Not a finding if: the status is legacy, documented, and unreachable from new items (note it in Dimension notes instead).
- Severity: High when items get stuck in production; Medium when the dead state is unreachable code.
- Fix: write the state table; give every non-terminal state an exit, every decision both branches, and every error state a retry or close.
- Verify the fix: a table-driven test asserts every non-terminal state has at least one allowed next state and every state is reachable from the start.
- Refs: BPMN 2.0 (explicit start and end events, matching gateway joins); state-machine completeness

### PROC-R4 Two people can change the same item and one silently overwrites the other
- Leads: `scan.sh PROC-R4` lists updates and saves of shared items and any version, ETag, or `If-Match` checks.
- Confirm: an update on an item several people act on (a ticket, an approval, a shared record) writes the item or its status without comparing a version, `updated_at`, or ETag, so the last write wins and the earlier decision disappears.
- Not a finding if: optimistic locking (a version column, `If-Match`), a claim or lock ("assigned to you"), or a merge protects it.
- Severity: High when a decision (approve, pay, publish) can be overwritten; Medium otherwise.
- Fix: add a version to the item and reject stale writes with 409 and a message that shows the other person's change.
- Verify the fix: two updates sent with the same version: the second gets 409 and nothing is lost.
- Refs: optimistic concurrency control; RFC 9110 conditional requests

### PROC-R5 A primary task carries waste: extra steps, repeat confirmations, re-keyed data, or manual rule work
- Leads: count the steps, clicks, fields, and confirmations for each primary task in the Map; `scan.sh PROC-R5` lists confirmation prompts, exports, and copy steps.
- Confirm: name the step and its waste. Transport: staff re-key data from one system into another (swivel-chair). Inventory: drafts, queues, or backlogs that pile up with no owner. Motion: extra clicks, scrolling, or tab switching. Waiting: a serial wait or approval that could run in parallel or be removed. Overproduction: data collected in a back-office step that nothing reads. Overprocessing: a second confirmation or an "are you sure" that prevents no real, costly, irreversible harm. Defects: errors that force rework. Skills: a person doing deterministic rule work (routing, status changes, validation, copying) that the system could do.
- Not a finding if: the step prevents real, costly, or irreversible harm, or law or audit requires it (cite the reason).
- Severity: Medium; High when the waste sits on the task most users repeat daily or on the bottleneck.
- Fix: remove or merge the step, run approvals in parallel, prefill from data the system holds, or automate the rule; classify each step as value-added, necessary, or waste and remove the waste.
- Verify the fix: the step count for the task drops; state the before and after count.
- Refs: Lean TIMWOODS; value-added versus non-value-added analysis; Keystroke-Level Model

### PROC-R6 People waiting on a step cannot see where their item is
- Leads: read the requester's view of a waiting item and the notification senders; `scan.sh PROC-R6` lists status labels shown to requesters.
- Confirm: after submitting something that waits on another person or system, the requester sees no current step, holder, or expected time (only "Submitted" or "Pending" until done), and no notification fires when it moves.
- Not a finding if: a status view shows the current step, who holds it, and what happens next, and notifications fire on each transition.
- Severity: Medium; High when customers wait on it (refunds, applications, claims).
- Fix: show a status timeline with the step, the holder, and the expected time, and notify on every transition.
- Verify the fix: move an item through each status and see the requester's view and notifications update.
- Refs: Nielsen heuristic 1; TIMWOODS waiting

## Also check
- The bottleneck (Theory of Constraints): name the single slowest or most-abandoned step. Without analytics, pick it from structure (the longest serial chain, the most fields, the most external handoffs), mark it Suspected, and name funnel analytics or session data as what would confirm it. Improvements to already-fast steps do not count.
- Happy path and rework: define the ideal path, estimate how often real use follows it (Suspected without analytics), and flag rework loops and dead-end states.
- Handoffs and approvals: count transitions between people, systems, and teams; justify each gate; flag serial approvals that could run in parallel or be removed.
- Recovery: stuck or mis-routed items fixed by manual database edits or one-off scripts instead of a reassign, recall, or rollback action in the product.
- Automation candidates: deterministic human steps (status changes, routing, validation, re-keying between systems) flagged for automation or integration.
- Workflow smells: implicit start or end states, decision branches with no matching join, missing exception paths.

## Paper controls (look protective, protect nothing)
- An SLA or due-date field stored on every item but read by no job or view.
- A role check on the Approve button in the UI while the approve endpoint checks nothing (PROC-R1).
- An escalation rule in config that no job loads.
- A notification template for "request approved" that no code sends.
