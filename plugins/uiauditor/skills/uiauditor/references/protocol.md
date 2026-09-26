# Audit protocol

Shared by every auditor-suite skill. SKILL.md tells you when to read this file; read all of it once before you record your first finding.

## Contents

1. Evidence rules
2. Finding format (with a filled example)
3. Severity, confidence, effort
4. Which dimension owns a finding
5. Refute before you record
6. Repeats and systemic patterns
7. Calibration
8. Scoring (score.sh does the arithmetic)
9. Remediation buckets
10. Modes
11. Before you finish

## 1. Evidence rules

- Cite only code you opened in this session. Write locations as `path:line` or `path:start-end` in backticks, with the path relative to the project root.
- Evidence must quote the code at the first cited location, copied exactly from the tool output into single backticks (at least 6 characters). check-report.sh fails any finding whose quote is not found within 6 lines of the cited line.
- Never cite from memory, from a search summary, or from a file name alone. A scan.sh lead is a place to read, not a finding.
- Code that exists only in git history (for example a secret deleted from the working tree): cite `<commit>:path:line` and quote the line from `git show <commit>:path`.
- A missing control (no rate limit, no index, no test): cite the line where the control should be (the route registration, the migration, the workflow step) and quote that line.
- Names, comments, and docs state intent; code states reality. When they disagree, the gap is a finding: cite the code, and mention the doc in Evidence.

## 2. Finding format

Every finding is one block under `## Findings`, highest severity first, in exactly this shape:

```
### [DIM-001] Title that names the defect and where it is
- Severity: Critical|High|Medium|Low | Confidence: Confirmed|Likely|Suspected | Effort: S|M|L | Dimension: DIM
- Location: `path:line` (and more locations, each in backticks)
- Evidence: what the code does now, quoting it in backticks
- Impact: the concrete consequence, and who or what is affected
- Recommendation: the specific change and where to make it
- Verify the fix: a test to add, a behavior to observe, or a command to run
- References: standard IDs (CWE, OWASP, WCAG, ...) or "none"
- Related: SYS-n or other finding IDs, or "none"
```

Filled example (from codeauditor; your dimension IDs are listed in SKILL.md):

```
### [ERR-001] Payment webhook swallows database errors and still returns 200
- Severity: High | Confidence: Confirmed | Effort: S | Dimension: ERR
- Location: `src/webhooks/stripe.ts:48` (also `src/webhooks/paypal.ts:31`)
- Evidence: the handler runs `try { await db.payment.update(update) } catch (e) {}` and then always calls `res.sendStatus(200)`.
- Impact: when the database write fails, the provider is told the payment was recorded, never retries, and the order stays unpaid.
- Recommendation: delete the empty catch; on failure log the event id and return 500 so the provider retries.
- Verify the fix: a test that makes `db.payment.update` throw expects status 500 and one error log line with the event id.
- References: CWE-390
- Related: SYS-1
```

Rules for the fields:
- IDs: the dimension ID, a dash, and three digits, numbered in the order you record them (AUTHZ-001, AUTHZ-002). Never reuse an ID.
- Title and Impact must name something specific to this project (a file, function, route, table, or value). If the sentence would be true of any project, rewrite it.
- Recommendation says what to change and where. Banned on their own: "improve", "consider", "add validation", "refactor", "harden".
- Quote code inline with single backticks. Do not put fenced code blocks inside a finding.
- One finding per defect. Several places with the same defect are one finding with several locations (see section 6).

## 3. Severity, confidence, effort

Each card in references/ gives the severity for its defect; use it. Without a card, use these:

- **Critical**: exploitable now, loses or corrupts data, breaks a core flow for many users, or guarantees an outage. Act immediately.
- **High**: a serious defect likely to cause an incident or block users on an important path. Act this cycle.
- **Medium**: a real problem with preconditions, on a secondary path, or slowing the team down. Schedule it.
- **Low**: minor, cosmetic, or hygiene. Batch it.

Confidence, decided by what you can point to:
- **Confirmed**: you can cite the line that shows the defect and you checked there is no guard elsewhere.
- **Likely**: the code shows the defect, but its effect depends on something you state and could not see (a runtime setting, deployment, data volume). Write the assumption in Evidence or Impact.
- **Suspected**: inferred without confirming (for example you could not find where a value comes from). Say in Verify the fix what would confirm it. Suspected findings count half in the score and never cap it.

When unsure between two severities, choose the lower one and say why in Impact. When unsure about confidence, choose the lower one.

Effort: **S** under about an hour, localized; **M** a few files or about half a day; **L** cross-cutting or needs design, several days.

## 4. Which dimension owns a finding

- A finding found through a card belongs to that card's dimension: the card ID prefix is the finding ID prefix.
- A defect no card covers belongs to the dimension whose code you would change to fix it.
- Record each defect once. If another dimension is also affected, say so in Impact or Related; never file it twice.
- The "Not here" line at the top of each dimension file names what belongs elsewhere.

## 5. Refute before you record

For every candidate, look for the reason it is not a defect, and read the code to answer:
1. Is there a guard, check, or default elsewhere (middleware, framework, database constraint, gateway) that already prevents it?
2. Does the card's "Not a finding if" line apply?
3. Is it deliberate and documented (a comment or doc that explains the trade-off)?
4. Can the path actually be reached (routes mounted, feature enabled, code not dead)?
5. Does it matter at this project's scale and exposure?

If any answer removes the problem, drop it. If you cannot answer, keep it and lower the confidence.

## 6. Repeats and systemic patterns

- The same defect in several places is one finding: list up to five locations in Location and state the total count in Evidence ("12 handlers; the first five are cited").
- Different findings with one root cause (for example no central validation layer behind three injection findings) get one bullet under `## Systemic patterns (root causes)`:
  `- SYS-1: root cause. Members: INJ-001, INJ-002, AUTHZ-003. Root fix: the one change that removes all of them.`
  A pattern needs at least two members. Put `SYS-1` in each member's Related field.

## 7. Calibration

Grade against what the project is: a weekend script is not held to the bar of a payment service. Decide the bar from the README, the deployment files, and who can reach the code, and write it on the Calibration line. Calibration changes severity through the cards' conditions (for example "Critical when reachable without authentication"); it never changes the scoring formula.

## 8. Scoring (score.sh does the arithmetic)

Run `bash <skill>/scripts/score.sh --write`; never compute or edit scores by hand. The rules, so you can explain a score:

- Each finding deducts points from its dimension: Critical 25, High 10, Medium 3, Low 1. Suspected findings deduct half. Low findings deduct at most 10 points per dimension in total.
- Dimension score = 100 minus the deductions, rounded down, never below 0.
- Dimension caps: one Critical (not Suspected) holds the dimension at 69 at most; two or more hold it at 59.
- Overall = the weighted mean of the scored dimensions, weights re-normalized over them, rounded to the nearest whole number. Not-applicable and not-assessed dimensions are left out.
- Overall caps: one Critical (not Suspected) anywhere holds the overall at 79; two or more, or one in a floor dimension (marked in SKILL.md), hold it at 69.
- Grades: A 90-100 exemplary; B 80-89 solid, minor issues; C 70-79 adequate, real gaps; D 60-69 weak, systemic problems; F 0-59 failing.

A dimension with no findings scores 100 only if its notes show you worked every card; check-report.sh enforces that.

## 9. Remediation buckets

score.sh sorts every finding into exactly one bucket:
- **Quick wins**: Critical or High, not Suspected, effort S.
- **Plan now**: Critical or High, not Suspected, effort M or L.
- **Verify first**: any Suspected finding.
- **Schedule**: Medium, not Suspected.
- **Backlog**: Low, not Suspected.

"What to fix first" is Quick wins plus Plan now: Critical before High, then findings that belong to a systemic pattern, then smaller effort.

## 10. Modes

- **full** (default): every active dimension, every card.
- **quick**: every active dimension, only the cards tagged `(quick)` (the Critical-class checks). No numeric score; the report says how many Critical and High findings the triage confirmed.
- **only=DIM,DIM**: only the listed dimensions, every card; the score is labeled partial.
- **path**: any mode can be limited to paths (for example `quick src/api`); pass them to new-report.sh and scan.sh.

## 11. Before you finish

1. `bash <skill>/scripts/check-report.sh` prints `check-report: OK`. Fix every problem it lists and rerun it; do not stop while it reports problems.
2. Reread every title and Impact line: each names something in this project.
3. Scope and limitations says what you did not read and what needs a running system to confirm. Never claim you ran the app, a scanner, a query, or a test.
4. Send the output of `bash <skill>/scripts/score.sh --chat` as your final message. Do not finish silently.
