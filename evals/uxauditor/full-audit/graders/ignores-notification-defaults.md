---
type: regex
target:
  source: file
  path: uxaudit.md
pattern: '- Location:[^\n]*Notifications\.jsx'
match: not_contains
arm: with-only
---

Does not file a finding at the safe decoy src/pages/settings/Notifications.jsx (see ANSWERS.md).
