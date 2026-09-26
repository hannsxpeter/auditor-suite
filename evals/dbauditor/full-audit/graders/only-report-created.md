---
type: regex
target: files
pattern: '^(?!dbaudit\.md$).+$'
flags: m
match: not_contains
---

The only file the run creates is dbaudit.md.
