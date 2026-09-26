---
type: regex
target:
  source: file
  path: uiaudit.md
pattern: 'Header\.jsx(:| line | \(line |, line |#L)(1[89]|2[0-6])\b'
---

Finds the cart button with no accessible name at src/components/Header.jsx:21 (A11Y-R2).
