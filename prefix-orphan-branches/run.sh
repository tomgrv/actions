#!/usr/bin/sh

set -e

ORPHAN_PREFIX="${ORPHAN_PREFIX:-orphan/}"
DRY_RUN="${DRY_RUN:-false}"

push="-p"
[ "$DRY_RUN" = "true" ] && push=""

# git-fix-orphans prints one "<old> -> <new>" line per rename on stdout and
# logs on stderr.
# shellcheck disable=SC2086
renamed=$(git fix-orphans $push -x "$ORPHAN_PREFIX")

count=0
[ -n "$renamed" ] && count=$(printf '%s\n' "$renamed" | wc -l | tr -d ' ')

{
  echo "renamed-branches<<EOF"
  [ -n "$renamed" ] && printf '%s\n' "$renamed"
  echo "EOF"
  echo "count=${count}"
}
