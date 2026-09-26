---
type: regex
target:
  source: file
  path: secaudit.md
pattern: '- Location:[^\n]*reports\.js'
match: not_contains
arm: with-only
---

Does not file a finding at the safe decoy src/routes/reports.js (see ANSWERS.md).
