---
type: regex
target:
  source: file
  path: uiaudit.md
pattern: 'Hero\.jsx(:| line | \(line |, line |#L)([5-9]|1[0-2])\b'
---

Finds the lazy-loaded hero image at src/components/Hero.jsx:9 (PERF-R1).
