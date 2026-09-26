---
type: regex
target: files
pattern: '^(?!llmaudit\.md$).+$'
flags: m
match: not_contains
---

The only file the run creates is llmaudit.md.
