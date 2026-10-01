# Evals

Each auditor has an eval case that measures whether the skill makes a model find more real defects, with fewer false ones, in the report format, without breaking the read-only contract. The cases run with Claude Code's `claude plugin eval` (Claude Code 2.1.269 or later).

## Layout

```
evals/<skill>/full-audit/
  prompt.md      the user request (it names the report file) and run limits
  case.yaml      the case name and the scaffold hook
  scaffold.sh    copies repo/ into the empty eval workspace and commits it
  ANSWERS.md     the answer key: planted defects, decoys, strengths (never copied into the workspace)
  repo/          the fixture project
  graders/       one file per check
```

The fixture for each skill is a small realistic project with planted defects, one per file, and two decoys: code that looks like a defect but is safe. [docs/AUTHORING.md](../docs/AUTHORING.md) section 6 sets the sizes; the shipped cases have 9 to 11 planted defects. File names never reveal the defects. The example report shipped with each skill audits a different project (`tests/fixtures/<skill>/`), so the skill never sees the answers.

## Graders

| Grader | Type | Checks | Arm |
|---|---|---|---|
| `finds-<slug>` | regex over the report | the report cites the planted defect's file and a line within about three lines of it | both |
| `ignores-<slug>` | regex over the report, `not_contains` | no finding's first cited location is the decoy | with-only |
| `report-written` | regex over the report | the report exists and starts with a heading | both |
| `finding-format` | regex over the report | at least one finding block in the exact format | both |
| `read-only` | tool_used | the run never used the Edit tool on a file other than its report | both |
| `only-report-created` | regex over created files | the report is the only file created | both |
| `skill-used` | tool_used | the Skill tool loaded the auditor | with-only |
| `validator-used` | tool_used | the run ran `check-report.sh` | with-only |

The two read-only graders watch the Edit tool and the list of created files. Neither sees a source file changed through Bash (`sed -i`, a redirect), and a file overwritten with Write is caught only if the runner counts it as created. Read a kept run's transcript when read-only behavior is in doubt.

"With-only" graders describe the plugin's own mechanics; they do not count in the no-plugin arm, so the with-minus-without delta compares like with like.

## Run

```bash
bash scripts/eval.sh secauditor --model claude-haiku-4-5 --runs 3 --max-cost-usd 15 --no-publish
```

`scripts/eval.sh` assembles a temporary plugin from `plugins/<skill>/` plus `evals/<skill>/`, then runs `claude plugin eval` with the scaffold enabled, `--trust-plugin`, `--allow-tools Write Edit Bash` (auditors write and fill in their report and run their bundled read-only scripts), and results under `evals/results/` (git-ignored). Any other `claude plugin eval` option passes through: `--model`, `--runs`, `-j`, `--ablation none`, `--max-cost-usd`, `--keep-temp`, `--json`.

To compare against an older version of a skill, add `--ref` right after the skill name (eval.sh reads it only there). The plugin comes from that git ref; the eval case comes from the working tree:

```bash
bash scripts/eval.sh secauditor --ref v1.0.0 --model claude-haiku-4-5 --runs 3 --ablation none --no-publish
```

Runs call the model with your credentials and count against your plan or API bill. Set `--max-cost-usd`. Pass `--no-publish` to keep the HTML report local. Run `bash scripts/refresh-plugins.sh` first so `plugins/<skill>/` matches the canonical skill.

## Reading results

- **Score** is the fraction of graders passed per run, averaged over runs. **Delta** is the with-plugin score minus the no-plugin score: what the skill contributes on that model.
- Recall graders count a defect as found when the report cites its file and line. ANSWERS.md is the precise key for a manual read of the report.
- A single run is noisy. Use `--runs 3` or more before drawing conclusions, and pin `--model` so a model rollout is not mistaken for a skill regression.

## Results so far

Recorded in the hub [CHANGELOG](../CHANGELOG.md) for each release. At 1.1.0, on Haiku 4.5, the seven skills scored 0.86 to 1.00 against 0.21 to 0.64 with no skill (mean delta +0.53). secauditor, run three times per arm, scored 1.00 on every run against a no-skill mean of 0.60. On Sonnet 5 it scored 1.00 against 0.87 without the skill: the frontier model finds most defects natively, so the skill adds less there.

The first finding that shaped the 1.1.0 design: three 1.0.0 skills (codeauditor, secauditor, dbauditor) made Haiku 4.5 load a long third-person skill, reply that "the audit is running", and end its turn without writing a report. Every 1.1.0 spine now opens by telling the model to do the audit itself, now.

productauditor is new in 1.2.0. Its eval case has not been run yet; per MAINTAINING.md, its scores go in the 1.2.0 hub CHANGELOG entry once the maintainer approves the run.

## Other models and harnesses

`claude plugin eval` runs Claude models. For local models in pi, OpenClaw, or another harness, copy `repo/` into a scratch directory, run the skill there, then check the report by hand: `bash skills/<skill>/scripts/check-report.sh <report>` for format and evidence, and ANSWERS.md for recall and precision.
