---
type: regex
target:
  source: file
  path: dbaudit.md
pattern: 'routes/orders\.js(:| line | \(line |, line |#L)([8-9]|1[0-6])\b'
---

Finds OFFSET pagination over all orders at src/routes/orders.js:13 (QUERY-R3).
