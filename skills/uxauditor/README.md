# uxauditor

A read-only **UX audit** skill for AI coding agents, part of the [auditor-suite](../../README.md). It audits the user experience of the product in the current directory from its code, copy, routes, and config, writes a scored, prioritized, self-contained `uxaudit.md` at the project root, and prints the verdict in chat. It never edits source and never runs the product, a browser, or a usability test.

- Claude Code: `/uxauditor`, or ask for "a UX audit", "a usability review", "a user journey audit", "a workflow audit", or "a dark-pattern check".
- Codex: `$uxauditor`.
- Other Agent Skills harnesses: the harness's native skill invocation.

"Experience" is broad: web, mobile, and desktop screens, command-line tools and APIs (developer experience), and the processes behind a product (onboarding, approvals, admin flows, checkout, support paths).

## What it audits

Eleven dimensions, all always active, grounded in Nielsen's heuristics, WCAG 2.2, ISO 9241, the Laws of UX, Baymard form research, Lean and the Theory of Constraints, AARRR, and the deceptive.design taxonomy.

| ID | Dimension | Weight | Rule cards |
|---|---|---|---|
| USE | Usability and Heuristics | 13 | `references/USE.md` |
| ACC | Accessibility and Inclusive Design | 13 | `references/ACC.md` |
| JRN | User Journeys and Flows | 11 | `references/JRN.md` |
| PROC | Process and Workflow Efficiency | 11 | `references/PROC.md` |
| IXD | Interaction and Visual Design | 9 | `references/IXD.md` |
| IA | Information Architecture and Navigation | 8 | `references/IA.md` |
| CNT | Content and UX Writing | 8 | `references/CNT.md` |
| CNV | Onboarding, Conversion and Engagement | 8 | `references/CNV.md` |
| FRM | Forms and Input | 7 | `references/FRM.md` |
| PRF | Performance and Responsiveness | 6 | `references/PRF.md` |
| TRU | Trust, Ethics and Transparency | 6 | `references/TRU.md` |

Boundaries: uiauditor owns how the interface is built (the missing accessible name, the `outline: none`); uxauditor owns the lived consequence (can a keyboard or screen-reader user finish the journey), visual hierarchy, and UX copy. Security depth is secauditor's; code quality is codeauditor's. uxauditor judges how the journey feels and whether it deceives, and keeps whether the activation and funnel events exist; [productauditor](../productauditor) judges whether the product delivers, charges, entitles, and measures what it promises, including whether those events fire once at the true outcome, what cancellation and downgrade do at the billing provider, and whether the charge equals the total shown. The suite map is in [SUITE.md](../../SUITE.md).

## Modes

Text after the skill name picks the mode:

- nothing or `full`: every dimension, every card.
- `quick`: only the 14 Critical-class cards (blocking accessibility failures on core journeys, destructive actions with no guard, actions with no feedback or a false success, broken core journeys, workflow steps the wrong actor can move, and deceptive patterns); no numeric score.
- `only=ACC,TRU`: those dimensions only, with a partial score.
- a path, alone or after a mode (`quick src/checkout`): audit that part of the tree.

## How it works

1. `scripts/inventory.sh` maps the project (stack, size, entry points) and probes for a human-facing or developer-facing surface. With no UI, CLI, API, or modeled workflow, the audit stops and writes nothing.
2. `scripts/new-report.sh` writes the `uxaudit.md` skeleton. The model fills the Snapshot and the experience map: the primary actor, the top jobs, and two to four core journeys traced through the code with `path:line` at every step.
3. For each dimension the model reads its rule cards and runs `scripts/scan.sh <DIM>`, which turns card patterns into `path:line` leads. Each card says how to confirm a defect, when it is not a finding, its severity, the fix, and how to verify the fix; each file ends with "Also check" items and the paper controls that look protective and do nothing.
4. `scripts/score.sh --write` computes every dimension score, the overall score and grade, the caps, "What to fix first", and the remediation buckets from the findings. No model does the arithmetic.
5. `scripts/check-report.sh` validates the report: sections, finding fields, that every cited `path:line` exists and that code quoted in Evidence appears within 6 lines of the first cited location, that every card was worked, and that the generated blocks match the findings.
6. `scripts/score.sh --chat` prints the verdict for the chat.

The audit is static. Findings about runtime behavior (real contrast, timing, whether a displayed count is real, where users hesitate) are marked Likely or Suspected and name what would confirm them: running the product, a Lighthouse or contrast check, analytics, or a usability test.

## Files

```
skills/uxauditor/
  SKILL.md                  the spine: contract, modes, workflow, dimensions, judgment
  references/
    protocol.md             shared finding format, severity, confidence, scoring (vendored)
    example-report.md       a finished report of tests/fixtures/uxauditor that passes check-report.sh
    facts.md                dated standards and legal facts (WCAG 2.2, consent and deceptive-design law,
                            subscription and pricing rules, Core Web Vitals), last reviewed 2026-09-26
    USE.md ... TRU.md       one rule-card file per dimension
  scripts/                  inventory.sh, scan.sh, new-report.sh, score.sh, check-report.sh (vendored, read-only)
  assets/
    report-template.md      the report skeleton (vendored)
    skill.conf              report name, headlines, banner, map instruction, and domain rule
    dimensions.tsv          dimension IDs, weights, conditional and floor flags, and names
    patterns.tsv            search patterns that turn cards into leads
    surfaces.tsv            probes for a UI, CLI, API, or workflow surface
```

Vendored files come from the hub's `shared/` folder through `scripts/sync-shared.sh`; edit them there, never here. The eval case lives in `evals/uxauditor/full-audit/`.

## Install

Use the hub installer (`bash install.sh` from a clone of the auditor-suite repository) or the plugin marketplace (`/plugin install uxauditor@auditor-suite`); see the hub [README](../../README.md#install). A manual install must copy or link the whole skill directory (`SKILL.md`, `references/`, `scripts/`, `assets/`), not just `SKILL.md`.

## License

[MIT](LICENSE).
