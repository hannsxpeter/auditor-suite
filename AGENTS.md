# uxauditor

This repo is a single, tool-agnostic command: **audit a product's UX, user journeys, processes, and workflows, and write `uxaudit.md`, then show the results in chat.**

The source of truth is [`engine/uxauditor.md`](engine/uxauditor.md). `install.sh` renders it into the native skill or slash-command format of every AI coding tool found on the machine (Claude Code, Codex, Gemini, Cursor, opencode, Windsurf, Antigravity, pi). For any tool that does not have a skill or command mechanism but does read an `AGENTS.md` (the broad cross-tool standard), use the portable directive below.

---

## Portable directive (copy into any project's AGENTS.md, or a global AGENTS.md)

Use this for tools that only read `AGENTS.md` and have no skill or command system of their own. It points at the installed engine and restates the essentials so the behavior holds even if the file cannot be opened.

```markdown
## Command: audit UX

When the user asks to "audit the UX", "audit my UX", "review the user experience",
"audit the user journey", "audit the workflow", "score the UX", or "generate uxaudit.md",
run a complete read-only UX audit.

If it is available, follow the full method in the installed engine, in this order of preference:
  ~/.claude/skills/uxauditor/SKILL.md
  ~/.codex/skills/uxauditor/SKILL.md
  ~/.pi/skills/uxauditor.md
  ~/.config/opencode/command/uxauditor.md
(or wherever uxauditor is installed on this machine).

If you cannot open it, follow these essentials:
- Read-only. Modify no source, copy, or design file. The only file you create is uxaudit.md
  at the project root.
- The report is for a reader with no memory of the audit (often another AI agent). Every
  finding must stand alone, cite an exact location (file:line, route, component, or named
  step), and say how to verify the fix.
- Principles: evidence over assertion (no claim without a location; apply the substitution
  test); audit the experienced product, not its description; treat inference from static code
  as a prediction and mark it Suspected with what would confirm it; refuse theater (empty
  states that say only "No data", confirmation dialogs guarding nothing, a hidden "Reject
  all", a progress bar that does not track progress); cluster repeated issues into one
  root-cause finding; verify adversarially and tag each finding Confirmed / Likely /
  Suspected; calibrate to the product's maturity and audience and state the assumed persona
  and context of use; be honest about scope and whether you ran the product; name strengths
  so they are preserved.
- Analyze eleven lenses: Usability and Heuristics (Nielsen's 10); Accessibility and Inclusive
  Design (WCAG 2.2 AA); User Journeys and Flows; Process and Workflow Efficiency (Lean, Theory
  of Constraints); Interaction and Visual Design; Information Architecture and Navigation;
  Content and UX Writing; Onboarding, Conversion and Engagement (AARRR); Forms and Input
  (Baymard); Performance and Responsiveness (Core Web Vitals); Trust, Ethics and Transparency
  (deceptive-design taxonomy).
- Score each lens 0-100 with a justification, weight them (Usability 13, Accessibility 13,
  Journeys 11, Process and Workflow 11, Interaction and Visual 9, Information Architecture 8,
  Content 8, Onboarding and Conversion 8, Forms 7, Performance 6, Trust 6), and compute a
  weighted overall. A single Critical finding (a usability catastrophe, a blocking
  accessibility failure, or a deceptive pattern) caps its dimension at 69 and the overall at
  79 until fixed.
- uxaudit.md sections: Snapshot; Overall score + scorecard; What to fix first; Strengths;
  Systemic patterns; Findings (each with Severity, Confidence, Effort, Location, Evidence,
  Impact, Recommendation, Verify-the-fix, Related); Dimension notes; Remediation plan;
  Scope and limitations; How to use this report (a triage protocol for the acting agent).
- After writing the file, print a chat summary: the headline score and grade, the scorecard
  table, the top three to five fixes, finding counts by severity, and the path ./uxaudit.md.
```

## Working in this repo

- Edit behavior in `engine/uxauditor.md` only; it is the one source of truth. Re-run `./install.sh` to propagate to every tool.
- Do not introduce em dashes, en dashes, or emojis into any file. The repo is plain ASCII and this is enforced in CI.
