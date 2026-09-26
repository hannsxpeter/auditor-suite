---
type: regex
target:
  source: file
  path: uxaudit.md
pattern: 'MarketingConsent\.jsx(:| line | \(line |, line |#L)([1-9]|1[0-9]|2[0-4])\b'
---

Finds marketing and partner-sharing consent preselected at src/components/MarketingConsent.jsx:3 (TRU-R1).
