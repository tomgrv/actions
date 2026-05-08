#!/usr/bin/sh

set -e

if ! command -v vendor/bin/phpinsights >/dev/null 2>&1; then
  echo "::error::PHP Insights could not be found at vendor/bin/phpinsights. Please ensure it is installed." >&2
  exit 1
fi

if ! command -v reviewdog >/dev/null 2>&1; then
  echo "::error::reviewdog could not be found. Please ensure it is installed and in the PATH." >&2
  exit 1
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

FIX="${FIX:-false}"
TARGET_PATHS="${TARGET_PATHS:-${1:-app}}"
REVIEWDOG_REPORTER="${REVIEWDOG_REPORTER:-github-pr-check}"
REVIEWDOG_LEVEL="${REVIEWDOG_LEVEL:-error}"
REVIEWDOG_FILTER_MODE="${REVIEWDOG_FILTER_MODE:-added}"
REVIEWDOG_FAIL_LEVEL="${REVIEWDOG_FAIL_LEVEL:-none}"
REVIEWDOG_FLAGS="${REVIEWDOG_FLAGS:-}"

if [ "${TARGET_PATHS}" = "app" ]; then
  echo "::notice::TARGET_PATHS not set, using default: app" >&2
fi

if [ "${FIX}" = "true" ]; then
  echo "FIX is set to true, running PHPStan with --fix" >&2
  FIX_FLAG="--fix"
else
  FIX_FLAG=""
fi


echo "Running PHP Insights on: ${TARGET_PATHS}" >&2

exit_code=0
# shellcheck disable=SC2046,SC2086
vendor/bin/phpinsights analyse ${FIX_FLAG} --no-interaction --format=checkstyle -- $(echo "${TARGET_PATHS}" | tr ',' ' ') 2>/dev/null | \
  reviewdog \
    -f=checkstyle \
    -name="phpinsights" \
    -reporter="${REVIEWDOG_REPORTER}" \
    -level="${REVIEWDOG_LEVEL}" \
    -filter-mode="${REVIEWDOG_FILTER_MODE}" \
    -fail-level="${REVIEWDOG_FAIL_LEVEL}" \
    ${REVIEWDOG_FLAGS} || exit_code=$?
exit $exit_code

