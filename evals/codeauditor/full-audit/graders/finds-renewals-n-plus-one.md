---
type: regex
target:
  source: file
  path: codeaudit.md
pattern: 'reports\.py(:| line | \(line |, line |#L)(1[1-9]|20)\b'
---

Finds the per-subscription queries in the renewals report at app/routes/reports.py:14 (PERF-R2).
