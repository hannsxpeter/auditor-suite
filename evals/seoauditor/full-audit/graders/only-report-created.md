---
type: regex
target: files
pattern: '^(?!seoaudit\.md$).+$'
flags: m
match: not_contains
---

The only file the run creates is seoaudit.md.
