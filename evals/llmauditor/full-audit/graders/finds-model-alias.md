---
type: regex
target:
  source: file
  path: llmaudit.md
pattern: 'config\.py(:| line | \(line |, line |#L)[1-5]\b'
---

Finds the floating model alias at app/config.py:3 (MODEL-R1).
