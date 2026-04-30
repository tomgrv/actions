#!/usr/bin/sh

set -e

PHPMD_RULESET="${PHPMD_RULESET:-cleancode,codesize,controversial,design,naming,unusedcode}"
PHPMD_PRIORITY="${PHPMD_PRIORITY:-max}"
PHPMD_PATHS="${1:-app}"

if [ -n "${GITHUB_WORKSPACE:-}" ]; then
  cd "${GITHUB_WORKSPACE}" || exit 1
  git config --global --add safe.directory "${GITHUB_WORKSPACE}" || exit 1
fi

if [ -z "${REVIEWDOG_GITHUB_API_TOKEN:-}" ]; then
  export REVIEWDOG_GITHUB_API_TOKEN="${GITHUB_TOKEN}"
fi

echo "Running PHPmd analysis on <${PHPMD_PATHS}> with ruleset: ${PHPMD_RULESET}" >&2

{ vendor/bin/phpmd "${PHPMD_PATHS}" sarif "${PHPMD_RULESET}" --cache --cache-strategy content --ignore-errors-on-exit --ignore-violations-on-exit --${PHPMD_PRIORITY}-priority || true; } | \
  reviewdog \
    -f=sarif \
    -name="phpmd" \
    -reporter=${REVIEWDOG_REPORTER:-github-pr-review} \
    -filter-mode=nofilter \
    -fail-level=none
