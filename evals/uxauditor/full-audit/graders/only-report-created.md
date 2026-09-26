---
type: regex
target: files
pattern: '^(?!uxaudit\.md$).+$'
flags: m
match: not_contains
---

The only file the run creates is uxaudit.md.
