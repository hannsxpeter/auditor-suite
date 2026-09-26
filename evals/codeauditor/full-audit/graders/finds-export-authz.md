---
type: regex
target:
  source: file
  path: codeaudit.md
pattern: 'customers\.py(:| line | \(line |, line |#L)(3[5-9]|4[0-4])\b'
---

Finds the export route with no authentication or owner check at app/routes/customers.py:35 (SEC-R2).
