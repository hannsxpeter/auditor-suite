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
8. Adding an auditor

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
    <topic>.md              optional domain files a step reads on demand (seoauditor stacks.md, dbauditor nonrelational.md)
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

Keep it under 5,000 tokens (lint skill-structure: the body after the frontmatter at most 20,000 bytes, the whole file at most 500 lines). It is loaded whole on activation, so it holds only what every run needs; everything else is a reference file read at the step that uses it.

Frontmatter:
- `name`: the directory name.
- `description`: third person, under 1,024 characters. What it audits, the report it writes, when to use it (the words a user would say), that it is read-only, the modes, and the invocation tokens (`/name`, `$name`).
- `allowed-tools: 'Bash(bash "${CLAUDE_SKILL_DIR}/scripts/*)'` exactly, so Claude Code runs the bundled scripts without prompting. Other harnesses ignore it. Lint does not check this line, so copy it from a sibling; without it, every script call in Claude Code waits for a permission prompt.

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
- Tag a card `(quick)` when its Severity can be Critical. Quick mode works only these, so every Critical-class defect of the domain needs a quick card. Lint skill-structure enforces this: a card whose Severity can be Critical must be tagged `(quick)`, and a `(quick)` card's Severity must name Critical or use `as <CARD>` (for example "as AUTHZ-R1"). Lint reads the Severity line clause by clause (split at `;`, `,`, and `.`): a clause that names Critical with no "never" or "not" before it makes the card Critical-class. Each `patterns.tsv` row of a `(quick)` card needs flag `q`, and only those rows may have it.
- Every card belongs to exactly one dimension. When a defect could live in two dimensions, pick one (the dimension whose code the fix changes), write the card there, and name the other dimension in the other file's "Not here" line. The cards are the ownership map.
- Confirm and Not a finding if must be checkable by reading code. "Consider whether..." is not checkable.
- Severity gives conditions, not adjectives. Use the protocol's four levels.
- Aim for 4 to 8 cards per dimension and 1,000 to 3,000 tokens per file. The shipped files run 1,150 to 5,000 tokens, most of them 1,500 to 3,500; the few above 3,500 (uiauditor A11Y and productauditor CLM, ENT, BILL, and MET) hold seven to eleven cards each, most of them quick cards whose Not a finding if lines must stay complete. Put the checks a frontier model would miss (recent platform changes, counterintuitive traps, paper controls) in cards; compress what every model knows into Also check.
- Plain words, short sentences, consistent terms. No em dashes, en dashes, arrows, box-drawing characters, symbols, or emojis (lint enforces).

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
| `SCAN_SKIP_RE` | optional, unset in secauditor; see below (productauditor sets it to skip tests, stories, fixtures, mocks, agent planning folders, archived docs, and lockfiles) |

Every key but `STOP_HINT` and `SCAN_SKIP_RE` is required and non-empty, and `REPORT_FILE` must be `<name without "auditor">audit.md` (lint skill-structure). Write the double-quoted values with no double quote, `$`, or backtick inside, so the file is safe to source.

`SCAN_SKIP_RE` drops files from this auditor's scans only. When it is set, `scan.sh` shows no leads in the paths it matches, `inventory.sh` and `new-report.sh` probe no surfaces there, and `inventory.sh` prints how many files it skipped, so Scope and limitations can say so. `check-report.sh` ignores it: a finding may still cite a skipped file the model opened on purpose. The rules:
- One line, single-quoted, so the shell never expands a `$` or a backslash in it: `SCAN_SKIP_RE='(^|/)(test|tests|fixtures)/|(^|/)package-lock[.]json$'`.
- An extended regular expression that awk accepts (lint skill-structure checks both), matched against each path relative to the project root. Write a literal dot as `[.]`, like `AS_EXCLUDE_RE` in `shared/scripts/_lib.sh`, and avoid `[[:class:]]` brackets, which older mawk builds reject.
- The scripts pass it to awk through ENVIRON (`as_match_lines`), never `awk -v`, so its backslashes survive on every awk.
- Skip only files that are never this domain's subject. codeauditor reads tests (TEST) and lockfiles (DEP), and secauditor reads lockfiles (SUPPLY), so neither sets it, and it is per skill rather than global.

### dimensions.tsv

Tab-separated: `id`, `weight`, `applies` (`always` or `conditional`), `floor` (`yes` or `no`), `name`. Weights are positive integers; they are re-normalized over the active dimensions, so they need not sum to 100. A Critical finding in a floor dimension caps the overall score at 69 instead of 79; mark a dimension as floor only when its Critical findings make the whole project unacceptable no matter what else is good (for example accessibility lockouts in uiauditor).

### patterns.tsv

Tab-separated: `card`, `flags`, `globs`, `regex`. Several rows may share one card; their hits merge.
- `flags`: `-` or letters: `i` ignore case, `q` quick (only on rows of `(quick)` cards).
- `globs`: comma-separated basename globs (`*.py`, `Dockerfile*`) or macros: `@code`, `@web`, `@style`, `@config`, `@sql`, `@infra`, `@ci`, `@docs`, `@shell` (defined in shared/scripts/_lib.sh). `*` alone matches every file. A mistyped macro (`@cdoe`) is not an error: it matches no file, and the card silently gets no leads, so check the spelling.
- `regex`: one extended regular expression that works in both `grep -E` (BSD and GNU) and ripgrep. Use `[[:space:]]`, `[[:alnum:]_]`, `[0-9]`; never `\s`, `\w`, `\d`, `\b`, lookarounds, backreferences, non-greedy quantifiers, or `(?i)` (use the `i` flag). Escape literal `.()[]{}|+?*^$` with a backslash. `bash scripts/lint.sh patterns-valid` compiles every pattern with both tools.
- A pattern finds candidate lines worth reading; it never proves a defect. Prefer patterns that return tens of hits on a real project, not thousands. A card with no reliable pattern gets none; scan.sh then tells the model to read the files the card's Leads line names.
- scan.sh shows at most 12 leads per card (`--max N` changes the cap), in path and line order. Past the cap it picks them round-robin across files in path order (the first lead of each file, then the second of each, until the cap) and prints a closing line that counts the leads left out. So one noisy file cannot hide the others, but when more files match than the cap, the files late in path order show no lead: keep patterns narrow enough that a real project stays near the cap.

### surfaces.tsv

Tab-separated: `dim`, `label`, `flags`, `globs`, `regex`. A conditional dimension is active when any of its rows matches. Every conditional dimension needs at least one row. The pseudo-dimension `_SURFACE` marks the domain surface itself (for example "a schema, migration, ORM model, or query" for dbauditor); when none of its rows match, inventory.sh tells the model to confirm and stop. Labels are short noun phrases; they appear in the report as "no match for: <label>".

## 5. The example report

`references/example-report.md` is a finished, valid report of a small project in `tests/fixtures/<name>/`. It is the model's format anchor, so keep it short (about 3,000 to 4,000 tokens; the shipped ones run 3,050 to 4,330) and exemplary.

1. Build the fixture: 3 to 6 source files (static assets such as images aside), one realistic stack, two to four real defects of this domain, one clean area to show a Strength. It must be different from the eval fixture (section 6) so the example never leaks eval answers.
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
- A realistic small project (8 to 20 files) in one stack, with 6 to 12 planted defects that the cards cover, at least 3 of them Critical-class. The shipped cases have 9 to 11. `lint.sh evals-structure` requires at least 5 `finds-*` graders and at least 1 `ignores-*` grader, and that `prompt.md` names this skill's report and neither it nor any grader names another auditor's `*audit.md`.
- One planted defect per file, so a grader can match the file path. File and identifier names must not reveal the defect (no `vuln`, `insecure`, `bad`, `sqli`, `todo_fix`).
- 2 decoys: code that looks like a defect but is guarded (the card's "Not a finding if" applies), each in its own file.
- No real secret formats anywhere: never `AKIA...`, `ghp_`, `sk_live_`, `xox`, `AIza`, or PEM private keys. GitHub push protection rejects a push that holds one; the lint does not look for them. Use plain values such as `jwtSecret: "dev-secret-change-me"`.
- No em dashes, en dashes, arrows, box-drawing characters, symbols, or emojis (lint scans tracked files and untracked files that git does not ignore).

Graders (copy secauditor's and change names and paths):
- `report-written.md`: regex over the report file for `^# ` (the report exists).
- `finds-<slug>.md`, one per planted defect: regex over the report file for the defect's file name followed by a line within about three lines of the planted line, in any common citation form, for example `orders\.js(:| line | \(line |, line |#L)(9|1[0-5])\b` for a defect on line 12.
- `ignores-<slug>.md`, one per decoy: regex over the report file for ``- Location: `[^`\n]*<decoy file>`` (the finding's first cited location is the decoy) with `match: not_contains` and `arm: with-only`. Checking only the first location keeps a correct finding elsewhere that mentions the decoy file as context from failing the grader.
- `finding-format.md`: regex for one complete finding header plus Severity line.
- `read-only.md`: `tool_used` on `Edit` with `input_match: '"file_path"\s*:\s*"(?![^"]*<report>\.md")'`, `min: 0`, and `max: 0` (editing the report skeleton is expected; editing anything else is not). It sees only the Edit tool: a change made through Bash or by overwriting a file with Write is not graded, so read a kept run's transcript when in doubt.
- `only-report-created.md`: regex over `files` for any created path other than the report, `match: not_contains`.
- `skill-used.md` and `validator-used.md`: `tool_used` on `Skill` (input matches the skill name) and on `Bash` (input matches `check-report\.sh`), both `arm: with-only`.

## 7. Checks before you hand off

```bash
bash scripts/refresh-plugins.sh
bash scripts/lint.sh --verbose
bash tests/run.sh
bash tests/lint-selftest.sh
```

`refresh-plugins.sh` runs `sync-shared.sh` first, then vendors the payload into `plugins/`. The lint runs `tests/run.sh` and `tests/install.sh` itself (check `script-tests`); `tests/lint-selftest.sh` proves eight of the thirteen lint checks still fail on an injected violation. Then, for a skill you changed:
- `(cd evals/<name>/full-audit/repo && bash ../../../../skills/<name>/scripts/scan.sh all --max 50)`, pasted from the repo root, prints a lead for each planted defect whose card has a pattern.
- `bash skills/<name>/scripts/check-report.sh skills/<name>/references/example-report.md --root tests/fixtures/<name>` prints OK.
- The skill's `CHANGELOG.md` top entry describes the change (AGENTS.md rule).

## 8. Adding an auditor

There is no list of skill names to edit. `scripts/lint.sh`, `scripts/sync-shared.sh`, and `scripts/refresh-plugins.sh` take the roster from the directories under `skills/` (`scripts/_skills.sh`), and `install.sh` and `uninstall.sh` install every `skills/<name>/` that holds a `SKILL.md`. Every directory under `skills/` is on the roster, so a half-built skill fails the lint instead of dropping out of it.

1. Pick a name: lower-case letters, digits, and hyphens, starting with a letter and ending in `auditor`. suite-registry fails a directory under `skills/` whose name has another character or starts with a digit or hyphen (`scripts/_skills.sh` keeps it off the roster). The report is `<name without "auditor">audit.md`. Pick dimension IDs; they need not be unique across the suite, but avoid one a sibling uses for a different topic.
2. Create `skills/<name>/` with `SKILL.md` (section 2), `README.md`, `CHANGELOG.md`, `LICENSE`, the dimension files (section 3), and `assets/skill.conf`, `dimensions.tsv`, `patterns.tsv`, and `surfaces.tsv` (section 4).
3. Add the report name to the `(code|sec|...)audit[.]md$` group in `AS_EXCLUDE_RE` in `shared/scripts/_lib.sh`, so no auditor scans an earlier report as source. The root `.gitignore` already ignores `/*audit.md`.
4. Run `bash scripts/refresh-plugins.sh`. It runs `sync-shared.sh`, which copies `protocol.md`, `report-template.md`, and the scripts into the new skill, then vendors the payload into `plugins/<name>/skills/<name>/`.
5. Write `plugins/<name>/.claude-plugin/plugin.json` by hand, copied from a sibling: the name, the `SKILL.md` description byte for byte, the version in `VERSION`, homepage, repository, and keywords. Add the marketplace entry (source `./plugins/<name>`, the same description) and the meta plugin dependency in `plugins/auditor-suite/.claude-plugin/plugin.json`, and update the counts in their descriptions.
6. Build the example fixture and report (section 5) and the eval case (section 6).
7. Add a table row to README.md (its Dimensions column must equal the rows of `dimensions.tsv`) and to SUITE.md (a row starting `| **<name>** |`), with boundary bullets for every sibling whose topics touch the new auditor. Add a "Not here" line to each sibling dimension file that hands a topic to the new auditor, with that sibling's CHANGELOG entry. Update the auditor count in README.md and SUITE.md prose and the list in AGENTS.md; no check reads them.
8. Run `bash scripts/lint.sh suite-registry`. It names every place the new auditor must still appear: the vendored plugin, the marketplace, the meta plugin, `evals/<name>/`, `tests/fixtures/<name>/`, the README and SUITE.md rows, the report exclusion, and the ignore rule. Repeat until it passes. `plugin-sync` then checks the manifest itself.
9. A new auditor is a minor release train. Bump the version everywhere MAINTAINING.md lists, add the hub CHANGELOG entry, then run the full checks in section 7.
