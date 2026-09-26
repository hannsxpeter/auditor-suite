---
type: regex
target:
  source: file
  path: llmaudit.md
pattern: 'tools\.py(:| line | \(line |, line |#L)(2[4-9]|3[0-9]|5[4-9]|6[0-2])\b'
---

Finds the send_customer_email tool that sends to any recipient with no approval at app/tools.py:54-62 (AGENT-R1).
