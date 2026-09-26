---
type: regex
target:
  source: file
  path: dbaudit.md
pattern: 'routes/customers\.js(:| line | \(line |, line |#L)([7-9]|1[0-3])\b'
---

Finds the email concatenated into SQL at src/routes/customers.js:10 (DBSEC-R1).
