#!/usr/bin/sh

# Idempotently install the `gitversion` devcontainer feature's toolchain: a
# docker-wrapped GitVersion CLI plus the gv/bump-tag/bump-changelog/bump-version
# bin scripts. git-release-beta/git-release-prod (from tomgrv/scripts) call
# these directly to compute the release version and bump the changelog/tag --
# neither tomgrv/scripts nor this action's own setup-scripts step installs
# them, so release-promote needs this as a separate step.

set -eu

# Idempotent: skip the (slow, network) feature install when a previous step
# in the same job, or a caller image that ships it, already put these tools
# on PATH.
if ! command -v gv > /dev/null 2>&1 \
    || ! command -v bump-tag > /dev/null 2>&1 \
    || ! command -v bump-changelog > /dev/null 2>&1 \
    || ! command -v bump-version > /dev/null 2>&1; then
    npm exec --yes --legacy-peer-deps --package github:tomgrv/devcontainer-features -- devcontainer-features -- add gitversion
fi
export PATH="${INSTALL_BIN_DIR:-/usr/local/bin}:$PATH"
# GITHUB_PATH is unset outside a real Actions run (e.g. under bats) -- only
# later steps in the same job need this, so skip it rather than fail.
if [ -n "${GITHUB_PATH:-}" ]; then
    echo "${INSTALL_BIN_DIR:-/usr/local/bin}" >> "${GITHUB_PATH}"
fi

for name in gv bump-tag bump-changelog bump-version gitversion; do
    command -v "${name}" > /dev/null || {
        echo "setup-gitversion: ${name} not on PATH after install" >&2
        exit 1
    }
done
