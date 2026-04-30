#!/usr/bin/sh

set -e

if [ -n "${GITHUB_WORKSPACE:-}" ]; then
  cd "${GITHUB_WORKSPACE}" || exit 1
  git config --global --add safe.directory "${GITHUB_WORKSPACE}" || exit 1
fi

if [ -z "${REVIEWDOG_GITHUB_API_TOKEN:-}" ]; then
  export REVIEWDOG_GITHUB_API_TOKEN="${GITHUB_TOKEN}"
fi

echo "Running Pint analysis on: ${1:-app}" >&2

{ vendor/bin/pint --test --no-interaction --format=checkstyle -- $(echo ${1:-app} | tr ',' ' ') 2>/dev/null || true; } | \
  reviewdog \
    -f=checkstyle \
    -name="pint" \
    -reporter=${REVIEWDOG_REPORTER:-github-pr-review} \
    -fail-level=none
