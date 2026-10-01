---
type: regex
target:
  source: file
  path: productaudit.md
pattern: 'plan-limits\.js(:| line | \(line |, line |#L)([6-9]|1[0-2])\b'
---

Finds the plan-limit job that hard-deletes projects above the new limit on a downgrade or cancellation at server/jobs/plan-limits.js:9 (BILL-R8).
