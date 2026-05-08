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
PINT_PATHS="${PINT_PATHS:-${1:-app}}"
PINT_PRESET="${PINT_PRESET:-laravel}"
REVIEWDOG_REPORTER="${REVIEWDOG_REPORTER:-github-pr-check}"
REVIEWDOG_LEVEL="${REVIEWDOG_LEVEL:-error}"
REVIEWDOG_FILTER_MODE="${REVIEWDOG_FILTER_MODE:-added}"
REVIEWDOG_FAIL_LEVEL="${REVIEWDOG_FAIL_LEVEL:-none}"
REVIEWDOG_FLAGS="${REVIEWDOG_FLAGS:-}"

if [ "${PINT_PATHS}" = "app" ]; then
  echo "::notice::PINT_PATHS not set, using default: app" >&2
fi

echo "Running Pint on: ${PINT_PATHS} with preset: ${PINT_PRESET}" >&2

if [ "${FIX}" = "true" ]; then
  echo "Running Pint in fix mode." >&2
  # Word splitting is intentional: tr converts commas to spaces so each path becomes a separate argument.
  # shellcheck disable=SC2046
  vendor/bin/pint --no-interaction --preset="${PINT_PRESET}" -- $(echo "${PINT_PATHS}" | tr ',' ' ') >&2 || true
  if git diff --quiet; then
    printf 'has-changes=false\n'
  else
    printf 'has-changes=true\n'
  fi
else
  echo "Running Pint in test mode (no fixes will be applied)." >&2
  exit_code=0
  # shellcheck disable=SC2046,SC2086
  vendor/bin/pint --test --no-interaction --preset="${PINT_PRESET}" --format=checkstyle -- $(echo "${PINT_PATHS}" | tr ',' ' ') 2>/dev/null | \
    reviewdog \
      -f=checkstyle \
      -name="pint" \
      -reporter="${REVIEWDOG_REPORTER}" \
      -level="${REVIEWDOG_LEVEL}" \
      -filter-mode="${REVIEWDOG_FILTER_MODE}" \
      -fail-level="${REVIEWDOG_FAIL_LEVEL}" \
      ${REVIEWDOG_FLAGS} || exit_code=$?
  printf 'has-changes=false\n'
  exit $exit_code
fi
