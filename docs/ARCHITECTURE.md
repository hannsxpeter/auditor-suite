# Architecture

Why the auditors are built the way they are, and how the pieces fit. For the step-by-step authoring rules, see [AUTHORING.md](AUTHORING.md).

## Contents

1. The problem this design solves
2. The principle
3. The pieces
4. How a run flows
5. Scoring
6. The shared core and how it stays in sync
7. Packaging and install
8. Evaluation
9. Context budget by mode
10. Trade-offs we accepted

## 1. The problem this design solves

Through 1.0.0 each auditor was one large SKILL.md (about 5,000 to 18,000 tokens) of domain checklists, principles, and report rules, loaded whole on activation. That shape suited frontier models, which need it least: they already know OWASP, WCAG, and N+1 queries. It failed smaller and local models in predictable ways:

- The file was far over the Agent Skills recommendation of under 5,000 tokens for the body, so small models skimmed it and dropped the middle.
- Checklists said what is wrong but not how to find it.
- The hardest judgment was left unchecked: "score each dimension 0 to 100 on adequacy", weight re-normalization by hand, ownership maps with split rules, and self-attested quality gates.
- Nothing verified that a cited `file:line` exists, the worst failure for a report meant as a work order for another agent.
- There was no worked example of a finished report.
- The seven files had drifted apart (see [DRIFT.md](DRIFT.md)).

## 2. The principle

Frontier models bring the knowledge. Every model needs the contract. Small models need the judgment turned into procedure.

So: keep the contract in the always-loaded file, move knowledge to files read at the step that needs them, put mechanical work in scripts, turn self-checks into a validator loop, and prove the result with evals on the models we care about. This follows the Agent Skills specification (progressive disclosure: metadata, a short body, resources on demand) and Anthropic's skill-authoring guidance (low freedom for fragile steps, utility scripts over generated code, validate-fix-repeat loops, test on Haiku, Sonnet, and Opus).

## 3. The pieces

| Piece | Where | Loaded or run | What it does |
|---|---|---|---|
| Spine | `SKILL.md` | loaded on activation (about 2,000 to 3,800 tokens) | contract, modes, an eight-step workflow checklist, the dimension table, domain judgment, the reference list |
| Protocol | `references/protocol.md` (shared) | read once per run | evidence rules, finding format with a filled example, severity, confidence, ownership, refutation, clustering, scoring, buckets, modes, finishing |
| Rule cards | `references/<DIM>.md` | read before that dimension's pass | per defect: leads, confirm, not a finding if, severity, fix, verify, refs; plus also-check lines and paper controls |
| Example report | `references/example-report.md` | read once | a complete report that passes the validator, as a format anchor |
| Facts | `references/facts.md` | read when citing a dated fact (seoauditor reads it in workflow step 2) | standards IDs, platform changes, and incidents with a review date |
| Inventory | `scripts/inventory.sh` | run first | languages, manifests, frameworks, entry points, size and read strategy, and which conditional dimensions have a surface |
| Scan | `scripts/scan.sh` | run per dimension | turns card patterns into `path:line` leads; ripgrep when present, grep otherwise, over the same file list; at most 12 leads per card (`--max N`), picked round-robin across files in path order and counted when some are left out |
| Report skeleton | `scripts/new-report.sh` | run once | writes the report from the template with the date, commit, mode, and active dimensions filled |
| Scorer | `scripts/score.sh` | run after findings | computes scores, "What to fix first", the remediation buckets, and the chat summary |
| Validator | `scripts/check-report.sh` | run until OK | layout, placeholders, fields, cited paths and lines, quoted evidence (a span of 6 or more characters) within 6 lines of the first cited location, the dimension lists (every dimension listed exactly once, each not-applicable one with a reason in parentheses), card coverage, generated blocks |
| Tables | `assets/*.tsv`, `assets/skill.conf` | read by scripts | dimensions and weights, search patterns, surface probes, names and sentences, and an optional per-skill scan skip (`SCAN_SKIP_RE`) |
| Template | `assets/report-template.md` (shared) | read by new-report.sh | the uniform report layout |

The report is also the working memory: it is created after inventory, findings are appended after each dimension, and the scorer fills the generated blocks at the end. It is the one file an audit may write, so a small model never has to hold forty findings in context.

## 4. How a run flows

1. `inventory.sh` maps the project and prints the suggested active dimensions, or tells the model to stop when there is nothing to audit.
2. The model reads the protocol and the example report.
3. `new-report.sh --mode <mode>` writes the skeleton; the model fills Snapshot and Map.
4. For each active dimension: read the card file, run `scan.sh <DIM>`, confirm or refute every lead by reading the code, append findings, and list every card worked under the dimension's notes.
5. The model groups repeats into systemic patterns and writes strengths and scope.
6. `score.sh --write` fills the scorecard, "What to fix first", and the remediation plan; the model writes the verdict and calibration lines.
7. `check-report.sh` lists problems; the model fixes and reruns until it prints OK.
8. `score.sh --chat` prints the summary the model sends as its final message.

The model does the judgment: which leads are real, severity, confidence, the words. The scripts do the bookkeeping. Nothing in this flow edits the audited project, runs it, or calls a network service.

## 5. Scoring

Scores are computed, never estimated, so the same findings always produce the same score and re-runs measure progress.

- Each finding deducts from its dimension: Critical 25, High 10, Medium 3, Low 1. Suspected findings deduct half. Lows deduct at most 10 per dimension.
- Dimension score = 100 minus deductions, rounded down, not below 0. One Critical (not Suspected) caps the dimension at 69; two or more cap it at 59.
- Overall = the weighted mean over scored dimensions, weights re-normalized, rounded to nearest. One Critical anywhere caps the overall at 79; two or more, or one in a floor dimension, cap it at 69.
- Not-applicable and not-assessed dimensions are excluded. `quick` mode is not scored; `only=` is labeled partial.
- A dimension with no findings reaches 100 only if its notes list every card worked, which check-report.sh enforces.

The rules live in `shared/references/protocol.md` (for the model) and `shared/scripts/_score.awk` (for the machine); `tests/run.sh` pins the arithmetic.

## 6. The shared core and how it stays in sync

`shared/` holds the only editable copy of the protocol, the template, and the scripts. `scripts/sync-shared.sh` copies them into every skill so each skill works standalone (from a symlinked install or a plugin cache). `bash scripts/lint.sh shared-sync` fails when any copy differs. Skill-specific content lives only in the skill: the spine, the cards, the example, the facts, and the tables in `assets/`.

The roster is the set of directories under `skills/` (`scripts/_skills.sh`). The lint, sync, and refresh scripts read it from there, and the installer installs every skill folder that holds a `SKILL.md`, so no script carries a list of skill names. `bash scripts/lint.sh suite-registry` checks that every other place that names the auditors agrees with that set: `plugins/`, the marketplace, the meta plugin, `evals/`, `tests/fixtures/`, the README and SUITE.md tables, the report exclusion in `AS_EXCLUDE_RE`, and the ignore rule. Prose is kept by hand: no check reads the auditor count in README.md, SUITE.md, and the marketplace and meta plugin descriptions, or the list of auditors in AGENTS.md.

The shared scripts must behave the same on every platform a user may have: macOS `/bin/bash` 3.2 with BSD awk and grep, and Linux with bash 5 and mawk or gawk. Every regex reaches awk through ENVIRON (`as_match_lines` in `_lib.sh`), never `awk -v`, because BSD awk and gawk strip backslashes from `-v` values. In 1.1.0 that turned the exclusion `\.min\.js$` into `.min.js$`, which silently dropped `admin.js` and similar files from every audit on macOS and gawk. CI runs the lint, which includes the script tests, and the lint self-test (`tests/lint-selftest.sh`) on macOS and on Ubuntu, then the lint again on Ubuntu with awk set to mawk, then gawk.

## 7. Packaging and install

- `install.sh` symlinks each skill's runtime payload (`SKILL.md`, `references/`, `scripts/`, `assets/`) into every detected harness for every `skills/<skill-name>/` that holds a `SKILL.md`. It finds Claude Code at `$CLAUDE_CONFIG_DIR` or `~/.claude`, Codex at `$CODEX_HOME` or `~/.codex`, Cursor at `~/.cursor`, and writes the neutral `~/.agents/skills/` path when `~/.agents`, pi, or OpenClaw is present. It never moves or deletes anything inside the clone, however its path is spelled: a by-hand folder link into the clone and a dangling link are replaced, and only the link is removed. An existing skill folder that holds real files, or a link to somewhere else, is moved whole to `~/.auditor-suite-backups/<platform>/<skill-name>-<timestamp>/`, outside every harness skills directory, so it cannot load as a duplicate skill. It exits non-zero when any link fails.
- `uninstall.sh` removes those links and a by-hand folder link, and leaves the clone and the backups alone.
- `tests/install.sh` runs both scripts against a throwaway hub and a temporary HOME (a path with a space included), and the lint runs it through `script-tests`.
- `scripts/refresh-plugins.sh` runs sync-shared and copies the same payload into `plugins/<skill>/skills/<skill>/`; `lint.sh plugin-sync` verifies it byte for byte. It never writes a manifest: each `plugins/<skill>/.claude-plugin/plugin.json` and the marketplace are edited by hand, and `plugin-sync` checks that each is valid JSON with the right name, version, source, and description.
- In Claude Code, `${CLAUDE_SKILL_DIR}` in the spine is replaced with the skill's path, and the `allowed-tools` line pre-approves running the bundled scripts. Other harnesses show the literal text; the spine tells the model to substitute the folder that contains SKILL.md.

## 8. Evaluation

Each skill has an eval case under `evals/<skill>/full-audit/`: a small realistic project with planted defects (one per file; [AUTHORING.md](AUTHORING.md) section 6 sets the range), two decoys that look like defects but are safe, an answer key, and graders for recall (the report cites each planted defect's file and line), precision (no finding at a decoy), format, read-only behavior (no Edit tool call outside the report, and no file created besides it), and whether the skill and validator ran. The read-only graders do not see a change made through Bash or by overwriting a file with Write. `bash scripts/eval.sh <skill>` runs it through `claude plugin eval`, by default with a no-plugin baseline arm, so the reported delta is what the skill contributes on that model. `--ref v1.0.0` evaluates an older version for comparison. See [evals/README.md](../evals/README.md).

## 9. Context budget by mode

Measured at 1.2.0, in tokens (bytes divided by four, rounded down), for the instruction text a run reads; the code, scan output, and report come on top. The 1.0.0 column is the single-file skill each auditor replaced.

| Skill | 1.0.0 SKILL.md | Spine | Protocol | Example | All cards | Quick cards (text) |
|---|---|---|---|---|---|---|
| codeauditor | 5,198 | 2,210 | 2,434 | 3,111 | 55 cards, 19,556 | 13, 4,444 |
| secauditor | 12,334 | 2,021 | 2,434 | 3,057 | 68 cards, 19,869 | 35, 8,232 |
| dbauditor | 15,548 | 2,810 | 2,434 | 3,600 | 71 cards, 28,017 | 21, 7,975 |
| llmauditor | 15,867 | 2,706 | 2,434 | 3,933 | 69 cards, 21,392 | 10, 3,124 |
| seoauditor | 17,933 | 3,227 | 2,434 | 3,545 | 74 cards, 23,730 | 14, 4,161 |
| uiauditor | 15,431 | 3,105 | 2,434 | 3,456 | 60 cards, 22,365 | 14, 4,933 |
| uxauditor | 8,729 | 2,668 | 2,434 | 3,362 | 56 cards, 21,155 | 14, 4,537 |
| productauditor | none (new) | 3,799 | 2,434 | 4,324 | 58 cards, 30,529 | 17, 8,498 |

So a run reads about 7,500 to 10,600 tokens before its first dimension (spine, protocol, example). seoauditor also reads `references/facts.md` (4,041) and the `references/stacks.md` section for the detected stack (about 150 to 550) and, when a host is detected, the hosting section (about 370) before its first dimension, about 13,400 to 14,200 in all; dbauditor reads `references/nonrelational.md` (1,448) only when the project has a non-relational store. Then:

- `quick`: the quick cards through `scan.sh quick --show-cards`, 3,100 to 8,500 more. That command prints the quick cards of every dimension, inactive ones included, so this is the whole quick set.
- `only=ONE`: one dimension file, 1,150 to 5,000 more (most files are 1,500 to 3,500).
- `full`: every active dimension file, up to 19,500 to 30,500 more when every dimension applies.

A full run therefore reads more instruction text in total than 1.0.0 loaded up front, but it arrives in stages: each card file lands right before the pass that uses it, where a small model attends best, instead of tens of thousands of tokens earlier, and no card file for an inactive dimension or another stack loads at all. The eval results in the hub CHANGELOG are the evidence that the trade pays: on Haiku 4.5, three 1.0.0 skills (codeauditor, secauditor, dbauditor) wrote no report at all, and the other four never used the report format. For models with small context windows, run `quick` first, then `only=` one or two dimensions at a time.

productauditor has the largest card set: its three money dimensions (CLM, ENT, and BILL, about 4,700 to 5,000 each) hold 16 of its 17 quick cards, whose Not a finding if lines and boundary hand-offs must stay complete. On a small model, run its `quick` mode, then `only=ENT,BILL`, then the rest.

## 10. Trade-offs we accepted

- Scripts add maintenance and bash 3.2 constraints. They are small, share one parser, and are covered by `tests/run.sh`, which CI runs under macOS `/bin/bash` 3.2 and BSD awk and under mawk and gawk on Ubuntu.
- Search patterns go stale or get noisy. They only produce leads; every finding still needs a confirming read, and each card names the files to read even without hits. A noisy card shows 12 leads by default: past that cap, `scan.sh` takes the first lead of each file in path order, then the second of each, and so on, so one file full of hits cannot crowd out the files after it, and a closing line counts the leads left out. When more than 12 files match, the files late in path order show none; `--max N` or a path argument shows them. A domain whose words fill tests, fixtures, and lockfiles (productauditor) skips them with `SCAN_SKIP_RE`, per skill, because codeauditor and secauditor must read those files.
- Pattern-first audits can narrow attention. The spine requires reading entry points and each card's named files regardless of hits, and "Also check" lines cover what patterns cannot.
- Deterministic scoring can feel mechanical. It is what makes scores comparable across runs and models; judgment still sets severity and confidence.
- Harnesses differ in how they expose a skill's folder and run scripts. Claude Code gets exact paths; elsewhere the model substitutes the folder, and the scripts locate their own assets from their location.
