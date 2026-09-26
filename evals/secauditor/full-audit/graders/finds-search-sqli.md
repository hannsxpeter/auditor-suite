---
type: regex
target:
  source: file
  path: secaudit.md
pattern: 'search\.js(:| line | \(line |, line |#L)([5-9]|1[01])\b'
---

Finds the concatenated search SQL at src/routes/search.js:8 (INJ-R1).
