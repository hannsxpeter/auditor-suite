---
type: regex
target:
  source: file
  path: codeaudit.md
pattern: 'subscriptions\.py(:| line | \(line |, line |#L)(1[5-9]|[2-9][0-9]|10[0-9]|11[0-5])\b'
---

Finds the 100-line create_subscription at app/routes/subscriptions.py:17 (QUAL-R1).
