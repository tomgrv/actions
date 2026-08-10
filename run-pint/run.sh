#!/usr/bin/sh

# Run Laravel Pint code style checks (or fixes) and report via reviewdog.
#
# noglob: PINT_ARGS may be an unquoted, word-split list of git-diff-derived
# filenames (dirty/wip mode) and must never undergo pathname expansion.
set -ef

if [ -n "${GITHUB_WORKSPACE:-}" ]; then
    cd "${GITHUB_WORKSPACE}" || exit 1
    git config --global --add safe.directory "${GITHUB_WORKSPACE}" || exit 1
fi

PINT_BIN="pint"
REVIEWDOG_BIN="reviewdog"

# Token/tooling resolution is a setup concern, not a Pint finding: plain log
# only, no GitHub annotation (see .github/instructions/action-creation.md).
if [ -z "${REVIEWDOG_GITHUB_API_TOKEN:-}" ]; then
    if [ -z "${GITHUB_TOKEN:-}" ]; then
        echo "Error: GITHUB_TOKEN or REVIEWDOG_GITHUB_API_TOKEN is required" >&2
        exit 1
    fi
    echo "REVIEWDOG_GITHUB_API_TOKEN not set, using GITHUB_TOKEN" >&2
    export REVIEWDOG_GITHUB_API_TOKEN="${GITHUB_TOKEN}"
fi

FIX="${FIX:-false}"
PINT_PATHS="${PINT_PATHS:-${1:-app}}"
PINT_PRESET="${PINT_PRESET:-laravel}"
PINT_CONFIG="${PINT_CONFIG:-}"
DIRTY="${DIRTY:-false}"
WIP="${WIP:-false}"
DIRTY_FILES="${DIRTY_FILES:-}"
WIP_FILES="${WIP_FILES:-}"
REVIEWDOG_NAME="${REVIEWDOG_NAME:-pint}"
REVIEWDOG_REPORTER="${REVIEWDOG_REPORTER:-github-pr-check}"
REVIEWDOG_LEVEL="${REVIEWDOG_LEVEL:-error}"
REVIEWDOG_FILTER_MODE="${REVIEWDOG_FILTER_MODE:-added}"
REVIEWDOG_FAIL_LEVEL="${REVIEWDOG_FAIL_LEVEL:-none}"
REVIEWDOG_FLAGS="${REVIEWDOG_FLAGS:-}"

if [ "${PINT_PATHS}" = "app" ]; then
    echo "PINT_PATHS not set, using default: app" >&2
fi

# dirty/wip are resolved upstream by the list-dirty/list-wip actions; combine
# their file lists into the explicit target list Pint actually analyzes.
if [ "${DIRTY}" = "true" ] || [ "${WIP}" = "true" ]; then
    PINT_ARGS="$(printf '%s\n%s\n' "${DIRTY_FILES}" "${WIP_FILES}" | sed '/^$/d' | sort -u | tr '\n' ' ')"
    if [ -z "$(printf '%s' "${PINT_ARGS}" | tr -d '[:space:]')" ]; then
        # Functional: nothing in the analyzed repo matches the filter.
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
        echo "Error: config file not found: ${PINT_CONFIG}" >&2
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
    pint_log=$(mktemp)
    trap 'rm -f "${pint_log}"' EXIT INT TERM
    echo "Reviewdog parameters: -f=checkstyle -name=${REVIEWDOG_NAME} -reporter=${REVIEWDOG_REPORTER} -level=${REVIEWDOG_LEVEL} -filter-mode=${REVIEWDOG_FILTER_MODE} -fail-level=${REVIEWDOG_FAIL_LEVEL} -flags=${REVIEWDOG_FLAGS}" >&2
    # shellcheck disable=SC2046,SC2086
    "${PINT_BIN}" --test --no-interaction "${RULES_FLAG}" --format=checkstyle -- ${PINT_ARGS} 2>"${pint_log}" \
        | tee -a "${pint_log}" \
        | "${REVIEWDOG_BIN}" \
            -f=checkstyle \
            -name="${REVIEWDOG_NAME}" \
            -reporter="${REVIEWDOG_REPORTER}" \
            -level="${REVIEWDOG_LEVEL}" \
            -filter-mode="${REVIEWDOG_FILTER_MODE}" \
            -fail-level="${REVIEWDOG_FAIL_LEVEL}" \
            ${REVIEWDOG_FLAGS} || exit_code=$?
    echo "Pint stdout/stderr log:" >&2
    cat "${pint_log}" >&2
    printf 'has-changes=false\n'
    exit $exit_code
fi
