---
type: regex
target:
  source: file
  path: llmaudit.md
pattern: 'summaries\.py(:| line | \(line |, line |#L)([6-8]|1[5-7]|30)\b'
---

Finds the timestamp that busts the prompt cache at app/summaries.py:16 (COST-R1).
