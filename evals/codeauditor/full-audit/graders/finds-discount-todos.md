---
type: regex
target:
  source: file
  path: codeaudit.md
pattern: 'discounts\.py(:| line | \(line |, line |#L)([1-9]|[1-3][0-9])\b'
---

Finds the pile of untracked TODO, FIXME, HACK, and XXX markers in app/services/discounts.py (QUAL-R5).
