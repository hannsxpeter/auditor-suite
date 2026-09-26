---
type: regex
target:
  source: file
  path: seoaudit.md
pattern: '- Location:[^\n]*dashboard/layout\.tsx'
match: not_contains
arm: with-only
---

Does not file a finding at the safe decoy app/dashboard/layout.tsx (see ANSWERS.md).
