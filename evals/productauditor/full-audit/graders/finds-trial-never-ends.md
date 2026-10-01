---
type: regex
target:
  source: file
  path: productaudit.md
pattern: 'auth\.js(:| line | \(line |, line |#L)(3[5-9]|4[01])\b'
---

Finds the Pro trial every sign-up gets with no card, whose trial_ends_at nothing reads, at server/routes/auth.js:38 (BILL-R5).
