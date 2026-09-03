#!/usr/bin/sh

# Idempotently bootstrap zz_use from tomgrv/scripts, then optionally
# zz_use every tool listed in SCRIPTS (each pinned to SCRIPTS_REF, when
# set, as "<name>@<ref>").

set -eu

# Idempotent: a zz_use already on PATH (a previous step, a caller image
# that ships it, or a re-run in the same job) is reused as-is -- only
# fetch/install when it's genuinely missing.
if ! command -v zz_use > /dev/null 2>&1; then
    curl -fsSL "${ZZ_SCRIPTS_SETUP_URL:-https://raw.githubusercontent.com/tomgrv/scripts/main/setup.sh}" -o /tmp/zz_setup.sh
    sh /tmp/zz_setup.sh
    rm -f /tmp/zz_setup.sh
fi
export PATH="${INSTALL_BIN_DIR:-/usr/local/bin}:$PATH"
# GITHUB_PATH is unset outside a real Actions run (e.g. under bats) --
# only later steps in the same job need this, so skip it rather than fail.
if [ -n "${GITHUB_PATH:-}" ]; then
    echo "${INSTALL_BIN_DIR:-/usr/local/bin}" >> "${GITHUB_PATH}"
fi

SCRIPTS="${SCRIPTS:-}"
SCRIPTS_REF="${SCRIPTS_REF:-}"

[ -z "${SCRIPTS}" ] && exit 0

pinned=""
for name in ${SCRIPTS}; do
    if [ -n "${SCRIPTS_REF}" ]; then
        pinned="${pinned} ${name}@${SCRIPTS_REF}"
    else
        pinned="${pinned} ${name}"
    fi
done

# shellcheck disable=SC2086 -- $pinned is an intentional word-split list
zz_use ${pinned}

for name in ${SCRIPTS}; do
    command -v "${name}" > /dev/null || {
        echo "setup-scripts: ${name} not on PATH after zz_use" >&2
        exit 1
    }
done
