#!/usr/bin/sh

set -eu

if [ -z "${GITHUB_TOKEN:-}" ]; then
  echo "::error::GITHUB_TOKEN is required" >&2
  exit 1i

if ! command -v gh >/dev/null 2>&1; then
  echo "::error::gh CLI could not be found. Please install it to run this action." >&2
  exit 1
fi

export GH_TOKEN="${GITHUB_TOKEN}"

REPOSITORY="${REPOSITORY:-${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required}}"
AUTOSQUASH="${AUTOSQUASH:-false}"

# Resolve PR number from input or current event context
if [ -n "${PR_NUMBER:-}" ]; then
  PR_DATA=$(gh pr view "${PR_NUMBER}" --repo "${REPOSITORY}" --json number,url,headRefName,baseRefName,mergeable 2>/dev/null || true)
else
  PR_DATA=$(gh pr view --repo "${REPOSITORY}" --json number,url,headRefName,baseRefName,mergeable 2>/dev/null || true)
fi

if [ -z "${PR_DATA:-}" ]; then
  echo "::error::Could not find pull request." >&2
  exit 1
fi

PR_NUMBER=$(printf '%s' "${PR_DATA}" | gh api /repos/"${REPOSITORY}"/pulls --jq '.number' 2>/dev/null || \
  printf '%s' "${PR_DATA}" | grep -o '"number":[0-9]*' | head -1 | cut -d: -f2)

# Use gh JSON extraction via process substitution compatible with POSIX sh
PR_NUMBER=$(printf '%s' "${PR_DATA}" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['number'])" 2>/dev/null || \
            printf '%s' "${PR_DATA}" | sed -n 's/.*"number":\([0-9]*\).*/\1/p' | head -1)
HEAD_BRANCH=$(printf '%s' "${PR_DATA}" | sed -n 's/.*"headRefName":"\([^"]*\)".*/\1/p' | head -1)
BASE_BRANCH=$(printf '%s' "${PR_DATA}" | sed -n 's/.*"baseRefName":"\([^"]*\)".*/\1/p' | head -1)
PR_URL=$(printf '%s' "${PR_DATA}" | sed -n 's/.*"url":"\([^"]*\)".*/\1/p' | head -1)

if [ -z "${HEAD_BRANCH:-}" ] || [ -z "${BASE_BRANCH:-}" ]; then
  echo "::error::Could not resolve head or base branch for PR #${PR_NUMBER}." >&2
  exit 1
fi

echo "::notice::Rebasing PR #${PR_NUMBER} (${HEAD_BRANCH} onto ${BASE_BRANCH})" >&2

git config --global --add safe.directory "$(pwd)" >/dev/null 2>&1 || true

# Fetch both branches
git fetch origin "${BASE_BRANCH}" "${HEAD_BRANCH}" >&2

# Check if rebase is needed
MERGE_BASE=$(git merge-base "origin/${HEAD_BRANCH}" "origin/${BASE_BRANCH}")
BASE_TIP=$(git rev-parse "origin/${BASE_BRANCH}")

if [ "${MERGE_BASE}" = "${BASE_TIP}" ]; then
  echo "::notice::PR #${PR_NUMBER} is already up-to-date with ${BASE_BRANCH}, nothing to do." >&2
  printf 'action=up-to-date\n'
  printf 'head_branch=%s\n' "${HEAD_BRANCH}"
  printf 'base_branch=%s\n' "${BASE_BRANCH}"
  printf 'pr_number=%s\n' "${PR_NUMBER}"
  printf 'pr_url=%s\n' "${PR_URL}"
  exit 0
fi

# Create a temporary worktree for the rebase
TMP_DIR=$(mktemp -d)
trap 'rm -rf "${TMP_DIR}"' EXIT INT TERM

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

git worktree remove "${TMP_DIR}" --force >/dev/null 2>&1 || true

NEW_HEAD=$(git rev-parse "origin/${HEAD_BRANCH}")
echo "::notice::PR #${PR_NUMBER} successfully rebased. New HEAD: ${NEW_HEAD}" >&2

printf 'action=rebased\n'
printf 'head_branch=%s\n' "${HEAD_BRANCH}"
printf 'base_branch=%s\n' "${BASE_BRANCH}"
printf 'pr_number=%s\n' "${PR_NUMBER}"
printf 'pr_url=%s\n' "${PR_URL}"
