#!/usr/bin/sh

set -e

if [ -n "${GITHUB_WORKSPACE:-}" ]; then
    cd "${GITHUB_WORKSPACE}" || exit 1
    git config --global --add safe.directory "${GITHUB_WORKSPACE}" || exit 1
fi

LIST_PATHS="${LIST_PATHS:-${1:-.}}"
LIST_EXTENSIONS="${LIST_EXTENSIONS:-php}"

if [ "${LIST_PATHS}" = "." ]; then
    echo "::notice::path not set, using default: ." >&2
fi

_base_regex="^($(printf '%s' "${LIST_PATHS}" | sed 's/,/|/g; s/[^A-Za-z0-9|_.\/-]//g'))(/|$)"
_ext_regex="\\.($(printf '%s' "${LIST_EXTENSIONS}" | sed 's/,/|/g; s/[^A-Za-z0-9|_.\/-]//g'))\$"

echo "Listing dirty files under: ${LIST_PATHS} (extensions: ${LIST_EXTENSIONS})" >&2

FILES="$(
    {
        git diff --name-only --diff-filter=ACMR -- .
        git diff --name-only --cached --diff-filter=ACMR -- .
        git ls-files --others --exclude-standard -- .
    } | sed '/^$/d' | sort -u | grep -E "${_base_regex}" | grep -E "${_ext_regex}" || true
)"

COUNT=0
if [ -n "${FILES}" ]; then
    COUNT="$(printf '%s\n' "${FILES}" | wc -l | tr -d ' ')"
fi

echo "Found ${COUNT} dirty file(s)" >&2

{
    echo "files<<GH_LIST_DIRTY_EOF"
    printf '%s\n' "${FILES}"
    echo "GH_LIST_DIRTY_EOF"
    printf 'count=%s\n' "${COUNT}"
    if [ "${COUNT}" -gt 0 ]; then
        printf 'has-files=true\n'
    else
        printf 'has-files=false\n'
    fi
}
