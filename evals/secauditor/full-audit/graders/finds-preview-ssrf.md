---
type: regex
target:
  source: file
  path: secaudit.md
pattern: 'preview\.js(:| line | \(line |, line |#L)([4-9]|10)\b'
---

Finds the server-side fetch of a user URL at src/routes/preview.js:7 (INJ-R4).
