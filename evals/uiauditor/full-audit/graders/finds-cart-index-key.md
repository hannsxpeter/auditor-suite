---
type: regex
target:
  source: file
  path: uiaudit.md
pattern: 'CartList\.jsx(:| line | \(line |, line |#L)([34]|3[6-9]|4[0-5])\b'
---

Finds the index keys on the stateful cart rows at src/components/CartList.jsx:42 (COMP-R3).
