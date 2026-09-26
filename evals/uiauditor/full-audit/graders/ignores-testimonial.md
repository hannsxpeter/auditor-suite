---
type: regex
target:
  source: file
  path: uiaudit.md
pattern: '- Location:[^\n]*Testimonial\.jsx'
match: not_contains
arm: with-only
---

Does not file a finding at the safe decoy src/components/Testimonial.jsx (see ANSWERS.md).
