---
type: regex
target:
  source: file
  path: productaudit.md
pattern: 'subscription\.js(:| line | \(line |, line |#L)3[2-8]\b'
---

Finds the cancel handler that only changes local state and never cancels the Paddle subscription at server/routes/subscription.js:35 (BILL-R4).
