#!/usr/bin/sh

# List the PHP test parts (core, modules, packages) affected by the current
# change, as a JSON matrix. Selection logic lives in the php-changed script.

set -e

if [ -n "${GITHUB_WORKSPACE:-}" ]; then
    cd "${GITHUB_WORKSPACE}" || exit 1
    git config --global --add safe.directory "${GITHUB_WORKSPACE}" || exit 1
fi

LIST_BASE_REF="${LIST_BASE_REF:-${GITHUB_BASE_REF:-}}"
LIST_ALL="${LIST_ALL:-false}"

if [ -n "${LIST_BASE_REF}" ]; then
    git fetch --depth=1 origin "${LIST_BASE_REF}" > /dev/null 2>&1 || true
fi

set -- -f json
[ -n "${LIST_BASE_REF}" ] && set -- "$@" -b "origin/${LIST_BASE_REF}"
[ "${LIST_ALL}" = "true" ] && set -- "$@" -a

MATRIX="$(php-changed "$@")" || exit 1
[ -n "${MATRIX}" ] || MATRIX="[]"

COUNT="$(printf '%s' "${MATRIX}" | jq 'length')"
zz_log i "Found ${COUNT} affected part(s): $(printf '%s' "${MATRIX}" | jq -r 'map(.name) | join(", ")')"

printf 'matrix=%s\n' "${MATRIX}"
if [ "${COUNT}" -gt 0 ]; then
    printf 'has-parts=true\n'
else
    printf 'has-parts=false\n'
fi
