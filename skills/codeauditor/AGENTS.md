# codeauditor

This repo is a single, tool-agnostic command: **audit a codebase and write `codeaudit.md`, then show the results in chat.**

The source of truth is [`engine/codeauditor.md`](engine/codeauditor.md). `install.sh` renders it into the native skill or slash-command format of every AI coding tool found on the machine (Claude Code, Codex, Gemini, Cursor, opencode, Windsurf, Antigravity). For any tool that does not have a skill or command mechanism but does read an `AGENTS.md` (the broad cross-tool standard), use the portable directive below.

---

## Portable directive (copy into any project's AGENTS.md, or a global AGENTS.md)

Use this for tools that only read `AGENTS.md` and have no skill or command system of their own. It points at the installed engine and restates the essentials so the behavior holds even if the file cannot be opened.

```markdown
## Command: audit codebase

When the user asks to "audit the codebase", "audit codebase", "do a full code analysis",
"score the code", or "generate codeaudit.md", run a complete read-only audit.

If it is available, follow the full method in the installed engine, in this order of preference:
  ~/.claude/skills/codeauditor/SKILL.md
  ~/.codex/skills/codeauditor/SKILL.md
  ~/.pi/skills/codeauditor.md
  ~/.config/opencode/command/codeauditor.md
(or wherever codeauditor is installed on this machine).

If you cannot open it, follow these essentials:
- Read-only. Modify no source. The only file you create is codeaudit.md at the codebase root.
- The report is for a reader with no memory of the audit (often another AI agent). Every
  finding must stand alone, cite exact file:line locations, and say how to verify the fix.
- Principles: evidence over assertion (no claim without file:line; apply the substitution
  test); read the code, not the comments; refuse theater (find validators never called,
  middleware not applied, tests that assert nothing, health checks that check nothing);
  cluster repeated issues into one root-cause finding; verify adversarially and tag each
  finding Confirmed / Likely / Suspected; calibrate to the project's maturity; be honest
  about scope; name strengths so they are preserved.
- Analyze nine lenses: Security, Architecture and Design, Code Quality and Maintainability,
  Testing and Verification, Error Handling and Resilience, Performance and Efficiency,
  Dependencies and Supply Chain, Documentation and Drift, Observability and Operability.
- Score each lens 0-100 with a justification, weight them (Security 20, Architecture 15,
  Code Quality 15, Testing 15, Error Handling 10, Performance 8, Dependencies 7,
  Documentation 5, Observability 5), and compute a weighted overall. A single Critical
  finding caps its dimension at 69 and the overall at 79 until fixed.
- codeaudit.md sections: Snapshot; Overall score + scorecard; What to fix first; Strengths;
  Systemic patterns; Findings (each with Severity, Confidence, Effort, Location, Evidence,
  Impact, Recommendation, Verify-the-fix, Related); Dimension notes; Remediation plan;
  Scope and limitations; How to use this report (a triage protocol for the acting agent).
- After writing the file, print a chat summary: the headline score and grade, the scorecard
  table, the top three to five fixes, finding counts by severity, and the path ./codeaudit.md.
```

## Working in this repo

- Edit behavior in `engine/codeauditor.md` only; it is the one source of truth. Re-run `./install.sh` to propagate to every tool.
- Do not introduce em dashes, en dashes, or emojis into any file (see the existing global rules).
