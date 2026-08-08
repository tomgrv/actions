#!/usr/bin/sh

set -e

PHPMD_RULESET="${PHPMD_RULESET:-}"
PHPMD_PRIORITY="${PHPMD_PRIORITY:-max}"
PHPMD_PATHS="${PHPMD_PATHS:-${1:-app}}"
DIRTY="${DIRTY:-false}"
WIP="${WIP:-false}"
WIP_BASE_REF="${WIP_BASE_REF:-${GITHUB_BASE_REF:-}}"

if [ "${PHPMD_PATHS}" = "app" ]; then
    echo "::notice::PHPMD_PATHS not set, using default: app" >&2
fi

if [ -n "${GITHUB_WORKSPACE:-}" ]; then
    cd "${GITHUB_WORKSPACE}" || exit 1
    git config --global --add safe.directory "${GITHUB_WORKSPACE}" || exit 1
fi

if [ -z "${PHPMD_RULESET}" ]; then
    if [ -f "phpmd.xml" ]; then
        PHPMD_RULESET="phpmd.xml"
        echo "::notice::ruleset not set, using phpmd.xml found at repository root" >&2
    else
        PHPMD_RULESET="cleancode,codesize,controversial,design,naming,unusedcode"
        echo "::notice::ruleset not set and no phpmd.xml found, using default ruleset: ${PHPMD_RULESET}" >&2
    fi
fi

PATH="${GITHUB_WORKSPACE:-.}/vendor/bin:$(composer config -g home)/vendor/bin:${PATH}"
PHPMD_BIN="phpmd"
REVIEWDOG_BIN="reviewdog"

if [ -z "${REVIEWDOG_GITHUB_API_TOKEN:-}" ]; then
    if [ -z "${GITHUB_TOKEN:-}" ]; then
        echo "::error::GITHUB_TOKEN or REVIEWDOG_GITHUB_API_TOKEN is required" >&2
        exit 1
    fi
    echo "::notice::REVIEWDOG_GITHUB_API_TOKEN not set, using GITHUB_TOKEN" >&2
    export REVIEWDOG_GITHUB_API_TOKEN="${GITHUB_TOKEN}"
fi

REVIEWDOG_NAME="${REVIEWDOG_NAME:-phpmd}"
REVIEWDOG_REPORTER="${REVIEWDOG_REPORTER:-github-pr-check}"
REVIEWDOG_LEVEL="${REVIEWDOG_LEVEL:-error}"
REVIEWDOG_FILTER_MODE="${REVIEWDOG_FILTER_MODE:-nofilter}"
REVIEWDOG_FAIL_LEVEL="${REVIEWDOG_FAIL_LEVEL:-none}"
REVIEWDOG_FLAGS="${REVIEWDOG_FLAGS:-}"

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

# Restrict PHPMD_PATHS to only the changed files under them. PHPMD's input
# path argument accepts a comma-separated list of files/directories.
_filter_changed_paths() {
    _base_regex="^($(printf '%s' "${PHPMD_PATHS}" | sed 's/,/|/g; s/[^A-Za-z0-9|_.\/-]//g'))(/|$)"
    _changed_files | grep -E "${_base_regex}" | grep -E '\.php$' | paste -sd, -
}

if [ "${DIRTY}" = "true" ] || [ "${WIP}" = "true" ]; then
    PHPMD_TARGET="$(_filter_changed_paths)" || exit 1
    if [ -z "${PHPMD_TARGET}" ]; then
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
