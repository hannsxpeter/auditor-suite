---
type: regex
target:
  source: file
  path: seoaudit.md
pattern: '(?:^|[^/\w.-])(?:\./)?app/docs/\[\.\.\.slug\]/page\.tsx(:| line | \(line |, line |#L)(1[7-9]|2[0-8])\b'
---

Finds the help-center catch-all that renders "Article not found" with status 200 at app/docs/[...slug]/page.tsx:21 (URLARCH-R1).
