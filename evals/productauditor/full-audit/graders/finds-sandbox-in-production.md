---
type: regex
target:
  source: file
  path: productaudit.md
pattern: 'production\.json(:| line | \(line |, line |#L)[1-7]\b'
---

Finds the production config that points billing at the Paddle sandbox while checkout is live at config/production.json:4 (BILL-R2).
