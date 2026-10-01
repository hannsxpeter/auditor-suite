---
type: regex
target:
  source: file
  path: productaudit.md
pattern: 'feedback\.js(:| line | \(line |, line |#L)([7-9]|1[0-3])\b'
---

Finds the feedback route that returns success after only logging the message at server/routes/feedback.js:10 (VOC-R1).
