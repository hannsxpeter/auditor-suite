# USE: Usability and Heuristics

Weight 13. Always active.
Owns: Nielsen's heuristics as the product behaves: feedback on every action (system status), the outcome shown truthfully, user control and freedom (undo, exits, no traps), error prevention (double submit, guards on costly actions), recognition over recall, accelerators for frequent work, and platform conventions such as the browser Back button.
Not here: the wording of errors, buttons, and empty states (CNT); where errors appear on a form and whether input survives (FRM); the look of states and the one primary action per screen (IXD); step indicators in multi-step flows (JRN-R4); confirmations that guard nothing costly (PROC-R5); keyboard and screen-reader completion (ACC); a submission that succeeds but reaches no one (productauditor VOC-R1); a sold feature that is a stub (productauditor CLM-R2); shared work deleted as a side effect of removing a member or deleting a member's user, even after a confirmation (productauditor CUST-R2); records deleted or locked as a side effect of a downgrade, a lapse, or a trial end, even after a confirmation (productauditor BILL-R8).
Standards: Nielsen's 10 usability heuristics; ISO 9241-110:2020 interaction principles (controllability, use error robustness); Laws of UX (Doherty threshold, Jakob's Law, Miller's Law).
Read first: the core journeys from the Map, the shared button, dialog, and toast components, and the handler behind every destructive or paid action.

## Cards

### USE-R1 Destructive action runs at once with no confirmation and no undo (quick)
- Leads: `scan.sh USE-R1` lists delete, remove, and deactivate handlers, buttons, and forms.
- Confirm: a control that deletes or irreversibly changes the user's data (the account, a workspace, a project, records in bulk) calls the endpoint on the first click, with no step that names what will be lost and no undo, trash, or grace period. Read the server handler: a hard delete means there is no way back.
- Not a finding if: a confirmation names the object and the consequence (a typed confirmation for accounts and workspaces); the server soft-deletes and the UI offers restore (`deleted_at`, a trash view, a grace period); the item is trivial to recreate (a saved filter, a UI preference).
- Severity: Critical when one click permanently deletes the account, a workspace, or data other people rely on; High when it deletes one record the user cannot recreate; Medium when the data is easy to recreate.
- Fix: soft delete with an undo toast for records; a confirmation that names the object and uses a specific verb ("Delete project Q3 plan") for larger scopes; a typed confirmation plus a grace period for the account.
- Verify the fix: one click leaves the data intact until the user confirms; undo or restore brings it back.
- Refs: Nielsen heuristics 3 (user control and freedom) and 5 (error prevention); ISO 9241-110 use error robustness

### USE-R2 Action gives no feedback while it runs, so users repeat it (quick)
- Leads: `scan.sh USE-R2` lists submit handlers and mutation calls; read whether each sets a pending state.
- Confirm: a submit or action starts a request while its control stays enabled, with no pending label, spinner, or disabled state until the response, so a second click sends a second request; or nothing tells the user it worked.
- Not a finding if: the control binds `disabled` or `aria-busy` to a pending flag (read the component); the form library blocks resubmission (`isSubmitting`, `formState`); the server rejects repeats with an idempotency key (then only the silence remains: Medium at most).
- Severity: Critical when a repeat click can charge money or place an order twice and the server has no idempotency key; High when it sends duplicate records, invites, or messages; Medium when the only harm is silence.
- Fix: set a pending flag on submit, disable the control and change its label ("Sending..."), show the outcome, and send an idempotency key for payments and orders.
- Verify the fix: a double click sends one request (count them in a test); the control changes state at once and the result shows within about 400 ms or a progress state appears.
- Refs: Nielsen heuristics 1 (visibility of system status) and 5; Doherty threshold (400 ms)

### USE-R3 The product reports success when the action failed, or swallows the failure (quick)
- Leads: `scan.sh USE-R3` lists `finally` blocks, empty catch blocks, and success toasts or redirects.
- Confirm: the success message or redirect runs whatever the response was (in `finally`, before the request resolves, or with no check of `res.ok` or the status), or an error is caught and dropped with no message, so users believe a payment, order, booking, or submission went through.
- Not a finding if: the success path runs only after a checked response and the error path shows a message (read both branches); the call cannot fail in a way users care about (a best-effort analytics ping).
- Severity: Critical when a failed payment, order, booking, or application is shown as done; High when a failed save is shown as saved; Medium for secondary actions.
- Fix: show success only after a checked response; on failure keep the user's input, say what failed, and offer retry.
- Verify the fix: a test that makes the request fail sees the error message and no success message or redirect.
- Refs: Nielsen heuristics 1 and 9; ISO 9241-110 self-descriptiveness

### USE-R4 A modal, wizard, or full-page flow traps the user with no way out
- Leads: `scan.sh USE-R4` lists modals, dialogs, drawers, wizards, and options that disable closing.
- Confirm: a modal has no close button, ignores Escape, and has no cancel; a wizard step has no Back; a full-page flow hides the navigation and offers no exit; or leaving throws away all progress with no warning.
- Not a finding if: the component closes on Escape by default (native `<dialog>`, a library default: read the prop, for example `disableEscapeKeyDown`, `closeOnEsc`); the blocking step is deliberate (a required legal acceptance) and a sign-out stays visible.
- Severity: High when it sits on a core journey; Medium otherwise.
- Fix: every modal gets a visible close and Escape; every wizard step gets Back and keeps its data; an exit says what happens to unsaved work.
- Verify the fix: from every modal and step, the user can leave in one action and return without losing entered data.
- Refs: Nielsen heuristic 3; ISO 9241-110 controllability

### USE-R5 Browser Back or a refresh loses a multi-step flow's progress
- Leads: `scan.sh USE-R5` lists step state (`setStep`, `currentStep`, `nextStep`) held in component state.
- Confirm: the current step and the entered data live only in component state (no route, query string, history entry, or saved draft), so browser Back leaves the flow and a refresh restarts it with inputs lost.
- Not a finding if: the step is in the URL or pushed to history; drafts persist (server draft, `localStorage`); a `beforeunload` warning guards a short flow.
- Severity: High on a core flow of three or more steps; Medium otherwise.
- Fix: put the step in the route or query string, push a history entry per step, and save a draft after each step.
- Verify the fix: on step three, press Back and land on step two with data intact; refresh and stay on step three.
- Refs: Nielsen heuristics 3 and 4 (consistency and standards); Jakob's Law

## Also check
- Match with the real world: icons and metaphors that mean something else to users, and system concepts (queues, jobs, records) exposed where users think in tasks. Formats for dates, numbers, and currency are CNT's.
- Recognition over recall: the flow asks users to remember something from an earlier screen (a code, an order number, a choice) instead of showing it; no format hints; no recently used items where users repeat choices (Miller's Law: working memory is small).
- Flexibility and efficiency: frequent tasks with no accelerator (bulk actions on lists processed one by one, saved defaults or templates, keyboard shortcuts in a tool used all day) that would speed experts without blocking novices.
- Help and documentation: no contextual, task-focused help at the point of a complex or risky decision; help that is not searchable; help that leaves the flow and loses the user's place.
- Platform conventions: links that are not links (no middle-click or open in new tab), custom scrolling that breaks the platform, Enter that does not submit a simple form.

## Paper controls (look protective, protect nothing)
- An undo toast shown after the server already hard-deleted the record, so Undo cannot restore it.
- A confirmation dialog that opens after the request has been sent.
- A spinner keyed on `!items.length`, so an empty result spins forever and looks like loading.
- A disabled attribute set on a wrapper `div`, so the real button stays clickable.
