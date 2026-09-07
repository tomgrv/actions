#!/usr/bin/sh

# List files changed on the current branch relative to a base ref, filtered
# by path and extension.

set -e

if [ -n "${GITHUB_WORKSPACE:-}" ]; then
    cd "${GITHUB_WORKSPACE}" || exit 1
    git config --global --add safe.directory "${GITHUB_WORKSPACE}" || exit 1
fi

# LIST_PATHS is normally supplied via action.yml's env block; the positional
# fallback below only matters for local dispatch.sh usage.
eval "$(zz_args "List WIP files" "$0" "$@" <<-help
	- path	list_paths	Comma-separated list of paths to restrict the list to (default: .)
help
)"

LIST_PATHS="${LIST_PATHS:-${list_paths:-.}}"
LIST_EXTENSIONS="${LIST_EXTENSIONS:-php}"
LIST_BASE_REF="${LIST_BASE_REF:-${GITHUB_BASE_REF:-}}"

# Input defaulting is a setup detail, not a finding: plain log only.
if [ "${LIST_PATHS}" = "." ]; then
    zz_log i "path not set, using default: ."
fi

# Missing base-ref is a setup/configuration problem, not a finding about the
# analyzed repository: plain log only, no GitHub annotation.
if [ -z "${LIST_BASE_REF}" ]; then
    zz_log e "base-ref is required: set GITHUB_BASE_REF (automatic on pull_request events) or the base-ref input"
    printf 'files<<GH_LIST_WIP_EOF\nGH_LIST_WIP_EOF\n'
    printf 'count=0\n'
    printf 'has-files=false\n'
    exit 1
fi

git fetch --depth=1 origin "${LIST_BASE_REF}" > /dev/null 2>&1 || true
MERGE_BASE="$(git merge-base "origin/${LIST_BASE_REF}" HEAD 2> /dev/null || echo "${LIST_BASE_REF}")"

if [ "${LIST_PATHS}" = "." ]; then
    _base_regex="."
else
    _base_regex="^($(printf '%s' "${LIST_PATHS}" | sed 's/,/|/g; s/[^A-Za-z0-9|_.\/-]//g; s/\./\\./g'))(/|$)"
fi
_ext_regex="\\.($(printf '%s' "${LIST_EXTENSIONS}" | sed 's/,/|/g; s/[^A-Za-z0-9|_.\/-]//g; s/\./\\./g'))\$"

zz_log i "Listing files changed since ${LIST_BASE_REF} (merge-base ${MERGE_BASE}) under: ${LIST_PATHS} (extensions: ${LIST_EXTENSIONS})"

FILES="$(
    git diff --name-only --diff-filter=ACMR "${MERGE_BASE}" -- . \
        | sed '/^$/d' | sort -u | grep -E "${_base_regex}" | grep -E "${_ext_regex}" || true
)"

COUNT=0
if [ -n "${FILES}" ]; then
    COUNT="$(printf '%s\n' "${FILES}" | wc -l | tr -d ' ')"
fi

zz_log i "Found ${COUNT} changed file(s)"

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
