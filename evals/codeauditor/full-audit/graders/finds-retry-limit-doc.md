---
type: regex
target:
  source: file
  path: codeaudit.md
pattern: 'README\.md(:| line | \(line |, line |#L)(2[89]|3[0-4])\b'
---

Finds the documented RENEWAL_RETRY_LIMIT that no code reads at README.md:31 (DOC-R2).
