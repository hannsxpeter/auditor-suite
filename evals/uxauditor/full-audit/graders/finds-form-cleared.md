---
type: regex
target:
  source: file
  path: uxaudit.md
pattern: 'NewExpense\.jsx(:| line | \(line |, line |#L)(2[6-9]|3[0-4])\b'
---

Finds the expense form cleared on a validation error at src/pages/NewExpense.jsx:31 (FRM-R1).
