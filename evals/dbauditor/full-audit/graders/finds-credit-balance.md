---
type: regex
target:
  source: file
  path: dbaudit.md
pattern: 'credits\.js(:| line | \(line |, line |#L)([3-9]|1[01])\b'
---

Finds the read-modify-write of credit_balance at src/services/credits.js:8-9 (TXN-R1).
