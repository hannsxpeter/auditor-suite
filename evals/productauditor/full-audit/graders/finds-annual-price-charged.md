---
type: regex
target:
  source: file
  path: productaudit.md
pattern: 'PricingTable\.jsx(:| line | \(line |, line |#L)4[0-6]\b'
---

Finds the pricing table that shows the monthly price but sends the annual price id to checkout at src/components/PricingTable.jsx:43 (ENT-R1).
