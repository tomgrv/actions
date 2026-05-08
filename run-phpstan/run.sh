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

FIX="${FIX:-false}"
TARGET_PATHS="${TARGET_PATHS:-${1:-app}}"
BASELINE_FILE="${BASELINE_FILE:-phpstan-baseline.neon}"
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

echo "Running PHPStan analysis on: ${TARGET_PATHS}" >&2

exit_code=0
vendor/bin/phpstan analyse ${FIX_FLAG} --error-format=checkstyle --memory-limit=512M --no-progress -- $(echo "${TARGET_PATHS}" | tr ',' ' ') 2>/dev/null | \
  reviewdog \
    -f=checkstyle \
    -name="phpstan" \
    -reporter="${REVIEWDOG_REPORTER}" \
    -level="${REVIEWDOG_LEVEL}" \
    -filter-mode="${REVIEWDOG_FILTER_MODE}" \
    -fail-level="${REVIEWDOG_FAIL_LEVEL}" \
    ${REVIEWDOG_FLAGS} || exit_code=$?
exit $exit_code

