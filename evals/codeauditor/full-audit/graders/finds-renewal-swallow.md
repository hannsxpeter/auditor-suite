---
type: regex
target:
  source: file
  path: codeaudit.md
pattern: 'billing\.py(:| line | \(line |, line |#L)(39|4[0-9]|5[0-2])\b'
---

Finds the swallowed charge failure in charge_renewal at app/services/billing.py:45 (ERR-R1).
