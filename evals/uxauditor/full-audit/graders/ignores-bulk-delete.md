---
type: regex
target:
  source: file
  path: uxaudit.md
pattern: '- Location:[^\n]*BulkDeleteDialog\.jsx'
match: not_contains
arm: with-only
---

Does not file a finding at the safe decoy src/components/BulkDeleteDialog.jsx (see ANSWERS.md).
