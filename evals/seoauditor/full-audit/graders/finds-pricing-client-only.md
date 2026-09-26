---
type: regex
target:
  source: file
  path: seoaudit.md
pattern: '(?:^|[^/\w.-])(?:\./)?app/pricing/page\.tsx(:| line | \(line |, line |#L)([1-9]|1[0-9]|2[0-6])\b'
---

Finds the pricing plans that exist only after a client-side fetch at app/pricing/page.tsx:1 and :14 (RENDER-R1).
