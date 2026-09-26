---
type: regex
target:
  source: file
  path: uxaudit.md
pattern: 'Signup\.jsx(:| line | \(line |, line |#L)(3[6-9]|[45][0-9]|6[0-3])\b'
---

Finds the payment card required before first value at src/pages/Signup.jsx:51 (CNV-R1).
