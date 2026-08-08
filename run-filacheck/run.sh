#!/usr/bin/sh

set -e

if [ -n "${GITHUB_WORKSPACE:-}" ]; then
    cd "${GITHUB_WORKSPACE}" || exit 1
    git config --global --add safe.directory "${GITHUB_WORKSPACE}" || exit 1
fi

PATH="${GITHUB_WORKSPACE:-.}/vendor/bin:$(composer config -g home)/vendor/bin:${PATH}"
FILACHECK_BIN="filacheck"
REVIEWDOG_BIN="reviewdog"

if [ -z "${REVIEWDOG_GITHUB_API_TOKEN:-}" ]; then
    if [ -z "${GITHUB_TOKEN:-}" ]; then
        echo "::error::GITHUB_TOKEN or REVIEWDOG_GITHUB_API_TOKEN is required" >&2
        exit 1
    fi
    echo "::notice::REVIEWDOG_GITHUB_API_TOKEN not set, using GITHUB_TOKEN" >&2
    export REVIEWDOG_GITHUB_API_TOKEN="${GITHUB_TOKEN}"
fi

FILACHECK_PATH="${FILACHECK_PATH:-${1:-app/Filament}}"
FIX="${FIX:-false}"
DETAILED="${DETAILED:-false}"
DIRTY="${DIRTY:-false}"
WIP="${WIP:-false}"
WIP_BASE_REF="${WIP_BASE_REF:-${GITHUB_BASE_REF:-}}"
DRY_RUN="${DRY_RUN:-false}"
BACKUP="${BACKUP:-false}"
REVIEWDOG_NAME="${REVIEWDOG_NAME:-filacheck}"
REVIEWDOG_REPORTER="${REVIEWDOG_REPORTER:-github-pr-check}"
REVIEWDOG_LEVEL="${REVIEWDOG_LEVEL:-error}"
REVIEWDOG_FILTER_MODE="${REVIEWDOG_FILTER_MODE:-added}"
REVIEWDOG_FAIL_LEVEL="${REVIEWDOG_FAIL_LEVEL:-none}"
REVIEWDOG_FLAGS="${REVIEWDOG_FLAGS:-}"

if [ "${FILACHECK_PATH}" = "app/Filament" ]; then
    echo "::notice::FILACHECK_PATH not set, using default: app/Filament" >&2
fi

#
# FilaCheck has no native flag for `wip` (unlike `dirty`, which it accepts
# natively as `--dirty` and is passed straight through below). Emulate it by
# resolving the files changed on this pull request and passing that explicit
# list in place of the target path.
#
if [ "${WIP}" = "true" ]; then
    if [ -z "${WIP_BASE_REF}" ]; then
        echo "::error::wip requires a base ref: set GITHUB_BASE_REF (automatic on pull_request events) or the wip-base-ref input" >&2
        exit 1
    fi
    git fetch --depth=1 origin "${WIP_BASE_REF}" > /dev/null 2>&1 || true
    _merge_base="$(git merge-base "origin/${WIP_BASE_REF}" HEAD 2> /dev/null || echo "${WIP_BASE_REF}")"
    _base_regex="^($(printf '%s' "${FILACHECK_PATH}" | sed 's/,/|/g; s/[^A-Za-z0-9|_.\/-]//g'))(/|$)"
    FILACHECK_TARGET="$(git diff --name-only --diff-filter=ACMR "${_merge_base}" -- . | grep -E "${_base_regex}" | grep -E '\.(blade\.php|php)$' | tr '\n' ' ')"
    if [ -z "$(printf '%s' "${FILACHECK_TARGET}" | tr -d '[:space:]')" ]; then
        echo "::notice::No changed files under: ${FILACHECK_PATH} on this pull request; skipping FilaCheck." >&2
        printf 'has-changes=false\n'
        exit 0
    fi
    echo "Restricting FilaCheck to changed files: ${FILACHECK_TARGET}" >&2
else
    FILACHECK_TARGET="${FILACHECK_PATH}"
fi

echo "Running FilaCheck on: ${FILACHECK_PATH}" >&2

filacheck_args=""
if [ "${FIX}" = "true" ]; then
    filacheck_args="${filacheck_args} --fix"
fi
if [ "${DETAILED}" = "true" ]; then
    filacheck_args="${filacheck_args} --detailed"
fi
if [ "${DIRTY}" = "true" ]; then
    filacheck_args="${filacheck_args} --dirty"
fi
if [ "${DRY_RUN}" = "true" ]; then
    filacheck_args="${filacheck_args} --dry-run"
fi
if [ "${BACKUP}" = "true" ]; then
    filacheck_args="${filacheck_args} --backup"
fi

exit_code=0
# shellcheck disable=SC2086
"${FILACHECK_BIN}" ${filacheck_args} -- ${FILACHECK_TARGET} 2> /dev/null \
    | awk '
        /^[[:space:]]+[^[:space:]].*\.(blade\.php|php)$/ {
            current_file=$0
            sub(/^[[:space:]]+/, "", current_file)
            pending_suggestion=""
            next
        }
        /^[[:space:]]+Line [0-9]+: / {
            if (current_file != "") {
                line=$0
                sub(/^[[:space:]]+Line /, "", line)
                line_no=line
                sub(/:.*$/, "", line_no)
                message=line
                sub(/^[0-9]+:[[:space:]]*/, "", message)
                if (pending_suggestion != "") {
                    message=message " (" pending_suggestion ")"
                    pending_suggestion=""
                }
                print current_file ":" line_no ": " message
            }
            next
        }
        /^[[:space:]]+→ / {
            pending_suggestion=$0
            sub(/^[[:space:]]+→[[:space:]]*/, "", pending_suggestion)
            next
        }
    ' \
    | "${REVIEWDOG_BIN}" \
        -efm='%f:%l: %m' \
        -name="${REVIEWDOG_NAME}" \
        -reporter="${REVIEWDOG_REPORTER}" \
        -level="${REVIEWDOG_LEVEL}" \
        -filter-mode="${REVIEWDOG_FILTER_MODE}" \
        -fail-level="${REVIEWDOG_FAIL_LEVEL}" \
        ${REVIEWDOG_FLAGS} || exit_code=$?

if [ "${FIX}" = "true" ] && [ "${DRY_RUN}" != "true" ]; then
    if git diff --quiet; then
        printf 'has-changes=false\n'
    else
        printf 'has-changes=true\n'
    fi
else
    printf 'has-changes=false\n'
fi

exit $exit_code
