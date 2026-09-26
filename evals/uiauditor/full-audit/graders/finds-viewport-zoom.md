---
type: regex
target:
  source: file
  path: uiaudit.md
pattern: 'index\.html(:| line | \(line |, line |#L)[2-8]\b'
---

Finds the viewport meta that blocks zoom at index.html:5 (A11Y-R4).
