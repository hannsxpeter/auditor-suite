---
type: regex
target:
  source: file
  path: codeaudit.md
pattern: 'requirements\.txt(:| line | \(line |, line |#L)[4-8]\b'
---

Finds the unused pandas dependency at requirements.txt:7 (DEP-R4).
