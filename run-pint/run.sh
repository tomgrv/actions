#!/usr/bin/sh

set -e

if [ -n "${GITHUB_WORKSPACE:-}" ]; then
    cd "${GITHUB_WORKSPACE}" || exit 1
    git config --global --add safe.directory "${GITHUB_WORKSPACE}" || exit 1
fi

PATH="${GITHUB_WORKSPACE:-.}/vendor/bin:$(composer config -g home)/vendor/bin:${PATH}"
PINT_BIN="pint"
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
PINT_PATHS="${PINT_PATHS:-${1:-app}}"
PINT_PRESET="${PINT_PRESET:-laravel}"
PINT_CONFIG="${PINT_CONFIG:-}"
DIRTY="${DIRTY:-false}"
WIP="${WIP:-false}"
WIP_BASE_REF="${WIP_BASE_REF:-${GITHUB_BASE_REF:-}}"
REVIEWDOG_NAME="${REVIEWDOG_NAME:-pint}"
REVIEWDOG_REPORTER="${REVIEWDOG_REPORTER:-github-pr-check}"
REVIEWDOG_LEVEL="${REVIEWDOG_LEVEL:-error}"
REVIEWDOG_FILTER_MODE="${REVIEWDOG_FILTER_MODE:-added}"
REVIEWDOG_FAIL_LEVEL="${REVIEWDOG_FAIL_LEVEL:-none}"
REVIEWDOG_FLAGS="${REVIEWDOG_FLAGS:-}"

if [ "${PINT_PATHS}" = "app" ]; then
    echo "::notice::PINT_PATHS not set, using default: app" >&2
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

# Restrict PINT_PATHS to only the changed files under them, space-joined.
_filter_changed_paths() {
    _base_regex="^($(printf '%s' "${PINT_PATHS}" | sed 's/,/|/g; s/[^A-Za-z0-9|_.\/-]//g'))(/|$)"
    _changed_files | grep -E "${_base_regex}" | grep -E '\.php$' | tr '\n' ' '
}

if [ "${DIRTY}" = "true" ] || [ "${WIP}" = "true" ]; then
    PINT_ARGS="$(_filter_changed_paths)" || exit 1
    if [ -z "$(printf '%s' "${PINT_ARGS}" | tr -d '[:space:]')" ]; then
        echo "::notice::No changed PHP files under: ${PINT_PATHS} (dirty=${DIRTY}, wip=${WIP}); skipping Pint." >&2
        printf 'has-changes=false\n'
        exit 0
    fi
    echo "Restricting Pint to changed files: ${PINT_ARGS}" >&2
else
    PINT_ARGS="$(echo "${PINT_PATHS}" | tr ',' ' ')"
fi

if [ -n "${PINT_CONFIG}" ]; then
    if [ ! -f "${PINT_CONFIG}" ]; then
        echo "::error::config file not found: ${PINT_CONFIG}" >&2
        exit 1
    fi
    echo "Running Pint on: ${PINT_PATHS} with config: ${PINT_CONFIG}" >&2
    RULES_FLAG="--config=${PINT_CONFIG}"
else
    echo "Running Pint on: ${PINT_PATHS} with preset: ${PINT_PRESET}" >&2
    RULES_FLAG="--preset=${PINT_PRESET}"
fi

if [ "${FIX}" = "true" ]; then
    echo "Running Pint in fix mode." >&2
    # Word splitting is intentional: PINT_ARGS is a space-separated list of paths/files.
    # shellcheck disable=SC2046,SC2086
    "${PINT_BIN}" --no-interaction "${RULES_FLAG}" -- ${PINT_ARGS} >&2 || true
    if git diff --quiet; then
        printf 'has-changes=false\n'
    else
        printf 'has-changes=true\n'
    fi
else
    echo "Running Pint in test mode (no fixes will be applied)." >&2
    exit_code=0
    # shellcheck disable=SC2046,SC2086
    "${PINT_BIN}" --test --no-interaction "${RULES_FLAG}" --format=checkstyle -- ${PINT_ARGS} 2> /dev/null \
        | "${REVIEWDOG_BIN}" \
            -f=checkstyle \
            -name="${REVIEWDOG_NAME}" \
            -reporter="${REVIEWDOG_REPORTER}" \
            -level="${REVIEWDOG_LEVEL}" \
            -filter-mode="${REVIEWDOG_FILTER_MODE}" \
            -fail-level="${REVIEWDOG_FAIL_LEVEL}" \
            ${REVIEWDOG_FLAGS} || exit_code=$?
    printf 'has-changes=false\n'
    exit $exit_code
fi
