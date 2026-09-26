# MODEL: Model Selection, Configuration and Routing

Weight 10. Always active.
Owns: which model each path calls and with which parameters: model-id pinning and deprecation, where ids live, sampling and output-limit parameters, reasoning budgets, tier choice, routing, cascades, and fallback models.
Not here: the embedding model's lifecycle and vector-space consistency (RAG-R1, RAG-R3); the eval gate for model changes (EVAL-R3); when a fallback triggers in the error path (RELIABILITY-R6).
Standards: provider model and deprecation pages (references/facts.md), NIST AI 600-1 (Value Chain and Component Integration).
Read first: the config or constants that hold model ids, every call site's model and parameter arguments, and any router, cascade, or fallback code.

## Cards

### MODEL-R1 Floating model alias instead of a pinned snapshot
- Leads: `scan.sh MODEL-R1` lists model-id literals.
- Confirm: a model id is one the provider documents as moving: an undated alias that points to the newest snapshot, or a `-latest` name. Judge each id by the provider conventions in references/facts.md, never by whether it has a date. A key named `MODEL_VERSION` or "pinned" whose value is an alias counts.
- Not a finding if: the provider documents the id as a fixed snapshot (some providers' dateless ids are pinned; see facts.md); the choice to float is documented and an eval gate runs on every provider change.
- Severity: Medium. High when the output feeds parsers, thresholds, or automations that an unannounced model change can break and no eval gate exists. Use Suspected when you cannot confirm the provider's convention.
- Fix: pin the snapshot id in one config constant, and change it only through a reviewed, eval-gated change (EVAL-R3).
- Verify the fix: every call reads the model from that constant, and its value appears as a snapshot on the provider's model page.
- Refs: provider model pages (references/facts.md)

### MODEL-R2 Deprecated or retired model id still referenced
- Leads: `scan.sh MODEL-R2` lists model-id literals, including embedding and fallback ids.
- Confirm: a model id in a caller, registry, fallback list, or test fixture is listed as deprecated or retired on the provider's deprecation page. Use the dated entries in references/facts.md; never decide from memory.
- Not a finding if: the page lists the id as active; the reference is dead code (confirm nothing calls it).
- Severity: High when the id is retired, or retires within about 90 days, on a live path, or when it is the fallback model (then the failover itself fails). Medium otherwise. Use Suspected when you could not check the page, and name the page in Verify the fix.
- Fix: move to the provider's named replacement through the eval gate, and add a scheduled check of every model id against the deprecation pages.
- Verify the fix: a search for the old id returns nothing, and the replacement is listed as active.
- Refs: provider deprecation pages (references/facts.md)

### MODEL-R3 Model ids hardcoded across call sites or identical in every environment
- Leads: `scan.sh MODEL-R3` lists inline `model=` literals at call sites.
- Confirm: model ids are literals in several files instead of one config source, or tests and development run the same expensive or preview model as production with no override.
- Not a finding if: the project has a single call site; one config source with per-environment overrides exists and every call uses it.
- Severity: Medium. Low for two or three call sites in one small service.
- Fix: one config source (an environment variable with a pinned default) with per-environment overrides.
- Verify the fix: a search for model literals outside the config returns nothing.
- Refs: none

### MODEL-R4 Sampling parameters wrong for the task or rejected by the model
- Leads: `scan.sh MODEL-R4` lists temperature, top_p, top_k, and penalty settings.
- Confirm: extraction, classification, structured-output, or tool-argument calls run at the default or a high temperature on a model that honors it; or sampling parameters go to a model that ignores or rejects them (many reasoning models; see facts.md), so `temperature=0` "for determinism" is decorative or a 400 error.
- Not a finding if: the task is creative or open-ended; the model accepts the parameter and the value fits the task.
- Severity: High when a rejected parameter makes the call fail. Medium otherwise.
- Fix: a low or zero temperature for deterministic tasks on models that support it; remove unsupported parameters and get consistency from structured output and validation.
- Verify the fix: the request for this path carries only parameters the model's API reference accepts.
- Refs: provider API references (references/facts.md)

### MODEL-R5 Output-limit or reasoning parameter wrong for the model or task
- Leads: `scan.sh MODEL-R5` lists output caps, thinking budgets, and effort settings.
- Confirm: the wrong limit key for the API surface (`max_tokens`, `max_completion_tokens`, `max_output_tokens`); a required cap missing; a cap far below the expected output (truncation) or far above it (latency and spend); `max_tokens` not above the thinking budget where one is set; reasoning effort maxed on every request or off for a hard task.
- Not a finding if: the cap and effort fit the expected output and the task, under the key the API reference names.
- Severity: High when the call fails or truncates on a core path. Medium when it only wastes spend or latency.
- Fix: use the surface's limit key, size the cap to the expected output with headroom, and set effort per task.
- Verify the fix: the request log shows the corrected parameters and no length stops on normal inputs.
- Refs: provider API references (references/facts.md)

### MODEL-R6 Model tier, routing, or fallback does not fit the workload
- Leads: `scan.sh MODEL-R6` lists fallback, router, and cascade code.
- Confirm: a flagship or reasoning model is hardcoded for trivial high-volume or latency-sensitive work (routing, classification, autocomplete, guardrails); a router's branches all return the flagship; a cascade's escalation trigger never fires, always fires, or ignores answer quality; or a fallback model is shape-incompatible (parameter names, message or tool schema) or unreachable (wrong key, missing capability).
- Not a finding if: one model serves a homogeneous workload (single-model design is legitimate; missing tiered routing is a gap only under demonstrated heterogeneous load); an eval shows the smaller model fails the task.
- Severity: High when the fallback cannot work during an outage, or the tier drives most of the spend on a high-volume path. Medium otherwise.
- Fix: route by task with a measured trigger, and test the fallback path with a mocked provider error.
- Verify the fix: a test forces the primary to fail and gets a valid answer from the fallback, and every router branch is reachable.
- Refs: none

## Also check
- A preview or experimental model in production, where the provider says it can change or disappear on short notice.
- No scheduled review of model ids against the deprecation pages (cite it inside the MODEL-R2 finding when one exists).

## Paper controls (look protective, protect nothing)
- A `MODEL_VERSION` or "pinned" key whose value is still an alias.
- A fallback list naming a retired model, so the failover itself fails.
- A `select_model()` whose branches all return the flagship; the cheap branch is dead code.
- A configured fallback that nothing reaches (wrong key, or the call needs a capability it lacks).
