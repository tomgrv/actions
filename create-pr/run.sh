#!/usr/bin/sh

set -eu

REPOSITORY="${REPOSITORY:-${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required}}"
HEAD_BRANCH="${HEAD_BRANCH:?HEAD_BRANCH is required}"
WORKING_DIRECTORY="${WORKING_DIRECTORY:-.}"

HEAD_OWNER="${HEAD_OWNER:-${GITHUB_REPOSITORY%%/*}}"

DEFAULT_BRANCH=$(gh repo view "${REPOSITORY}" --json defaultBranchRef --jq '.defaultBranchRef.name')
DEFAULT_TITLE="sync: Update from ${HEAD_BRANCH}"

BASE_BRANCH="${BASE_BRANCH:-${DEFAULT_BRANCH:-main}}"

COMMIT_MESSAGE="${COMMIT_MESSAGE:-${DEFAULT_TITLE}}"
COMMIT_FILES="${COMMIT_FILES:-.}"

PR_TITLE="${PR_TITLE:-${DEFAULT_TITLE}}"
PR_BODY="${PR_BODY:-${DEFAULT_TITLE}} \
--- \
_This pull request was created automatically by [tomgrv/actions/create-pr](https://github.com/tomgrv/actions/create-pr)_"

if [ -z "${GITHUB_TOKEN:-}" ]; then
  echo "::error::GITHUB_TOKEN is required" >&2
  exit 1
fi

export GH_TOKEN="${GITHUB_TOKEN}"

cd "${WORKING_DIRECTORY}" || {
  echo "::error::Working directory '${WORKING_DIRECTORY}' does not exist" >&2
  exit 1
}

git config --global --add safe.directory "$(pwd)" >/dev/null 2>&1 || true

if [ -z "$(git status --porcelain)" ]; then
    echo "::notice::No changes detected in working directory, skipping PR creation." >&2
    printf 'action=skip\n'
    printf 'has-changes=false\n'
    printf 'pr-number=\n'
    printf 'pr-url=\n'
    exit 0
fi

if [ -z "${COMMIT_MESSAGE}" ]; then
    echo "::error::commit-message is required when commit-all is true" >&2
    exit 1
fi

git checkout -B "${HEAD_BRANCH}" >&2
git add $(echo "${COMMIT_FILES:-.}" | tr ',' ' ') >&2
git commit -m "${COMMIT_MESSAGE}" --no-verify >&2
git push origin "HEAD:${HEAD_BRANCH}" --no-verify --force >&2

HEAD_REF="${HEAD_OWNER}:${HEAD_BRANCH}"

PR_NUMBER_JQ="[.[] | select(.headRepositoryOwner.login == \"${HEAD_OWNER}\")] | .[0].number // empty"
PR_NUMBER=$(gh pr list \
  --repo "${REPOSITORY}" \
  --state open \
  --head "${HEAD_BRANCH}" \
  --json number,headRepositoryOwner \
  --jq "${PR_NUMBER_JQ}" 2>/dev/null || true)

if [ -n "${PR_NUMBER}" ]; then

  echo "Existing PR #${PR_NUMBER} found for head '${HEAD_REF}'" >&2

  if [ -n "${PR_BODY}" ]; then
    gh pr edit "${PR_NUMBER}" \
      --repo "${REPOSITORY}" \
      --title "${PR_TITLE}" \
      --body "${PR_BODY}" >/dev/null
  else
    gh pr edit "${PR_NUMBER}" \
      --repo "${REPOSITORY}" \
      --title "${PR_TITLE}" >/dev/null
  fi

  ACTION="updated"

else

  echo "No existing PR found for head '${HEAD_REF}', creating a new one" >&2

  if [ -n "${PR_BODY}" ]; then
    gh pr create \
      --repo "${REPOSITORY}" \
      --head "${HEAD_REF}" \
      --base "${BASE_BRANCH}" \
      --title "${PR_TITLE}" \
      --body "${PR_BODY}" >/dev/null
  else
    gh pr create \
      --repo "${REPOSITORY}" \
      --head "${HEAD_REF}" \
      --base "${BASE_BRANCH}" \
      --title "${PR_TITLE}" >/dev/null
  fi

  PR_NUMBER=$(gh pr list \
  --repo "${REPOSITORY}" \
  --state open \
  --head "${HEAD_BRANCH}" \
  --json number,headRepositoryOwner \
  --jq "${PR_NUMBER_JQ}" 2>/dev/null || true)

  ACTION="created"
fi

PR_URL=$(gh pr view "${PR_NUMBER}" --repo "${REPOSITORY}" --json url --jq '.url')
echo "::notice::PR #${PR_NUMBER} ${ACTION}: ${PR_URL}" >&2

printf 'action=%s\n' "${ACTION}"
printf 'has-changes=true\n'
printf 'pr-number=%s\n' "${PR_NUMBER}"
printf 'pr-url=%s\n' "${PR_URL}"
