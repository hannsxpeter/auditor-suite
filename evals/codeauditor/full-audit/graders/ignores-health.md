---
type: regex
target:
  source: file
  path: codeaudit.md
pattern: '- Location:[^\n]*app/routes/health\.py'
match: not_contains
arm: with-only
---

Does not file a finding at the safe decoy app/routes/health.py (see ANSWERS.md).
