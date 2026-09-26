---
type: regex
target:
  source: file
  path: dbaudit.md
pattern: 'create_orders\.js(:| line | \(line |, line |#L)[3-9]\b'
---

Finds the order total stored as a float at migrations/20230105092000_create_orders.js:6 (TYPES-R1).
