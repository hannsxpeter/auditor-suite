# Drift log

Inconsistencies found across the seven auditors and the hub tooling at auditor-suite 1.0.0, found in the 2026-09-26 review, and how 1.1.0 resolved each one. Drift matters more than it looks: a small model follows whichever instruction it read last, so two files that disagree produce two behaviors.

How drift is prevented from 1.1.0 on: one shared copy of the protocol, report template, and scripts in `shared/` with a byte-identity lint (`shared-sync`); one report format enforced by `check-report.sh`; one scoring implementation (`_score.awk`) pinned by `tests/run.sh`; descriptions checked across SKILL.md, plugin manifests, and the marketplace (`plugin-sync`); and the full runtime payload checked in plugins (`plugin-sync`).

Sections 1 to 8 cover that 1.1.0 work. Section 9 covers the drift between the 1.1.0 docs and the 1.1.0 tooling, found while adding productauditor, and how 1.2.0 resolved it.

## Contents

1. Contract drift
2. Scoring and prioritization drift
3. Report format drift
4. Frontmatter and invocation drift
5. Packaging and install drift
6. Documentation drift
7. Overlaps inside each auditor
8. Stale facts
9. Docs against tooling (resolved in 1.2.0)

## 1. Contract drift

| Where | Drift | Resolution |
|---|---|---|
| uxauditor Phase 0 and Notes | Told the model to run the product and walk flows ("If you can, walk the core flows"; "Prefer running the product where you can"), contradicting the suite contract that auditors never run the live system. | uxauditor is static like every auditor; runtime behavior is inferred from code and marked Likely or Suspected with what would confirm it. |
| All seven Notes sections | "Shell commands only for inspection" with no word on the auditor's own tools. | The contract (SUITE.md, each spine) explicitly allows the bundled read-only scripts and names the only two that write, and only the report. |

## 2. Scoring and prioritization drift

| Where | Drift | Resolution |
|---|---|---|
| Six of seven skills | Only uiauditor defined what two Critical findings do (dimension held at 59, overall at 69), that caps apply after weighting with the lowest cap winning, and that Suspected findings never cap. The other six were silent, so two runs could cap differently. | uiauditor's rules apply to every auditor, implemented once in `score.sh`. |
| dbauditor, llmauditor, seoauditor vs uiauditor | Floors were numeric in uiauditor (accessibility Critical caps the overall at 69) but only "caps the overall grade" in the other three. | Floor dimensions are flagged in each skill's `dimensions.tsv`; a Critical in a floor dimension caps the overall at 69 everywhere. |
| All seven | "Score each dimension 0 to 100 on adequacy" left every number to judgment, so re-runs were not comparable. | Scores are computed from the findings (protocol section 8). |
| codeauditor, uxauditor, dbauditor | Allowed discretionary re-weighting ("re-weight only when the project type warrants it"; dbauditor's "re-weight SCALE up when growth signals are strong"). The others fixed weights. | No discretionary re-weighting. Only conditional re-normalization over active dimensions, done by the script. |
| All seven | The remediation buckets did not cover every finding: Medium findings fell in no bucket, and a Likely High or Critical finding with effort S was neither a Quick win (which required Confirmed) nor Plan now (which required effort M or L). | Five buckets partition every finding: Quick wins, Plan now, Verify first, Schedule (Medium), Backlog (Low); Quick wins and Plan now exclude only Suspected findings. |
| uiauditor | Asked the model to multiply weights by 100/108 or 100/117 and display them to one decimal. | The script re-normalizes and displays weights. |

## 3. Report format drift

| Where | Drift | Resolution |
|---|---|---|
| codeauditor, uxauditor | No Map section (the other five had one), so reports had 11 or 12 sections. | Every report has the same 12 sections; `check-report.sh` enforces order and presence. |
| codeauditor, uxauditor | No References field in the finding block (the other five required one). | Every finding has the same 8 fields. |
| dbauditor, llmauditor, seoauditor, uiauditor | An `Owner: <dimension or "this">` field (with an unclosed quote in dbauditor's template, which models copy literally). | The Owner field is gone: the finding ID prefix is the owning dimension, and cross-references go in Related. |
| All seven | The "How to use this report" protocol had 7 steps in six skills and 8 in seoauditor, with domain variants inline. | One 8-step protocol from the shared template, with one domain rule slot per skill. |
| All seven | Nothing checked that a cited `file:line` existed or matched its claim. | Evidence must quote the code at the first cited location; `check-report.sh` verifies paths, line ranges, and the quote. |

## 4. Frontmatter and invocation drift

| Where | Drift | Resolution |
|---|---|---|
| secauditor | The description did not name the invocation tokens (`/secauditor`, `$secauditor`); the other six did. | Every description names what, when, read-only, modes, and invocation. |
| codeauditor, secauditor, uxauditor | No invocation block telling the model how to treat text after the skill name; the other four had one. | Every spine has the same Modes section. |
| All seven | Descriptions were imperative ("Audit the codebase...") though the description is injected into the system prompt, where Anthropic's guidance asks for third person. | Third-person descriptions. |
| All seven | The body opened by describing the audit in the third person. In the 1.0.0 secauditor eval, Haiku 4.5 read the skill as a background job, replied that the audit was running, and stopped after three turns without a report. | Every spine opens by telling the model to do the audit itself, now. |

## 5. Packaging and install drift

| Where | Drift | Resolution |
|---|---|---|
| install.sh, uninstall.sh vs refresh-plugins.sh and lint | The installer linked `SKILL.md` and `references/`, but plugin vendoring and the plugin-sync lint handled only `SKILL.md`, so any skill that added reference files would have shipped a broken plugin. | One payload list (`SKILL.md`, `references/`, `scripts/`, `assets/`) in install, uninstall, refresh, and lint. |
| MAINTAINING.md vs lint | "Descriptions should match the skill frontmatter description" was a rule nothing enforced. | `lint.sh plugin-sync` compares each plugin manifest and marketplace description with the SKILL.md description. |
| lint | `patterns-valid` did not exist; a pattern with an unbalanced parenthesis passed BSD grep and failed ripgrep. | Every pattern compiles under grep and ripgrep in lint; CI installs ripgrep. |

## 6. Documentation drift

| Where | Drift | Resolution |
|---|---|---|
| Per-skill READMEs | Described the standalone era: install by copying a single `SKILL.md`, and (secauditor) "it ships a `.claude-plugin/plugin.json` manifest" that was retired in the consolidation. | Each README describes the hub install, the payload folders, modes, and scripts. |
| `references/STANDALONE-ARCHIVE.md` | Not linked from any document, and it shared the `references/` name the skills now use for their payload. | Moved to `docs/STANDALONE-ARCHIVE.md` and linked from the README lineage section. |
| README table | uxauditor's dimension count read "end to end" while it had eleven dimensions. | The table lists 11. |

## 7. Overlaps inside each auditor

Before 1.1.0, several auditors listed the same defect under two or three dimensions and relied on an ownership table to keep it from being scored twice; small models did not apply those tables reliably. In 1.1.0 every defect has exactly one card, so the card files are the ownership map, and each dimension file names what belongs elsewhere on its "Not here" line.

secauditor:
- Excessive data exposure was in both AUTHZ and APISEC: now AUTHZ-R6.
- SSRF was in both INJ and APISEC: now INJ-R4.
- Rate limiting was in MISCFG, APISEC, and AUTHN: now AUTHN-R4 for login, MFA, and reset, and APISEC-R1 for everything else.
- CORS and verbose errors appeared in MISCFG and APISEC: now MISCFG-R2 and MISCFG-R3.
- Outbound TLS verification appeared in CRYPTO, MISCFG, and APISEC: now CRYPTO-R3.
- Secrets in logs appeared in SECRET and LOGPRIV: now SECRET-R5; LOGPRIV-R2 covers personal data in logs.
- Session cookie flags appeared in AUTHN and MISCFG: now AUTHN-R5.
- Password hashing appeared in AUTHN and CRYPTO: now AUTHN-R1.

The other six auditors' resolutions are listed in their CHANGELOG 1.1.0 entries.

## 8. Stale facts

| Where | Drift | Resolution |
|---|---|---|
| uxauditor | Cited "the FTC click-to-cancel rule" as a current standard; the US Court of Appeals for the Eighth Circuit vacated the FTC's Negative Option Rule in July 2025. | Each skill's dated facts now live in `references/facts.md` with a last-reviewed date and a review ritual in MAINTAINING.md. |
| All seven | Dated platform facts (retired rich-result types, deprecated APIs, standards editions) were inline in checklists with no review date. | Moved to `references/facts.md` per skill. |
| dbauditor | Factual errors: `ADD COLUMN ... DEFAULT now()` was called table-rewriting (now() is stable; PostgreSQL 11 and later add it without a rewrite); Django, Prisma, SQLAlchemy, TypeORM, and JPA unique settings were said to enforce nothing in the database (they generate constraints through migrations; Rails and Laravel validations do not); Prisma `onDelete` was said to be client-only (only under `relationMode = "prisma"`); SQL Server snapshot isolation behavior was misstated. | Corrected in the cards; the full list is in dbauditor's CHANGELOG. |
| dbauditor | Two unsourced numbers (5 to 15 percent write cost per index, 30 to 60 percent index bloat from random UUID keys) were stated as facts. | Removed; the cards describe the effect without a number. |
| uiauditor | Said global CSS custom properties "never cross the shadow boundary", so tokens were inert inside custom elements. Custom properties inherit through shadow roots; it is ordinary selectors and stylesheets that do not. | Corrected in the DS and STYLE cards. |
| seoauditor | Said `property=` on Twitter card tags makes them inert, and treated Next.js `output: 'export'` as a client-rendering signal (static export pre-renders HTML). | Reworded to "use the documented `name=` attribute"; static export is no longer flagged. The unsourced "97 percent of llms.txt files get zero AI fetches" figure is marked "verify" in facts.md. |

## 9. Docs against tooling (resolved in 1.2.0)

The 1.1.0 docs promised checks the tooling did not make, and the hub kept its roster by hand. Adding productauditor exposed both.

| Where | Drift | Resolution |
|---|---|---|
| lint.sh, sync-shared.sh, refresh-plugins.sh, install.sh, uninstall.sh | Each script carried its own list of the seven skill names, and `plugin-sync` expected the meta plugin to depend on all seven. Adding an auditor meant five script edits, and nothing checked that `evals/`, `tests/fixtures/`, the README and SUITE.md tables, or the report exclusion named the same skills. | The roster is the set of `skills/` directories (`scripts/_skills.sh`), and the installers take every `skills/<name>/` that holds a `SKILL.md`. `lint.sh suite-registry` checks every place that names the auditors. The auditor count in prose and the AGENTS.md list stay hand-kept, and MAINTAINING.md and RELEASE-CHECKLIST.md say so. |
| Shared scripts vs CI | Regexes reached awk through `awk -v`. BSD awk and gawk strip backslashes from `-v` values, so the exclusion `\.min\.js$` became `.min.js$` and dropped `admin.js` and similar files from every audit on macOS and with gawk. CI ran only on Ubuntu, whose mawk keeps the backslashes, so it stayed green. AGENTS.md said "Keep awk POSIX (BSD awk and mawk)", and CONTRIBUTING.md said a green local run means a green build. | Every regex reaches awk through ENVIRON (`as_match_lines`). CI runs the lint and its self-test on macOS (`/bin/bash` 3.2, BSD awk) and on Ubuntu, then the lint under mawk and gawk. AGENTS.md and CONTRIBUTING.md state the ENVIRON rule. |
| CONTRIBUTING.md, AUTHORING.md vs `unicode-clean` | Said the lint rejects em dashes, en dashes, arrows, and emojis anywhere in the tree. The check matched the em dash, the en dash, and one arrow (U+2192), in tracked files only. | The check covers every arrow, box drawing, symbols and dingbats, emoji, and the emoji variation selector, in tracked files and in untracked files that git does not ignore. The docs list exactly that. |
| CONTRIBUTING.md vs lint.sh | Told contributors to verify with `bash scripts/lint.sh shared-sync plugin-sync`. The lint kept only the last name it was given, so only `plugin-sync` ran. | The lint runs every check it is given and rejects an unknown name; `tests/lint-selftest.sh` pins both. |
| 1.0.0 CHANGELOG, CONTRIBUTING.md vs `bash-syntax` | Said the lint enforces bash 3.2 syntax, with no associative arrays, `mapfile`, or `${var,,}`. The check ran `bash -n` under the CI's bash 5, which accepts all three. | `bash-syntax` also flags the bash 4 constructs that `bash -n` accepts, and CI runs the lint under macOS `/bin/bash` 3.2. |
| README, SUITE.md vs `check-report.sh` | Said the validator checks that each cited `path:line` contains the quoted code. It checks that every cited line exists and that one quoted span of 6 or more characters appears within 6 lines of the first cited location. | README, SUITE.md, and ARCHITECTURE.md state the rule as coded. |
| ARCHITECTURE.md, evals/README.md vs the graders | Said the read-only graders catch any edit and any file besides the report. They watch only the Edit tool and the list of created files, so a change made through Bash, or a Write over an existing file, goes unseen. | Both docs say what the graders see, and to read a kept run's transcript when in doubt. |
| AUTHORING.md, ARCHITECTURE.md, evals/README.md vs the eval cases | Said each case plants six to ten defects; the shipped cases plant 9 to 11. | The rule is 6 to 12, and the docs give the shipped range. |
| AUTHORING.md vs lint and secauditor | Said to tag a card `(quick)` when its Severity can be Critical, but nothing checked it. secauditor SECRET-R5 (secrets in logs, errors, or image layers) could be Critical untagged, so quick mode never worked it. | `skill-structure` fails a card whose Severity can be Critical without the tag, and a `(quick)` card whose Severity never reaches Critical. SECRET-R5 is tagged. |
| AUTHORING.md vs lint | Said the lint rejects real secret formats (`AKIA...`, `ghp_`) in eval fixtures. No check looks for them. | AUTHORING.md says GitHub push protection rejects them and the lint does not. |
| SUITE.md vs install.sh | Listed `~/.agents/skills/` as the path for any Agent Skills harness, but install.sh wrote it only when pi or OpenClaw was present, and both installers ignored `CLAUDE_CONFIG_DIR` and `CODEX_HOME`. | install.sh writes the neutral path when `~/.agents` exists and honors both variables; `tests/install.sh` pins it. |

How drift is prevented from 1.2.0 on: no script lists the skills, and `suite-registry` checks every file that names them; `tests/lint-selftest.sh` proves the checks it covers fail on an injected violation; and CI runs on both platforms the shared scripts must support.
