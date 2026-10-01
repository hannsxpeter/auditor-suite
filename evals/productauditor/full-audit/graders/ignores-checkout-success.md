---
type: regex
target:
  source: file
  path: productaudit.md
pattern: '- Location: `[^`\n]*checkout\.js'
match: not_contains
arm: with-only
---

Does not file a finding at the safe decoy server/routes/checkout.js (see ANSWERS.md). Only the first cited location counts, so a finding elsewhere that mentions this file as context does not fail the grader.
