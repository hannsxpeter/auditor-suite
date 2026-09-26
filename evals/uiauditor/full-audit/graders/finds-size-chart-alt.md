---
type: regex
target:
  source: file
  path: uiaudit.md
pattern: 'SizeGuide\.jsx(:| line | \(line |, line |#L)([5-9]|1[01])\b'
---

Finds the size chart image with no alt attribute at src/components/SizeGuide.jsx:8 (A11Y-R10).
