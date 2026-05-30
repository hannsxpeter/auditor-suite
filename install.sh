#!/usr/bin/env bash
#
# install.sh - install (or uninstall) the codeauditor command across every AI
# coding tool found on this machine. One source of truth (engine/codeauditor.md)
# rendered into each tool's native skill or slash-command format.
#
# Usage:
#   ./install.sh                    install codeauditor into all detected tools
#   ./install.sh uninstall          remove codeauditor from all detected tools
#   ./install.sh uninstall <name>   remove a prior install under a different name
#
# Re-run after editing engine/codeauditor.md to re-sync every tool. Idempotent.

set -euo pipefail

# Resolve this script's real directory, following symlinks (npm bin, npx, etc.)
# so the engine is found whether run from the repo or an installed package.
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  DIR="$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)"
  SOURCE="$(readlink "$SOURCE")"
  [ "${SOURCE#/}" = "$SOURCE" ] && SOURCE="$DIR/$SOURCE"
done
SCRIPT_DIR="$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)"
NAME="codeauditor"
DESC="Audit the codebase end to end, write codeaudit.md (a scored, prioritized, self-contained report), then display the results in chat. Read-only: never edits source."
ARGHINT='"[path or scope, optional]"'

MODE="install"
if [ "${1:-}" = "uninstall" ]; then
  MODE="uninstall"
  [ -n "${2:-}" ] && NAME="$2"
fi

ENGINE="$SCRIPT_DIR/engine/$NAME.md"
if [ "$MODE" = "install" ] && [ ! -f "$ENGINE" ]; then
  echo "error: engine not found at $ENGINE" >&2; exit 1
fi

changed=()

# Each emit function writes its artifact in install mode, or removes it in
# uninstall mode. The target path is identical in both directions.

emit_skill() {            # <tool>/skills/<name>/SKILL.md  (directory form)
  local target="$1/$NAME"
  if [ "$MODE" = "uninstall" ]; then [ -e "$target" ] && { rm -rf "$target"; changed+=("removed -> $target"); }; return 0; fi
  mkdir -p "$target"
  { printf -- '---\nname: %s\ndescription: %s\n---\n\n' "$NAME" "$DESC"; cat "$ENGINE"; } > "$target/SKILL.md"
  changed+=("skill   -> $target/SKILL.md")
}

emit_pi_skill() {         # pi: flat <skills>/<name>.md ; filename stem becomes /<name>
  local target="$1/$NAME.md"
  if [ "$MODE" = "uninstall" ]; then [ -e "$target" ] && { rm -f "$target"; changed+=("removed -> $target"); }; return 0; fi
  mkdir -p "$1"
  { printf -- '---\nname: %s\ndescription: %s\n---\n\n' "$NAME" "$DESC"; cat "$ENGINE"; } > "$target"
  changed+=("skill   -> $target")
}

emit_cmd() {              # <tool>/commands/<name>.md  (description + argument-hint) -> /<name>
  local target="$1/$NAME.md"
  if [ "$MODE" = "uninstall" ]; then [ -e "$target" ] && { rm -f "$target"; changed+=("removed -> $target"); }; return 0; fi
  mkdir -p "$1"
  { printf -- '---\ndescription: %s\nargument-hint: %s\n---\n\n' "$DESC" "$ARGHINT"; cat "$ENGINE"; } > "$target"
  changed+=("command -> $target")
}

emit_opencode_cmd() {     # opencode: tools: block; read+write+bash, edit off (read-only on source)
  local target="$1/$NAME.md"
  if [ "$MODE" = "uninstall" ]; then [ -e "$target" ] && { rm -f "$target"; changed+=("removed -> $target"); }; return 0; fi
  mkdir -p "$1"
  { printf -- '---\ndescription: %s\nargument-hint: %s\ntools:\n  read: true\n  write: true\n  edit: false\n  bash: true\n---\n\n' "$DESC" "$ARGHINT"; cat "$ENGINE"; } > "$target"
  changed+=("command -> $target")
}

echo "mode: $MODE   name: $NAME"
[ "$MODE" = "install" ] && echo "from: $ENGINE"
echo ""

[ -d "$HOME/.claude" ]             && { echo "[Claude Code]";                  emit_skill "$HOME/.claude/skills"; }
[ -d "$HOME/.codex" ]              && { echo "[Codex CLI]";                    emit_skill "$HOME/.codex/skills"; emit_cmd "$HOME/.codex/commands"; }
[ -d "$HOME/.gemini" ]             && { echo "[Gemini CLI]";                   emit_skill "$HOME/.gemini/skills"; emit_cmd "$HOME/.gemini/commands"; }
[ -d "$HOME/.cursor" ]             && { echo "[Cursor]";                       emit_skill "$HOME/.cursor/skills"; emit_cmd "$HOME/.cursor/commands"; }
[ -d "$HOME/.antigravity" ]        && { echo "[Antigravity]";                  emit_skill "$HOME/.antigravity/skills"; }
[ -d "$HOME/.gemini/antigravity" ] && { echo "[Antigravity (gemini profile)]"; emit_skill "$HOME/.gemini/antigravity/skills"; emit_cmd "$HOME/.gemini/antigravity/commands"; }
[ -d "$HOME/.pi" ]                 && { echo "[pi (pi.dev)]";                  emit_pi_skill "$HOME/.pi/skills"; }
[ -d "$HOME/.windsurf" ]           && { echo "[Windsurf]";                     emit_cmd "$HOME/.windsurf/commands"; }
[ -d "$HOME/.config/opencode" ]    && { echo "[opencode]";                     emit_opencode_cmd "$HOME/.config/opencode/command"; }

echo ""
if [ ${#changed[@]} -eq 0 ]; then
  echo "Nothing to $MODE. No matching tools or artifacts found under \$HOME."
  exit 0
fi

[ "$MODE" = "uninstall" ] && echo "Removed ${#changed[@]} artifact(s):" || echo "Installed ${#changed[@]} artifact(s):"
for line in "${changed[@]}"; do echo "  $line"; done

if [ "$MODE" = "install" ]; then
  echo ""
  echo "Invoke it:"
  echo "  Claude Code / Antigravity / pi:  ask \"audit my codebase\" (skill auto-triggers), or /$NAME"
  echo "  Codex / Gemini / Cursor / Windsurf / opencode:  /$NAME"
  echo "  Any other tool:  see AGENTS.md, or paste $ENGINE as the prompt"
fi
