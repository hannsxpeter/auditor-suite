---
type: regex
target:
  source: file
  path: uxaudit.md
pattern: '(InviteForm\.jsx(:| line | \(line |, line |#L)([89]|[1-3][0-9]|4[01])|index\.js(:| line | \(line |, line |#L)11[0-9])\b'
---

Finds the invite form that never disables and sends duplicate invites at src/components/InviteForm.jsx:36 (USE-R2).
