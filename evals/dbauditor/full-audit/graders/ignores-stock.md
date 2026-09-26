---
type: regex
target:
  source: file
  path: dbaudit.md
pattern: '- Location:[^\n]*stock\.js'
match: not_contains
arm: with-only
---

Does not file a finding at the safe decoy src/services/stock.js (see ANSWERS.md).
