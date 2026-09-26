---
type: regex
target:
  source: file
  path: seoaudit.md
pattern: '(?:^|[^/\w.-])(?:\./)?lib/seo\.ts(:| line | \(line |, line |#L)1[2-7]\b'
---

Finds the shared metadata helper that canonicalizes every page to the home page at lib/seo.ts:16 (CANON-R1).
