# CUST: Customer Accounts and Operations

Weight 9. Active when multi-member organizations, workspaces, or teams (a membership, invite, or role entity), or admin, support, or back-office tooling exist. A workspace id alone, or a workspace with a single owner, does not activate it.
Owns: the customer account's life from the product side: workspace ownership and its transfer; what happens to a team's shared work when a member leaves or is removed; closure that stops what the account set running; export coverage of what customers create; routine account and billing operations (plan changes, trial extensions, credits, refunds, restoring a cancelled account, ownership transfers) done as product actions rather than database edits; and arrangements for one named customer hardcoded in product logic.
Not here: whether a role check is enforced on a route, and SSO, sessions, API key revocation, and SCIM deprovisioning as access risks (secauditor AUTHZ, AUTHN); personal-data erasure, retention, and the data-subject access path (secauditor LOGPRIV-R5); audit records of admin actions (secauditor LOGPRIV-R1); how hard deleting an account is, and a missing online path (uxauditor TRU-R2); a confirmation or undo missing on a destructive control, including remove member, when the data survives (uxauditor USE-R1); stuck or mis-routed workflow items fixed by hand (uxauditor PROC, Also check); cascades that reach financial or audit rows, and delete behavior defined only in the ORM (dbauditor INTEGRITY-R2, INTEGRITY-R4); stopping billing on deletion (BILL-R4); seat billing (BILL-R7); a promised export that does not exist (CLM-R1); staff allowlists in flag checks (SHIP, Also check); sign-up abuse at machine speed (secauditor APISEC-R3).
Standards: EnterpriseReady (team management, change management); SCIM 2.0 (RFC 7643, RFC 7644); EU Data Act, Regulation (EU) 2023/2854, Chapter VI (switching between data processing services; dates in facts.md).
Read first: the user, membership, and organization or workspace models; the invite, remove-member, leave, role-change, and transfer-ownership handlers; delete and close handlers for accounts and workspaces; export handlers; admin and support routes; and the scripts/, bin/, and runbook folders.

## Cards

### CUST-R1 A workspace can be left with no owner, or ownership cannot be transferred
- Leads: `scan.sh CUST-R1` lists member removal, leave, role change, user deletion, and ownership transfer handlers.
- Confirm: the last owner or admin can leave, be removed, be demoted, or delete their user account while the workspace keeps members, data, or a paid subscription, because no handler checks that another owner remains; or no transfer-ownership action exists, so an ownership change needs a database edit.
- Not a finding if: every path that removes or demotes an owner first checks that another owner exists, and a transfer action exists in the product (run by the owner or by support); the product has no multi-member workspaces.
- Severity: High when the workspace holds a paid subscription or customer data; Medium otherwise.
- Fix: refuse to remove, demote, or delete the last owner until another member is promoted, and add a transfer-ownership action that the owner and support can run.
- Verify the fix: a test removes the last owner and gets an error that names the transfer step.
- Refs: EnterpriseReady (team management)

### CUST-R2 Removing a member or deleting a member's user destroys or strands the team's shared work (quick)
- Leads: `scan.sh CUST-R2` lists member removal and user deletion handlers, cascade rules from users to content, and reassignment steps.
- Confirm: content the workspace still needs (projects, documents, records, comments) is owned by the individual `user_id` with no workspace owner, and removing a member or deleting the member's user account deletes it (an explicit delete, or an `ON DELETE CASCADE` or ORM `dependent: :destroy` from the user) or leaves it hidden or uneditable with no reassignment step, even when the removal was confirmed.
- Not a finding if: the content belongs to the workspace and survives the member; removal offers or forces reassignment to another member (read the handler); the cascade reaches only financial or audit rows (dbauditor INTEGRITY-R2); the deleted content is the member's private data by design and the product says so; the only gap is that the remove control runs with no confirmation or undo while the shared work survives (uxauditor USE-R1).
- Severity: Critical when Confirmed that a routine member removal or member account deletion hard-deletes content the rest of the workspace uses, with no recovery window; High when the content survives but cannot be seen, edited, or reassigned; Medium otherwise.
- Fix: make the workspace the owner of shared content, keep the creator as an attribute, add a reassign step to member removal, and soft-delete with a restore window.
- Verify the fix: a test removes a member who created three projects, and the remaining members still see and edit all three.
- Refs: EnterpriseReady (team management); protocol section 3 (data loss)

### CUST-R3 Closing an account or workspace leaves its integrations, webhooks, or scheduled sends running
- Leads: `scan.sh CUST-R3` lists delete, close, deactivate, and offboard handlers for accounts and workspaces. Read what each one stops.
- Confirm: closure or deactivation marks the account or workspace closed but leaves its connected integrations, outbound webhooks, automation API keys, scheduled reports, campaigns, or marketing and notification sends running, so the product keeps acting for a customer who left.
- Not a finding if: the closure handler, or a job it enqueues, disables every integration, webhook, schedule, and send for the account (read each); credential revocation as an access risk is secauditor AUTHN.
- Severity: High when the closed account keeps sending to its customers or third parties, or keeps calling paid external services; Medium otherwise.
- Fix: stop every integration, webhook, schedule, and send for the account in the closure handler or in one job it enqueues, and record what was stopped.
- Verify the fix: a test closes a workspace and finds no job, webhook delivery, or send scheduled for it.
- Refs: EnterpriseReady (change management)

### CUST-R4 An export the product offers leaves out content customers create
- Leads: `scan.sh CUST-R4` lists export, download-all, takeout, and archive handlers. List the customer content types from the models.
- Confirm: an owner-run export exists, or copy promises one, and it covers only part of the customer's content (projects but not files, comments, or history; the current page of a table; one workspace of several), exists only as an admin script, or writes a format the product cannot import again while the copy promises portability.
- Not a finding if: the export covers every customer content type in an open format; the omitted type is derived or regenerable; no export is offered or promised (a promised export that does not exist is CLM-R1); the request is the personal-data access path (secauditor LOGPRIV-R5).
- Severity: High when export is promised in pricing, terms, security, or sales copy, or the plan is sold to businesses; Medium otherwise.
- Fix: export every customer content type (JSON plus CSV, files as an archive) as a job that sends a download link to the owner.
- Verify the fix: a test creates one record of each content type and finds all of them in the export.
- Refs: Regulation (EU) 2023/2854 Chapter VI (facts.md); GDPR Article 20 (context only; the personal-data path is secauditor's)

### CUST-R5 Routine account and billing operations exist only as SQL or one-off scripts
- Leads: `scan.sh CUST-R5` lists direct updates to plans, statuses, trials, credits, seats, and owners in scripts, SQL, and runbooks.
- Confirm: a runbook or README lists an account or billing operation as a support procedure (changing or comping a plan, extending a trial, granting credits, refunding, restoring a cancelled account, transferring ownership, merging accounts, changing the account email), or two or more committed scripts do the same one, and it runs as SQL or a script against production, writing plan or billing state without calling the provider, or the product has no admin action for it.
- Not a finding if: an admin action does the work through the product's own lifecycle functions and calls the provider (whether the action is audited is secauditor LOGPRIV-R1); a single script that no runbook mentions and that writes no plan, credit, or billing state (record nothing; the repository cannot show how often it runs); it unsticks or re-routes a workflow item (uxauditor PROC, Also check).
- Severity: High when the script writes plan, credit, or billing state the provider never learns, so the two drift; Medium otherwise. Name secauditor in Impact when the script needs production database credentials on a laptop.
- Fix: build one admin action per recurring operation on top of the lifecycle functions, restricted to a support role, calling the provider, and taking a reason field.
- Verify the fix: the runbook's SQL steps are replaced by admin actions, and a test runs each action and asserts the provider call.
- Refs: EnterpriseReady (change management)

### CUST-R6 Product logic branches on one named customer's id, domain, or email
- Leads: `scan.sh CUST-R6` lists comparisons of account, workspace, organization, tenant, or customer ids, slugs, and email domains with string literals, and lists of customer ids or domains.
- Confirm: production code compares the current account, workspace, organization, or member email or domain with a literal that names one customer (`org.slug === "acme"`, `VIP_ACCOUNT_IDS.includes(account.id)`, `email.endsWith("@bigclient.com")`) to change a price, a limit, a feature, a retention period, or a check, and neither the plan catalog nor an account field set through an admin action records the arrangement.
- Not a finding if: the literal is the product's own company, its staff, or a test or demo account; the branch reads an override field on the account that an admin action sets; a migration or one-time backfill uses the literal; the literal is a third-party domain the product integrates with.
- Severity: High when the branch changes a price, billing, data retention, or a permission or security check (name secauditor in Impact for a skipped check); Medium otherwise.
- Fix: move each arrangement into an account-level override or contract record (plan, limits, features, deal reference, end date) set through an admin action, and delete the literal branch.
- Verify the fix: a search for the customer's identifier finds no literal in product code, and the account's override record reproduces the behavior.
- Refs: EnterpriseReady (change management); Monetizing Innovation (packaging)

## Also check
- Changing the account email and merging duplicate accounts exist as product actions.
- Customer admins can see seats used, pending invites, and who holds which role.
- Trials that can be restarted indefinitely with new emails on a product that is costly to serve (automated sign-up abuse is secauditor APISEC-R3).
- Domain capture or auto-join for company domains, when a B2B plan sells it.
- The closure screen says what is deleted and when: the copy is uxauditor CNT; the schedule is here.

## Paper controls (look protective, protect nothing)
- An `is_owner` column with no check that one owner remains.
- A transfer-ownership endpoint with no UI, admin action, or runbook mention.
- An "Export data" button that exports only the current page of a table.
- An admin panel route mounted only in development.
- A closed workspace that still sends its weekly report.
- A `customer_overrides` JSON column beside an `if (org.slug === ...)` branch that ignores it (CUST-R6).
