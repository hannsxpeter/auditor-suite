---
type: regex
target:
  source: file
  path: dbaudit.md
pattern: 'create_order_items\.js(:| line | \(line |, line |#L)[2-8]\b'
---

Finds the unindexed order_items.order_id foreign key at migrations/20230105093000_create_order_items.js:4 (INDEX-R1).
