# Security policy

## Reporting a vulnerability

Report security vulnerabilities privately, not via public issues or pull requests.

Use GitHub Private Vulnerability Reporting from the repository's Security tab whenever possible:

1. Open the Security tab for `hannsxpeter/auditor-suite`.
2. Click "Report a vulnerability."
3. Include the affected file, reproduction steps, impact, and any proposed mitigation.

If GitHub Private Vulnerability Reporting is unavailable, email `hprincivil@gmail.com` with subject line `SECURITY: auditor-suite`.

## Response timeline

| Milestone | Commitment |
|---|---|
| Initial acknowledgement | Within 3 business days |
| Critical triage | Within 24 hours |
| High severity triage | Within 3 business days |
| Medium or low severity triage | Within 7 business days |

Fix timelines depend on severity and release scope. Security fixes land on the latest release train.

## Scope

auditor-suite is static Markdown skill content plus bash install, uninstall, refresh, and lint scripts. The security surface is unusual, but real.

In scope:

- Malicious or hidden prompt instructions in skill content.
- Content that would cause an auditor to break its read-only contract: editing source, running the app, connecting to live systems, calling models, or exfiltrating code or secrets into its report.
- Dangerous generated guidance, such as report recommendations that disable verification, expose secrets, or configure CI with unsafe token permissions.
- Installer, uninstaller, refresh, or lint script behavior that can overwrite unexpected paths, expose secrets, or run unsafe commands.
- Plugin packaging drift that could ship different skill content than the source tree documents.

Out of scope:

- Typos, broken Markdown, or style disagreements.
- Missing platform coverage.
- Findings an auditor missed in a target codebase (that is a quality issue; open a regular issue).

## Coordinated disclosure

Please keep vulnerability details private until a fix is available and an advisory or release note can be published. If a fix requires longer than 90 days, the maintainer will explain the blocker and proposed disclosure date.
