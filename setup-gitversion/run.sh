#!/usr/bin/sh

# Idempotently install the GitVersion toolchain git-release-beta/
# git-release-prod (from tomgrv/scripts) depend on: a docker-wrapped
# GitVersion CLI plus the gv/bump-tag/bump-changelog/bump-version scripts
# (also from tomgrv/scripts -- zz_used by this action's own setup-scripts
# step, ahead of this run.sh).

set -eu

GITVERSION_VERSION="${GITVERSION_VERSION:-6.5.1}"
INSTALL_BIN_DIR="${INSTALL_BIN_DIR:-/usr/local/bin}"
GITVERSION_CACHE_DIR="${GITVERSION_CACHE_DIR:-${HOME:-/tmp}/.cache/gitversion}"

# Make the GitVersion image available locally: already present, restored from
# the archive the action's cache step brings back, or pulled and archived for
# the next run. Never fatal -- the wrapper below falls back to `docker run`,
# which pulls the image on first use exactly as it did before caching.
prepare_image() {
    command -v docker > /dev/null 2>&1 || return 0

    image="gittools/gitversion:${GITVERSION_VERSION}"
    archive="${GITVERSION_CACHE_DIR}/gitversion-${GITVERSION_VERSION}.tar.gz"

    docker image inspect "${image}" > /dev/null 2>&1 && return 0

    if [ -f "${archive}" ]; then
        if gunzip -c "${archive}" | docker load > /dev/null 2>&1; then
            zz-log i "setup-gitversion: loaded ${image} from cache"
            return 0
        fi
        zz-log w "setup-gitversion: cached image archive unusable, pulling instead"
        rm -f "${archive}"
    fi

    if ! docker pull -q "${image}" > /dev/null 2>&1; then
        zz-log w "setup-gitversion: could not pre-pull ${image}, it will be pulled on first use"
        return 0
    fi

    mkdir -p "${GITVERSION_CACHE_DIR}" || return 0
    if docker save -o "${archive%.gz}" "${image}" > /dev/null 2>&1 && gzip -1 -f "${archive%.gz}"; then
        zz-log i "setup-gitversion: archived ${image} for the next run"
    else
        rm -f "${archive%.gz}" "${archive}"
    fi
}

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
    prepare_image
fi

export PATH="${INSTALL_BIN_DIR}:$PATH"
# GITHUB_PATH is unset outside a real Actions run (e.g. under bats) -- only
# later steps in the same job need this, so skip it rather than fail.
if [ -n "${GITHUB_PATH:-}" ]; then
    echo "${INSTALL_BIN_DIR}" >> "${GITHUB_PATH}"
fi

for name in gv bump-tag bump-changelog bump-version gitversion; do
    command -v "${name}" > /dev/null || {
        zz-log e "setup-gitversion: ${name} not on PATH after install"
        exit 1
    }
done

zz-log i "setup-gitversion: installed gitversion ${GITVERSION_VERSION}"
