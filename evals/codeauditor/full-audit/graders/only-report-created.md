---
type: regex
target: files
pattern: '^(?!codeaudit\.md$).+$'
flags: m
match: not_contains
---

The only file the run creates is codeaudit.md.
