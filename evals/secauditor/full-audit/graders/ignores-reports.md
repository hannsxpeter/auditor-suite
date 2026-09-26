---
type: regex
target:
  source: file
  path: secaudit.md
pattern: '- Location: `[^`\n]*reports\.js'
match: not_contains
arm: with-only
---

Does not file a finding at the safe decoy src/routes/reports.js (see ANSWERS.md). Only the first cited location counts, so a finding elsewhere that mentions this file as context does not fail the grader.
