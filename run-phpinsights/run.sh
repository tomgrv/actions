#!/usr/bin/sh

# Run PHP Insights and report findings via reviewdog.
#
# noglob: TARGET_ARGS may be an unquoted, word-split list of git-diff-derived
# filenames (dirty/wip mode) and must never undergo pathname expansion.
set -ef

if [ -n "${GITHUB_WORKSPACE:-}" ]; then
    cd "${GITHUB_WORKSPACE}" || exit 1
    git config --global --add safe.directory "${GITHUB_WORKSPACE}" || exit 1
fi

# Missing binaries are a setup concern, not a PHP Insights finding: plain
# log only, no GitHub annotation. setup-php puts both ./vendor/bin and the
# global Composer bin directory on PATH, so a plain PATH lookup covers both.
resolve_binary() {
    binary="$1"
    display_name="$2"

    if command -v "${binary}" > /dev/null 2>&1; then
        command -v "${binary}"
        return 0
    fi

    echo "Error: ${display_name} could not be found in vendor/bin or in PATH. Please install it locally or make it available globally." >&2
    exit 1
}

PHPINSIGHTS_BIN="$(resolve_binary phpinsights 'PHP Insights')"
REVIEWDOG_BIN="$(resolve_binary reviewdog reviewdog)"

# Token resolution (input vs GITHUB_TOKEN) happens in setup-reviewdog.
if [ -z "${REVIEWDOG_GITHUB_API_TOKEN:-}" ]; then
    echo "Error: GITHUB_TOKEN or REVIEWDOG_GITHUB_API_TOKEN is required" >&2
    exit 1
fi

TARGET_PATHS="${TARGET_PATHS:-${1:-app}}"
PHPINSIGHTS_CONFIG_PATH="${PHPINSIGHTS_CONFIG_PATH:-}"
DIRTY="${DIRTY:-false}"
WIP="${WIP:-false}"
DIRTY_FILES="${DIRTY_FILES:-}"
WIP_FILES="${WIP_FILES:-}"
REVIEWDOG_NAME="${REVIEWDOG_NAME:-phpinsights}"
REVIEWDOG_REPORTER="${REVIEWDOG_REPORTER:-github-check}"
REVIEWDOG_LEVEL="${REVIEWDOG_LEVEL:-error}"
REVIEWDOG_FILTER_MODE="file"
REVIEWDOG_FAIL_LEVEL="${REVIEWDOG_FAIL_LEVEL:-none}"
REVIEWDOG_FLAGS="${REVIEWDOG_FLAGS:-}"

if [ "${TARGET_PATHS}" = "app" ]; then
    echo "TARGET_PATHS not set, using default: app" >&2
fi

# dirty/wip are resolved upstream by the list-dirty/list-wip actions; combine
# their file lists into the explicit target list PHP Insights actually analyzes.
if [ "${DIRTY}" = "true" ] || [ "${WIP}" = "true" ]; then
    TARGET_ARGS="$(printf '%s\n%s\n' "${DIRTY_FILES}" "${WIP_FILES}" | sed '/^$/d' | sort -u | tr '\n' ' ')"
    if [ -z "$(printf '%s' "${TARGET_ARGS}" | tr -d '[:space:]')" ]; then
        # Functional: nothing in the analyzed repo matches the filter.
        echo "::notice::No changed PHP files under: ${TARGET_PATHS} (dirty=${DIRTY}, wip=${WIP}); skipping PHP Insights." >&2
        exit 0
    fi
    echo "Restricting PHP Insights to changed files: ${TARGET_ARGS}" >&2
else
    TARGET_ARGS="$(echo "${TARGET_PATHS}" | tr ',' ' ')"
fi

if [ -n "${PHPINSIGHTS_CONFIG_PATH}" ]; then
    if [ ! -f "${PHPINSIGHTS_CONFIG_PATH}" ]; then
        echo "Error: config-path file not found: ${PHPINSIGHTS_CONFIG_PATH}" >&2
        exit 1
    fi
    echo "Using custom PHP Insights configuration: ${PHPINSIGHTS_CONFIG_PATH}" >&2
    CONFIG_FLAG="--config-path=${PHPINSIGHTS_CONFIG_PATH}"
else
    CONFIG_FLAG=""
fi

echo "Running PHP Insights on: ${TARGET_PATHS}" >&2

exit_code=0
phpinsights_log=$(mktemp)
trap 'rm -f "${phpinsights_log}"' EXIT INT TERM
echo "Reviewdog parameters: -f=checkstyle -name=${REVIEWDOG_NAME} -reporter=${REVIEWDOG_REPORTER} -level=${REVIEWDOG_LEVEL} -filter-mode=${REVIEWDOG_FILTER_MODE} -fail-level=${REVIEWDOG_FAIL_LEVEL} -flags=${REVIEWDOG_FLAGS}" >&2
# shellcheck disable=SC2046,SC2086
"${PHPINSIGHTS_BIN}" analyse ${CONFIG_FLAG} --no-interaction --format=checkstyle -- ${TARGET_ARGS} 2>"${phpinsights_log}" \
    | tee -a "${phpinsights_log}" \
    | "${REVIEWDOG_BIN}" \
        -f=checkstyle \
        -name="${REVIEWDOG_NAME}" \
        -reporter="${REVIEWDOG_REPORTER}" \
        -level="${REVIEWDOG_LEVEL}" \
        -filter-mode="${REVIEWDOG_FILTER_MODE}" \
        -fail-level="${REVIEWDOG_FAIL_LEVEL}" \
        ${REVIEWDOG_FLAGS} || exit_code=$?
echo "PHP Insights stdout/stderr log:" >&2
cat "${phpinsights_log}" >&2
exit $exit_code
