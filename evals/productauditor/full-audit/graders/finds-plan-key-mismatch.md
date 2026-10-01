---
type: regex
target:
  source: file
  path: productaudit.md
pattern: 'entitlements\.js(:| line | \(line |, line |#L)[3-9]\b'
---

Finds the entitlement check that compares workspace.plan with "pro" and "studio" while billing stores a Paddle price id at server/entitlements.js:6 (ENT-R2).
