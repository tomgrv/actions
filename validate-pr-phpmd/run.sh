#!/usr/bin/sh

set -e

if [ -n "${GITHUB_WORKSPACE:-}" ]; then
  cd "${GITHUB_WORKSPACE}" || exit 1
  git config --global --add safe.directory "${GITHUB_WORKSPACE}" || exit 1
fi

if [ -z "${REVIEWDOG_GITHUB_API_TOKEN:-}" ]; then
  export REVIEWDOG_GITHUB_API_TOKEN="${GITHUB_TOKEN}"
fi

echo "Running PHPmd analysis on: $1 with ruleset: $2"

{ vendor/bin/phpmd "${1:-app}" sarif "${2:-cleancode,codesize,controversial,design,naming,unusedcode}" --cache --ignore-errors-on-exit --ignore-violations-on-exit --${3:-max}-priority 2>/dev/null || true; } | \
  reviewdog \
    -f=sarif \
    -name="phpmd" \
    -reporter=${REVIEWDOG_REPORTER:-github-pr-review} \
    -filter-mode=nofilter \
    -fail-level=none
