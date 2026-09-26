---
type: regex
target:
  source: file
  path: codeaudit.md
pattern: 'mailer\.py(:| line | \(line |, line |#L)[1-7]\b'
---

Finds the hardcoded email API token at app/services/mailer.py:4 (SEC-R5).
