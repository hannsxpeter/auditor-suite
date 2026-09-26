---
type: regex
target:
  source: file
  path: seoaudit.md
pattern: '- Location:[^\n]*components/Analytics\.tsx'
match: not_contains
arm: with-only
---

Does not file a finding at the safe decoy components/Analytics.tsx (see ANSWERS.md).
