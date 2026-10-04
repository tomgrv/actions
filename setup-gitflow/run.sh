#!/usr/bin/sh

# Install the git-flow extension if missing, then initialize it against the
# already-checked-out repo. git-release-beta/git-release-prod (from
# tomgrv/scripts) call `git flow release start`/`git flow <flow> finish`
# directly -- both the git-flow binary and its local git-config
# (gitflow.branch.*/gitflow.prefix.*, normally set once by a developer's own
# devcontainer setup) are otherwise missing on a bare CI checkout.

set -eu

GITFLOW_MASTER_BRANCH="${GITFLOW_MASTER_BRANCH:-main}"
GITFLOW_DEVELOP_BRANCH="${GITFLOW_DEVELOP_BRANCH:-develop}"
GITFLOW_FEATURE_PREFIX="${GITFLOW_FEATURE_PREFIX:-feature/}"
GITFLOW_BUGFIX_PREFIX="${GITFLOW_BUGFIX_PREFIX:-bugfix/}"
GITFLOW_RELEASE_PREFIX="${GITFLOW_RELEASE_PREFIX:-release/}"
GITFLOW_HOTFIX_PREFIX="${GITFLOW_HOTFIX_PREFIX:-hotfix/}"
GITFLOW_SUPPORT_PREFIX="${GITFLOW_SUPPORT_PREFIX:-support/}"
GITFLOW_VERSIONTAG_PREFIX="${GITFLOW_VERSIONTAG_PREFIX:-v}"

# Idempotent: skip the (network) install when a previous step in the same
# job, or a caller image that ships it, already has git-flow.
if ! git flow version > /dev/null 2>&1; then
    # zz_install (tomgrv/scripts, put on PATH by this action's setup-scripts
    # step) picks the available package manager and escalates through sudo
    # when not root; the names below are the ones that differ from `git-flow`.
    zz_install git-flow apk=gitflow-avh dnf=gitflow yum=gitflow \
        brew=git-flow-avh pacman=gitflow-avh || {
        zz_log e "setup-gitflow: unable to install git-flow automatically on this system"
        exit 1
    }

    git flow version > /dev/null 2>&1 || {
        zz_log e "setup-gitflow: git-flow still unavailable after install attempt"
        exit 1
    }
fi

# `git flow init` reads prefixes only from --system/--global config, so pass
# them explicitly -- otherwise it falls back to its (empty) built-in
# defaults, in particular for the version-tag prefix.
git config gitflow.branch.master "${GITFLOW_MASTER_BRANCH}"
git config gitflow.branch.develop "${GITFLOW_DEVELOP_BRANCH}"
git flow init -d -f \
    -p "${GITFLOW_FEATURE_PREFIX}" -b "${GITFLOW_BUGFIX_PREFIX}" -r "${GITFLOW_RELEASE_PREFIX}" \
    -x "${GITFLOW_HOTFIX_PREFIX}" -s "${GITFLOW_SUPPORT_PREFIX}" -t "${GITFLOW_VERSIONTAG_PREFIX}"
