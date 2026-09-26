# @@REPORT_TITLE@@: @@PROJECT@@

> Read-only @@AUDIT_NOUN@@ of the code as written, @@DATE@@. @@BANNER@@ Mode: @@MODE@@. Scope: @@SCOPE@@.
> Self-contained: every finding cites the file and line it is about, so an agent holding only this report and the code can act on it. Written with @@SKILL_NAME@@ (auditor-suite @@SUITE_VERSION@@).

## Snapshot

- Project: @@PROJECT@@ (@@COMMIT@@)
- Stack: {{languages, frameworks, and key libraries, from inventory.sh}}
- Size and coverage: {{source file count; exhaustive or sampled; if sampled, exactly what you read}}
- Maturity and exposure: {{prototype, internal tool, production service, or public product; who uses it and how exposed it is}}
- Active dimensions: @@ACTIVE@@
- Not applicable: @@NA@@
- Not assessed: @@NOT_ASSESSED@@
- Excluded: {{vendored, generated, or build paths you did not read, or "none"}}

## Map

{{@@MAP_HINT@@}}

## Overall score

<!-- BEGIN GENERATED: score (score.sh --write fills this block; do not edit it by hand) -->
<!-- END GENERATED: score -->

Verdict: {{two to four sentences on the state of this project, specific enough that they could not describe any other project}}

Calibration: {{one line: the bar you graded against and why}}

## What to fix first

<!-- BEGIN GENERATED: fix-first (score.sh --write) -->
<!-- END GENERATED: fix-first -->

## Strengths (preserve these)

{{bullets: what the project gets right, each with a `path:line` citation so the acting agent keeps it; or write "None found."}}

## Systemic patterns (root causes)

{{one bullet per root cause shared by two or more findings, written as "- SYS-1: root cause. Members: ID-001, ID-002. Root fix: one fix."; or write "None."}}

## Findings

<!-- One block per finding in the exact format of references/protocol.md (Finding format). -->

## Dimension notes

@@DIMENSION_NOTES@@

## Remediation plan

<!-- BEGIN GENERATED: plan (score.sh --write) -->
<!-- END GENERATED: plan -->

## Scope and limitations

{{what you read and what you did not; which findings need a running system, a scanner, real data, or production config to confirm; the assumptions that would change your conclusions if untrue}}

## How to use this report (for the acting agent)

1. Triage by severity and confidence. Confirmed Critical and High findings are safe to act on now, in the order under "What to fix first". Re-verify every Suspected finding against the cited code before changing anything.
2. Confirm the stated assumption on Likely findings before acting.
3. Fix root causes first: prefer a systemic pattern's root fix over its individual members.
4. Preserve the strengths; do not refactor them away while fixing something else.
5. @@DOMAIN_RULE@@
6. One finding, one change, verified: after each fix, run its "Verify the fix" step and keep the change traceable to the finding ID.
7. Do not widen scope silently; note adjacent issues instead of sprawling into a rewrite.
8. Re-run the audit to measure progress: confirm findings are resolved, not relocated, and that the strengths did not regress.
