#!/usr/bin/sh

set -e

if [ -n "${GITHUB_WORKSPACE:-}" ]; then
    cd "${GITHUB_WORKSPACE}" || exit 1
    git config --global --add safe.directory "${GITHUB_WORKSPACE}" || exit 1
fi

LIST_PATHS="${LIST_PATHS:-${1:-.}}"
LIST_EXTENSIONS="${LIST_EXTENSIONS:-php}"
LIST_BASE_REF="${LIST_BASE_REF:-${GITHUB_BASE_REF:-}}"

if [ "${LIST_PATHS}" = "." ]; then
    echo "::notice::path not set, using default: ." >&2
fi

if [ -z "${LIST_BASE_REF}" ]; then
    echo "::error::base-ref is required: set GITHUB_BASE_REF (automatic on pull_request events) or the base-ref input" >&2
    printf 'files<<GH_LIST_WIP_EOF\nGH_LIST_WIP_EOF\n'
    printf 'count=0\n'
    printf 'has-files=false\n'
    exit 1
fi

git fetch --depth=1 origin "${LIST_BASE_REF}" > /dev/null 2>&1 || true
MERGE_BASE="$(git merge-base "origin/${LIST_BASE_REF}" HEAD 2> /dev/null || echo "${LIST_BASE_REF}")"

_base_regex="^($(printf '%s' "${LIST_PATHS}" | sed 's/,/|/g; s/[^A-Za-z0-9|_.\/-]//g'))(/|$)"
_ext_regex="\\.($(printf '%s' "${LIST_EXTENSIONS}" | sed 's/,/|/g; s/[^A-Za-z0-9|_.\/-]//g'))\$"

echo "Listing files changed since ${LIST_BASE_REF} (merge-base ${MERGE_BASE}) under: ${LIST_PATHS} (extensions: ${LIST_EXTENSIONS})" >&2

FILES="$(
    git diff --name-only --diff-filter=ACMR "${MERGE_BASE}" -- . \
        | sed '/^$/d' | sort -u | grep -E "${_base_regex}" | grep -E "${_ext_regex}" || true
)"

COUNT=0
if [ -n "${FILES}" ]; then
    COUNT="$(printf '%s\n' "${FILES}" | wc -l | tr -d ' ')"
fi

echo "Found ${COUNT} changed file(s)" >&2

{
    echo "files<<GH_LIST_WIP_EOF"
    printf '%s\n' "${FILES}"
    echo "GH_LIST_WIP_EOF"
    printf 'count=%s\n' "${COUNT}"
    if [ "${COUNT}" -gt 0 ]; then
        printf 'has-files=true\n'
    else
        printf 'has-files=false\n'
    fi
}
