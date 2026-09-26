---
type: regex
target:
  source: file
  path: uxaudit.md
pattern: 'Reports\.jsx(:| line | \(line |, line |#L)(1[7-9]|2[0-6])\b'
---

Finds the bare "No data" empty state at src/pages/Reports.jsx:23 (CNT-R2).
