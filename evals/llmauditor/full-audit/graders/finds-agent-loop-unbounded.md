---
type: regex
target:
  source: file
  path: llmaudit.md
pattern: 'agent\.py(:| line | \(line |, line |#L)(19|2[0-7])\b'
---

Finds the unbounded while True tool loop at app/agent.py:20 (AGENT-R2).
