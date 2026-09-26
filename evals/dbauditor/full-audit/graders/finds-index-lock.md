---
type: regex
target:
  source: file
  path: dbaudit.md
pattern: 'add_orders_status_created_at_index\.js(:| line | \(line |, line |#L)[1-5]\b'
---

Finds the blocking index build on the 40-million-row orders table at migrations/20240312100000_add_orders_status_created_at_index.js:3 (MIGRATION-R1).
