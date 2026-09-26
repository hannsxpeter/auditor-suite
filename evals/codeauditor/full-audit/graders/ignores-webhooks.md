---
type: regex
target:
  source: file
  path: codeaudit.md
pattern: '- Location:[^\n]*app/routes/webhooks\.py'
match: not_contains
arm: with-only
---

Does not file a finding at the safe decoy app/routes/webhooks.py (see ANSWERS.md).
