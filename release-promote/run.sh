#!/usr/bin/sh

# Run git-release-beta then git-release-prod against the already-checked-out
# repo. Assumes this action's own earlier steps already put both commands
# on PATH (setup-scripts) and configured git identity (config-bot).

set -eu

DRY_RUN="${DRY_RUN:-false}"

# Inside GitLab CI the release is pushed with GITLAB_TOKEN (a project access
# token with the api and write_repository scopes, allowed to push to main and
# tags) and the "Released" comments go through the REST API instead of gh.
GITLAB="false"
if [ "${GITLAB_CI:-}" = "true" ]; then
    GITLAB="true"
    : "${GITLAB_TOKEN:?release-promote: GITLAB_TOKEN is required}"
    GITLAB_PROJECT="${CI_API_V4_URL}/projects/${CI_PROJECT_ID}"
    glapi() {
        curl -fsS --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" "$@"
    }
fi

command -v git-release-beta > /dev/null || {
    zz-log e "release-promote: git-release-beta not on PATH (the setup-scripts step should have installed it)"
    exit 1
}
command -v git-release-prod > /dev/null || {
    zz-log e "release-promote: git-release-prod not on PATH (the setup-scripts step should have installed it)"
    exit 1
}

# Comment "Released to main branch as vX.Y.Z" on every PR merged since the
# previous release, and on the issues those PRs close. Best-effort: the release itself already succeeded, so
# nothing here may fail the run.
# GitLab flavor of comment_released_prs: merge requests and the issues they close.
comment_released_mrs() {
    MRS="$(git rev-list "${PREV_TAG}..${NEW_TAG}" |
        while read -r sha; do
            glapi "${GITLAB_PROJECT}/repository/commits/${sha}/merge_requests" 2> /dev/null |
                jq -r '.[] | select(.state == "merged") | .iid' || true
        done | sort -nu)"

    echo "Merged MRs since ${PREV_TAG}: ${MRS:-none}" | tr '\n' ' '
    echo
    for mr in ${MRS}; do
        glapi --request POST "${GITLAB_PROJECT}/merge_requests/${mr}/notes" \
            --data-urlencode "body=Released to main branch as ${NEW_TAG}" > /dev/null ||
            zz-log w "release-promote: could not comment on MR !${mr}"
        for issue in $(glapi "${GITLAB_PROJECT}/merge_requests/${mr}/closes_issues" 2> /dev/null | jq -r '.[].iid' || true); do
            glapi --request POST "${GITLAB_PROJECT}/issues/${issue}/notes" \
                --data-urlencode "body=Released to main branch as ${NEW_TAG}" > /dev/null ||
                zz-log w "release-promote: could not comment on issue #${issue}"
        done
    done
}

comment_released_prs() {
    NEW_TAG="$(git describe --tags --abbrev=0 --match 'v[0-9]*' --exclude '*-*' main 2> /dev/null || true)"

    if [ -z "${PREV_TAG}" ] || [ -z "${NEW_TAG}" ] || [ "${PREV_TAG}" = "${NEW_TAG}" ]; then
        zz-log w "release-promote: no previous/new release tag found (prev='${PREV_TAG}' new='${NEW_TAG}'), skipping PR comments"
        return 0
    fi
    if [ "${GITLAB}" = "true" ]; then
        comment_released_mrs
        return 0
    fi
    command -v gh > /dev/null || {
        zz-log w "release-promote: gh not on PATH, skipping PR comments"
        return 0
    }

    REPO="${GITHUB_REPOSITORY:-$(gh repo view --json nameWithOwner -q .nameWithOwner)}"
    PRS="$(git rev-list "${PREV_TAG}..${NEW_TAG}" |
        while read -r sha; do
            gh api "repos/${REPO}/commits/${sha}/pulls" --jq '.[] | select(.merged_at != null) | .number' 2> /dev/null || true
        done | sort -nu)"

    echo "Merged PRs since ${PREV_TAG}: ${PRS:-none}" | tr '\n' ' '
    echo
    for pr in ${PRS}; do
        gh pr comment "${pr}" --repo "${REPO}" --body "Released to main branch as ${NEW_TAG}" ||
            zz-log w "release-promote: could not comment on PR #${pr}"
        # Issues the PR closes get the same notice.
        for issue in $(gh pr view "${pr}" --repo "${REPO}" --json closingIssuesReferences --jq '.closingIssuesReferences[].number' 2> /dev/null || true); do
            gh issue comment "${issue}" --repo "${REPO}" --body "Released to main branch as ${NEW_TAG}" ||
                zz-log w "release-promote: could not comment on issue #${issue}"
        done
    done
}

if [ "${DRY_RUN}" = "true" ]; then
    echo "dry-run=true, stopping before git-release-beta/git-release-prod would push to main."
    exit 0
fi

if [ "${GITLAB}" = "true" ]; then
    git remote set-url origin "https://oauth2:${GITLAB_TOKEN}@${CI_SERVER_HOST}/${CI_PROJECT_PATH}.git"
fi

# Last release before this run, so we can list what this one ships.
PREV_TAG="$(git describe --tags --abbrev=0 --match 'v[0-9]*' --exclude '*-*' origin/main 2> /dev/null || true)"

if git-release-beta && git-release-prod; then
    comment_released_prs
    exit 0
fi

zz-log e "git-release-prod failed to push -- if this looks like a protected-ref rejection, main/tag protection needs a bypass entry for github-actions[bot]. See .repo/docs/release-process.md in tomgrv/actions for the exact checklist."
exit 1
