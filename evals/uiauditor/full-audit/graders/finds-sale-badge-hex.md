---
type: regex
target:
  source: file
  path: uiaudit.md
pattern: 'SaleBadge\.jsx(:| line | \(line |, line |#L)[1-6]\b'
---

Finds the hardcoded token colors at src/components/SaleBadge.jsx:3 (DS-R1).
