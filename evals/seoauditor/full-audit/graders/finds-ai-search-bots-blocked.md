---
type: regex
target:
  source: file
  path: seoaudit.md
pattern: '(?:^|[^/\w.-])(?:\./)?app/robots\.ts(:| line | \(line |, line |#L)[5-9]\b'
---

Finds OAI-SearchBot and PerplexityBot blocked while the README and llms.txt court AI visibility at app/robots.ts:8 (AIVIS-R1).
