#!/usr/bin/sh

# Run git-release-beta then git-release-prod against the already-checked-out
# repo. Assumes this action's own earlier steps already put both commands
# on PATH (setup-scripts) and configured git identity (config-bot).

set -eu

DRY_RUN="${DRY_RUN:-false}"

command -v git-release-beta > /dev/null || {
    zz_log e "release-promote: git-release-beta not on PATH (the setup-scripts step should have installed it)"
    exit 1
}
command -v git-release-prod > /dev/null || {
    zz_log e "release-promote: git-release-prod not on PATH (the setup-scripts step should have installed it)"
    exit 1
}

# Comment "Released to main branch as vX.Y.Z" on every PR merged since the
# previous release, and on the issues those PRs close. Best-effort: the release itself already succeeded, so
# nothing here may fail the run.
comment_released_prs() {
    NEW_TAG="$(git describe --tags --abbrev=0 --match 'v[0-9]*' --exclude '*-*' main 2> /dev/null || true)"

    if [ -z "${PREV_TAG}" ] || [ -z "${NEW_TAG}" ] || [ "${PREV_TAG}" = "${NEW_TAG}" ]; then
        zz_log w "release-promote: no previous/new release tag found (prev='${PREV_TAG}' new='${NEW_TAG}'), skipping PR comments"
        return 0
    fi
    command -v gh > /dev/null || {
        zz_log w "release-promote: gh not on PATH, skipping PR comments"
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
            zz_log w "release-promote: could not comment on PR #${pr}"
        # Issues the PR closes get the same notice.
        for issue in $(gh pr view "${pr}" --repo "${REPO}" --json closingIssuesReferences --jq '.closingIssuesReferences[].number' 2> /dev/null || true); do
            gh issue comment "${issue}" --repo "${REPO}" --body "Released to main branch as ${NEW_TAG}" ||
                zz_log w "release-promote: could not comment on issue #${issue}"
        done
    done
}

if [ "${DRY_RUN}" = "true" ]; then
    echo "dry-run=true, stopping before git-release-beta/git-release-prod would push to main."
    exit 0
fi

# Last release before this run, so we can list what this one ships.
PREV_TAG="$(git describe --tags --abbrev=0 --match 'v[0-9]*' --exclude '*-*' origin/main 2> /dev/null || true)"

if git-release-beta && git-release-prod; then
    comment_released_prs
    exit 0
fi

zz_log e "git-release-prod failed to push -- if this looks like a protected-ref rejection, main/tag protection needs a bypass entry for github-actions[bot]. See docs/release-process.md in tomgrv/actions for the exact checklist."
exit 1
