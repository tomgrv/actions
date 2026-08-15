#!/usr/bin/sh

# Run Laravel Pint code style checks and report via reviewdog.
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

if [ -z "${REVIEWDOG_GITHUB_API_TOKEN:-}" ]; then
    echo "Error: GITHUB_TOKEN or REVIEWDOG_GITHUB_API_TOKEN is required" >&2
    exit 1
fi

PINT_PATHS="${PINT_PATHS:-${1:-app}}"
PINT_PRESET="${PINT_PRESET:-laravel}"
PINT_CONFIG="${PINT_CONFIG:-}"
BLADE="${BLADE:-false}"
DIRTY="${DIRTY:-false}"
WIP="${WIP:-false}"
DIRTY_FILES="${DIRTY_FILES:-}"
WIP_FILES="${WIP_FILES:-}"
REVIEWDOG_NAME="${REVIEWDOG_NAME:-pint}"
REVIEWDOG_REPORTER="${REVIEWDOG_REPORTER:-github-check}"
REVIEWDOG_LEVEL="${REVIEWDOG_LEVEL:-error}"
REVIEWDOG_FILTER_MODE="file"
REVIEWDOG_FAIL_LEVEL="${REVIEWDOG_FAIL_LEVEL:-none}"
REVIEWDOG_FLAGS="${REVIEWDOG_FLAGS:-}"

# dirty/wip are resolved upstream by the list-dirty/list-wip actions; combine
# their file lists into the explicit target list Pint actually analyzes.
if [ "${DIRTY}" = "true" ] || [ "${WIP}" = "true" ]; then
    PINT_ARGS="$(printf '%s\n%s\n' "${DIRTY_FILES}" "${WIP_FILES}" | sed '/^$/d' | sort -u | tr '\n' ' ')"
    if [ -z "$(printf '%s' "${PINT_ARGS}" | tr -d '[:space:]')" ]; then
        echo "::notice::No changed PHP files under: ${PINT_PATHS} (dirty=${DIRTY}, wip=${WIP}); skipping Pint." >&2
        exit 0
    fi
else
    PINT_ARGS="$(echo "${PINT_PATHS}" | tr ',' ' ')"
fi

if [ -n "${PINT_CONFIG}" ]; then
    if [ ! -f "${PINT_CONFIG}" ]; then
        echo "Error: config file not found: ${PINT_CONFIG}" >&2
        exit 1
    fi
    RULES_FLAG="--config=${PINT_CONFIG}"
else
    RULES_FLAG="--preset=${PINT_PRESET}"
fi

BLADE_FLAG=""
if [ "${BLADE}" = "true" ]; then
    BLADE_FLAG="--blade"
fi

# Pint's own exit code is not used as the step's exit code: findings are
# reviewdog's job to gate (via fail-level), not a script failure. The pipe's
# exit code below is reviewdog's, since it is the last command in the pipe.
exit_code=0
pint_log=$(mktemp)
trap 'rm -f "${pint_log}"' EXIT INT TERM
# shellcheck disable=SC2046,SC2086
"${PINT_BIN}" --test --no-interaction "${RULES_FLAG}" ${BLADE_FLAG} --format=checkstyle -- ${PINT_ARGS} 2>"${pint_log}" \
    | tee -a "${pint_log}" \
    | "${REVIEWDOG_BIN}" \
        -f=checkstyle \
        -name="${REVIEWDOG_NAME}" \
        -reporter="${REVIEWDOG_REPORTER}" \
        -level="${REVIEWDOG_LEVEL}" \
        -filter-mode="${REVIEWDOG_FILTER_MODE}" \
        -fail-level="${REVIEWDOG_FAIL_LEVEL}" \
        ${REVIEWDOG_FLAGS} || exit_code=$?

cat "${pint_log}" >&2
exit $exit_code
