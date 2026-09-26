---
type: regex
target:
  source: file
  path: llmaudit.md
pattern: 'insights\.py(:| line | \(line |, line |#L)([3-9]|1[0-9]|20)\b'
---

Finds model-written SQL executed on the app connection at app/insights.py:18-20 (LLMSEC-R2).
