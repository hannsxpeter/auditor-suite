---
type: regex
target:
  source: file
  path: dbaudit.md
pattern: 'create_products\.js(:| line | \(line |, line |#L)([2-9]|1[0-2])\b'
---

Finds the plain unique on sku in the soft-deleted products table at migrations/20230105091000_create_products.js:10 (CONSTRAINTS-R2).
