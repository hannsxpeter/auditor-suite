---
type: regex
target:
  source: file
  path: seoaudit.md
pattern: '- Location: `[^`\n]*components/Analytics\.tsx'
match: not_contains
arm: with-only
---

Does not file a finding at the safe decoy components/Analytics.tsx (see ANSWERS.md). Only the first cited location counts, so a finding elsewhere that mentions this file as context does not fail the grader.
