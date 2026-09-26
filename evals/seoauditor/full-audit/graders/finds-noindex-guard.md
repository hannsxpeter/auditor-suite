---
type: regex
target:
  source: file
  path: seoaudit.md
pattern: '(?:^|[^/\w.-])(?:\./)?app/layout\.tsx(:| line | \(line |, line |#L)1[0-2]\b'
---

Finds the inverted environment guard that noindexes production at app/layout.tsx:11 (CRAWL-R1).
