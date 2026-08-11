#!/usr/bin/sh

# Run PHP Mess Detector and report findings via reviewdog.

set -e

PHPMD_RULESET="${PHPMD_RULESET:-}"
PHPMD_PRIORITY="${PHPMD_PRIORITY:-max}"
PHPMD_PATHS="${PHPMD_PATHS:-${1:-app}}"
DIRTY="${DIRTY:-false}"
WIP="${WIP:-false}"
DIRTY_FILES="${DIRTY_FILES:-}"
WIP_FILES="${WIP_FILES:-}"

if [ -n "${GITHUB_WORKSPACE:-}" ]; then
    cd "${GITHUB_WORKSPACE}" || exit 1
    git config --global --add safe.directory "${GITHUB_WORKSPACE}" || exit 1
fi

if [ -z "${PHPMD_RULESET}" ]; then
    if [ -f "phpmd.xml" ]; then
        PHPMD_RULESET="phpmd.xml"
    else
        PHPMD_RULESET="cleancode,codesize,controversial,design,naming,unusedcode"
    fi
fi

PHPMD_BIN="phpmd"
REVIEWDOG_BIN="reviewdog"

if [ -z "${REVIEWDOG_GITHUB_API_TOKEN:-}" ]; then
    echo "Error: GITHUB_TOKEN or REVIEWDOG_GITHUB_API_TOKEN is required" >&2
    exit 1
fi

REVIEWDOG_NAME="${REVIEWDOG_NAME:-phpmd}"
REVIEWDOG_REPORTER="${REVIEWDOG_REPORTER:-github-check}"
REVIEWDOG_LEVEL="${REVIEWDOG_LEVEL:-error}"
REVIEWDOG_FILTER_MODE="file"
REVIEWDOG_FAIL_LEVEL="${REVIEWDOG_FAIL_LEVEL:-none}"
REVIEWDOG_FLAGS="${REVIEWDOG_FLAGS:-}"

# dirty/wip are resolved upstream by the list-dirty/list-wip actions; combine
# their file lists into the explicit target list PHPMD actually analyzes.
# PHPMD's input path argument accepts a comma-separated list of files/dirs.
if [ "${DIRTY}" = "true" ] || [ "${WIP}" = "true" ]; then
    PHPMD_TARGET="$(printf '%s\n%s\n' "${DIRTY_FILES}" "${WIP_FILES}" | sed '/^$/d' | sort -u | paste -sd, -)"
    if [ -z "${PHPMD_TARGET}" ]; then
        echo "::notice::No changed PHP files under: ${PHPMD_PATHS} (dirty=${DIRTY}, wip=${WIP}); skipping PHPMD." >&2
        exit 0
    fi
else
    PHPMD_TARGET="${PHPMD_PATHS}"
fi

# --ignore-errors-on-exit/--ignore-violations-on-exit keep PHPMD's own exit
# code out of the picture: findings are reviewdog's job to gate (via
# fail-level), not a script failure. The pipe's exit code below is
# reviewdog's, since it is the last command in it.
exit_code=0
phpmd_log=$(mktemp)
trap 'rm -f "${phpmd_log}"' EXIT INT TERM
# shellcheck disable=SC2086
"${PHPMD_BIN}" "${PHPMD_TARGET}" sarif "${PHPMD_RULESET}" --cache --cache-strategy content --ignore-errors-on-exit --ignore-violations-on-exit --${PHPMD_PRIORITY}-priority 2>"${phpmd_log}" \
    | tee -a "${phpmd_log}" \
    | "${REVIEWDOG_BIN}" \
        -f=sarif \
        -name="${REVIEWDOG_NAME}" \
        -reporter="${REVIEWDOG_REPORTER}" \
        -level="${REVIEWDOG_LEVEL}" \
        -filter-mode="${REVIEWDOG_FILTER_MODE}" \
        -fail-level="${REVIEWDOG_FAIL_LEVEL}" \
        ${REVIEWDOG_FLAGS} || exit_code=$?

cat "${phpmd_log}" >&2
exit $exit_code
