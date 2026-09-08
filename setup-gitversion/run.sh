#!/usr/bin/sh

# Idempotently install the GitVersion toolchain git-release-beta/
# git-release-prod (from tomgrv/scripts) depend on: a docker-wrapped
# GitVersion CLI plus the gv/bump-tag/bump-changelog/bump-version scripts
# (also from tomgrv/scripts -- zz_used by this action's own setup-scripts
# step, ahead of this run.sh).

set -eu

GITVERSION_VERSION="${GITVERSION_VERSION:-6.5.1}"
INSTALL_BIN_DIR="${INSTALL_BIN_DIR:-/usr/local/bin}"

# Idempotent: skip the (network) install when a previous step in the same
# job, or a caller image that ships it, already put these tools on PATH.
if ! command -v gitversion > /dev/null 2>&1; then
    # Mirrors install-tools.sh's own docker-gitversion wrapper.
    cat > "${INSTALL_BIN_DIR}/docker-gitversion" << DOCKERWRAP
#!/bin/sh
cd "\$(git rev-parse --show-toplevel)" && \\
docker run --rm -v "\$(git rev-parse --show-toplevel):/repo" gittools/gitversion:${GITVERSION_VERSION} /repo "\$@"
DOCKERWRAP
    chmod +x "${INSTALL_BIN_DIR}/docker-gitversion"
    ln -sf "${INSTALL_BIN_DIR}/docker-gitversion" "${INSTALL_BIN_DIR}/gitversion"
fi

export PATH="${INSTALL_BIN_DIR}:$PATH"
# GITHUB_PATH is unset outside a real Actions run (e.g. under bats) -- only
# later steps in the same job need this, so skip it rather than fail.
if [ -n "${GITHUB_PATH:-}" ]; then
    echo "${INSTALL_BIN_DIR}" >> "${GITHUB_PATH}"
fi

for name in gv bump-tag bump-changelog bump-version gitversion; do
    command -v "${name}" > /dev/null || {
        zz_log e "setup-gitversion: ${name} not on PATH after install"
        exit 1
    }
done
