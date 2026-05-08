#!/bin/sh

set -eu

if [ -z "${GITHUB_TOKEN:-}" ]; then
    echo "::error::GITHUB_TOKEN is required" >&2
    exit 1
fi

SOURCE_ORG="${SOURCE_ORG:?SOURCE_ORG is required}"
SOURCE_NAME="${SOURCE_NAME:?SOURCE_NAME is required}"

DEFAULT_BRANCH=$(gh repo view "${SOURCE_ORG}/${SOURCE_NAME}" --json defaultBranchRef --jq '.defaultBranchRef.name')

SOURCE_BRANCH="${SOURCE_BRANCH:-${DEFAULT_BRANCH:-main}}"
TARGET_SUBDIR="${TARGET_SUBDIR:?TARGET_SUBDIR is required}"
EXCLUDE_PATHS="${EXCLUDE_PATHS:-.github,.devcontainer}"
HEAD_BRANCH="${HEAD_BRANCH:-}"

if [ "${EXCLUDE_PATHS}" = ".github,.devcontainer" ]; then
  echo "::notice::EXCLUDE_PATHS not set, using default: .github,.devcontainer" >&2
fi

if [ -z "${SOURCE_ORG}" ] || [ -z "${SOURCE_NAME}" ]; then
    echo "::error::source-organization and source-repository are required" >&2
    exit 1
fi

SOURCE_URL="https://github.com/${SOURCE_ORG}/${SOURCE_NAME}.git"

WORKDIR=$(mktemp -d)
git config --global --add safe.directory "${WORKDIR}" >/dev/null 2>&1 || true

echo "Cloning ${SOURCE_URL}/tree/${SOURCE_BRANCH} to temporary directory..." >&2

if ! git clone --depth 1 --branch "${SOURCE_BRANCH}" "${SOURCE_URL}" "${WORKDIR}" >/dev/null 2>&1; then
    echo "::error::Failed to clone ${SOURCE_URL}/tree/${SOURCE_BRANCH}. Check if the repository and branch exist and the token has access." >&2
    exit 1
fi

SOURCE_SHA=$(git -C "${WORKDIR}" rev-parse --short=12 HEAD)

if [ -z "${HEAD_BRANCH}" ]; then
    HEAD_BRANCH="chore/degit-${SOURCE_ORG}-${SOURCE_NAME}-${SOURCE_SHA}"
fi

TARGET_PATH="./${TARGET_SUBDIR}"

# Build rsync exclude arguments from the comma-separated EXCLUDE_PATHS input
EXCLUDE_ARGS=""
echo ".git,${EXCLUDE_PATHS}" | tr ',' '\n' | sort --unique | while read -r exclude; do
    if [ -n "${exclude}" ]; then
        EXCLUDE_ARGS="${EXCLUDE_ARGS} --exclude='${exclude}'"
    fi
done

echo "Syncing files from ${SOURCE_URL}/tree/${SOURCE_BRANCH} (SHA: ${SOURCE_SHA}) to <${TARGET_PATH}> (excluding paths: ${EXCLUDE_PATHS})" >&2

# Sync files from the source repository to the target subdirectory, excluding specified paths.
if ! mkdir -p "${TARGET_PATH}" && rsync -a --delete ${EXCLUDE_ARGS} "${WORKDIR}/" "${TARGET_PATH}/"; then
    echo "::error::Failed to sync files from ${SOURCE_URL}/tree/${SOURCE_BRANCH} to <${TARGET_PATH}>" >&2
    exit 1
fi

tree ${TARGET_PATH} >&2
git status "${TARGET_PATH}" >&2

# Check if there are any changes on the target path after syncing
if [ -z "$(git status --porcelain "${TARGET_PATH}")" ]; then
    printf 'has-changes=false\n'
    printf 'degit-branch=\n'
else
    echo "::notice::Imported ${SOURCE_URL}/tree/${SOURCE_BRANCH} to <${TARGET_PATH}>" >&2
    printf 'has-changes=true\n'
    printf 'degit-branch=%s\n' "${HEAD_BRANCH}"
fi

printf 'degit-workdir=%s\n' "${TARGET_PATH}"
printf 'source-branch=%s\n' "${SOURCE_BRANCH}"
printf 'source-sha=%s\n' "${SOURCE_SHA}"
