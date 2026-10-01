# VOC: Customer Feedback and Demand Signals

Weight 7. Active when feedback, survey, bug-report, contact, support-widget, cancellation-reason, waitlist, or contact-sales code exists.
Owns: whether what customers tell the product reaches the team with enough context to act: feedback, bug-report, survey, rating, and contact submissions; support, sales, and feedback destinations; cancellation and downgrade reasons; and demand signals (waitlists, notify me, request access, coming-soon interest, feature and integration requests, contact sales, book a demo).
Not here: whether any contact path exists at all, and the credibility it gives (uxauditor TRU, Also check); success shown when a submission request failed, including a post to a route no server defines (uxauditor USE-R3); an error the server catches and drops (codeauditor ERR-R1); a survey that must be passed before cancelling, and nagging prompts (uxauditor TRU-R2, TRU-R4); form fields and validation (uxauditor FRM); form wording (uxauditor CNT); a support link on a core journey that points to a missing route (uxauditor JRN-R1); a feedback component no page mounts, or a trigger that can never be true (codeauditor QUAL-R4); thumbs on model outputs joined to traces (llmauditor OBSERV); personal data in tickets and third-party tools (secauditor LOGPRIV); a committed credential, including a Slack incoming-webhook URL (secauditor SECRET-R1; never quote it); operator error reporting (codeauditor OBS-R3).
Standards: ISO 10002:2018 (complaints handling); ISO 10004:2018 (monitoring and measuring customer satisfaction); Torres, Continuous Discovery Habits (2021); Reichheld, "The One Number You Need to Grow" (HBR, 2003); Savoia, The Right It (2019) (fake-door tests).
Read first: the feedback, contact, bug-report, survey, and rating components and their submit handlers; the server routes they call; support-widget, ticketing, CRM, and chat integrations; support and sales addresses in config; the cancellation flow; and the waitlist, request-access, and contact-sales handlers.

## Cards

### VOC-R1 A feedback, bug-report, survey, or contact submission succeeds and reaches no one
- Leads: `scan.sh VOC-R1` lists feedback, bug-report, contact, survey, and support components and widget SDKs. Follow each submit handler to its destination.
- Confirm: the submission succeeds (the client handler or the server route returns success), but the text is only logged, written to browser storage, or kept in a variable, so no ticket, row, message, or event carries it to the team.
- Not a finding if: it creates a ticket, writes a row (the team may read tables through a BI or admin tool outside the repository, so a stored row is never this finding), emails a real address from config, or posts to a configured support or analytics tool (cite the call); the request fails or posts to a route no server defines while the UI says success (uxauditor USE-R3); the server catches an error and drops it (codeauditor ERR-R1); it is a test or story; the destination is an empty, placeholder, or test address, id, or channel (VOC-R2).
- Severity: High when it is the only support or bug-report path of a product that takes payments, or the copy promises a reply; Medium otherwise.
- Fix: send each submission to a channel the team reads, with the user, account, plan, page, and app version attached, and fail visibly when sending fails.
- Verify the fix: a test submits the form and asserts one call to the destination carrying the text and the user and account ids.
- Refs: ISO 10002:2018

### VOC-R2 A support, sales, or feedback destination is a placeholder or test value
- Leads: `scan.sh VOC-R2` lists example and test addresses, test channel names, and empty or placeholder widget ids.
- Confirm: a production destination for customer messages (a support or sales address, a `mailto:` link, a chat-widget id, a channel name) is a placeholder (`support@example.com`, `hello@yourdomain.com`, an empty or `xxx` id), a test value, or a channel named for development, so messages go nowhere.
- Not a finding if: production config overrides the literal (read the loader and the production values; if unseen, record Likely); it is an input placeholder showing an example (`placeholder="you@example.com"`); it is a personal mailbox (whether someone reads it cannot be read from code); it is a webhook URL or token (secauditor SECRET-R1; never quote it).
- Severity: High when it receives support, billing, cancellation, or sales messages for a product that takes payments; Medium otherwise.
- Fix: route customer messages to a shared, monitored destination set per environment, and fail startup in production on a placeholder.
- Verify the fix: production config resolves every customer-message destination to a shared address, and a startup check rejects example.com.
- Refs: ISO 10002:2018

### VOC-R3 Cancellation or downgrade reasons are asked and thrown away
- Leads: `scan.sh VOC-R3` lists cancellation reasons, exit surveys, and churn-reason code. Follow each answer to where it is stored or sent.
- Confirm: the cancel or downgrade flow asks why the customer is leaving, and the answer is never stored, sent, or forwarded, or is stored without the account, the plan, and the date, so churn reasons cannot be counted or followed up.
- Not a finding if: the reason is stored with the account and plan, passed to the provider's cancellation details (Stripe `cancellation_details`), or sent as an event with the account id (read the call).
- Severity: Medium; High at growth stage with paid plans when this is the only churn signal in the repository.
- Fix: store each reason with the account, plan, tenure, and date, or pass it to the provider's cancellation details, and send it to where the team reviews churn.
- Verify the fix: a test cancels with a reason and finds one stored record with the account and plan.
- Refs: ISO 10004:2018; Continuous Discovery Habits

### VOC-R4 Demand signals are captured and dropped
- Leads: `scan.sh VOC-R4` lists waitlist, notify-me, coming-soon, request-access, early-access, feature-request, upvote, contact-sales, and book-a-demo handlers. Read each to its end.
- Confirm: the product invites users to register interest or contact sales (on the pricing page, in an upgrade prompt, on a coming-soon feature, on an enterprise plan), and the handler is empty, only shows a toast, writes to browser storage, keeps the request in a variable, or sends it to a placeholder (VOC-R2), so nobody learns who asked for what.
- Not a finding if: the request reaches a CRM, a sales inbox, a stored row, or an analytics event with the user and the item requested (read it; a stored row is never this finding, since the team may read it outside the repository); a fake door that records the click is a valid product test.
- Severity: High for contact-sales and enterprise inquiry forms on a sales-led plan, and for interest controls on the pricing page or in an upgrade prompt (purchase intent); Medium otherwise.
- Fix: send each request to the CRM or a monitored queue with the user, account, plan, and the item requested, and confirm receipt to the user only after it is stored.
- Verify the fix: a test submits each form or clicks each control and finds one stored or sent record with the requested item.
- Refs: Savoia, The Right It (fake-door tests); Continuous Discovery Habits

### VOC-R5 Survey, rating, or bug-report responses are stored without the context to act on them
- Leads: `scan.sh VOC-R5` lists NPS, CSAT, rating, and "was this helpful" components. Find what each submission carries.
- Confirm: responses or bug reports are stored or sent with only the score or free text, without the user or account id, the plan, the page or subject, and the app version, although the code has them at hand (the session, the route, a version constant).
- Not a finding if: a third-party survey or support tool is loaded and identified with the user (read the init); the form is for anonymous visitors by design and a doc says so; the component is never mounted or its trigger can never be true (codeauditor QUAL-R4).
- Severity: Medium for bug reports and NPS on paid plans; Low otherwise.
- Fix: attach the user and account ids, the plan, the route or subject, and the app version from the session, not from the form.
- Verify the fix: a test submits a response and finds the score stored with all five fields.
- Refs: Reichheld (NPS); ISO 10004:2018

## Also check
- Feedback stored in a table that no admin view, export, or job in the repository reads: ask in Scope and limitations whether the team reads it through a BI or admin tool; never file it.
- NPS or CSAT stored without the question and the scale, so scores cannot be compared over time.
- Bug reports that drop the screenshot or console log the form promises to attach.
- App store review prompts shown on launch instead of after a success moment.
- A status or incident page linked from the product when the terms promise uptime.

## Paper controls (look protective, protect nothing)
- A feedback widget whose submit only closes the modal or calls `console.log`.
- An NPS score stored with no account, plan, or date (VOC-R5).
- A "Request integration" button that shows a thank-you toast and sends nothing.
- A support widget initialized with an empty or sample app id (VOC-R2).
- A cancellation survey whose answer goes into a variable that is never read.
