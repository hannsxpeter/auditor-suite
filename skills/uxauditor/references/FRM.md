# FRM: Forms and Input

Weight 7. Always active.
Owns: what happens to input on error, persistent visible labels, where errors appear and when validation runs, field economy (fields never used, already known, asked twice, split, or derivable, including WCAG redundant entry), input types, mobile keyboards, autofill tokens, format tolerance and hints, and required versus optional marking.
Not here: whether a screen reader hears the error (ACC-R2); paste and autofill blocked on sign-in (ACC-R3); the error's wording (CNT-R1); feedback and double submit while the form sends (USE-R2); consent checkboxes (TRU-R1); the programmatic label line itself (uiauditor).
Standards: Baymard Institute form usability research; WCAG 2.2 1.3.5, 3.3.1, 3.3.2, 3.3.7; WHATWG HTML autofill tokens; Postel's Law.
Read first: the form and field components, the validation schema (zod, yup, Joi, pydantic, server-side validators), and the submit handler and error path of each core form.

## Cards

### FRM-R1 A validation error clears the form or discards what the user typed
- Leads: `scan.sh FRM-R1` lists form resets, state resets, page reloads, and re-renders of a form template on error.
- Confirm: on a failed validation or submit, the code resets the form (`reset()`, `setValues(initialValues)`, a state object replaced with empty values), reloads the page, or re-renders a server template without the submitted values, so fields the user filled come back empty.
- Not a finding if: only fields that must be re-entered are cleared (password, card security code); the values are passed back into the template or state (read the error branch); the reset runs only after a successful submit.
- Severity: High on sign-up, checkout, and any core form longer than about five fields; Medium otherwise.
- Fix: keep every value on error, clear only passwords and card security codes, show each error at its field, and move focus to the first invalid field.
- Verify the fix: submit with one invalid field; every other field keeps its value.
- Refs: Baymard form usability; Nielsen heuristics 5 and 9

### FRM-R2 Fields use the placeholder as the only label, or errors appear far from the field
- Leads: `scan.sh FRM-R2` lists inputs with placeholders; check each for a visible label and where its error renders.
- Confirm: an input has a `placeholder` and no visible label, so the hint disappears as soon as the user types and on error; or errors show only in a banner at the top and never next to the field they concern.
- Not a finding if: a floating label stays visible after input; the placeholder only shows an example beside a real label.
- Severity: Medium; High when every field of a core form does it (file it once, with the locations, as a systemic finding).
- Fix: a persistent visible label above each field and the error text directly below its field.
- Verify the fix: type in each field and trigger each error; the label and the error stay visible next to the field.
- Refs: Baymard; WCAG 3.3.2, 1.3.1

### FRM-R3 Validation runs at the wrong time
- Leads: `scan.sh FRM-R3` lists validation-mode settings and per-keystroke validators.
- Confirm: fields show errors while the user is still typing for the first time (validation on every change before the first blur), or a long form validates only on submit and never confirms valid fields.
- Not a finding if: change-time validation starts only after the first blur or submit (`reValidateMode`, touched checks).
- Severity: Low; Medium on core forms.
- Fix: validate on blur, re-validate on change after the first error, and confirm valid input where rules are strict (password strength).
- Verify the fix: typing into an empty field shows no error until blur; fixing an error clears it at once.
- Refs: Baymard inline validation research

### FRM-R4 The form asks for what the product never uses, already has, or asked for earlier
- Leads: read each core form's fields and search where each field is read after save; `scan.sh FRM-R4` lists confirm-email, repeat-password, split-name, and survey-style fields.
- Confirm: a required field is never read after save; the form asks again for data given earlier in the same process (WCAG 3.3.7 redundant entry); it duplicates a field (confirm email); it splits one value into several fields where one serves (four card-number boxes); or it asks for what can be derived (city and state from the postal code, card type from the number).
- Not a finding if: law or payment processing requires the field; the earlier value is prefilled or offered for selection.
- Severity: Medium; High when it adds several required fields to sign-up or checkout.
- Fix: delete unused fields, prefill or offer earlier answers, merge split fields, derive what can be derived, and mark the rest optional.
- Verify the fix: the field count of the form drops, and no value is typed twice in one process.
- Refs: Baymard; WCAG 3.3.7 (A, new in 2.2); TIMWOODS overproduction

### FRM-R5 Inputs miss the right type, keyboard, or autofill token
- Leads: `scan.sh FRM-R5` lists text inputs for email, phone, postal code, card, and code fields; read the shared field component too.
- Confirm: a field for an email, phone number, number, postal code, name, address, card, or one-time code is a plain `type="text"` with no `inputmode`, or has no `autocomplete` token (`email`, `tel`, `given-name`, `street-address`, `postal-code`, `cc-number`, `one-time-code`), so phones show the wrong keyboard and browsers cannot fill it.
- Not a finding if: a shared field component sets type and autocomplete from the field name (read it).
- Severity: Medium on sign-up, checkout, and address forms; Low elsewhere.
- Fix: set `type`, `inputmode`, and `autocomplete` on every identifiable field.
- Verify the fix: each core field carries the right type and token; a browser autofills the address form.
- Refs: WHATWG autofill tokens; WCAG 1.3.5; Baymard

### FRM-R6 The form rejects fixable input or hides the format it wants
- Leads: `scan.sh FRM-R6` lists strict patterns and validators on phone, card, date, and postal fields.
- Confirm: validation rejects spaces, dashes, or parentheses in phone and card numbers, surrounding spaces, or lower-case postal codes instead of normalizing them; a format rule has no visible hint until it fails (a date format, password rules); free text is used where a picker would prevent errors (dates, countries); or required and optional fields are not marked.
- Not a finding if: input is normalized before validation (read the transform).
- Severity: Medium; High when it blocks sign-up or checkout for common input.
- Fix: strip spaces and punctuation before validating, show format hints and rules up front, use pickers for dates and fixed lists, and mark optional fields.
- Verify the fix: a card number with spaces and a phone with dashes pass; the rules show before the first attempt.
- Refs: Postel's Law; Baymard; Nielsen heuristic 5

## Also check
- Error prevention: constrain input with pickers, dropdowns, and input masks where free text invites mistakes; a submit that stays disabled until the form is valid must say what is still missing (a silently disabled button is a dead end).
- Required versus optional marked explicitly (mark the smaller group).
- Multi-column layouts that break the reading path of a form (one column is faster to complete).
- Positive confirmation for fields with strict rules.
- Large inputs and submit controls on touch screens (target size itself is ACC).

## Paper controls (look protective, protect nothing)
- A required marker on fields the schema does not require, or the reverse.
- `autocomplete="off"` added to stop autofill on fields users need filled.
- Client-side rules that differ from the server's, so users pass the form and fail on submit.
- An inline error component that the form never passes the error to.
