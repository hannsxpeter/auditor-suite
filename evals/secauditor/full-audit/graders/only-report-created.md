---
type: regex
target: files
pattern: '^(?!secaudit\.md$).+$'
flags: m
match: not_contains
---

The only file the run creates is secaudit.md.
