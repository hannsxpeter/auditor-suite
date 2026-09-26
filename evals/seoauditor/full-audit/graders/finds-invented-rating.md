---
type: regex
target:
  source: file
  path: seoaudit.md
pattern: '(?:^|[^/\w.-])(?:\./)?components/SoftwareSchema\.tsx(:| line | \(line |, line |#L)([2-9]|1[0-6])\b'
---

Finds the hardcoded AggregateRating with no visible reviews at components/SoftwareSchema.tsx:9 (SCHEMA-R1).
