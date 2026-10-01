---
type: regex
target: files
pattern: '^(?!productaudit\.md$).+$'
flags: m
match: not_contains
---

The only file the run creates is productaudit.md.
