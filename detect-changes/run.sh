#!/usr/bin/sh

set -e

if [ -n "${GITHUB_WORKSPACE:-}" ]; then
  cd "${GITHUB_WORKSPACE}" || exit 1
  git config --global --add safe.directory "${GITHUB_WORKSPACE}" || exit 1
fi

WORKDIR="${WORKDIR:-.}"
OPTIONS="${OPTIONS:-}"

echo "Checking for changes in: ${WORKDIR}" >&2

# shellcheck disable=SC2086
if [ -n "$(git status --porcelain ${OPTIONS} -- "${WORKDIR}")" ]; then
  echo "has-changes=true"
  echo "Changes detected in ${WORKDIR}" >&2
else
  echo "No changes detected in ${WORKDIR}" >&2
  echo "has-changes=false" 
fi
