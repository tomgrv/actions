#!/usr/bin/sh

set -e

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

PHPMD_BIN="$(resolve_binary phpmd phpmd PHPMD)"
REVIEWDOG_BIN="$(resolve_binary reviewdog reviewdog reviewdog)"

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
"${PHPMD_BIN}" "${PHPMD_PATHS}" sarif "${PHPMD_RULESET}" --cache --cache-strategy content --ignore-errors-on-exit --ignore-violations-on-exit --${PHPMD_PRIORITY}-priority 2> /dev/null \
    | "${REVIEWDOG_BIN}" \
        -f=sarif \
        -name="phpmd" \
        -reporter="${REVIEWDOG_REPORTER}" \
        -level="${REVIEWDOG_LEVEL}" \
        -filter-mode="${REVIEWDOG_FILTER_MODE}" \
        -fail-level="${REVIEWDOG_FAIL_LEVEL}" \
        ${REVIEWDOG_FLAGS} || exit_code=$?
exit $exit_code
