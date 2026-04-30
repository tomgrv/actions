#!/bin/sh
# Split a monorepo package subtree and prepare a PR workspace.
# Environment variables (all required):
#   PACKAGE_DIR    - relative path to the package from the repo root
#   REPO_ORG       - GitHub organization / user owning the origin repo
#   REPO_NAME      - name of the origin repository
#   GITHUB_TOKEN   - GitHub token (contents + pull_requests write)

set -eu

# Init variables with defaults
REPO_ROOT=$(git rev-parse --show-toplevel)
HEAD_OWNER="${HEAD_OWNER:-${REPO_ORG:-}}"

# Retrieve the package directory from the environment variable or input
PACKAGE_DIR="${PACKAGE_DIR:-${3:-}}"
case "${PACKAGE_DIR}" in
  /*) REL_DIR="${PACKAGE_DIR#${REPO_ROOT}/}" ;;
  *)  REL_DIR="${PACKAGE_DIR}" ;;
esac

# Run splitsh-lite; it outputs the SHA of the tip of the extracted subtree.
printf '%s\n' "Splitting '${REL_DIR}/' from monorepo at ${REPO_ROOT}..." >&2
SPLIT_BIN=/usr/local/bin/splitsh-lite
SPLIT_SHA=$("${SPLIT_BIN}" --prefix="${REL_DIR}/" || true)

if [ -z "${SPLIT_SHA}" ]; then
  printf '%s\n' "No commits found for '${REL_DIR}', skipping." >&2
  exit 0
else
  printf '%s\n' "Split SHA: ${SPLIT_SHA}" >&2
  SPLIT_BRANCH="chore/split-${SPLIT_SHA}"
fi

# Clone the fork repository to a temporary directory for preparing the PR.
FORK_URL="https://github.com/${HEAD_OWNER}/${REPO_NAME}"
REPO_URL="https://github.com/${REPO_ORG}/${REPO_NAME}"
CURRENT_ORG=$(git config --get remote.origin.url | sed -E 's#.*[:/]([^/]+)/[^/]+\.git#\1#')
CURRENT_REPO=$(git config --get remote.origin.url | sed -E 's#.*[:/][^/]+/([^/]+)\.git#\1#')
CURRENT_URL="https://github.com/${CURRENT_ORG}/${CURRENT_REPO}"
WORKDIR=$(mktemp -d)

# Mark the working directory as safe for Git operations to avoid "detected dubious ownership" errors.
git config --global --name-only --get-regexp safe.directory ${WORKDIR} || git config --global --add safe.directory ${WORKDIR}

# Clone the fork repository. If it fails, log an error and exit.
if ! git clone "${FORK_URL}" "${WORKDIR}" >/dev/null 2>&1; then
  printf '%s\n' "::error::Failed to clone ${FORK_URL}. Check if the repository exists and the token has access." >&2
  exit 1
else
  printf '%s\n' "Successfully cloned ${FORK_URL}." >&2
  cd "${WORKDIR}"
fi

# Try to check out the split branch from origin if it exists, otherwise create a new branch.
if git checkout -b "${SPLIT_BRANCH}" >/dev/null 2>&1; then
  printf '%s\n' "Checked out branch ${SPLIT_BRANCH} from origin." >&2
fi

# Fetch the split commit from the local monorepo into this clone so the tree
# object is reachable, then replace the working tree with the split content.
if ! git fetch "${REPO_ROOT}" "${SPLIT_SHA}" >/dev/null 2>&1; then
  printf '%s\n' "::error::Failed to fetch split commit ${SPLIT_SHA} from local repository. Check if the splitsh-lite output is correct and the commit exists." >&2
  exit 1
else
  printf '%s\n' "Successfully fetched split commit ${SPLIT_SHA}." >&2
  git read-tree --reset -u "${SPLIT_SHA}"
fi

# Skip push if the split content is empty.
if [ -z "$(git ls-files -z)" ]; then
  printf '%s\n' "Split content is empty, skipping PR." >&2
  exit 0
fi

printf '%s\n' "Prepared split workspace in ${WORKDIR}." >&2

printf 'split-branch=%s\n' "${SPLIT_BRANCH}"
printf 'split-sha=%s\n' "${SPLIT_SHA}"
printf 'split-workdir=%s\n' "${WORKDIR}"

