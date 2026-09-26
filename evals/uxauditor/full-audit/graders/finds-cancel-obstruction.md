---
type: regex
target:
  source: file
  path: uxaudit.md
pattern: 'CancelPlan\.jsx(:| line | \(line |, line |#L)([1-9]|[1-5][0-9]|6[01])\b'
---

Finds cancellation obstructed by a survey, offers, and a required phone call at src/pages/settings/CancelPlan.jsx:56 (TRU-R2).
