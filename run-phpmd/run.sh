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

# Input/ruleset defaulting is a setup detail, not a PHPMD finding: plain log
# only, no GitHub annotation (see .github/instructions/action-creation.md).
if [ "${PHPMD_PATHS}" = "app" ]; then
    echo "PHPMD_PATHS not set, using default: app" >&2
fi

if [ -n "${GITHUB_WORKSPACE:-}" ]; then
    cd "${GITHUB_WORKSPACE}" || exit 1
    git config --global --add safe.directory "${GITHUB_WORKSPACE}" || exit 1
fi

if [ -z "${PHPMD_RULESET}" ]; then
    if [ -f "phpmd.xml" ]; then
        PHPMD_RULESET="phpmd.xml"
        echo "ruleset not set, using phpmd.xml found at repository root" >&2
    else
        PHPMD_RULESET="cleancode,codesize,controversial,design,naming,unusedcode"
        echo "ruleset not set and no phpmd.xml found, using default ruleset: ${PHPMD_RULESET}" >&2
    fi
fi

PHPMD_BIN="phpmd"
REVIEWDOG_BIN="reviewdog"

if [ -z "${REVIEWDOG_GITHUB_API_TOKEN:-}" ]; then
    if [ -z "${GITHUB_TOKEN:-}" ]; then
        echo "Error: GITHUB_TOKEN or REVIEWDOG_GITHUB_API_TOKEN is required" >&2
        exit 1
    fi
    echo "REVIEWDOG_GITHUB_API_TOKEN not set, using GITHUB_TOKEN" >&2
    export REVIEWDOG_GITHUB_API_TOKEN="${GITHUB_TOKEN}"
fi

REVIEWDOG_NAME="${REVIEWDOG_NAME:-phpmd}"
REVIEWDOG_REPORTER="${REVIEWDOG_REPORTER:-github-pr-check}"
REVIEWDOG_LEVEL="${REVIEWDOG_LEVEL:-error}"
REVIEWDOG_FILTER_MODE="${REVIEWDOG_FILTER_MODE:-nofilter}"
REVIEWDOG_FAIL_LEVEL="${REVIEWDOG_FAIL_LEVEL:-none}"
REVIEWDOG_FLAGS="${REVIEWDOG_FLAGS:-}"

# dirty/wip are resolved upstream by the list-dirty/list-wip actions; combine
# their file lists into the explicit target list PHPMD actually analyzes.
# PHPMD's input path argument accepts a comma-separated list of files/dirs.
if [ "${DIRTY}" = "true" ] || [ "${WIP}" = "true" ]; then
    PHPMD_TARGET="$(printf '%s\n%s\n' "${DIRTY_FILES}" "${WIP_FILES}" | sed '/^$/d' | sort -u | paste -sd, -)"
    if [ -z "${PHPMD_TARGET}" ]; then
        # Functional: nothing in the analyzed repo matches the filter.
        echo "::notice::No changed PHP files under: ${PHPMD_PATHS} (dirty=${DIRTY}, wip=${WIP}); skipping PHPMD." >&2
        exit 0
    fi
    echo "Restricting PHPMD to changed files: ${PHPMD_TARGET}" >&2
else
    PHPMD_TARGET="${PHPMD_PATHS}"
fi

echo "Running PHPmd on <${PHPMD_TARGET}> with ruleset: ${PHPMD_RULESET}" >&2

exit_code=0
# shellcheck disable=SC2086
"${PHPMD_BIN}" "${PHPMD_TARGET}" sarif "${PHPMD_RULESET}" --cache --cache-strategy content --ignore-errors-on-exit --ignore-violations-on-exit --${PHPMD_PRIORITY}-priority 2> /dev/null \
    | "${REVIEWDOG_BIN}" \
        -f=sarif \
        -name="${REVIEWDOG_NAME}" \
        -reporter="${REVIEWDOG_REPORTER}" \
        -level="${REVIEWDOG_LEVEL}" \
        -filter-mode="${REVIEWDOG_FILTER_MODE}" \
        -fail-level="${REVIEWDOG_FAIL_LEVEL}" \
        ${REVIEWDOG_FLAGS} || exit_code=$?
exit $exit_code
