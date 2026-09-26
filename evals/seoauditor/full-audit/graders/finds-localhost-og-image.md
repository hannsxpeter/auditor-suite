---
type: regex
target:
  source: file
  path: seoaudit.md
pattern: '(?:^|[^/\w.-])(?:\./)?app/customers/page\.tsx(:| line | \(line |, line |#L)1[2-4]\b'
---

Finds the localhost share image on the customer stories page at app/customers/page.tsx:13 (SOCIAL-R1).
