# ACC: Accessibility and Inclusive Design

Weight 13. Always active.
Owns: whether people who use a keyboard, a screen reader, switch or voice control, magnification, or limited motor control can complete the core journeys; WCAG 2.2 outcomes as they play out in flows (POUR): keyboard completion, announced errors and status, accessible sign-in, pointer alternatives, predictable changes of context.
Not here: the static markup or style line itself (the missing accessible name, the `outline: none`, the `div` with a click handler, a contrast token pair) belongs to uiauditor, which scores the line; file here only the lived consequence on a journey, citing the same line and naming uiauditor in Impact. Visible form labels and redundant entry (FRM-R2, FRM-R4); a low-contrast "Reject all" (TRU-R5); reflow and horizontal scroll (PRF-R4).
Standards: WCAG 2.2 Level AA unless the project states another target (say which on the Calibration line); WAI-ARIA Authoring Practices; the 2.2 criteria and thresholds are in references/facts.md.
Read first: the core journeys from the Map, then the shared button, link, dialog, menu, and form-field components they pass through, and the router's focus handling.

## Cards

### ACC-R1 A core journey step cannot be completed with a keyboard alone (quick)
- Leads: `scan.sh ACC-R1` lists click handlers on non-interactive elements and tabindex values that remove or reorder focus.
- Confirm: a step every user must pass (sign up, sign in, checkout, the main task's save or submit) is reachable or completable only through an element that takes no keyboard focus or key input: a `div` or `span` with a click handler and no `tabindex` and Enter or Space handling, a custom select, menu, or date picker with mouse-only handlers, a dialog that traps focus with no Escape, or the only control set to `tabindex="-1"`.
- Not a finding if: the element is a native control, or has a role, `tabindex="0"`, and Enter and Space handling (read the component); another keyboard path completes the same step (the form submits on Enter); the element is decorative.
- Severity: Critical when the step is on a core journey and no keyboard alternative exists; High on a secondary flow.
- Fix: use the native element (`<button>`, `<a href>`, `<select>`) or implement the APG keyboard pattern; keep focus inside open dialogs and close them on Escape.
- Verify the fix: complete the journey with the keyboard only (Tab, Shift+Tab, Enter, Space, arrows, Escape) and list the steps in the test.
- Refs: WCAG 2.1.1, 2.1.2, 2.4.3, 4.1.2

### ACC-R2 Errors, status, or step changes on a core flow reach only sighted users (quick)
- Leads: `scan.sh ACC-R2` lists conditional error renders, live regions, and `aria-invalid` or `aria-describedby` use.
- Confirm: on a core flow, a failed submit, a validation error, or an async result is shown only visually (a red border, color, an icon, a toast outside any live region) with no text tied to the field, or the view moves to the next step or route without moving focus or announcing it, so a screen-reader user cannot tell it failed or advanced; or color alone marks the error or the selected option.
- Not a finding if: each error is text linked by `aria-describedby` with `aria-invalid`, or an error summary with `role="alert"` receives focus; the router or framework moves focus on navigation (read the config); the toast container is a live region.
- Severity: Critical when a screen-reader user cannot learn why a core flow failed and so cannot finish it; High when the core flow can be finished but a status goes unannounced; Medium elsewhere.
- Fix: render each error as text next to its field, link it with `aria-describedby`, set `aria-invalid`, move focus to an error summary on a failed submit, and announce async results in a `role="status"` region.
- Verify the fix: with VoiceOver or NVDA, submit the form empty, hear every error, fix them, and finish the flow.
- Refs: WCAG 1.4.1, 3.3.1, 3.3.3, 4.1.3, 2.4.3

### ACC-R3 Sign-in or verification needs memory, transcription, or a puzzle, or blocks paste and autofill (quick)
- Leads: `scan.sh ACC-R3` lists paste handlers, `autocomplete="off"` on credential fields, one-character code boxes, and CAPTCHA widgets.
- Confirm: a password or code field cancels paste (`onPaste` with `preventDefault`), turns off autofill on sign-in (`autocomplete="off"`), splits a one-time code into boxes that reject a pasted code, or sign-in requires a cognitive function test (transcribing a code, a puzzle, a remembered answer) with no alternative on the same step.
- Not a finding if: paste and password-manager autofill work (`autocomplete="current-password"`, `one-time-code`); an alternative method sits on the same step (passkey, magic link, a challenge that only asks to recognize objects or the user's own content, which WCAG allows at AA).
- Severity: Critical when a cognitive test is the only way to sign in; High when paste or autofill is blocked on sign-in or sign-up; Medium on other fields.
- Fix: allow paste everywhere, set the `autocomplete` tokens, accept a pasted code across split boxes, and offer a passkey or magic link beside any CAPTCHA.
- Verify the fix: paste a password and a one-time code; a password manager fills the sign-in form.
- Refs: WCAG 3.3.8 (AA, new in 2.2), 3.3.9 (AAA), 1.3.5

### ACC-R4 A task needs dragging or a swipe with no single-pointer alternative
- Leads: `scan.sh ACC-R4` lists drag-and-drop libraries and drag, drop, and swipe handlers.
- Confirm: reordering, moving, uploading, resizing, or dismissing is possible only by dragging or swiping, with no button, menu, or single tap that does the same.
- Not a finding if: the same result is reachable by clicks or keys (a "Move to" menu, up and down buttons, a Browse button beside the drop zone); the drag is essential to the task (freehand drawing).
- Severity: High when the task is on a core journey; Medium otherwise.
- Fix: add a single-pointer path next to the drag: a "Move to" menu, up and down buttons, or a file picker.
- Verify the fix: complete the task with single clicks only.
- Refs: WCAG 2.5.7 (AA, new in 2.2), 2.5.1

### ACC-R5 Choosing an option or typing changes the context without warning
- Leads: `scan.sh ACC-R5` lists change and input handlers that navigate, submit, or open windows.
- Confirm: a select, radio, or text input navigates, submits, reloads, opens a window, or moves focus as soon as its value changes, so keyboard users arrowing through options are sent away before they choose.
- Not a finding if: the change only filters content in place and announces the result; users were told beforehand ("Choosing a country reloads the page").
- Severity: High when it throws users out of a core flow; Medium otherwise.
- Fix: change context only on an explicit action (an Apply or Go button), or filter in place and announce the result.
- Verify the fix: arrow through the options with the keyboard; nothing navigates until the button is pressed.
- Refs: WCAG 3.2.1, 3.2.2

## Also check
- Contrast on core steps: body text under 4.5:1, large text (24 CSS px, or about 18.7 CSS px bold) under 3:1, and focus rings, borders, and state indicators under 3:1. Token values readable in code support a Likely finding; otherwise real contrast needs a contrast checker (Suspected).
- An image or icon that carries the only instruction or status on a core step with no text alternative; decorative images that are announced.
- No visible focus anywhere on a core journey (a global `outline: none` with no replacement), so keyboard users cannot see where they are (2.4.7; the stylesheet line itself is uiauditor's).
- Focus hidden under a sticky header, cookie bar, or chat widget on core steps (2.4.11), focus order that does not follow the visual order, and focus that is not moved to the new view after a route change.
- Touch targets for actions on core flows under 24 by 24 CSS px (2.5.8), and primary actions under about 44 to 48 px on touch screens.
- Motion not gated by `prefers-reduced-motion`; auto-playing carousels or tickers with no pause.
- Zoom blocked by the viewport meta (`user-scalable=no`, `maximum-scale=1`), which fails 1.4.4 on every flow.
- Help or contact placed differently across the pages of one flow (3.2.6 Consistent Help).
- A time limit that expires a core step with no warning or way to extend it (2.2.1).
- Headings, lists, tables, and native controls that the journey depends on for screen-reader navigation (the markup line is uiauditor's).
- State the conformance target, and in Scope and limitations name what static reading could not test (real contrast, runtime focus order, announcement quality).

## Paper controls (look protective, protect nothing)
- An `aria-label` that describes the wrong thing, or omits the visible text, so voice-control users cannot say the name they see (2.5.3).
- An `aria-live` region nothing ever writes to.
- A skip link whose target id does not exist.
- An accessibility overlay script or a conformance statement that the flows do not meet; an overlay is not a fix.
