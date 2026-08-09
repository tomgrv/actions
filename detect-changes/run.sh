#!/usr/bin/sh

# Report whether the working directory has uncommitted or untracked changes.

set -e

if [ -n "${GITHUB_WORKSPACE:-}" ]; then
  cd "${GITHUB_WORKSPACE}" || exit 1
  git config --global --add safe.directory "${GITHUB_WORKSPACE}" || exit 1
fi

WORKDIR="${WORKDIR:-.}"
OPTIONS="${OPTIONS:-}"

# Input defaulting is a setup detail, not a finding: plain log only.
if [ "${WORKDIR}" = "." ]; then
  echo "WORKDIR not set, using default: ." >&2
fi

echo "Checking for changes in: ${WORKDIR}" >&2

# shellcheck disable=SC2086
if [ -n "$(git status --porcelain ${OPTIONS} -- "${WORKDIR}")" ]; then
  echo "has-changes=true"
  echo "Changes detected in ${WORKDIR}" >&2
else
  echo "No changes detected in ${WORKDIR}" >&2
  echo "has-changes=false" 
fi
