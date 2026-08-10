#!/usr/bin/sh

# Run FilaCheck (Filament-specific checks) and report findings via reviewdog.
#
# noglob: FILACHECK_TARGET may be an unquoted, word-split list of
# git-diff-derived filenames (wip mode) and must never undergo pathname
# expansion.
set -ef

if [ -n "${GITHUB_WORKSPACE:-}" ]; then
    cd "${GITHUB_WORKSPACE}" || exit 1
    git config --global --add safe.directory "${GITHUB_WORKSPACE}" || exit 1
fi

FILACHECK_BIN="filacheck"
REVIEWDOG_BIN="reviewdog"

# Token resolution (input vs GITHUB_TOKEN) happens in setup-reviewdog.
if [ -z "${REVIEWDOG_GITHUB_API_TOKEN:-}" ]; then
    echo "Error: GITHUB_TOKEN or REVIEWDOG_GITHUB_API_TOKEN is required" >&2
    exit 1
fi

FILACHECK_PATH="${FILACHECK_PATH:-${1:-app/Filament}}"
DETAILED="${DETAILED:-false}"
DIRTY="${DIRTY:-false}"
WIP="${WIP:-false}"
WIP_FILES="${WIP_FILES:-}"
REVIEWDOG_NAME="${REVIEWDOG_NAME:-filacheck}"
REVIEWDOG_REPORTER="${REVIEWDOG_REPORTER:-github-check}"
REVIEWDOG_LEVEL="${REVIEWDOG_LEVEL:-error}"
REVIEWDOG_FILTER_MODE="file"
REVIEWDOG_FAIL_LEVEL="${REVIEWDOG_FAIL_LEVEL:-none}"
REVIEWDOG_FLAGS="${REVIEWDOG_FLAGS:-}"

#
# FilaCheck has no native flag for `wip` (unlike `dirty`, which it accepts
# natively as `--dirty` and is passed straight through below). Emulate it
# using the file list resolved upstream by the list-wip action, passed in
# place of the target path.
#
if [ "${WIP}" = "true" ]; then
    FILACHECK_TARGET="$(printf '%s\n' "${WIP_FILES}" | sed '/^$/d' | tr '\n' ' ')"
    if [ -z "$(printf '%s' "${FILACHECK_TARGET}" | tr -d '[:space:]')" ]; then
        echo "::notice::No changed files under: ${FILACHECK_PATH} on this pull request; skipping FilaCheck." >&2
        exit 0
    fi
else
    FILACHECK_TARGET="${FILACHECK_PATH}"
fi

filacheck_args=""
if [ "${DETAILED}" = "true" ]; then
    filacheck_args="${filacheck_args} --detailed"
fi
if [ "${DIRTY}" = "true" ]; then
    filacheck_args="${filacheck_args} --dirty"
fi

# FilaCheck's own exit code is not used as the step's exit code: findings
# are reviewdog's job to gate (via fail-level), not a script failure. The
# pipe's exit code below is reviewdog's, since it is the last command in it.
exit_code=0
filacheck_log=$(mktemp)
trap 'rm -f "${filacheck_log}"' EXIT INT TERM
# shellcheck disable=SC2086
"${FILACHECK_BIN}" ${filacheck_args} -- ${FILACHECK_TARGET} 2>"${filacheck_log}" \
    | tee -a "${filacheck_log}" \
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

cat "${filacheck_log}" >&2

exit $exit_code
