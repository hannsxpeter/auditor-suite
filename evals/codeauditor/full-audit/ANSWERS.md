# Answer key: codeauditor full-audit

Never copied into the eval workspace. Lines refer to files under repo/.

## Planted defects

| Grader | Location | Card | Expected severity | Defect |
|---|---|---|---|---|
| finds-renewal-swallow | app/services/billing.py:45 | ERR-R1 | Critical | `charge_renewal` catches every exception from the charge with `except Exception: pass`, then marks the invoice paid and advances the renewal date, so a declined or failed charge ships a free box with no record of the failure |
| finds-export-authz | app/routes/customers.py:35 | SEC-R2 | Critical | `GET /customers/<id>/export` has no `@require_customer` and no owner check (its siblings have both), so anyone can export any customer's profile, invoices, and payment token |
| finds-mailer-token | app/services/mailer.py:4 | SEC-R5 | Critical | a production email API token is a literal in source instead of an environment variable |
| finds-carrier-timeout | app/services/carrier.py:12 | ERR-R3 | High | `requests.post` to the shipping carrier has no timeout (requests waits forever) on the admin ship route |
| finds-hollow-tests | tests/test_billing.py:6 | TEST-R2 | High | the only billing tests assert nothing (`assert True` at line 22); the declined-card test passes because of the swallowed error |
| finds-renewals-n-plus-one | app/routes/reports.py:14 | PERF-R2 | Medium | the renewals report runs two queries per active subscription inside the loop |
| finds-subscription-god-function | app/routes/subscriptions.py:17 | QUAL-R1 | Medium or High | `create_subscription` is a 100-line function that validates, normalizes addresses, prices, persists, charges, and emails, nested five levels deep |
| finds-retry-limit-doc | README.md:31 | DOC-R2 | Medium or High | `RENEWAL_RETRY_LIMIT` is documented as the declined-card retry count, but no code reads it and renewals never retry |
| finds-unused-pandas | requirements.txt:7 | DEP-R4 | Medium or Low | `pandas` is a runtime dependency that nothing imports |
| finds-discount-todos | app/services/discounts.py:3 | QUAL-R5 | Medium | eight untracked TODO, FIXME, HACK, and XXX markers in the pricing module, one admitting a live bug (case-sensitive codes) |

## Decoys (safe; flagging them is a false positive)

| Grader | Location | Why it is safe |
|---|---|---|
| ignores-webhooks | app/routes/webhooks.py:32 | the broad `except Exception` logs with the event ID, rolls back, and returns 500 so the provider retries (ERR-R1 "Not a finding if"); the route is authenticated by an HMAC signature checked with `hmac.compare_digest` |
| ignores-health | app/routes/health.py:9 | `/healthz` is the liveness probe and must not check the database; `/readyz` checks it and returns 503 (OBS-R4 "Not a finding if") |

## Strengths worth naming

- Webhook signatures are checked in constant time (`app/routes/webhooks.py:18`) and failures return 500 so the provider retries (`app/routes/webhooks.py:35`), with tests that assert both (`tests/test_webhooks.py:22-23`, `tests/test_webhooks.py:41`).
- Required settings fail fast at startup (`app/config.py:7`), and the database connection has a connect timeout (`app/config.py:9`).
- The payment and email calls set timeouts (`app/services/billing.py:31`, `app/services/mailer.py:13`).
- The renewal job eager-loads customers and plans (`app/services/billing.py:56`).
- Customer routes share one ownership check (`app/routes/customers.py:11`).

## Other defensible findings (not graded)

- `app/__init__.py:21`: the schema is created with `db.create_all()` from a CLI command, with no versioned migrations (OBS-R6, Medium).
- `requirements.txt:8`: pytest ships as a runtime dependency, and transitive dependencies are not pinned (DEP Also check and DEP-R5, Low or Medium).
- No tests exercise `create_subscription` or the customer routes (TEST-R1, High), usually cited in `app/routes/subscriptions.py` or `app/routes/customers.py`.
- `app/services/billing.py:44`: the charge sends no idempotency key, so a job that crashes between the charge and the commit can charge twice on the next run (ERR-R4 or ERR-R5).
- `app/services/discounts.py:26`: discount codes are case sensitive, as the FIXME at line 25 admits (Low).
- No metrics or error reporting on a service that takes payments (OBS-R3, Medium).
