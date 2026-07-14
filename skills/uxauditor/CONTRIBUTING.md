# Contributing to uxauditor

Thanks for helping improve uxauditor. This is a small, file-only project: a UX audit command distributed across many AI coding tools from one source of truth. Contributions are welcome, from sharpening a single checklist item in the engine to adding support for a new tool.

## The one rule that matters

**All behavior lives in [`engine/uxauditor.md`](engine/uxauditor.md). Edit only that file.**

Every per-tool artifact (Claude skill, Codex command, pi skill, opencode command, and so on) is generated from the engine by [`install.sh`](install.sh). Do not hand-edit the installed copies under `~/.claude`, `~/.codex`, `~/.pi`, and the rest; they are overwritten on the next install. If you change the engine, re-sync every tool with:

```sh
./install.sh
```

## Project layout

```
engine/uxauditor.md   the complete, tool-neutral audit command (source of truth)
install.sh            detects installed tools and renders the engine into each
AGENTS.md             portable directive for any AGENTS.md-aware tool
README.md             overview and tool support matrix
```

## How to make a change

1. Fork and branch from `main` (for example `git checkout -b improve-accessibility-lens`).
2. Edit `engine/uxauditor.md` (or `install.sh` / docs).
3. Re-render: `./install.sh`.
4. Test it (see below).
5. Open a pull request describing what changed and why.

## Testing a change

There is no build step. To verify a change to the engine:

1. Point any installed tool at a real or sample product and run the command (for example `/uxauditor` in Codex, Cursor, Windsurf, opencode, or pi; or "audit my UX" in Claude Code or Antigravity).
2. Confirm it writes `uxaudit.md` at the audited project's root and prints the chat summary (score, scorecard, top fixes, finding counts, file path).
3. Spot-check the report against the quality gates in the engine: every finding cites a concrete location, every score is justified, recommendations are specific with a way to verify the fix, and Suspected findings are marked.

A quick way to exercise the full flow is to scaffold a small frontend with a few deliberate flaws (a placeholder-as-label form field, a control with no focus state, an empty state that says only "No data", a "Reject all" hidden behind low contrast) and confirm the audit finds them with accurate locations.

## Adding support for a new tool

`install.sh` is data-driven. To add a tool:

1. Add an `emit_*` function if the tool's format differs from the existing ones (skill directory, flat skill file, command with `description` + `argument-hint`, or opencode's `tools:` block).
2. Add one detection line that checks for the tool's config directory under `$HOME` and calls the right emitter.
3. Update the support matrix in `README.md` and the preference list in `AGENTS.md`.

Match the tool's real, documented convention. When in doubt, inspect an existing skill or command that the tool already loads and mirror its frontmatter exactly.

## Style

- No em dashes, no en dashes, no emojis in any file. Use commas, colons, parentheses, or separate sentences. The repo is plain ASCII and this is enforced in CI; do not introduce non-ASCII characters.
- Keep the engine tool-neutral. Refer to "the agent", "this command", "search", and "read", not to any single tool's product name or tool API.
- Practice what the engine preaches: claims about the experience should be specific and checkable, not filler.

## Reporting issues

Open an issue with a clear title, what you expected, what happened, and which tool you ran it in. For anything security-related, follow [SECURITY.md](SECURITY.md) instead of opening a public issue.

## License

By contributing, you agree that your contributions are licensed under the [MIT License](LICENSE).
