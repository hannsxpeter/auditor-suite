#!/usr/bin/env bash
# _skills.sh: the suite roster, read from the skills/ directories. Sourced by
# lint.sh, sync-shared.sh, and refresh-plugins.sh after they set ROOT; never
# run on its own.
#
# There is no list of skill names to edit. Every directory under skills/ is on
# the roster, with or without a SKILL.md, so a half-built skill fails the lint
# instead of dropping out of it. Adding an auditor means adding its files;
# `bash scripts/lint.sh suite-registry` names every place it must appear.
#
# Sets:
#   SKILLS          space-separated skill names, in glob order
#   SKILLS_INVALID  newline-separated directory names that are not lower-case
#                   letters, digits, and hyphens; kept off SKILLS because a
#                   space-separated list cannot carry them safely
#
# Bash 3.2 compatible.

SKILLS=""
SKILLS_INVALID=""
for _as_skill in "$ROOT"/skills/*/; do
  [ -d "$_as_skill" ] || continue
  _as_skill="${_as_skill%/}"
  _as_skill="${_as_skill##*/}"
  # Spelled-out classes: bracket ranges such as a-z follow the locale's
  # collation order in bash 3.2 and can match upper-case letters.
  case "$_as_skill" in
    (*[!abcdefghijklmnopqrstuvwxyz0123456789-]*|[!abcdefghijklmnopqrstuvwxyz]*)
      SKILLS_INVALID="$SKILLS_INVALID$_as_skill
" ;;
    (*) SKILLS="$SKILLS${SKILLS:+ }$_as_skill" ;;
  esac
done
unset _as_skill
