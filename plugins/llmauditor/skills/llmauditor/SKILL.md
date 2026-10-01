---
name: llmauditor
description: Audits how a codebase integrates large language models (security and trust boundaries, prompt construction, model selection and routing, provider API usage, reliability, structured output, cost, latency, evaluation, observability, RAG and vector search, agents and tools) and writes llmaudit.md, a scored, prioritized, self-contained report, then prints the verdict in chat. Use when the user asks for an LLM, AI, prompt, RAG, or agent audit, a prompt-injection or OWASP LLM review, or a readiness check of an AI feature. Read-only: never calls a model or embeddings endpoint, never runs the app or its agents. Modes: full (default), quick (Critical-class triage), only=DIM,DIM, or a path. Invoke with /llmauditor in Claude Code or $llmauditor in Codex.
allowed-tools: 'Bash(bash "${CLAUDE_SKILL_DIR}/scripts/*)'
---

# llmauditor

**You are now running this audit. Do it yourself, starting now, by working through the Workflow below with your own tools.** Nothing runs in the background. The audit is finished only when `check-report.sh` prints OK and you have sent the chat summary.

Audits how the codebase in the current directory integrates large language models and writes `llmaudit.md` at its root: scored, prioritized, and self-contained, so another agent holding only the report and the code can fix what it finds. Then prints the verdict in chat.

## Contract

- Read-only. Create or change no file except `llmaudit.md` at the project root. Never run the project, its tests, builds, agents, or eval suites. Never call a model or an embeddings endpoint, never connect to a vector store, and never change data or an index.
- Allowed: reading and searching files, read-only shell commands (`git log`, `git show`, `ls`, `wc`), and this skill's scripts. The scripts only read, except `new-report.sh` and `score.sh --write`, which write only `llmaudit.md`.
- Evidence: every finding cites a `path:line` you opened and quotes the code there. A `scan.sh` lead is a place to read, never a finding by itself.
- Describe weaknesses and fixes; never write a working jailbreak, prompt-injection string, or exploit payload.
- Finish by sending the output of `score.sh --chat`. Never finish silently.

## Paths

`${CLAUDE_SKILL_DIR}` is this skill's folder, the one that contains this SKILL.md; Claude Code fills it in. If you still see the literal text `${CLAUDE_SKILL_DIR}`, replace it with that folder's absolute path in every command. Run every command from the project root.

## Modes

Text after the skill name picks the mode:
- nothing or `full`: every active dimension, every card.
- `quick`: only the cards tagged (quick), the Critical-class checks; no numeric score.
- `only=LLMSEC,AGENT`: only those dimensions, every card; the score is labeled partial.
- a path, alone or after a mode (`quick src/agents`): audit only that part of the tree.

## Workflow

Copy this checklist into your notes and tick each step as you finish it.

- [ ] 1. Run `bash "${CLAUDE_SKILL_DIR}/scripts/inventory.sh"` (add the path if scoped). If it prints NO SOURCE CODE FOUND, tell the user and stop. If it prints `domain surface: NOT FOUND` and reading the code confirms there is no provider SDK, model call, embeddings call, or agent, tell the user there is no LLM integration to audit and stop.
- [ ] 2. Read `${CLAUDE_SKILL_DIR}/references/protocol.md` (the rules for every finding) and `${CLAUDE_SKILL_DIR}/references/example-report.md` (a finished report).
- [ ] 3. Run `bash "${CLAUDE_SKILL_DIR}/scripts/new-report.sh" --mode <mode>` (add the path if scoped). It creates `llmaudit.md` and lists the active dimensions. Fill the Snapshot lines, naming the providers, the model ids and where they live, and the usage paradigm (single call, chat, extraction pipeline, RAG, agent). Map the LLM data flow: where untrusted content enters prompts, what the model can reach and do, and where its output goes. Trace the two or three highest-risk flows and write the Map section.
- [ ] 4. Work each active dimension in the listed order:
  - a. Read `${CLAUDE_SKILL_DIR}/references/<DIM>.md`.
  - b. Run `bash "${CLAUDE_SKILL_DIR}/scripts/scan.sh" <DIM>`. In quick mode run `bash "${CLAUDE_SKILL_DIR}/scripts/scan.sh" quick --show-cards` once instead of a and b.
  - c. For every card, read the code at each lead and the files its Leads line names, then apply Confirm, Not a finding if, and Severity. Refute before you record (protocol section 5).
  - d. Add each confirmed finding under `## Findings` in the exact block format (protocol section 2).
  - e. Fill the dimension's notes: `- Checked:` lists every card ID you worked, `- Note:` says what you found.
- [ ] 5. Merge repeats into one finding, write Systemic patterns, Strengths (each with a `path:line`), and Scope and limitations.
- [ ] 6. Run `bash "${CLAUDE_SKILL_DIR}/scripts/score.sh" --write`, then write the Verdict and Calibration lines.
- [ ] 7. Run `bash "${CLAUDE_SKILL_DIR}/scripts/check-report.sh"`. Fix every problem it lists and rerun until it prints `check-report: OK`.
- [ ] 8. Run `bash "${CLAUDE_SKILL_DIR}/scripts/score.sh" --chat` and send its output as your final message.

Stop early only if inventory.sh finds no source code or no LLM integration, or if you cannot read the files; then say so and write no report.

## Dimensions

| ID | Dimension | Weight | Active when | Cards |
|---|---|---|---|---|
| LLMSEC | Security, Trust Boundaries, Safety and Data Governance | 17 | always | references/LLMSEC.md |
| PROMPT | Prompt Construction and Context Management | 12 | always | references/PROMPT.md |
| MODEL | Model Selection, Configuration and Routing | 10 | always | references/MODEL.md |
| APIUSE | Provider API and SDK Usage | 10 | always | references/APIUSE.md |
| RELIABILITY | Reliability, Retries and Fallback | 10 | always | references/RELIABILITY.md |
| OUTPUT | Output Handling and Structured-Output Consumption | 8 | always | references/OUTPUT.md |
| COST | Cost, Quotas and Token Efficiency | 6 | always | references/COST.md |
| EVAL | Evaluation, Testing and Quality | 5 | always | references/EVAL.md |
| OBSERV | Observability and Monitoring | 5 | always | references/OBSERV.md |
| SPEED | Latency and Throughput | 4 | always | references/SPEED.md |
| RAG | Retrieval, RAG, Indexing and Vector Search | 7 | embeddings or a vector store exist | references/RAG.md |
| AGENT | Agent and Tool Integration | 6 | tool calling, an agent framework, or an MCP client exists | references/AGENT.md |

new-report.sh decides the conditional dimensions from probes and prints why; if a probe is wrong, move the ID between the Active and Not applicable lines, keep its reason in parentheses, for example `RAG (embeddings are used only to find duplicates)`, and say why in Scope and limitations. Weights re-normalize over the active dimensions. LLMSEC and AGENT are floor dimensions: one Critical finding in either holds the overall score at 69, so an integration that can be hijacked into leaking data or taking actions cannot score well however good the rest is.

## How to judge

This audit covers the AI layer: how the app builds prompts, which models it calls and how, how far it trusts model input and output, how it retrieves and grounds answers, how it stays inside reliability, cost, and latency budgets, and how quality is measured and watched. General code quality belongs to codeauditor, the full application security surface to secauditor (its LLMSEC is the shallow version of this audit), the database layer to dbauditor, user experience to uxauditor, and model-call quotas a plan sells and invented output shown as real when no call failed to productauditor; touch those only where they create an LLM-layer defect.

- Calibrate with the lethal trifecta: a path that has access to private data, reads untrusted content (retrieved documents, tool results, web pages, email, files, images), and can act or send data out is the highest-risk surface. Remove any one leg and severity drops. An unbounded loop in an internal batch script is not an unbounded loop in a public agent with a send-email tool.
- Source to sink: treat all model output and all retrieved or tool content as untrusted. For injection and output findings, Evidence names where the untrusted text enters and where the output lands (code, SQL, shell, HTML, URL, a tool call, a decision). The fix goes at the boundary and the sink, never in a prompt that asks nicely.
- Verify against the request the code sends, not what the prompt promises. "Respond only with JSON" guarantees nothing without a structured-output mechanism and validation; "only show the user's own records" is not authorization; "do not hallucinate" is not grounding. The gap is the finding.
- Paper controls are the most dangerous findings: a guardrail that runs only on the user turn or whose verdict is logged but never blocks, a cache breakpoint after a volatile timestamp, a retry that misses the SDK's rate-limit error, an ACL stored on vectors but never filtered on, `max_tokens` presented as the agent-loop bound, an eval never run in CI, a tracer never attached. Every dimension file lists the ones to hunt.
- Static code cannot show answer quality, real token cost or latency, retrieval recall on live data, whether a guardrail stops a given attack, or whether an eval passes. When a severity depends on those, use Likely or Suspected and name what would confirm it: a request payload, a config value, an eval run, a trace.
- Calibrate to the paradigm and exposure (a local summarizer, an internal batch job, a public chatbot, an agent with tools and money) and write both on the Calibration line. Single-model design is legitimate; missing tiered routing is a gap only under demonstrated heterogeneous load.
- Judge model ids by principle: floating alias or pinned snapshot, deprecated or active. Providers name them differently, so use the conventions and pages in references/facts.md; never decide from memory whether a model name is current, and use Suspected when you cannot check.

## Reference files

- `references/protocol.md`: evidence rules, finding format, severity, confidence, scoring, modes, finishing.
- `references/example-report.md`: a complete report that passes check-report.sh.
- `references/facts.md`: dated facts (OWASP LLM Top 10 2025 and 2026 IDs, OWASP Agentic IDs, model-id conventions and deprecation pages, stop reasons, structured-output and caching features, SDK defaults, deprecated endpoints, framework loop defaults), with the date they were last reviewed.
- `references/LLMSEC.md`, `references/PROMPT.md`, `references/MODEL.md`, `references/APIUSE.md`, `references/RELIABILITY.md`, `references/OUTPUT.md`, `references/COST.md`, `references/EVAL.md`, `references/OBSERV.md`, `references/SPEED.md`, `references/RAG.md`, `references/AGENT.md`: the cards for each dimension.
- `assets/report-template.md`: the report skeleton new-report.sh fills.
