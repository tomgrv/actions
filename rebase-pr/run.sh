#!/usr/bin/sh
# No Python dependency: all processing done via sh, jq, and awk.

set -eu

if [ -z "${GITHUB_TOKEN:-}" ]; then
  echo "::error::GITHUB_TOKEN is required" >&2
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "::error::gh CLI could not be found. Please install it." >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "::error::jq could not be found. Please install it." >&2
  exit 1
fi

export GH_TOKEN="${GITHUB_TOKEN}"

REPOSITORY="${REPOSITORY:-${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required}}"
AUTOSQUASH="${AUTOSQUASH:-false}"

# Resolve PR metadata via gh + jq (no python)
if [ -n "${PR_NUMBER:-}" ]; then
  PR_VIEW_ARGS="${PR_NUMBER}"
else
  PR_VIEW_ARGS=""
fi

PR_JSON=$(gh pr view ${PR_VIEW_ARGS} --repo "${REPOSITORY}" --json number,headRefName,baseRefName,url)

HEAD_BRANCH=$(printf '%s' "${PR_JSON}" | jq -r '.headRefName')
BASE_BRANCH=$(printf '%s' "${PR_JSON}" | jq -r '.baseRefName')
PR_NUMBER=$(printf '%s'   "${PR_JSON}" | jq -r '.number')
PR_URL=$(printf '%s'      "${PR_JSON}" | jq -r '.url')

if [ -z "${HEAD_BRANCH:-}" ] || [ -z "${BASE_BRANCH:-}" ]; then
  echo "::error::Could not resolve head or base branch for PR #${PR_NUMBER}." >&2
  exit 1
fi

echo "::notice::Rebasing PR #${PR_NUMBER} (${HEAD_BRANCH} onto ${BASE_BRANCH})" >&2

git config --global --add safe.directory "$(pwd)" >/dev/null 2>&1 || true

# Fetch both branches
git fetch origin "${BASE_BRANCH}" "${HEAD_BRANCH}" >&2

# Check if rebase is needed using awk for comparison clarity
MERGE_BASE=$(git merge-base "origin/${HEAD_BRANCH}" "origin/${BASE_BRANCH}")
BASE_TIP=$(git rev-parse "origin/${BASE_BRANCH}")

if [ "${MERGE_BASE}" = "${BASE_TIP}" ]; then
  echo "::notice::PR #${PR_NUMBER} is already up-to-date with ${BASE_BRANCH}, nothing to do." >&2
  printf 'action=up-to-date\n'
  printf 'head_branch=%s\n' "${HEAD_BRANCH}"
  printf 'base_branch=%s\n' "${BASE_BRANCH}"
  printf 'pr_number=%s\n'   "${PR_NUMBER}"
  printf 'pr_url=%s\n'      "${PR_URL}"
  exit 0
fi

# Create a temporary worktree for the rebase
TMP_DIR=$(mktemp -d)
trap 'git worktree remove "${TMP_DIR}" --force >/dev/null 2>&1; rm -rf "${TMP_DIR}"' EXIT INT TERM

git worktree add "${TMP_DIR}" "origin/${HEAD_BRANCH}" >&2

(
  cd "${TMP_DIR}" || exit 1

  if [ "${AUTOSQUASH}" = "true" ]; then
    GIT_SEQUENCE_EDITOR=: git rebase --autosquash --interactive "origin/${BASE_BRANCH}" >&2
  else
    git rebase "origin/${BASE_BRANCH}" >&2
  fi

  git push origin "HEAD:${HEAD_BRANCH}" --force-with-lease >&2
)

NEW_HEAD=$(git -C "${TMP_DIR}" rev-parse HEAD)

# Extract short SHA with awk for annotation
SHORT_SHA=$(printf '%s\n' "${NEW_HEAD}" | awk '{print substr($0,1,8)}')

echo "::notice::PR #${PR_NUMBER} successfully rebased. New HEAD: ${SHORT_SHA} (${NEW_HEAD})" >&2

printf 'action=rebased\n'
printf 'head_branch=%s\n' "${HEAD_BRANCH}"
printf 'base_branch=%s\n' "${BASE_BRANCH}"
printf 'pr_number=%s\n'   "${PR_NUMBER}"
printf 'pr_url=%s\n'      "${PR_URL}"
