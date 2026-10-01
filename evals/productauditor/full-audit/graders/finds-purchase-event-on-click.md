---
type: regex
target:
  source: file
  path: productaudit.md
pattern: 'CheckoutButton\.jsx(:| line | \(line |, line |#L)(9|1[0-5])\b'
---

Finds purchase_completed sent from the click handler before checkout even starts at src/components/CheckoutButton.jsx:12 (MET-R2).
