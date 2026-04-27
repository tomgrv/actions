#!/usr/bin/sh

set -e

if [ -n "${GITHUB_WORKSPACE:-}" ]; then
  cd "${GITHUB_WORKSPACE}" || exit 1
  git config --global --add safe.directory "${GITHUB_WORKSPACE}" || exit 1
fi

if [ -z "${REVIEWDOG_GITHUB_API_TOKEN:-}" ]; then
  export REVIEWDOG_GITHUB_API_TOKEN="${GITHUB_TOKEN}"
fi

echo "Running PHPStan analysis on: $1"

{ vendor/bin/phpstan analyse --error-format=checkstyle --memory-limit=512M --no-progress -- $(echo ${1:-app} | tr ',' ' ') 2>/dev/null || true; } | \
  reviewdog \
    -f=checkstyle \
    -name="phpstan" \
    -reporter=${REVIEWDOG_REPORTER:-github-pr-review} \
    -filter-mode=diff_context \
    -fail-level=none

