#!/usr/bin/sh

# Idempotently install the GitVersion toolchain git-release-beta/
# git-release-prod (from tomgrv/scripts) depend on: a docker-wrapped
# GitVersion CLI plus the gv/bump-tag/bump-changelog/bump-version scripts.
#
# This fetches those pieces directly from the gitversion devcontainer
# feature's source (raw.githubusercontent.com), rather than running that
# feature's own installer (`devcontainer-features -- add gitversion`).
# That installer is built for onboarding a dev environment -- it deploys
# stub files (.gitattributes, package.json merges, VS Code tasks, skills)
# into the checked-out repo, which is unwanted noise for a CI release job
# that only needs the CLI tools on PATH. It also doesn't reliably land
# bin/ scripts on PATH outside a real devcontainer postCreate context.

set -eu

GITVERSION_VERSION="${GITVERSION_VERSION:-6.5.1}"
INSTALL_BIN_DIR="${INSTALL_BIN_DIR:-/usr/local/bin}"
GITVERSION_SOURCE_URL="${GITVERSION_SOURCE_URL:-https://raw.githubusercontent.com/tomgrv/devcontainer-features/main/src/gitversion}"

# Idempotent: skip the (network) install when a previous step in the same
# job, or a caller image that ships it, already put these tools on PATH.
if ! command -v gv > /dev/null 2>&1 \
    || ! command -v bump-tag > /dev/null 2>&1 \
    || ! command -v bump-changelog > /dev/null 2>&1 \
    || ! command -v bump-version > /dev/null 2>&1 \
    || ! command -v gitversion > /dev/null 2>&1; then

    # Mirrors install-tools.sh's own docker-gitversion wrapper.
    cat > "${INSTALL_BIN_DIR}/docker-gitversion" << DOCKERWRAP
#!/bin/sh
cd "\$(git rev-parse --show-toplevel)" && \\
docker run --rm -v "\$(git rev-parse --show-toplevel):/repo" gittools/gitversion:${GITVERSION_VERSION} /repo "\$@"
DOCKERWRAP
    chmod +x "${INSTALL_BIN_DIR}/docker-gitversion"
    ln -sf "${INSTALL_BIN_DIR}/docker-gitversion" "${INSTALL_BIN_DIR}/gitversion"

    for name in gv bump-tag bump-changelog bump-version; do
        curl -fsSL "${GITVERSION_SOURCE_URL}/bin/${name}.sh" -o "${INSTALL_BIN_DIR}/${name}"
        chmod +x "${INSTALL_BIN_DIR}/${name}"
    done
fi

export PATH="${INSTALL_BIN_DIR}:$PATH"
# GITHUB_PATH is unset outside a real Actions run (e.g. under bats) -- only
# later steps in the same job need this, so skip it rather than fail.
if [ -n "${GITHUB_PATH:-}" ]; then
    echo "${INSTALL_BIN_DIR}" >> "${GITHUB_PATH}"
fi

for name in gv bump-tag bump-changelog bump-version gitversion; do
    command -v "${name}" > /dev/null || {
        echo "setup-gitversion: ${name} not on PATH after install" >&2
        exit 1
    }
done
