#!/usr/bin/sh

set -e

if [ -n "${GITHUB_WORKSPACE:-}" ]; then
    cd "${GITHUB_WORKSPACE}" || exit 1
    git config --global --add safe.directory "${GITHUB_WORKSPACE}" || exit 1
fi

PATH="${GITHUB_WORKSPACE:-.}/vendor/bin:$(composer config -g home)/vendor/bin:${PATH}"
PHPSTAN_BIN="phpstan"
REVIEWDOG_BIN="reviewdog"

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
PHPSTAN_CONFIG="${PHPSTAN_CONFIG:-}"
DIRTY="${DIRTY:-false}"
WIP="${WIP:-false}"
WIP_BASE_REF="${WIP_BASE_REF:-${GITHUB_BASE_REF:-}}"
REVIEWDOG_NAME="${REVIEWDOG_NAME:-phpstan}"
REVIEWDOG_REPORTER="${REVIEWDOG_REPORTER:-github-pr-check}"
REVIEWDOG_LEVEL="${REVIEWDOG_LEVEL:-error}"
REVIEWDOG_FILTER_MODE="${REVIEWDOG_FILTER_MODE:-added}"
REVIEWDOG_FAIL_LEVEL="${REVIEWDOG_FAIL_LEVEL:-none}"
REVIEWDOG_FLAGS="${REVIEWDOG_FLAGS:-}"

if [ "${TARGET_PATHS}" = "app" ]; then
    echo "::notice::TARGET_PATHS not set, using default: app" >&2
fi

#
# Emulate dirty/wip when the tool itself has no such flag: collapse the
# directory-based path list down to only the files that actually changed, so
# unrelated files are never even handed to the tool.
#
_changed_files() {
    _files=""

    if [ "${DIRTY}" = "true" ]; then
        _files="${_files}
$(git diff --name-only --diff-filter=ACMR -- .)
$(git diff --name-only --cached --diff-filter=ACMR -- .)
$(git ls-files --others --exclude-standard -- .)"
    fi

    if [ "${WIP}" = "true" ]; then
        if [ -z "${WIP_BASE_REF}" ]; then
            echo "::error::wip requires a base ref: set GITHUB_BASE_REF (automatic on pull_request events) or the wip-base-ref input" >&2
            return 1
        fi
        git fetch --depth=1 origin "${WIP_BASE_REF}" > /dev/null 2>&1 || true
        _merge_base="$(git merge-base "origin/${WIP_BASE_REF}" HEAD 2> /dev/null || echo "${WIP_BASE_REF}")"
        _files="${_files}
$(git diff --name-only --diff-filter=ACMR "${_merge_base}" -- .)"
    fi

    printf '%s\n' "${_files}" | sed '/^$/d' | sort -u
}

# Restrict TARGET_PATHS to only the changed files under them, space-joined.
_filter_changed_paths() {
    _base_regex="^($(printf '%s' "${TARGET_PATHS}" | sed 's/,/|/g; s/[^A-Za-z0-9|_.\/-]//g'))(/|$)"
    _changed_files | grep -E "${_base_regex}" | grep -E '\.php$' | tr '\n' ' '
}

if [ "${DIRTY}" = "true" ] || [ "${WIP}" = "true" ]; then
    TARGET_ARGS="$(_filter_changed_paths)" || exit 1
    if [ -z "$(printf '%s' "${TARGET_ARGS}" | tr -d '[:space:]')" ]; then
        echo "::notice::No changed PHP files under: ${TARGET_PATHS} (dirty=${DIRTY}, wip=${WIP}); skipping PHPStan." >&2
        printf 'has-changes=false\n'
        exit 0
    fi
    echo "Restricting PHPStan to changed files: ${TARGET_ARGS}" >&2
else
    TARGET_ARGS="$(echo "${TARGET_PATHS}" | tr ',' ' ')"
fi

if [ "${FIX}" = "true" ]; then
    echo "FIX is set to true, running PHPStan with --fix" >&2
    FIX_FLAG="--fix"
else
    FIX_FLAG=""
fi

if [ -n "${PHPSTAN_CONFIG}" ]; then
    if [ ! -f "${PHPSTAN_CONFIG}" ]; then
        echo "::error::config file not found: ${PHPSTAN_CONFIG}" >&2
        exit 1
    fi
    echo "Using custom PHPStan configuration: ${PHPSTAN_CONFIG}" >&2
    CONFIG_FLAG="-c ${PHPSTAN_CONFIG}"
else
    CONFIG_FLAG=""
fi

echo "Running PHPStan analysis on: ${TARGET_PATHS}" >&2

exit_code=0
# shellcheck disable=SC2086
"${PHPSTAN_BIN}" analyse ${FIX_FLAG} ${CONFIG_FLAG} --error-format=checkstyle --memory-limit=512M --no-progress -- ${TARGET_ARGS} 2> /dev/null \
    | "${REVIEWDOG_BIN}" \
        -f=checkstyle \
        -name="${REVIEWDOG_NAME}" \
        -reporter="${REVIEWDOG_REPORTER}" \
        -level="${REVIEWDOG_LEVEL}" \
        -filter-mode="${REVIEWDOG_FILTER_MODE}" \
        -fail-level="${REVIEWDOG_FAIL_LEVEL}" \
        ${REVIEWDOG_FLAGS} || exit_code=$?
exit $exit_code
