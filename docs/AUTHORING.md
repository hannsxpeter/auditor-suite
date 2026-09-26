# Authoring an auditor

How every auditor in this suite is built, so it works for frontier models and for small or local models alike. Read [ARCHITECTURE.md](ARCHITECTURE.md) first for the why; this file is the how. secauditor is the reference implementation: when in doubt, copy its shape.

## Contents

1. Anatomy of a skill
2. SKILL.md (the spine)
3. Dimension files and rule cards
4. assets/: skill.conf, dimensions.tsv, patterns.tsv, surfaces.tsv
5. The example report
6. The eval case
7. Checks before you hand off

## 1. Anatomy of a skill

```
skills/<name>/
  SKILL.md                  the spine: contract, modes, workflow, dimension table, judgment notes
  README.md  CHANGELOG.md  LICENSE
  references/
    protocol.md             shared, vendored from shared/ (never edit the copy)
    example-report.md       a complete report that passes check-report.sh
    facts.md                dated facts with a last-reviewed date (when the domain has any)
    <DIM>.md                one file per dimension: header, cards, also check, paper controls
  scripts/                  shared, vendored from shared/ (never edit the copies)
  assets/
    report-template.md      shared, vendored from shared/
    skill.conf              per-skill names and sentences the scripts use
    dimensions.tsv          the dimensions, weights, and which are conditional
    patterns.tsv            search patterns that turn cards into leads
    surfaces.tsv            probes that decide the conditional dimensions
evals/<name>/full-audit/    the eval case (section 6)
tests/fixtures/<name>/      the small project example-report.md audits
```

Shared files come from `shared/`; `bash scripts/sync-shared.sh` copies them into every skill and `bash scripts/lint.sh shared-sync` proves the copies are identical. A skill-specific file must never reuse a shared file name.

## 2. SKILL.md (the spine)

Keep it under 5,000 tokens (lint: body under 20,000 bytes and 500 lines). It is loaded whole on activation, so it holds only what every run needs; everything else is a reference file read at the step that uses it.

Frontmatter:
- `name`: the directory name.
- `description`: third person, under 1,024 characters. What it audits, the report it writes, when to use it (the words a user would say), that it is read-only, the modes, and the invocation tokens (`/name`, `$name`).
- `allowed-tools: 'Bash(bash "${CLAUDE_SKILL_DIR}/scripts/*)'` exactly, so Claude Code runs the bundled scripts without prompting. Other harnesses ignore it.

Body sections, in this order, following skills/secauditor/SKILL.md:
1. The opening line, verbatim: **You are now running this audit. Do it yourself, starting now, by working through the Workflow below with your own tools.** Nothing runs in the background. The audit is finished only when `check-report.sh` prints OK and you have sent the chat summary. (Without it, Haiku-class models read a third-person skill as a background job, reply "the audit is running", and stop; the 1.0.0 secauditor did exactly that in its eval.) Then one paragraph: what it audits, the report, the chat verdict.
2. **Contract**: read-only rules, what may run, the evidence rule, the domain's hard prohibition (no exploits, no live database, no model calls, no crawling), finish with `score.sh --chat`.
3. **Paths**: the `${CLAUDE_SKILL_DIR}` paragraph, verbatim.
4. **Modes**: full, quick, only=, path. Use this skill's dimension IDs in the example.
5. **Workflow**: the eight-step checklist, verbatim except for the report name and any domain step (for example "trace the data model" in dbauditor's step 3).
6. **Dimensions**: a table with ID, name, weight, "Active when", and the card file. Then one sentence on conditional dimensions and one naming the floor dimensions (or saying there are none).
7. **How to judge**: five to eight bullets of domain judgment a small model would not know: what the audit covers and what belongs to sibling auditors, the domain's principles (source to sink, reachability and blast radius, calibration), the highest-value paper controls. No checklists here; checks live in cards.
8. **Reference files**: every file in references/ and assets/report-template.md, one line each. Lint requires every references/ file name to appear in SKILL.md.

Write for the smallest model you support: numbered steps, one instruction per sentence, exact commands, no "consider" or "as appropriate". Say what to do when something is missing.

## 3. Dimension files and rule cards

One file per dimension: `references/<DIM>.md`. Shape:

```markdown
# AUTHZ: Authorization and Access Control

Weight 18. Always active.            (or: Active when <condition>.)
Owns: <what this dimension judges, as a list of topics>.
Not here: <topics that belong to other dimensions or sibling auditors, with their IDs>.
Standards: <OWASP, WCAG, RFC, docs this dimension cites>.
Read first: <the files to open before the cards: route table, schema, head component>.

## Cards

### AUTHZ-R1 Record read or changed by a request ID with no owner or tenant check (quick)
- Leads: `scan.sh AUTHZ-R1` lists record lookups that take an ID from the request.
- Confirm: <the exact condition that makes it a defect, checkable by reading code>.
- Not a finding if: <the guards, defaults, or designs that make it safe; tell the model where to look>.
- Severity: <Critical when ..., High when ..., otherwise ...>.
- Fix: <the specific change, with a code shape when it helps>.
- Verify the fix: <a test, a request, a count that should become zero>.
- Refs: <CWE, OWASP, WCAG, RFC, doc IDs>

## Also check
- <one-line checks that do not need a full card; findings from them still file under this dimension>

## Paper controls (look protective, protect nothing)
- <controls that exist but do not work: defined but not mounted, configured but not enforced>
```

Card rules:
- Card IDs are `<DIM>-R<n>`, numbered from 1 in the file. Never renumber a published card; retire it by deleting and leave the number unused.
- Tag a card `(quick)` when its Severity can be Critical. Quick mode works only these, so every Critical-class defect of the domain needs a quick card.
- Every card belongs to exactly one dimension. When a defect could live in two dimensions, pick one (the dimension whose code the fix changes), write the card there, and name the other dimension in the other file's "Not here" line. The cards are the ownership map.
- Confirm and Not a finding if must be checkable by reading code. "Consider whether..." is not checkable.
- Severity gives conditions, not adjectives. Use the protocol's four levels.
- Aim for 4 to 8 cards per dimension and 1,000 to 3,000 tokens per file (the 1.1.0 files run 1,500 to 3,500). Put the checks a frontier model would miss (recent platform changes, counterintuitive traps, paper controls) in cards; compress what every model knows into Also check.
- Plain words, short sentences, consistent terms. No em dashes, en dashes, arrows, or emojis (lint enforces).

## 4. assets/

### skill.conf

Shell syntax, sourced by the scripts:

| Key | Example (secauditor) |
|---|---|
| `SKILL_NAME` | `secauditor` |
| `REPORT_FILE` | `secaudit.md` |
| `REPORT_TITLE` | `Security audit` (report heading: "Security audit: <project>") |
| `AUDIT_NOUN` | `security audit` (banner: "Read-only security audit of the code as written") |
| `HEADLINE` | `Security audit complete` (chat headline) |
| `QUICK_HEADLINE` | `Security quick triage complete` |
| `BANNER` | one sentence of what was not done: `No exploits were run and no live system was touched.` |
| `MAP_HINT` | what the Map section must contain, as one instruction (no trailing period) |
| `DOMAIN_RULE` | step 5 of "How to use this report": the domain's fixing rule, one or two sentences |
| `STOP_HINT` | printed when the domain surface probe finds nothing (empty when every codebase qualifies) |

### dimensions.tsv

Tab-separated: `id`, `weight`, `applies` (`always` or `conditional`), `floor` (`yes` or `no`), `name`. Weights are positive integers; they are re-normalized over the active dimensions, so they need not sum to 100. A Critical finding in a floor dimension caps the overall score at 69 instead of 79; mark a dimension as floor only when its Critical findings make the whole project unacceptable no matter what else is good (for example accessibility lockouts in uiauditor).

### patterns.tsv

Tab-separated: `card`, `flags`, `globs`, `regex`. Several rows may share one card; their hits merge.
- `flags`: `-` or letters: `i` ignore case, `q` quick (only on rows of `(quick)` cards).
- `globs`: comma-separated basename globs (`*.py`, `Dockerfile*`) or macros: `@code`, `@web`, `@style`, `@config`, `@sql`, `@infra`, `@ci`, `@docs`, `@shell` (defined in shared/scripts/_lib.sh). `*` alone matches every file.
- `regex`: one extended regular expression that works in both `grep -E` (BSD and GNU) and ripgrep. Use `[[:space:]]`, `[[:alnum:]_]`, `[0-9]`; never `\s`, `\w`, `\d`, `\b`, lookarounds, backreferences, non-greedy quantifiers, or `(?i)` (use the `i` flag). Escape literal `.()[]{}|+?*^$` with a backslash. `bash scripts/lint.sh patterns-valid` compiles every pattern with both tools.
- A pattern finds candidate lines worth reading; it never proves a defect. Prefer patterns that return tens of hits on a real project, not thousands. A card with no reliable pattern gets none; scan.sh then tells the model to read the files the card's Leads line names.

### surfaces.tsv

Tab-separated: `dim`, `label`, `flags`, `globs`, `regex`. A conditional dimension is active when any of its rows matches. Every conditional dimension needs at least one row. The pseudo-dimension `_SURFACE` marks the domain surface itself (for example "a schema, migration, ORM model, or query" for dbauditor); when none of its rows match, inventory.sh tells the model to confirm and stop. Labels are short noun phrases; they appear in the report as "no match for: <label>".

## 5. The example report

`references/example-report.md` is a finished, valid report of a small project in `tests/fixtures/<name>/`. It is the model's format anchor, so keep it short (about 3,000 to 4,000 tokens) and exemplary.

1. Build the fixture: 3 to 6 files, one realistic stack, two to four real defects of this domain, one clean area to show a Strength. It must be different from the eval fixture (section 6) so the example never leaks eval answers.
2. From inside `tests/fixtures/<name>/`, run `bash ../../../skills/<name>/scripts/new-report.sh --mode full`, work the audit exactly as SKILL.md says, including three to five findings (at least one Critical or High Confirmed, one Medium, and one Suspected), a systemic pattern if two findings share a root, strengths, and dimension notes that list every card.
3. Run `score.sh --write` and `check-report.sh` until OK, then move the report to `skills/<name>/references/example-report.md`.
4. `bash scripts/lint.sh examples-valid` re-checks it against the fixture on every run.

## 6. The eval case

Eval cases measure whether the skill makes a model find more real defects, with fewer false ones, in the right format, without breaking read-only. They run with `claude plugin eval` through `bash scripts/eval.sh <name>` (see evals/README.md). Layout:

```
evals/<name>/full-audit/
  prompt.md       frontmatter (max_turns: 150, timeout_seconds: 2400, allowed_tools: [Read, Glob, Grep, Skill, Bash, Write, Edit, TodoWrite]) and a user-style request that names the report file
  case.yaml       schema_version "1.1", name full-audit, tags [full], context.scaffold_script: scaffold.sh
  scaffold.sh     copies repo/ into the empty workspace and commits it (copy secauditor's)
  ANSWERS.md      the answer key: each planted defect (file, line, card, expected severity), each decoy and why it is safe, the strengths
  repo/           the fixture project
  graders/        one file per check (below)
```

Fixture rules:
- A realistic small project (8 to 20 files) in one stack, with 6 to 10 planted defects that the cards cover, at least 3 of them Critical-class.
- One planted defect per file, so a grader can match the file path. File and identifier names must not reveal the defect (no `vuln`, `insecure`, `bad`, `sqli`, `todo_fix`).
- 2 decoys: code that looks like a defect but is guarded (the card's "Not a finding if" applies), each in its own file.
- No real secret formats anywhere (lint and GitHub push protection): never `AKIA...`, `ghp_`, `sk_live_`, `xox`, `AIza`, or PEM private keys. Use plain values such as `jwtSecret: "dev-secret-change-me"`.
- No em dashes, en dashes, arrows, or emojis (lint scans every tracked file).

Graders (copy secauditor's and change names and paths):
- `report-written.md`: regex over the report file for `^# ` (the report exists).
- `finds-<slug>.md`, one per planted defect: regex over the report file for the defect's file name followed by a line within about three lines of the planted line, in any common citation form, for example `orders\.js(:| line | \(line |, line |#L)(9|1[0-5])\b` for a defect on line 12.
- `ignores-<slug>.md`, one per decoy: regex over the report file for ``- Location: `[^`\n]*<decoy file>`` (the finding's first cited location is the decoy) with `match: not_contains` and `arm: with-only`. Checking only the first location keeps a correct finding elsewhere that mentions the decoy file as context from failing the grader.
- `finding-format.md`: regex for one complete finding header plus Severity line.
- `read-only.md`: `tool_used` on `Edit` with `input_match: '"file_path"\s*:\s*"(?![^"]*<report>\.md")'`, `min: 0`, and `max: 0` (editing the report skeleton is expected; editing anything else is not).
- `only-report-created.md`: regex over `files` for any created path other than the report, `match: not_contains`.
- `skill-used.md` and `validator-used.md`: `tool_used` on `Skill` (input matches the skill name) and on `Bash` (input matches `check-report\.sh`), both `arm: with-only`.

## 7. Checks before you hand off

```bash
bash scripts/sync-shared.sh
bash scripts/lint.sh --verbose
```

Then, for a skill you changed:
- `bash skills/<name>/scripts/scan.sh all` from inside `evals/<name>/full-audit/repo/` prints a lead for each planted defect whose card has a pattern.
- `bash skills/<name>/scripts/check-report.sh skills/<name>/references/example-report.md --root tests/fixtures/<name>` prints OK.
- The skill's `CHANGELOG.md` top entry describes the change (AGENTS.md rule).
