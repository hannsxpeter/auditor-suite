---
type: regex
target:
  source: file
  path: secaudit.md
pattern: 'server\.js(:| line | \(line |, line |#L)([7-9]|1[0-4])\b'
---

Finds CORS reflecting any origin with credentials at src/server.js:10 (MISCFG-R2).
