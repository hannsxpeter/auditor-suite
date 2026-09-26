# Dated facts for secauditor

Last reviewed: 2026-09-26. Facts change; before citing one as the reason for a Critical or High finding, prefer the version the project actually uses and say which source you relied on. Items marked "verify" were carried over from auditor-suite 1.0.0 without a fresh check against the source.

## OWASP Top 10: 2025 IDs and their 2021 equivalents

Cite both IDs in References when a team may still use the 2021 list. Source: owasp.org/Top10.

| 2025 | Name | 2021 equivalent |
|---|---|---|
| A01:2025 | Broken Access Control (now includes SSRF) | A01:2021, plus A10:2021 SSRF |
| A02:2025 | Security Misconfiguration | A05:2021 |
| A03:2025 | Software Supply Chain Failures | A06:2021 Vulnerable and Outdated Components, widened |
| A04:2025 | Cryptographic Failures | A02:2021 |
| A05:2025 | Injection | A03:2021 |
| A06:2025 | Insecure Design | A04:2021 |
| A07:2025 | Authentication Failures | A07:2021 Identification and Authentication Failures |
| A08:2025 | Software or Data Integrity Failures | A08:2021 |
| A09:2025 | Security Logging and Alerting Failures | A09:2021 Security Logging and Monitoring Failures |
| A10:2025 | Mishandling of Exceptional Conditions (new) | none |

## Other standards the cards cite

- OWASP API Security Top 10: 2023 edition (API1 BOLA through API10 unsafe consumption of APIs). Source: owasp.org/API-Security.
- OWASP Top 10 for LLM Applications: the LLMSEC cards cite the 2025 edition (LLM01 prompt injection through LLM10 unbounded consumption). A 2026 edition was published on 2026-08-03 with the same entries reordered: Excessive Agency moved from LLM06 to LLM03, Unbounded Consumption from LLM10 to LLM06, and System Prompt Leakage (LLM07:2025) was broadened and renamed Hidden Context Exposure (LLM08:2026). llmauditor's facts.md carries the full mapping. In a report, cite the 2025 ID and add the 2026 ID in parentheses when the reader uses the 2026 list. Source: genai.owasp.org.
- RFC 9700, Best Current Practice for OAuth 2.0 Security (published January 2025): authorization code with PKCE, no implicit or password grant, exact redirect URI matching.
- RFC 8725, JSON Web Token Best Current Practices (2020): pin algorithms, reject `none`, validate `iss`, `aud`, and `exp`.
- NIST SP 800-63B-4 (the revision 4 digital identity guidelines): breached-password screening over composition rules, no periodic forced rotation. Verify the publication status at csrc.nist.gov.
- PCI DSS v4.0.1 (June 2024): show at most the first six and last four digits of a card number; Requirement 10 covers audit logging.
- SLSA v1.x build levels for provenance. Source: slsa.dev.

## Supply-chain incidents worth knowing

- tj-actions/changed-files (March 2025): a moved Git tag served malicious code to every workflow that referenced the Action by tag, dumping CI secrets into logs. It is why SUPPLY-R3 asks for full commit SHAs.
- xz-utils backdoor (CVE-2024-3094, March 2024): a maintainer-level compromise in a release tarball; checks on source provenance, not just versions, matter.
- Log4Shell (CVE-2021-44228) in log4j-core 2.0 through 2.14.1, with follow-up fixes through 2.17.1.

## Advisories used in the example report

- CVE-2023-30861, Flask: a missing `Vary: Cookie` header can let a caching proxy serve one user's refreshed permanent session cookie to another. Fixed in Flask 2.2.5 and 2.3.2.

## Old patterns (do not recommend)

- `X-XSS-Protection`: obsolete; modern browsers removed the XSS auditor. Use CSP instead.
- `Expect-CT`: deprecated; Certificate Transparency is enforced by browsers.
- HPKP (public key pinning headers): removed from browsers; do not recommend it.
