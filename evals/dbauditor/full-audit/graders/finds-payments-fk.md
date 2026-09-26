---
type: regex
target:
  source: file
  path: dbaudit.md
pattern: 'create_payments\.js(:| line | \(line |, line |#L)[2-9]\b'
---

Finds payments.order_id with no foreign key at migrations/20230105094000_create_payments.js:4 (INTEGRITY-R1).
