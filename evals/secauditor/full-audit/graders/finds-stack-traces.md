---
type: regex
target:
  source: file
  path: secaudit.md
pattern: 'errors\.js(:| line | \(line |, line |#L)[2-8]\b'
---

Finds stack traces returned to clients at src/errors.js:5 (MISCFG-R3).
