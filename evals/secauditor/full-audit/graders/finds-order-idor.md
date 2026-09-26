---
type: regex
target:
  source: file
  path: secaudit.md
pattern: 'orders\.js(:| line | \(line |, line |#L)(9|1[0-5])\b'
---

Finds the unscoped order lookup at src/routes/orders.js:12 (AUTHZ-R1).
