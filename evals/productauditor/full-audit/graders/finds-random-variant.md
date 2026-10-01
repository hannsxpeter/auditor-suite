---
type: regex
target:
  source: file
  path: productaudit.md
pattern: 'experiments\.js(:| line | \(line |, line |#L)(1[89]|2[0-4])\b'
---

Finds the pricing experiment variant drawn with Math.random on every render and never stored at src/lib/experiments.js:21 (EXP-R1).
