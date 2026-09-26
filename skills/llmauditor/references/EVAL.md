# EVAL: Evaluation, Testing and Quality

Weight 5. Always active.
Owns: whether output quality is measured before release and whether prompt and model changes are gated: eval suites and datasets, mocks in tests, CI gates, LLM-judge design, and retrieval evaluation.
Not here: production quality monitoring and user feedback (OBSERV); runtime schema validation (OUTPUT).
Standards: NIST AI RMF and NIST AI 600-1 (Measure), OWASP LLM09:2025 (Misinformation).
Read first: the tests that touch model code, any eval directory or dataset (list them with `ls`), and the CI workflows.

## Cards

### EVAL-R1 No offline eval for a quality-critical LLM feature
- Leads: `scan.sh EVAL-R1` lists eval tools, datasets, and benchmarks named in code, config, CI, and docs.
- Confirm: a feature whose output people or systems rely on (answers, extraction, classification, routing, agent actions) has no golden set of inputs with expected outputs or a rubric, and no script that scores it.
- Not a finding if: a suite covers the feature (then check EVAL-R3); the README marks the feature as a demo.
- Severity: High when the output makes or drives decisions without human review, or is customer-facing at scale. Medium otherwise.
- Fix: build a golden set from real cases (start with 30 to 100, including negative, adversarial, and refusal cases) and a scoring script with metrics that fit the task, and run it on every prompt or model change.
- Verify the fix: the script runs against the fixed dataset and prints a score.
- Refs: NIST AI 600-1, OWASP LLM09:2025

### EVAL-R2 Tests call a live model or assert exact text from unpinned calls
- Leads: `scan.sh EVAL-R2` lists client construction, API keys, and mocks in test files.
- Confirm: unit tests or CI call the real provider with no mock, recorded response, or fixture; or tests assert exact strings on model output from calls with unpinned sampling.
- Not a finding if: live calls sit in a separate eval job that runs on purpose, with pinned parameters and tolerant scoring.
- Severity: Medium: the suite is flaky, costs money, and gives different answers run to run.
- Fix: mock the client in unit tests with recorded responses, and move live runs to a gated eval job.
- Verify the fix: the unit suite passes with no API key set.
- Refs: none

### EVAL-R3 Eval exists but gates nothing
- Leads: `scan.sh EVAL-R3` lists eval and test steps in CI files.
- Confirm: an eval suite, dataset, or eval dependency is committed, but no CI job runs it, or it runs with no threshold and no committed baseline, so prompt, few-shot, or model-id changes merge with no before-and-after number; a model swap landed with no comparative run on the same dataset.
- Not a finding if: a CI job runs the suite on changes to prompts and model config and fails below the baseline.
- Severity: High when prompts or models change often on a customer-facing feature. Medium otherwise.
- Fix: a CI job, triggered by prompt and model-config changes, that runs the suite and fails below the baseline minus a tolerance; commit the baseline.
- Verify the fix: a pull request that degrades a prompt fails the job.
- Refs: NIST AI RMF (Measure)

### EVAL-R4 LLM-as-judge scores trusted without bias controls
- Leads: `scan.sh EVAL-R4` lists judge, grader, and rubric code.
- Confirm: a judge prompt has no rubric or anchored scale; pairwise comparisons always use one order (position bias); the judge comes from the same model family as the system under test (self-preference); or judge scores are treated as ground truth with no check against human labels.
- Not a finding if: the rubric is anchored, the order is randomized or swapped, and a human-labeled sample shows agreement.
- Severity: Medium.
- Fix: an anchored rubric, randomized or swapped order, a judge from a different model family, and calibration against a human-labeled sample.
- Verify the fix: agreement between the judge and human labels on a sample is measured and reported.
- Refs: none

### EVAL-R5 RAG evaluated end to end only
- Leads: `scan.sh EVAL-R5` lists retrieval and groundedness metrics.
- Confirm: a retrieval feature's eval scores only the final answer, with no retrieval metrics (recall@k, precision@k, MRR, nDCG) on a labeled query-to-document set and no check that answers are supported by the retrieved context, so changes to chunking, the embedding model, k, or index settings land unmeasured.
- Not a finding if: there is no retrieval surface; retrieval metrics and a faithfulness check both run in the gated suite.
- Severity: Medium. High when retrieval settings change often on a customer-facing feature.
- Fix: a labeled query-to-chunk set, retrieval metrics, and a faithfulness check in the gated suite.
- Verify the fix: changing k or the chunk size moves a reported retrieval metric.
- Refs: none

## Also check
- Datasets with only happy paths: no negative, adversarial, or refusal cases; exact-match scoring on open-ended text; cases that overlap the few-shot examples or were picked from cases the system already passes.
- Agents scored only on the final answer, with no check of which tools ran, in what order, or that the loop ended (trajectory blindness).
- Evals that trust structured-output mode and never validate the outputs.

## Paper controls (look protective, protect nothing)
- An `eval/` directory or a RAGAS or promptfoo dependency that no CI job runs.
- Scores printed with no committed baseline to compare against.
- A judge whose scores look precise while position and self-preference bias make them systematically wrong.
