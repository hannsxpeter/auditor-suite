# Security Policy

## What uxauditor does and does not do

uxauditor is a read-only analysis command. By design it:

- Reads source files, copy, and design artifacts, and inspects manifests, route lists, and version-control state.
- Writes exactly one file, `uxaudit.md`, at the root of the audited project.
- Does not modify, delete, or refactor source code, copy, or design files.
- Does not execute the audited project's own code, run migrations, or make network calls on the project's behalf. If a running instance is available to walk, it observes without changing state.

If you observe the command doing anything beyond reading the product and writing `uxaudit.md`, treat it as a bug and report it.

## Handle audit reports as sensitive

A generated `uxaudit.md` can contain sensitive material: file paths, copy and flow excerpts, screenshots of internal screens, and the precise locations of unfixed accessibility or trust issues. Treat a report like any other internal finding. Do not paste it into public issues or untrusted channels, and prefer to keep it out of version control (the repo's `.gitignore` ignores `uxaudit.md` for this reason).

## Reporting a vulnerability

If you find a security issue in this project (for example the engine instructing an unsafe action, or the installer writing outside its intended directories), please report it privately rather than opening a public issue:

- Use GitHub's private vulnerability reporting: open the repository's **Security** tab and choose **Report a vulnerability**.

Please include what you found, how to reproduce it, which tool you ran it in, and the impact you expect. We will acknowledge the report, investigate, and coordinate a fix and disclosure timeline with you.

## Supported versions

This project follows semantic versioning. Security fixes are made against the latest released version on `main`.
