---
type: regex
target:
  source: file
  path: secaudit.md
pattern: 'tokens\.js(:| line | \(line |, line |#L)([6-9]|1[0-2])\b'
---

Finds jwt.verify accepting alg none at src/auth/tokens.js:9 (AUTHN-R3).
