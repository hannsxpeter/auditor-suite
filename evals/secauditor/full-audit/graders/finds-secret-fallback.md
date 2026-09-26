---
type: regex
target:
  source: file
  path: secaudit.md
pattern: 'config\.js(:| line | \(line |, line |#L)[1-5]\b'
---

Finds the hardcoded JWT secret fallback at src/config.js:2 (SECRET-R2).
