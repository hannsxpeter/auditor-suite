# Answer key: uxauditor full-audit

Never copied into the eval workspace. Lines refer to files under repo/.

Ledgerly is a public SaaS expense app: members submit expenses with a receipt, an approver approves or returns them, and the owner manages the team and the paid plan. The core journeys are sign-up to the first submitted expense, submitting an expense, approving it, and managing the team and plan.

## Planted defects

| Grader | Location | Card | Expected severity | Defect |
|---|---|---|---|---|
| finds-preticked-consent | src/components/MarketingConsent.jsx:3 | TRU-R1 | Critical | `DEFAULTS = { newsletter: true, partnerSharing: true }` is merged in on mount, so the sign-up form submits marketing and partner-sharing consent unless the user unticks both |
| finds-cancel-obstruction | src/pages/settings/CancelPlan.jsx:56 | TRU-R2 | Critical | cancelling takes a required survey (40 characters minimum), a discount offer, a warning screen, and then a phone call during office hours, while sign-up is one online page; the plan keeps renewing until the call |
| finds-account-delete | src/pages/settings/DangerZone.jsx:27 | USE-R1 | Critical | "Delete account" calls `DELETE /api/account` on the first click; the server (server/index.js:121) hard-deletes every member, expense, receipt, and report, with no confirmation, undo, or grace period |
| finds-card-before-trial | src/pages/Signup.jsx:51 | CNV-R1 | High | a payment card is required before the team can submit its first expense, although the product has a free trial and nothing needs the card yet |
| finds-form-cleared | src/pages/NewExpense.jsx:31 | FRM-R1 | High | a failed client validation calls `setForm(EMPTY)`, wiping every field and the attached receipt of the main recurring form |
| finds-raw-error-code | src/components/UploadReceipt.jsx:18 | CNT-R1 | High | a failed receipt upload shows `Upload failed: RCPT_E413 (413)` with no explanation or next step, on the core submission flow |
| finds-invite-double-submit | src/components/InviteForm.jsx:36 | USE-R2 | High | "Send invite" never disables or shows progress, and `POST /api/invites` (server/index.js:112) creates an invite and sends an email on every request, so repeat clicks send duplicate invites |
| finds-approval-stall | server/approvals.js:15 | PROC-R2 | High | expenses enter `pending_approval` with no due date, reminder, escalation, or reassign action, and `approverId` is null when the team has no other approver, so reimbursements can wait forever |
| finds-empty-state | src/pages/Reports.jsx:23 | CNT-R2 | Medium | the reports page shows only "No data" when a team has no reports, with no word on what reports are, when they appear, or what to do |
| finds-signin-wording | src/components/NavBar.jsx:26 | CNT-R3 | Medium | the header says "Log in" while the page it opens says "Sign in" (src/pages/SignIn.jsx:30, :52) |

Critical-class defects: TRU-R1, TRU-R2, USE-R1. A report may rate the empty state Low or the wording Low and still be right; it should not rate any Critical row below High.

## Decoys (safe; flagging them is a false positive)

| Grader | Location | Why it is safe |
|---|---|---|
| ignores-bulk-delete | src/components/BulkDeleteDialog.jsx:39 | the irreversible bulk delete sits behind a modal (`showModal`) that names the count and the consequence, requires typing "delete N reports", keeps the reports on Escape or "Keep the reports", and reports failure; `autoComplete="off"` is on that typed-confirmation field, not a credential or identity field |
| ignores-notification-defaults | src/pages/settings/Notifications.jsx:43 | `defaultChecked` shows the member's saved preferences from `GET /api/me/notifications`; the defaults (server/db.js:15) turn on only service notices about the member's own approvals and leave product news off |

## Strengths worth naming

- Sign-in keeps the email on failure, shows a plain error in `role="alert"` tied to both fields, sets autofill tokens, and disables the button while pending (src/pages/SignIn.jsx:21-52).
- The approval transition checks the role, refuses self-approval, and rejects stale versions on the server (server/approvals.js:27-29).
- Submitting an expense ends on a confirmation that names the expense and what happens next (src/pages/NewExpense.jsx:50-57), and a server failure keeps the input (src/pages/NewExpense.jsx:42-45).
- The trial terms (price after the trial and where to cancel) sit next to the sign-up heading (src/pages/Signup.jsx:40).
