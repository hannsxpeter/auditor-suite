---
type: regex
target:
  source: file
  path: llmaudit.md
pattern: 'retrieval\.py(:| line | \(line |, line |#L)(1[7-9]|2[0-4])\b'
---

Finds the vector search with no tenant filter on the shared index at app/retrieval.py:17-24 (LLMSEC-R7).
