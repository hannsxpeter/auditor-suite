---
type: regex
target:
  source: file
  path: uiaudit.md
pattern: 'ProductCard\.jsx(:| line | \(line |, line |#L)(9|1[0-5])\b'
---

Finds the pointer-only "Add to cart" div at src/components/ProductCard.jsx:12 (A11Y-R1).
