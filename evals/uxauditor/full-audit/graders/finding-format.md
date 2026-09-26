---
type: regex
target:
  source: file
  path: uxaudit.md
pattern: '### \[[A-Z][A-Z0-9]*-\d{3}\] .+\n- Severity: (Critical|High|Medium|Low) \| Confidence: (Confirmed|Likely|Suspected) \| Effort: [SML] \| Dimension: [A-Z][A-Z0-9]*\n- Location: `[^`]+:\d+'
---

At least one finding uses the exact block format with a cited path:line.
