#!/usr/bin/sh

set -e

# Export GitHub token for gh CLI
export GH_TOKEN="${GITHUB_TOKEN:-}"

PROTECTED_BRANCHES="${PROTECTED_BRANCHES:-main,master,develop}"
MERGED_ONLY="${MERGED_ONLY:-false}"
REPO="${REPO:-${GITHUB_REPOSITORY:-}}"

if [ -z "$REPO" ]; then
  REPO=$(git config --get remote.origin.url | sed -E 's/.*[:\/]([^\/]+\/[^\.]+)(\.git)?$/\1/')
  if [ -z "$REPO" ]; then
    zz_log e "could not determine repository from GITHUB_REPOSITORY or git remote."
    exit 1
  fi
fi

zz_log i "Cleaning branches with closed PRs for repo: ${REPO}"
zz_log i "Protected branches: ${PROTECTED_BRANCHES}"
zz_log i "Merged only: ${MERGED_ONLY}"

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

# Fetch closed PRs whose head branch lives in this repo (exclude forks) and
# is not currently referenced by any still-open PR.
closed_branches=$(gh pr list --repo "${REPO}" --state closed --limit 500 \
  --json headRefName,headRepositoryOwner,merged --jq \
  '.[] | select(.headRepositoryOwner.login != null) | "\(.headRefName)\t\(.merged)"')

open_branches=$(gh pr list --repo "${REPO}" --state open --limit 500 \
  --json headRefName --jq '.[].headRefName')

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
    zz_log i "Skipping protected branch: ${branch}"
    continue
  fi

  if [ "$MERGED_ONLY" = "true" ] && [ "$merged" != "true" ]; then
    zz_log i "Skipping unmerged closed PR branch: ${branch}"
    continue
  fi

  if printf '%s\n' "$open_branches" | grep -qx "$branch"; then
    zz_log i "Skipping branch still referenced by an open PR: ${branch}"
    continue
  fi

  if ! gh api "repos/${REPO}/git/refs/heads/${branch}" >/dev/null 2>&1; then
    zz_log i "Branch already deleted: ${branch}"
    continue
  fi

  zz_log i "Deleting branch: ${branch}"
  if gh api -X DELETE "repos/${REPO}/git/refs/heads/${branch}" >/dev/null 2>&1; then
    deleted="${deleted}${branch}
"
    count=$((count + 1))
  else
    zz_log w "Failed to delete branch: ${branch}"
  fi
done
IFS="$old_ifs"

zz_log i "Deleted ${count} branch(es)."

{
  echo "deleted-branches<<EOF"
  printf '%s' "$deleted"
  echo "EOF"
  echo "count=${count}"
}
