---
type: regex
target:
  source: file
  path: uxaudit.md
pattern: 'approvals\.js(:| line | \(line |, line |#L)([4-9]|1[0-9]|2[0-3])\b'
---

Finds approvals that can wait forever with no deadline, reminder, escalation, or reassignment at server/approvals.js:15 (PROC-R2).
