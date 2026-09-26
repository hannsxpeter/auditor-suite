---
type: regex
target:
  source: file
  path: llmaudit.md
pattern: '- Location:[^\n]*tagging\.py'
match: not_contains
arm: with-only
---

Does not file a finding at the safe decoy app/tagging.py (see ANSWERS.md).
