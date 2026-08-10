#!/usr/bin/sh

# Run PHPStan static analysis and report findings via reviewdog.
#
# noglob: TARGET_ARGS may be an unquoted, word-split list of git-diff-derived
# filenames (dirty/wip mode) and must never undergo pathname expansion.
set -ef

if [ -n "${GITHUB_WORKSPACE:-}" ]; then
    cd "${GITHUB_WORKSPACE}" || exit 1
    git config --global --add safe.directory "${GITHUB_WORKSPACE}" || exit 1
fi

PHPSTAN_BIN="phpstan"
REVIEWDOG_BIN="reviewdog"

if [ -z "${REVIEWDOG_GITHUB_API_TOKEN:-}" ]; then
    echo "Error: GITHUB_TOKEN or REVIEWDOG_GITHUB_API_TOKEN is required" >&2
    exit 1
fi

TARGET_PATHS="${TARGET_PATHS:-${1:-app}}"
PHPSTAN_CONFIG="${PHPSTAN_CONFIG:-}"
DIRTY="${DIRTY:-false}"
WIP="${WIP:-false}"
DIRTY_FILES="${DIRTY_FILES:-}"
WIP_FILES="${WIP_FILES:-}"
REVIEWDOG_NAME="${REVIEWDOG_NAME:-phpstan}"
REVIEWDOG_REPORTER="${REVIEWDOG_REPORTER:-github-check}"
REVIEWDOG_LEVEL="${REVIEWDOG_LEVEL:-error}"
REVIEWDOG_FILTER_MODE="file"
REVIEWDOG_FAIL_LEVEL="${REVIEWDOG_FAIL_LEVEL:-none}"
REVIEWDOG_FLAGS="${REVIEWDOG_FLAGS:-}"

# dirty/wip are resolved upstream by the list-dirty/list-wip actions; combine
# their file lists into the explicit target list PHPStan actually analyzes.
if [ "${DIRTY}" = "true" ] || [ "${WIP}" = "true" ]; then
    TARGET_ARGS="$(printf '%s\n%s\n' "${DIRTY_FILES}" "${WIP_FILES}" | sed '/^$/d' | sort -u | tr '\n' ' ')"
    if [ -z "$(printf '%s' "${TARGET_ARGS}" | tr -d '[:space:]')" ]; then
        echo "::notice::No changed PHP files under: ${TARGET_PATHS} (dirty=${DIRTY}, wip=${WIP}); skipping PHPStan." >&2
        exit 0
    fi
else
    TARGET_ARGS="$(echo "${TARGET_PATHS}" | tr ',' ' ')"
fi

if [ -n "${PHPSTAN_CONFIG}" ]; then
    if [ ! -f "${PHPSTAN_CONFIG}" ]; then
        echo "Error: config file not found: ${PHPSTAN_CONFIG}" >&2
        exit 1
    fi
    CONFIG_FLAG="-c ${PHPSTAN_CONFIG}"
else
    CONFIG_FLAG=""
fi

command -v "${PHPSTAN_BIN}" >/dev/null 2>&1 || { echo "Error: ${PHPSTAN_BIN} not found in PATH" >&2; exit 1; }
command -v "${REVIEWDOG_BIN}" >/dev/null 2>&1 || { echo "Error: ${REVIEWDOG_BIN} not found in PATH" >&2; exit 1; }

# Run PHPStan to a temp file so its report can be validated before passing it
# to reviewdog.
tmpfile=$(mktemp)
trap 'rm -f "${tmpfile}"' EXIT INT TERM
# shellcheck disable=SC2086
"${PHPSTAN_BIN}" analyse ${CONFIG_FLAG} --error-format=checkstyle --memory-limit=512M --no-progress -- ${TARGET_ARGS} >"${tmpfile}" 2>&1 || true

# PHPStan crashing before producing any report is a tooling/setup failure,
# not an analysis finding.
if [ ! -s "${tmpfile}" ]; then
    echo "Error: PHPStan produced no output." >&2
    exit 1
fi

if grep -qi "no files found to analyse" "${tmpfile}"; then
    echo "::notice::PHPStan: No files found to analyse; nothing to do." >&2
    exit 0
fi

# Do not fail the action if PHPStan found issues, but do fail if reviewdog
# fails to process the report: PHPStan's own exit code is discarded above,
# so the step's exit status is reviewdog's.
cat "${tmpfile}" | "${REVIEWDOG_BIN}" \
    -f=checkstyle \
    -name="${REVIEWDOG_NAME}" \
    -reporter="${REVIEWDOG_REPORTER}" \
    -level="${REVIEWDOG_LEVEL}" \
    -filter-mode="${REVIEWDOG_FILTER_MODE}" \
    -fail-level="${REVIEWDOG_FAIL_LEVEL}" \
    ${REVIEWDOG_FLAGS}
