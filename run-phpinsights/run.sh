#!/usr/bin/sh

set -e

if [ -n "${GITHUB_WORKSPACE:-}" ]; then
    cd "${GITHUB_WORKSPACE}" || exit 1
    git config --global --add safe.directory "${GITHUB_WORKSPACE}" || exit 1
fi

resolve_binary() {
    local_binary="$1"
    global_binary="$2"
    display_name="$3"

    if [ -x "./vendor/bin/${local_binary}" ]; then
        printf './vendor/bin/%s' "${local_binary}"
        return 0
    fi

    if command -v "${global_binary}" > /dev/null 2>&1; then
        command -v "${global_binary}"
        return 0
    fi

    echo "::error::${display_name} could not be found in ./vendor/bin/${local_binary} or in PATH. Please install it locally or make it available globally." >&2
    exit 1
}

PHPINSIGHTS_BIN="$(resolve_binary phpinsights phpinsights 'PHP Insights')"
REVIEWDOG_BIN="$(resolve_binary reviewdog reviewdog reviewdog)"

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
"${PHPINSIGHTS_BIN}" analyse ${FIX_FLAG} --no-interaction --format=checkstyle -- $(echo "${TARGET_PATHS}" | tr ',' ' ') 2> /dev/null \
    | "${REVIEWDOG_BIN}" \
        -f=checkstyle \
        -name="phpinsights" \
        -reporter="${REVIEWDOG_REPORTER}" \
        -level="${REVIEWDOG_LEVEL}" \
        -filter-mode="${REVIEWDOG_FILTER_MODE}" \
        -fail-level="${REVIEWDOG_FAIL_LEVEL}" \
        ${REVIEWDOG_FLAGS} || exit_code=$?
exit $exit_code
