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

if ! command -v reviewdog >/dev/null 2>&1; then
  echo "::error::reviewdog could not be found. Please install it to run this action." >&2
  exit 1
fi

if ! command -v npm >/dev/null 2>&1; then
  echo "::error::npm could not be found. Please install it to run this action." >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "::error::jq could not be found. Please install it to run this action." >&2
  exit 1
fi

REVIEWDOG_NAME="${REVIEWDOG_NAME:-npm-audit}"
REVIEWDOG_REPORTER="${REVIEWDOG_REPORTER:-github-pr-review}"
REVIEWDOG_LEVEL="${REVIEWDOG_LEVEL:-error}"
REVIEWDOG_FILTER_MODE="${REVIEWDOG_FILTER_MODE:-nofilter}"
REVIEWDOG_FAIL_LEVEL="${REVIEWDOG_FAIL_LEVEL:-none}"
REVIEWDOG_FLAGS="${REVIEWDOG_FLAGS:-}"

echo "Running npm audit..." >&2

PACKAGE_JSON_PATH="package.json"
if [ ! -f "${PACKAGE_JSON_PATH}" ]; then
  PACKAGE_JSON_PATH="$(mktemp)"
  trap 'rm -f "${PACKAGE_JSON_PATH}"' EXIT
fi

exit_code=0
# shellcheck disable=SC2086
npm audit --workspaces --audit-level moderate --package-lock-only --json 2>/dev/null \
  | jq -f "$(dirname "$0")/rdjson.jq" --rawfile pkgjson "${PACKAGE_JSON_PATH}" \
  | reviewdog \
      -f=rdjson \
      -name="${REVIEWDOG_NAME}" \
      -reporter="${REVIEWDOG_REPORTER}" \
      -level="${REVIEWDOG_LEVEL}" \
      -filter-mode="${REVIEWDOG_FILTER_MODE}" \
      -fail-level="${REVIEWDOG_FAIL_LEVEL}" \
      ${REVIEWDOG_FLAGS} || exit_code=$?
exit $exit_code
