---
type: regex
target:
  source: file
  path: dbaudit.md
pattern: '(create_customers\.js|accounts\.js)(:| line | \(line |, line |#L)([2-9]|1[0-3])\b'
---

Finds customer email uniqueness enforced only by the check in src/services/accounts.js:5, with no unique constraint at migrations/20230105090000_create_customers.js:4 (CONSTRAINTS-R1).
