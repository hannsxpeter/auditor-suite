---
type: regex
target:
  source: file
  path: dbaudit.md
pattern: '- Location:[^\n]*catalog\.js'
match: not_contains
arm: with-only
---

Does not file a finding at the safe decoy src/routes/catalog.js (see ANSWERS.md).
