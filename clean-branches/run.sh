#!/usr/bin/sh

set -e

# Export GitHub token for gh CLI
export GH_TOKEN="${GITHUB_TOKEN:-}"

# Inside GitLab CI the merge requests and branches go through the REST API
# (GITLAB_TOKEN: a project access token with the api scope) instead of gh.
GITLAB="false"
[ "${GITLAB_CI:-}" = "true" ] && GITLAB="true"

PROTECTED_BRANCHES="${PROTECTED_BRANCHES:-main,master,develop}"
MERGED_ONLY="${MERGED_ONLY:-false}"
REPO="${REPO:-${GITHUB_REPOSITORY:-${CI_PROJECT_PATH:-}}}"

if [ -z "$REPO" ]; then
  REPO=$(git config --get remote.origin.url | sed -E 's/.*[:\/]([^\/]+\/[^\.]+)(\.git)?$/\1/')
  if [ -z "$REPO" ]; then
    zz-log e "could not determine repository from GITHUB_REPOSITORY or git remote."
    exit 1
  fi
fi

zz-log i "Cleaning branches with closed PRs for repo: ${REPO}"
zz-log i "Protected branches: ${PROTECTED_BRANCHES}"
zz-log i "Merged only: ${MERGED_ONLY}"

is_protected() {
  branch="$1"
  old_ifs="$IFS"
  IFS=','
  for protected in $PROTECTED_BRANCHES; do
    if [ "$branch" = "$protected" ]; then
      IFS="$old_ifs"
      return 0
    fi
  done
  IFS="$old_ifs"
  return 1
}

if [ "${GITLAB}" = "true" ]; then
  GITLAB_API="${CI_API_V4_URL:-https://gitlab.com/api/v4}"
  GITLAB_PROJECT="$(printf '%s' "${REPO}" | sed 's|/|%2F|g')"
  glapi() {
    curl -fsS --header "PRIVATE-TOKEN: ${GITLAB_TOKEN:-}" "$@"
  }
  # One JSON array per page (up to 500 merge requests per state, like the gh limit)
  mrs() {
    page=1
    while [ "${page}" -le 5 ]; do
      json=$(glapi "${GITLAB_API}/projects/${GITLAB_PROJECT}/merge_requests?state=$1&per_page=100&page=${page}") || return 1
      [ "$(printf '%s' "${json}" | jq 'length')" -gt 0 ] || break
      printf '%s\n' "${json}"
      page=$((page + 1))
    done
  }
  # Merge requests whose source branch lives in this project (exclude forks)
  closed_branches=$(
    {
      mrs closed | jq -r '.[] | select(.source_project_id == .target_project_id) | "\(.source_branch)\tfalse"'
      mrs merged | jq -r '.[] | select(.source_project_id == .target_project_id) | "\(.source_branch)\ttrue"'
    }
  )
  open_branches=$(mrs opened | jq -r '.[].source_branch')

  branch_exists() {
    glapi "${GITLAB_API}/projects/${GITLAB_PROJECT}/repository/branches/$(printf '%s' "$1" | sed 's|/|%2F|g')" >/dev/null 2>&1
  }
  branch_delete() {
    glapi --request DELETE "${GITLAB_API}/projects/${GITLAB_PROJECT}/repository/branches/$(printf '%s' "$1" | sed 's|/|%2F|g')" >/dev/null 2>&1
  }
else
  # Fetch closed PRs whose head branch lives in this repo (exclude forks) and
  # is not currently referenced by any still-open PR.
  closed_branches=$(gh pr list --repo "${REPO}" --state closed --limit 500 \
    --json headRefName,headRepositoryOwner,merged --jq \
    '.[] | select(.headRepositoryOwner.login != null) | "\(.headRefName)\t\(.merged)"')

  open_branches=$(gh pr list --repo "${REPO}" --state open --limit 500 \
    --json headRefName --jq '.[].headRefName')

  branch_exists() {
    gh api "repos/${REPO}/git/refs/heads/$1" >/dev/null 2>&1
  }
  branch_delete() {
    gh api -X DELETE "repos/${REPO}/git/refs/heads/$1" >/dev/null 2>&1
  }
fi

deleted=""
count=0

old_ifs="$IFS"
IFS='
'
for line in $closed_branches; do
  [ -z "$line" ] && continue
  branch=$(printf '%s' "$line" | cut -f1)
  merged=$(printf '%s' "$line" | cut -f2)

  if [ -z "$branch" ]; then
    continue
  fi

  if is_protected "$branch"; then
    zz-log i "Skipping protected branch: ${branch}"
    continue
  fi

  if [ "$MERGED_ONLY" = "true" ] && [ "$merged" != "true" ]; then
    zz-log i "Skipping unmerged closed PR branch: ${branch}"
    continue
  fi

  if printf '%s\n' "$open_branches" | grep -qx "$branch"; then
    zz-log i "Skipping branch still referenced by an open PR: ${branch}"
    continue
  fi

  if ! branch_exists "${branch}"; then
    zz-log i "Branch already deleted: ${branch}"
    continue
  fi

  zz-log i "Deleting branch: ${branch}"
  if branch_delete "${branch}"; then
    deleted="${deleted}${branch}
"
    count=$((count + 1))
  else
    zz-log w "Failed to delete branch: ${branch}"
  fi
done
IFS="$old_ifs"

zz-log i "Deleted ${count} branch(es)."

{
  echo "deleted-branches<<EOF"
  printf '%s' "$deleted"
  echo "EOF"
  echo "count=${count}"
}
