---
type: regex
target: files
pattern: '^(?!uiaudit\.md$).+$'
flags: m
match: not_contains
---

The only file the run creates is uiaudit.md.
