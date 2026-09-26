---
type: regex
target:
  source: file
  path: secaudit.md
pattern: 'package\.json(:| line | \(line |, line |#L)1[2-8]\b'
---

Finds the vulnerable lodash pin at package.json:15 (SUPPLY-R1).
