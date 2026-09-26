---
type: regex
target:
  source: file
  path: seoaudit.md
pattern: '(?:^|[^/\w.-])(?:\./)?app/page\.tsx(:| line | \(line |, line |#L)(19|2[0-5])\b'
---

Finds the lazy-loaded hero image on the home page at app/page.tsx:24 (PERF-R1).
