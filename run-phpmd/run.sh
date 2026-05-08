#!/usr/bin/sh

set -e


if ! command -v vendor/bin/phpmd >/dev/null 2>&1; then
  echo "::error::PHPMD could not be found at vendor/bin/phpmd. Please ensure it is installed." >&2
  exit 1
fi

if ! command -v reviewdog >/dev/null 2>&1; then
  echo "::error::reviewdog could not be found. Please ensure it is installed and in the PATH." >&2
  exit 1
fi

PHPMD_RULESET="${PHPMD_RULESET:-cleancode,codesize,controversial,design,naming,unusedcode}"
PHPMD_PRIORITY="${PHPMD_PRIORITY:-max}"
PHPMD_PATHS="${PHPMD_PATHS:-${1:-app}}"

if [ "${PHPMD_PATHS}" = "app" ]; then
  echo "::notice::PHPMD_PATHS not set, using default: app" >&2
fi

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

REVIEWDOG_REPORTER="${REVIEWDOG_REPORTER:-github-pr-check}"
REVIEWDOG_LEVEL="${REVIEWDOG_LEVEL:-error}"
REVIEWDOG_FILTER_MODE="${REVIEWDOG_FILTER_MODE:-nofilter}"
REVIEWDOG_FAIL_LEVEL="${REVIEWDOG_FAIL_LEVEL:-none}"
REVIEWDOG_FLAGS="${REVIEWDOG_FLAGS:-}"


echo "Running PHPmd on <${PHPMD_PATHS}> with ruleset: ${PHPMD_RULESET}" >&2

exit_code=0
# shellcheck disable=SC2086
vendor/bin/phpmd "${PHPMD_PATHS}" sarif "${PHPMD_RULESET}" --cache --cache-strategy content --ignore-errors-on-exit --ignore-violations-on-exit --${PHPMD_PRIORITY}-priority 2>/dev/null | \
  reviewdog \
    -f=sarif \
    -name="phpmd" \
    -reporter="${REVIEWDOG_REPORTER}" \
    -level="${REVIEWDOG_LEVEL}" \
    -filter-mode="${REVIEWDOG_FILTER_MODE}" \
    -fail-level="${REVIEWDOG_FAIL_LEVEL}" \
    ${REVIEWDOG_FLAGS} || exit_code=$?
exit $exit_code
