# Security Policy

## What codeauditor does and does not do

codeauditor is a read-only analysis command. By design it:

- Reads source files and inspects manifests, line counts, and version-control state.
- Writes exactly one file, `codeaudit.md`, at the root of the audited project.
- Does not modify, delete, or refactor source code.
- Does not execute the audited project's own code, run migrations, or make network calls on the project's behalf.

If you observe the command doing anything beyond reading the codebase and writing `codeaudit.md`, treat it as a bug and report it.

## Handle audit reports as sensitive

A generated `codeaudit.md` can contain sensitive material: file paths, code excerpts, and the precise locations of unfixed vulnerabilities. Treat a report like any other security finding. Do not paste it into public issues or untrusted channels, and prefer to keep it out of version control (the repo's `.gitignore` ignores `codeaudit.md` for this reason).

## Reporting a vulnerability

If you find a security issue in this project (for example the engine instructing an unsafe action, or the installer writing outside its intended directories), please report it privately rather than opening a public issue:

- Use GitHub's private vulnerability reporting: open the repository's **Security** tab and choose **Report a vulnerability**.

Please include what you found, how to reproduce it, which tool you ran it in, and the impact you expect. We will acknowledge the report, investigate, and coordinate a fix and disclosure timeline with you.

## Supported versions

This project follows semantic versioning. Security fixes are made against the latest released version on `main`.
