#!/usr/bin/sh

set -e

if [ -n "${GITHUB_WORKSPACE:-}" ]; then
  cd "${GITHUB_WORKSPACE}" || exit 1
  git config --global --add safe.directory "${GITHUB_WORKSPACE}" || exit 1
fi

if [ -z "${REVIEWDOG_GITHUB_API_TOKEN:-}" ]; then
  if [ -z "${GITHUB_TOKEN:-}" ]; then
    echo "::error::GITHUB_TOKEN or REVIEWDOG_GITHUB_API_TOKEN is required" >&2
    exit 1
  fi
  echo "::notice::REVIEWDOG_GITHUB_API_TOKEN not set, using GITHUB_TOKEN" >&2
  export REVIEWDOG_GITHUB_API_TOKEN="${GITHUB_TOKEN}"
fi

PINT_PATHS="${PINT_PATHS:-${1:-app}}"
REVIEWDOG_REPORTER="${REVIEWDOG_REPORTER:-github-pr-review}"

echo "Running Pint analysis on: ${PINT_PATHS}" >&2

{ vendor/bin/pint --test --no-interaction --format=checkstyle -- $(echo "${PINT_PATHS}" | tr ',' ' ') 2>/dev/null || true; } | \
  reviewdog \
    -f=checkstyle \
    -name="pint" \
    -reporter="${REVIEWDOG_REPORTER}" \
    -fail-level=none
