---
type: regex
target:
  source: file
  path: uxaudit.md
pattern: 'UploadReceipt\.jsx(:| line | \(line |, line |#L)(1[4-9]|2[01])\b'
---

Finds the raw error code shown on a failed receipt upload at src/components/UploadReceipt.jsx:18 (CNT-R1).
