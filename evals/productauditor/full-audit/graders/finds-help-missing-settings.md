---
type: regex
target:
  source: file
  path: productaudit.md
pattern: 'billing\.md(:| line | \(line |, line |#L)2[0-6]\b'
---

Finds the help article that sends users to Settings > Plan & usage and Download invoices, which do not exist, at content/help/billing.md:23 (CLM-R6).
