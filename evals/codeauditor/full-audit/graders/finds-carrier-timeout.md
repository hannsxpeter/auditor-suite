---
type: regex
target:
  source: file
  path: codeaudit.md
pattern: 'carrier\.py(:| line | \(line |, line |#L)(9|1[0-9]|2[01])\b'
---

Finds the carrier request with no timeout at app/services/carrier.py:12 (ERR-R3).
