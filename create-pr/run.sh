#!/usr/bin/sh

# Commit any pending changes in the working directory and open or update a
# pull request for them.

set -eu

REPOSITORY="${REPOSITORY:-${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required}}"
HEAD_BRANCH="${HEAD_BRANCH:?HEAD_BRANCH is required}"
WORKING_DIRECTORY="${WORKING_DIRECTORY:-.}"

# Input defaulting is a setup detail, not a finding: plain log only.
if [ "${WORKING_DIRECTORY}" = "." ]; then
  zz-log i "WORKING_DIRECTORY not set, using default: ."
fi

# The forge hosting REPOSITORY: GitLab inside GitLab CI, GitHub otherwise. Set FORGE=github
# to target a GitHub repository from a GitLab job (e.g. a monorepo split).
if [ -z "${FORGE:-}" ]; then
  [ "${GITLAB_CI:-}" = "true" ] && FORGE=gitlab || FORGE=github
fi

if [ "${FORGE}" = "gitlab" ]; then
  # GITLAB_TOKEN: a project access token with the api and write_repository scopes.
  if [ -z "${GITLAB_TOKEN:-}" ]; then
    zz-log e "GITLAB_TOKEN is required"
    exit 1
  fi
  GITLAB_API="${CI_API_V4_URL:-https://gitlab.com/api/v4}"
  GITLAB_PROJECT="$(printf '%s' "${REPOSITORY}" | sed 's|/|%2F|g')"
  glapi() {
    curl -fsS --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" "$@"
  }
  DEFAULT_BRANCH=$(glapi "${GITLAB_API}/projects/${GITLAB_PROJECT}" | jq -r '.default_branch')
else
  HEAD_OWNER="${HEAD_OWNER:-${GITHUB_REPOSITORY%%/*}}"
  DEFAULT_BRANCH=$(gh repo view "${REPOSITORY}" --json defaultBranchRef --jq '.defaultBranchRef.name')
fi
DEFAULT_TITLE="sync: Update from ${HEAD_BRANCH}"

BASE_BRANCH="${BASE_BRANCH:-${DEFAULT_BRANCH:-main}}"

COMMIT_MESSAGE="${COMMIT_MESSAGE:-${DEFAULT_TITLE}}"
COMMIT_FILES="${COMMIT_FILES:-.}"

PR_TITLE="${PR_TITLE:-${DEFAULT_TITLE}}"
PR_BODY="${PR_BODY:-${DEFAULT_TITLE}} \
--- \
_This pull request was created automatically by [tomgrv/actions/create-pr](https://github.com/tomgrv/actions/create-pr)_"

if [ "${FORGE}" = "github" ]; then
  if [ -z "${GITHUB_TOKEN:-}" ]; then
    zz-log e "GITHUB_TOKEN is required"
    exit 1
  fi

  export GH_TOKEN="${GITHUB_TOKEN}"
fi

cd "${WORKING_DIRECTORY}" || {
  zz-log e "Working directory '${WORKING_DIRECTORY}' does not exist"
  exit 1
}

git config --global --add safe.directory "$(pwd)" >/dev/null 2>&1 || true

if [ -z "$(git status --porcelain)" ]; then
    zz-log n "No changes detected in working directory, skipping PR creation."
    printf 'action=skip\n'
    printf 'has-changes=false\n'
    printf 'pr-number=\n'
    printf 'pr-url=\n'
    exit 0
fi

if [ -z "${COMMIT_MESSAGE}" ]; then
    zz-log e "commit-message is required when commit-all is true"
    exit 1
fi

git checkout -B "${HEAD_BRANCH}" >&2
git add $(echo "${COMMIT_FILES:-.}" | tr ',' ' ') >&2
git commit -m "${COMMIT_MESSAGE}" --no-verify >&2
if [ "${FORGE}" = "gitlab" ]; then
  # The CI checkout token is read-only: push with the access token.
  git remote set-url origin "https://oauth2:${GITLAB_TOKEN}@${CI_SERVER_HOST:-gitlab.com}/${REPOSITORY}.git" >&2
fi
git push origin "HEAD:${HEAD_BRANCH}" --no-verify --force >&2

if [ "${FORGE}" = "gitlab" ]; then
  MRS="${GITLAB_API}/projects/${GITLAB_PROJECT}/merge_requests"
  PR_NUMBER=$(glapi "${MRS}?state=opened&source_branch=${HEAD_BRANCH}" | jq -r '.[0].iid // empty')

  if [ -n "${PR_NUMBER}" ]; then
    zz-log i "Existing MR !${PR_NUMBER} found for branch '${HEAD_BRANCH}'"
    glapi --request PUT "${MRS}/${PR_NUMBER}" \
      --data-urlencode "title=${PR_TITLE}" --data-urlencode "description=${PR_BODY}" >/dev/null
    ACTION="updated"
  else
    zz-log i "No existing MR found for branch '${HEAD_BRANCH}', creating a new one"
    PR_NUMBER=$(glapi --request POST "${MRS}" \
      --data-urlencode "source_branch=${HEAD_BRANCH}" --data-urlencode "target_branch=${BASE_BRANCH}" \
      --data-urlencode "title=${PR_TITLE}" --data-urlencode "description=${PR_BODY}" | jq -r '.iid')
    ACTION="created"
  fi

  PR_URL=$(glapi "${MRS}/${PR_NUMBER}" | jq -r '.web_url')
  zz-log n "MR !${PR_NUMBER} ${ACTION}: ${PR_URL}"

  printf 'action=%s\n' "${ACTION}"
  printf 'has-changes=true\n'
  printf 'pr-number=%s\n' "${PR_NUMBER}"
  printf 'pr-url=%s\n' "${PR_URL}"
  exit 0
fi

HEAD_REF="${HEAD_OWNER}:${HEAD_BRANCH}"

PR_NUMBER_JQ="[.[] | select(.headRepositoryOwner.login == \"${HEAD_OWNER}\")] | .[0].number // empty"
PR_NUMBER=$(gh pr list \
  --repo "${REPOSITORY}" \
  --state open \
  --head "${HEAD_BRANCH}" \
  --json number,headRepositoryOwner \
  --jq "${PR_NUMBER_JQ}" 2>/dev/null || true)

if [ -n "${PR_NUMBER}" ]; then

  zz-log i "Existing PR #${PR_NUMBER} found for head '${HEAD_REF}'"

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

  zz-log i "No existing PR found for head '${HEAD_REF}', creating a new one"

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
zz-log n "PR #${PR_NUMBER} ${ACTION}: ${PR_URL}"

printf 'action=%s\n' "${ACTION}"
printf 'has-changes=true\n'
printf 'pr-number=%s\n' "${PR_NUMBER}"
printf 'pr-url=%s\n' "${PR_URL}"
