---
type: regex
target:
  source: file
  path: llmaudit.md
pattern: 'triage\.py(:| line | \(line |, line |#L)([5-8]|2[5-9]|3[0-6])\b'
---

Finds triage JSON parsed and written with no schema validation at app/triage.py:31-34 (OUTPUT-R1).
