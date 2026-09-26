# TRU: Trust, Ethics and Transparency

Weight 6. Always active.
Owns: deceptive design in the deceptive.design taxonomy (preselection, obstruction and hard to cancel, sneaking and hidden costs, hidden subscription, forced action, interface interference, trick wording, confirmshaming, fake urgency, fake scarcity, fake social proof, nagging, disguised ads, comparison prevention), symmetry of joining and leaving, consent, pricing transparency, credibility, honest social proof, and privacy at the point of collection.
Not here: protection of personal data in storage and transit (secauditor); the accessibility of the consent banner (ACC); walls before first value that deceive no one (CNV-R1); the clarity of ordinary copy (CNT).
Standards: the deceptive.design taxonomy; EU DSA Article 25; GDPR Articles 4(11) and 7 with the EDPB consent guidelines; EU Consumer Rights Directive Article 22; ROSCA and state automatic-renewal laws; Stanford web credibility guidelines. Dates and current status are in references/facts.md; cite them from there.
Read first: the sign-up, checkout, pricing, and cancellation routes, the consent or cookie banner, account settings and notification preferences, and any countdown, stock, review, or testimonial component.

A deceptive pattern confirmed in code is Critical: it deceives users and exposes the product to legal risk. When the proof depends on data you cannot see (whether a stock count or a review is real), record it as Suspected and say what would confirm it.

## Cards

### TRU-R1 Consent or a paid extra is preselected (quick)
- Leads: `scan.sh TRU-R1` lists checkboxes checked by default and consent or add-on state that starts true.
- Confirm: a checkbox, toggle, or initial value for marketing email, data sharing, tracking, or a paid add-on (insurance, donation, priority support) starts on (`defaultChecked`, `checked` bound to a true default, `useState(true)`, `marketing: true`), so doing nothing opts the user in or adds a charge.
- Not a finding if: the value reflects a choice the user already saved (read where it loads); the setting is a service notice the user needs (approval alerts, receipts, security email), not marketing, sharing, tracking, or a paid extra.
- Severity: Critical when confirmed for marketing consent, data sharing, tracking, or a paid extra; High for other defaults that favor the business over the user.
- Fix: start every consent and every paid extra unchecked, make each purpose a separate choice the user can withdraw as easily as they gave it, and store the consent with its wording and time.
- Verify the fix: submitting the form untouched records no consent and adds no charge.
- Refs: GDPR Articles 4(11) and 7, Recital 32; CJEU Planet49 (C-673/17); EDPB Guidelines 05/2020; Consumer Rights Directive Article 22; deceptive.design preselection

### TRU-R2 Leaving is harder than joining (quick)
- Leads: `scan.sh TRU-R2` lists cancel, unsubscribe, downgrade, and delete-account routes and handlers; count the steps from the account page to done and compare them with sign-up.
- Confirm: cancelling a subscription, unsubscribing, or deleting the account takes more steps, screens, or channels than joining did: a survey or offers that must be passed, several "are you sure" screens, a required phone call or chat, a link hidden in fine print, sign-in required to unsubscribe, or no online path when sign-up was online.
- Not a finding if: cancellation sits in account settings and takes one or two steps, with at most one retention offer that is declined in one click.
- Severity: Critical when confirmed on a paid subscription (obstruction, the roach motel); High for free accounts and email unsubscribe.
- Fix: put cancellation in account settings, in the channel used to sign up, with at most one confirmation and one optional offer; add one-click unsubscribe to marketing email.
- Verify the fix: count the steps: cancelling takes no more steps than signing up; a test cancels a subscription from settings.
- Refs: deceptive.design hard to cancel (obstruction); ROSCA; California Automatic Renewal Law as amended; Germany BGB 312k; DSA Article 25; RFC 8058

### TRU-R3 Costs appear late or recur without clear terms (quick)
- Leads: `scan.sh TRU-R3` lists fees, surcharges, renewal and trial wording, and where totals are computed.
- Confirm: fees, shipping, or service charges are added only at the last step (the total changes between the first price shown and the pay button); a trial turns into a paid plan without the price, the date, and how to cancel shown beside the button that starts it; or an item or add-on is put in the cart without the user choosing it (sneaking).
- Not a finding if: the all-in price shows from the first price the user sees; tax that depends on the address is labeled as extra from the start; the renewal terms sit next to the start button.
- Severity: Critical when confirmed (drip pricing, a hidden subscription, sneaking into the basket); High when the disclosure exists but sits below the button or in fine print.
- Fix: show the all-in price early; put renewal price, date, and how to cancel next to the button that starts the trial; send a reminder before the first charge.
- Verify the fix: for a default order, the first price shown equals the amount charged.
- Refs: deceptive.design hidden costs, hidden subscription, sneaking; ROSCA; FTC Rule on Unfair or Deceptive Fees; Consumer Rights Directive Article 22

### TRU-R4 Pressure patterns: fake urgency, fake scarcity, fake social proof, confirmshaming, or nagging (quick)
- Leads: `scan.sh TRU-R4` lists countdowns, stock and viewer counts, random numbers in UI code, hardcoded testimonials, and shaming decline copy.
- Confirm: a countdown starts at page load or resets on reload instead of following a real deadline; a stock, viewer, or purchase count comes from `Math.random`, a constant, or a timer; testimonials or ratings are hardcoded with no source; the decline option shames the user ("No thanks, I like paying full price"); or a prompt returns after dismissal with no way to stop it.
- Not a finding if: the number or deadline comes from real data (read its source); testimonials are attributed and loaded from a real source (if you cannot see the source, record Suspected).
- Severity: Critical when confirmed in code (the number or deadline is invented, the decline copy shames, the prompt cannot be stopped); Suspected when the data source is out of sight.
- Fix: tie timers and counts to real data or remove them, attribute testimonials, use neutral decline copy ("No thanks"), and respect a dismissal.
- Verify the fix: reloading the page does not reset the timer or change the counts; a dismissed prompt stays dismissed.
- Refs: deceptive.design fake urgency, fake scarcity, fake social proof, confirmshaming, nagging; EU Unfair Commercial Practices Directive Annex I; FTC Rule on Consumer Reviews and Testimonials; DSA Article 25

### TRU-R5 The privacy-friendly or decline choice is visually suppressed or worded to trick (quick)
- Leads: `scan.sh TRU-R5` lists consent banners and accept, reject, and manage buttons; compare their styles and layers.
- Confirm: "Accept all" is a filled primary button while "Reject all" is absent from the first layer, is a low-contrast text link, or takes more clicks; a choice uses trick wording (double negatives, an unchecked box that means yes); or a button styled as disabled is the one that proceeds.
- Not a finding if: accept and reject share the same style, size, and layer, and the wording is plain.
- Severity: Critical when confirmed on a consent choice; High on other choices.
- Fix: put "Reject all" on the first layer with the same style and size as "Accept all", and use plain, positive wording for every choice.
- Verify the fix: both buttons share a class and a layer; one click rejects.
- Refs: deceptive.design interface interference, trick wording; EDPB Cookie Banner Taskforce report (2023); GDPR Article 7(3); DSA Article 25

### TRU-R6 Users must give consent or access unrelated to the task to continue (quick)
- Leads: `scan.sh TRU-R6` lists "by signing up you agree" wording, contact-import and location prompts, and permission requests.
- Confirm: sign-up or a core action cannot proceed unless the user accepts marketing or data sharing bundled into the terms ("By creating an account you agree to receive offers"), uploads contacts, or grants location or other access the task does not need, with no skip.
- Not a finding if: the access is needed for the task (location for a map search) and a skip or manual entry exists; the terms bundle only what the service needs to run.
- Severity: Critical when confirmed for bundled marketing or data-sharing consent (consent that is a condition of service is not freely given); High for permission prompts with no skip.
- Fix: separate marketing and sharing consent from the terms as optional unchecked choices; ask for access at the moment it is needed, with a skip.
- Verify the fix: a user who declines every optional choice can finish sign-up and the core action.
- Refs: deceptive.design forced action; GDPR Article 7(4); EDPB Guidelines 05/2020

## Also check
- Credibility (Stanford guidelines): a real organization and contact path, named people, sourced claims, fresh content, restraint with promotions, and no small errors (typos, broken links, console errors), which erode trust out of proportion to their size.
- Disguised ads that look like content; comparison prevention (plans priced in units that cannot be compared, the cheapest plan hidden).
- Misdirection: layout or motion that draws attention away from a cost or a choice.
- Honest social proof: reviews two-sided, not filtered to five stars; "N people viewing" and "only N left" claims backed by data.
- Privacy at the point of collection: each piece of data explained where it is asked, minimized, with defaults that favor the user.
- Marketing email honors unsubscribe (the List-Unsubscribe header, no sign-in required).

## Paper controls (look protective, protect nothing)
- A "Reject all" button in the markup but hidden by CSS or shown only after "Manage options".
- A consent choice saved but never read: tracking scripts load in the head before or regardless of it.
- An unsubscribe link that opens a sign-in page or a preference center with everything checked.
- A privacy toggle in settings that saves only in the browser.
