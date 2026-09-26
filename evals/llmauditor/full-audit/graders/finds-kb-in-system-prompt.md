---
type: regex
target:
  source: file
  path: llmaudit.md
pattern: 'prompts\.py(:| line | \(line |, line |#L)([1-9]|10)\b'
---

Finds retrieved knowledge-base text joined into the system prompt of an agent that can act at app/prompts.py:9-10 (LLMSEC-R1).
