---
type: regex
target:
  source: file
  path: secaudit.md
pattern: 'admin\.js(:| line | \(line |, line |#L)(9|1[0-6])\b'
---

Finds the refund route guarded by login only at src/routes/admin.js:12 (AUTHZ-R2).
