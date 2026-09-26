---
type: regex
target:
  source: file
  path: uiaudit.md
pattern: 'index\.css(:| line | \(line |, line |#L)(9|1[0-3])\b'
---

Finds the global focus outline reset at src/index.css:10 (A11Y-R6).
