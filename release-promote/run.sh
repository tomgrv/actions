#!/usr/bin/sh

# Install git-release-beta/git-release-prod from tomgrv/scripts (pinned via
# SCRIPTS_REF) and run beta->prod against the already-checked-out repo.
# Assumes the caller checked out the repo (fetch-depth 0, ref develop) and
# has git identity configured (this action's own "Configure git bot
# identity" step does that via config-bot before this script runs).

set -eu

: "${SCRIPTS_REF:?SCRIPTS_REF is required}"
DRY_RUN="${DRY_RUN:-false}"

# Idempotent: a zz_use already on PATH (e.g. a caller that bootstrapped it
# itself, or a re-run in the same job) is reused as-is -- only fetch/install
# when it's genuinely missing.
if ! command -v zz_use > /dev/null 2>&1; then
    curl -fsSL "${ZZ_SCRIPTS_SETUP_URL:-https://raw.githubusercontent.com/tomgrv/scripts/main/setup.sh}" -o /tmp/zz_setup.sh
    sh /tmp/zz_setup.sh
    rm -f /tmp/zz_setup.sh
fi
export PATH="${INSTALL_BIN_DIR:-/usr/local/bin}:$PATH"

zz_use "git-release-beta@${SCRIPTS_REF}" "git-release-prod@${SCRIPTS_REF}"

command -v git-release-beta > /dev/null || {
    echo "release-promote: git-release-beta not on PATH after zz_use" >&2
    exit 1
}
command -v git-release-prod > /dev/null || {
    echo "release-promote: git-release-prod not on PATH after zz_use" >&2
    exit 1
}

if [ "${DRY_RUN}" = "true" ]; then
    echo "dry-run=true, stopping before git-release-beta/git-release-prod would push to main."
    exit 0
fi

if git-release-beta && git-release-prod; then
    exit 0
fi

echo "::error::git-release-prod failed to push -- if this looks like a protected-ref rejection, main/tag protection needs a bypass entry for github-actions[bot]. See docs/release-process.md in tomgrv/actions for the exact checklist." >&2
exit 1
