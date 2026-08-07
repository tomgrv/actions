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

if ! command -v composer >/dev/null 2>&1; then
  echo "::error::composer could not be found. Please install it to run this action." >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "::error::jq could not be found. Please install it to run this action." >&2
  exit 1
fi

REVIEWDOG_NAME="${REVIEWDOG_NAME:-composer-audit}"
REVIEWDOG_REPORTER="${REVIEWDOG_REPORTER:-github-pr-review}"
REVIEWDOG_LEVEL="${REVIEWDOG_LEVEL:-error}"
REVIEWDOG_FILTER_MODE="${REVIEWDOG_FILTER_MODE:-nofilter}"
REVIEWDOG_FAIL_LEVEL="${REVIEWDOG_FAIL_LEVEL:-none}"
REVIEWDOG_FLAGS="${REVIEWDOG_FLAGS:-}"
MAX_DIAGNOSTICS="${MAX_DIAGNOSTICS:-40}"

echo "Running composer audit..." >&2

# Installed versions are needed to work out, per advisory, whether the locked
# version actually falls in the affected range and what the lowest version
# clearing all matching ranges is.
LOCKED_JSON="$(composer show --locked --format=json --no-interaction 2>/dev/null \
  | jq -c '[(.locked // [])[] | {key: .name, value: .version}] | from_entries' 2>/dev/null || true)"
[ -n "${LOCKED_JSON}" ] || LOCKED_JSON='{}'

COMPOSER_JSON_PATH="composer.json"
if [ ! -f "${COMPOSER_JSON_PATH}" ]; then
  COMPOSER_JSON_PATH="$(mktemp)"
  trap 'rm -f "${COMPOSER_JSON_PATH}"' EXIT
fi

exit_code=0
# shellcheck disable=SC2086
{ composer audit --locked --format=json --no-interaction 2>/dev/null || true; } | \
  jq -f "$(dirname "$0")/rdjson.jq" --rawfile composerjson "${COMPOSER_JSON_PATH}" --argjson locked "${LOCKED_JSON}" --argjson maxDiagnostics "${MAX_DIAGNOSTICS}" | \
  reviewdog \
    -f=rdjson \
    -name="${REVIEWDOG_NAME}" \
    -reporter="${REVIEWDOG_REPORTER}" \
    -level="${REVIEWDOG_LEVEL}" \
    -filter-mode="${REVIEWDOG_FILTER_MODE}" \
    -fail-level="${REVIEWDOG_FAIL_LEVEL}" \
    ${REVIEWDOG_FLAGS} || exit_code=$?
exit $exit_code
