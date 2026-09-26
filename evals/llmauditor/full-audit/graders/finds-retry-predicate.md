---
type: regex
target:
  source: file
  path: llmaudit.md
pattern: 'llm\.py(:| line | \(line |, line |#L)([5-9]|1[0-6])\b'
---

Finds the retry wrapper that retries only ConnectionError with SDK retries off at app/llm.py:6-10 (RELIABILITY-R2).
