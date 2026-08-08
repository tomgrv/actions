#!/usr/bin/sh

set -e

if [ -n "${GITHUB_WORKSPACE:-}" ]; then
  cd "${GITHUB_WORKSPACE}" || exit 1
  git config --global --add safe.directory "${GITHUB_WORKSPACE}" || exit 1
fi

if [ -z "${REVIEWDOG_GITHUB_API_TOKEN:-}" ]; then
  export REVIEWDOG_GITHUB_API_TOKEN="${GITHUB_TOKEN}"
fi

if ! command -v reviewdog >/dev/null 2>&1; then
  echo "::error::reviewdog could not be found. Please install it to run this action." >&2
  exit 1
fi

if ! command -v composer >/dev/null 2>&1; then
  echo "::error::composer could not be found. Please install it to run this action." >&2
  exit 1
fi

{ composer audit --locked --quiet 2>/dev/null || true; } | \
  reviewdog \
    -efm="%m" \
    -name="composer-audit" \
    -reporter=${REVIEWDOG_REPORTER:-github-pr-check} \
    -filter-mode=nofilter \
    -fail-level=none
