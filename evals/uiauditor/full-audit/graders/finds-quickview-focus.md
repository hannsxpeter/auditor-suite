---
type: regex
target:
  source: file
  path: uiaudit.md
pattern: 'QuickViewModal\.jsx(:| line | \(line |, line |#L)[1-6]\b'
---

Finds the quick-view overlay that never manages focus at src/components/QuickViewModal.jsx:3 (A11Y-R5).
