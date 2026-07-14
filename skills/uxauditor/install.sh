#!/usr/bin/env bash
#
# install.sh - install, uninstall, or inspect the uxauditor command across every
# AI coding tool found on this machine. One source of truth
# (engine/uxauditor.md) rendered into each tool's native skill or slash-command
# format.
#
# Usage:
#   ./install.sh [--dry-run]          install uxauditor into all detected tools
#   ./install.sh list                 show what is installed in each detected tool
#   ./install.sh uninstall [<name>]   remove uxauditor from all detected tools
#   ./install.sh --help               show usage
#   ./install.sh --version            print the version
#
# Re-run after editing engine/uxauditor.md to re-sync every tool. Idempotent,
# and read-only on your source: it only writes into your tools' config dirs.

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

NAME="uxauditor"
DESC="Audit the product's UX, user journeys, processes, and workflows end to end, write uxaudit.md (a scored, prioritized, self-contained report), then display the results in chat. Read-only: never edits source."
ARGHINT='"[path, flow, or scope, optional]"'
VERSION="$(cat "$SCRIPT_DIR/VERSION" 2>/dev/null || echo unknown)"

usage() {
  cat <<EOF
uxauditor installer $VERSION

Renders engine/uxauditor.md into the native skill or slash-command format of
every supported AI coding tool found under \$HOME. Idempotent, and read-only on
your source: it only writes into your tools' own config directories.

Usage:
  ./install.sh [--dry-run]          install into all detected tools (default)
  ./install.sh list                 show what is installed in each detected tool
  ./install.sh uninstall [<name>]   remove from all detected tools
  ./install.sh --help               show this help and exit
  ./install.sh --version            print the version and exit

Options:
  -n, --dry-run    show what an install would write, without writing anything
  -h, --help       show this help and exit
  -v, --version    print the version and exit

Detection looks under \$HOME (for example ~/.claude, ~/.codex, ~/.gemini,
~/.cursor, ~/.antigravity, ~/.pi, ~/.windsurf), plus \${XDG_CONFIG_HOME:-~/.config}/opencode.
A tool kept in a non-standard location is not detected; for those, copy
engine/uxauditor.md into the tool's command or prompt directory (see AGENTS.md).
EOF
}

# Parse the single subcommand/flag. Anything unrecognized is rejected rather
# than silently treated as an install.
MODE="install"
case "${1:-}" in
  "")              MODE="install" ;;
  -n|--dry-run)    MODE="dry-run" ;;
  list|status)     MODE="list" ;;
  uninstall)       MODE="uninstall"; [ -n "${2:-}" ] && NAME="$2" ;;
  -h|--help|help)  usage; exit 0 ;;
  -v|--version)    echo "$VERSION"; exit 0 ;;
  *)               echo "error: unknown argument: $1" >&2; echo >&2; usage >&2; exit 2 ;;
esac

ENGINE="$SCRIPT_DIR/engine/$NAME.md"
if { [ "$MODE" = "install" ] || [ "$MODE" = "dry-run" ]; } && [ ! -f "$ENGINE" ]; then
  echo "error: engine not found at $ENGINE" >&2; exit 1
fi

SKILL_FM="$(printf -- '---\nname: %s\ndescription: %s\n---\n\n' "$NAME" "$DESC")"
CMD_FM="$(printf -- '---\ndescription: %s\nargument-hint: %s\n---\n\n' "$DESC" "$ARGHINT")"
OPENCODE_FM="$(printf -- '---\ndescription: %s\nargument-hint: %s\ntools:\n  read: true\n  write: true\n  edit: false\n  bash: true\n---\n\n' "$DESC" "$ARGHINT")"

changed=()
detected=()

# do_emit <artifact-file> <remove-target> <frontmatter>
# install: write the artifact. uninstall: remove it. dry-run: report what would
# be written, writing nothing. list: report it only if it already exists. The
# artifact path is identical across all modes.
do_emit() {
  local artifact="$1" rm_target="$2" fm="$3"
  case "$MODE" in
    uninstall) [ -e "$rm_target" ] && { rm -rf "$rm_target"; changed+=("removed -> $rm_target"); } ;;
    dry-run)   changed+=("would write -> $artifact") ;;
    list)      [ -e "$artifact" ] && changed+=("installed -> $artifact") ;;
    install)   mkdir -p "$(dirname "$artifact")"; { printf -- '%s' "$fm"; cat "$ENGINE"; } > "$artifact"; changed+=("wrote   -> $artifact") ;;
  esac
}

emit_skill()        { do_emit "$1/$NAME/SKILL.md" "$1/$NAME"    "$SKILL_FM"; }    # directory form
emit_pi_skill()     { do_emit "$1/$NAME.md"       "$1/$NAME.md" "$SKILL_FM"; }    # flat file
emit_cmd()          { do_emit "$1/$NAME.md"       "$1/$NAME.md" "$CMD_FM"; }
emit_opencode_cmd() { do_emit "$1/$NAME.md"       "$1/$NAME.md" "$OPENCODE_FM"; }

# detect <dir> <label>: record and announce a tool when its config dir exists.
detect() { [ -d "$1" ] && { detected+=("$2"); echo "[$2]"; return 0; }; return 1; }

echo "mode: $MODE   name: $NAME   version: $VERSION"
{ [ "$MODE" = "install" ] || [ "$MODE" = "dry-run" ]; } && echo "from: $ENGINE"
echo ""

detect "$HOME/.claude"             "Claude Code"                   && emit_skill "$HOME/.claude/skills"
detect "$HOME/.codex"              "Codex CLI"                     && { emit_skill "$HOME/.codex/skills"; emit_cmd "$HOME/.codex/prompts"; }   # skill -> $NAME, prompt -> /$NAME
detect "$HOME/.gemini"             "Gemini CLI"                    && { emit_skill "$HOME/.gemini/skills"; emit_cmd "$HOME/.gemini/commands"; }
detect "$HOME/.cursor"             "Cursor"                        && { emit_skill "$HOME/.cursor/skills"; emit_cmd "$HOME/.cursor/commands"; }
detect "$HOME/.antigravity"        "Antigravity"                   && emit_skill "$HOME/.antigravity/skills"
detect "$HOME/.gemini/antigravity" "Antigravity (gemini profile)"  && { emit_skill "$HOME/.gemini/antigravity/skills"; emit_cmd "$HOME/.gemini/antigravity/commands"; }
detect "$HOME/.pi"                 "pi (pi.dev)"                   && emit_pi_skill "$HOME/.pi/skills"
detect "$HOME/.windsurf"           "Windsurf"                      && emit_cmd "$HOME/.windsurf/commands"
OPENCODE_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"   # opencode honors XDG_CONFIG_HOME
detect "$OPENCODE_DIR"             "opencode"                      && emit_opencode_cmd "$OPENCODE_DIR/command"

echo ""

# No tools at all: explain what was checked and what to do next, rather than a
# bare dead-end.
if [ ${#detected[@]} -eq 0 ]; then
  echo "No supported AI coding tools were detected under \$HOME."
  echo "Looked for: ~/.claude, ~/.codex, ~/.gemini, ~/.cursor, ~/.antigravity,"
  echo "            ~/.gemini/antigravity, ~/.pi, ~/.windsurf, $OPENCODE_DIR"
  echo ""
  echo "Next: open the AI tool once so it creates its config directory, then re-run"
  echo "this installer. For a tool kept elsewhere or not listed, copy"
  echo "  $ENGINE"
  echo "into that tool's command or prompt directory (see AGENTS.md)."
  exit 0
fi

# Tools detected, but nothing to report for this mode.
if [ ${#changed[@]} -eq 0 ]; then
  case "$MODE" in
    list)      echo "uxauditor is not installed in any detected tool. Run ./install.sh to install it." ;;
    uninstall) echo "Nothing to uninstall: uxauditor was not found in any detected tool." ;;
    *)         echo "Nothing to do." ;;
  esac
  exit 0
fi

case "$MODE" in
  install)   echo "Installed ${#changed[@]} artifact(s):" ;;
  dry-run)   echo "Dry run: would write ${#changed[@]} artifact(s) (nothing was written):" ;;
  uninstall) echo "Removed ${#changed[@]} artifact(s):" ;;
  list)      echo "Found ${#changed[@]} installed artifact(s) across ${#detected[@]} detected tool(s):" ;;
esac
for line in "${changed[@]}"; do echo "  $line"; done

if [ "$MODE" = "install" ]; then
  echo ""
  echo "Invoke it:"
  echo "  Claude Code / Antigravity:  /$NAME, or ask \"audit my UX\" (skill auto-triggers)"
  echo "  Codex:  \$$NAME (skill), or /$NAME (prompt)"
  echo "  Gemini / Cursor / Windsurf / opencode / pi:  /$NAME"
  echo "  Any other tool:  see AGENTS.md, or paste $ENGINE as the prompt"
  echo ""
  echo "Re-sync after editing the engine:  ./install.sh"
  echo "Preview without writing:           ./install.sh --dry-run"
  echo "See what is installed:             ./install.sh list"
  echo "Remove from every tool:            ./install.sh uninstall"
fi
