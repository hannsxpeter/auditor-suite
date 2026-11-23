# Quick proof

Ten-minute path that proves the suite installs and that one auditor can run.

## 1. Install

```bash
npx @hxp-tools/auditor-suite@latest
```

Or, from a clone:

```bash
bash install.sh
```

Claude Code plugin alternative (pick one method per host):

```text
/plugin marketplace add hannsxpeter/auditor-suite
/plugin install auditor-suite@auditor-suite
```

## 2. Run a triage pass

In a project you care about, inside your agent:

| Host | Command |
|---|---|
| Claude Code | `/secauditor quick` |
| Codex | `$secauditor quick` |
| Other slash hosts | `/secauditor quick` |

`quick` runs only Critical-class checks and skips the numeric score. It is the fastest first pass.

## 3. Open the reward

The auditor writes `secaudit.md` at the project root and prints the verdict in chat. Every finding cites a `path:line` and quotes the code there.

## 4. Optional fuller run

```text
/secauditor
/codeauditor quick
```

Full mode scores every applicable dimension. Reports are self-contained work orders for another agent.

## What this does not prove

- Live app behavior (auditors are static and read-only)
- Every auditor on every repo (run the ones that match your stack)
- Eval scores (see `evals/README.md`; those runs call models and need maintainer go-ahead)
