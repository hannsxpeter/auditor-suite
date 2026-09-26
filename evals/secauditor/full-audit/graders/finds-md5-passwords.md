---
type: regex
target:
  source: file
  path: secaudit.md
pattern: 'passwords\.js(:| line | \(line |, line |#L)([1-9]|1[01])\b'
---

Finds MD5 password hashing at src/auth/passwords.js:4 (AUTHN-R1).
