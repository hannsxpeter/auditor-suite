---
type: regex
target:
  source: file
  path: llmaudit.md
pattern: 'tracking\.py(:| line | \(line |, line |#L)([7-9]|1[0-2]|2[23])\b'
---

Finds the carrier API key placed in the system prompt at app/tracking.py:10 (LLMSEC-R5).
