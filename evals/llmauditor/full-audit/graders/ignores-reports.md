---
type: regex
target:
  source: file
  path: llmaudit.md
pattern: '- Location:[^\n]*reports\.py'
match: not_contains
arm: with-only
---

Does not file a finding at the safe decoy app/reports.py (see ANSWERS.md).
