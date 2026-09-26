---
type: regex
target:
  source: file
  path: codeaudit.md
pattern: 'test_billing\.py(:| line | \(line |, line |#L)([1-9]|1[0-9]|2[0-3])\b'
---

Finds the billing tests that assert nothing at tests/test_billing.py:6-22 (TEST-R2).
