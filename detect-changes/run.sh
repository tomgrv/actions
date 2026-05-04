#!/usr/bin/sh

set -e

if [ -n "${GITHUB_WORKSPACE:-}" ]; then
  cd "${GITHUB_WORKSPACE}" || exit 1
  git config --global --add safe.directory "${GITHUB_WORKSPACE}" || exit 1
fi

PATH_ARG="${1:-.}"
SUBPATH_ARG="${2:-}"
STATUS_OPTS="${3:-}"

if [ -n "${SUBPATH_ARG}" ]; then
  TARGET="${PATH_ARG}/${SUBPATH_ARG}"
else
  TARGET="${PATH_ARG}"
fi

echo "Checking for changes in: ${TARGET}" >&2

echo "has-changes=false" >> "${GITHUB_OUTPUT}"

# shellcheck disable=SC2086
if [ -n "$(git status --porcelain ${STATUS_OPTS} -- "${TARGET}")" ]; then
  echo "has-changes=true" >> "${GITHUB_OUTPUT}"
  echo "Changes detected in ${TARGET}" >&2
fi
