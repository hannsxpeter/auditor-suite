---
type: regex
target:
  source: file
  path: uxaudit.md
pattern: 'DangerZone\.jsx(:| line | \(line |, line |#L)([5-9]|[12][0-9]|3[0-2])\b'
---

Finds account deletion on the first click with no confirmation or undo at src/pages/settings/DangerZone.jsx:27 (USE-R1).
