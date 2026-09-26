---
type: regex
target:
  source: file
  path: secaudit.md
pattern: 'files\.js(:| line | \(line |, line |#L)([5-9]|1[01])\b'
---

Finds the path traversal at src/routes/files.js:8 (INJ-R5).
