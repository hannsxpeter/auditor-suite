---
type: regex
target:
  source: file
  path: uiaudit.md
pattern: 'CheckoutForm\.jsx(:| line | \(line |, line |#L)(2[3-9]|3[01])\b'
---

Finds the placeholder-only checkout fields at src/components/CheckoutForm.jsx:26 (A11Y-R3).
