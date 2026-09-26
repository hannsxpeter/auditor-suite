# CNT: Content and UX Writing

Weight 8. Always active.
Owns: plain language and reading level, microcopy and calls to action, the wording of error messages, empty states (what the area is for, why it is empty, the next action), the wording of confirmation dialogs, one term per concept across the product, tone and voice, and user-facing formats for dates, numbers, and currency.
Not here: where an error appears and whether the form keeps the input (FRM); whether a screen reader announces it (ACC-R2); navigation labels (IA-R1); a stack trace sent to the browser as a security leak (secauditor; file the wording here only); shaming decline copy (TRU-R4); the first-run tour and blank canvas (CNV-R2).
Standards: ISO 24495-1:2023 plain language; Nielsen heuristics 2, 4, 9, and 10; WCAG 2.4.4 (link purpose); Flesch-Kincaid grade level.
Read first: the message catalogs or strings files, the error-mapping layer (if any), the empty-state components, and the dialogs and buttons on the core journeys.

## Cards

### CNT-R1 Users see raw error codes, exception text, or system jargon instead of what to do
- Leads: `scan.sh CNT-R1` lists renders of `error.message`, error codes, and status values in UI code and templates.
- Confirm: the UI shows an error code, HTTP status, exception message, or internal name ("Error 4012", "RCPT_E413", "Request failed with status code 500", "undefined") with no plain explanation of what happened and what to do.
- Not a finding if: a mapping layer turns codes into messages before render (read it and check it covers this path); the code appears as a secondary support reference beside a human message.
- Severity: High when it is the only feedback on a core journey's failure (sign-in, checkout, the main task's save); Medium otherwise.
- Fix: map each error to a message that says what happened, why if it helps, and what to do next, in the users' words; keep the code as a small reference line for support.
- Verify the fix: force each known error; each shows a human message with a next step and no raw code as the headline.
- Refs: Nielsen heuristics 2 and 9

### CNT-R2 An empty state says only "No data" or shows a blank panel
- Leads: `scan.sh CNT-R2` lists empty-state strings and zero-length renders.
- Confirm: when a list, table, dashboard, or search area is empty, the UI shows a bare phrase ("No data", "Nothing here", "No items") or nothing, and does not say what the area is for, why it is empty, or what to do next.
- Not a finding if: the empty state names the area and offers a call to action, a template, or sample data (read the component).
- Severity: Medium; High when it is the first screen a new user sees after sign-up (say in Impact that it also stalls activation).
- Fix: write the empty state to answer where am I, why is this empty, what do I do next (a button that does it), and what it will look like when full.
- Verify the fix: open the view with no data; it shows the explanation and a working call to action.
- Refs: Nielsen heuristic 10

### CNT-R3 One concept has several names across the product
- Leads: `scan.sh CNT-R3` lists sign-in, log-in, sign-up, register, and sign-out wording in UI copy; compare the counts.
- Confirm: the same action or object carries two or more names in user-facing copy (buttons, headings, emails): "Sign in" on one screen and "Log in" on another, "Workspace" and "Team" for one entity, "Remove" and "Delete" for one action.
- Not a finding if: the words name different things (for example "Remove from list" versus "Delete permanently").
- Severity: Low; Medium when it sits on sign-in, sign-up, or billing, where users doubt they are in the right place.
- Fix: pick one term per concept, record it in the glossary or message catalog, and replace the others.
- Verify the fix: a search for the rejected term finds no user-facing copy.
- Refs: Nielsen heuristic 4; Jakob's Law

### CNT-R4 Buttons, links, and dialogs do not say what will happen
- Leads: `scan.sh CNT-R4` lists generic labels (Submit, OK, Yes, Click here, Learn more) and "Are you sure" dialogs.
- Confirm: a consequential button says "Submit", "OK", "Yes", or "Confirm" without naming the outcome; a dialog asks "Are you sure?" without naming the object and the consequence; or link text is "Click here" or "Learn more" with no context.
- Not a finding if: the outcome is named right beside it (a dialog titled "Delete project Q3 plan?" with a "Delete project" button).
- Severity: Medium; High when an ambiguous "Yes" or "OK" guards a destructive or payment action.
- Fix: label buttons with the verb and object ("Create account", "Send invoice", "Delete project"); make dialog titles name what will happen and to what.
- Verify the fix: every button on the core journeys names its outcome.
- Refs: Nielsen heuristic 2; WCAG 2.4.4

### CNT-R5 Copy is written above the audience's reading level or in internal language
- Leads: read the onboarding, pricing, consent, error, and help copy; there is no search pattern.
- Confirm: user-facing copy on the core journeys uses long sentences, passive voice, internal terms, or a reading level well above the audience (public-facing copy targets about US grade 8; run Flesch-Kincaid on the copy files if it matters).
- Not a finding if: the audience is expert and the terms are theirs (developer tools, clinical staff).
- Severity: Low; Medium on pricing, consent, legal, and error copy that users must understand to decide.
- Fix: short sentences, common words, active voice, second person; move detail behind a link.
- Verify the fix: the rewritten copy scores at or below the target grade.
- Refs: ISO 24495-1:2023; US Plain Writing Act of 2010

## Also check
- Tone and voice: documented and consistent; tone adapts to the moment (calm and serious for errors and destructive actions, lighter for success and empty states) while the voice stays the same.
- Dates, numbers, and currency shown in a system format (ISO timestamps, cents, epoch values) instead of the user's locale.
- Success messages that do not name what happened ("Done" instead of "Invoice INV-104 sent to Ana").
- Error messages that blame the user or use alarm words ("fatal", "illegal", "invalid user").

## Paper controls (look protective, protect nothing)
- An error-message map defined in a file that no component imports, so raw codes still render.
- A message catalog with friendly strings while components hardcode "Error" next to it.
- A voice and tone guide that the shipped copy ignores.
