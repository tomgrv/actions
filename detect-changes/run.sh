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
  zz_log i "WORKDIR not set, using default: ."
fi

zz_log i "Checking for changes in: ${WORKDIR}"

# shellcheck disable=SC2086
if [ -n "$(git status --porcelain ${OPTIONS} -- "${WORKDIR}")" ]; then
  echo "has-changes=true"
  zz_log i "Changes detected in ${WORKDIR}"
else
  zz_log i "No changes detected in ${WORKDIR}"
  echo "has-changes=false" 
fi
