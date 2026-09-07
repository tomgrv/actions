#!/usr/bin/sh

# Reject a PR whose source branch is the restricted branch unless its title
# marks it as a hotfix.

set -eu

SOURCE_BRANCH="${SOURCE_BRANCH:?SOURCE_BRANCH is required}"
PR_TITLE="${PR_TITLE:-}"

if [ -z "${RESTRICTED_BRANCH:-}" ]; then
    zz_log i "RESTRICTED_BRANCH not set, using default: main"
fi
RESTRICTED_BRANCH="${RESTRICTED_BRANCH:-main}"

if [ "${SOURCE_BRANCH}" != "${RESTRICTED_BRANCH}" ]; then
    zz_log i "Source branch '${SOURCE_BRANCH}' is not restricted, nothing to check."
    exit 0
fi

case "${PR_TITLE}" in
    *hotfix*)
        zz_log n "PR from '${RESTRICTED_BRANCH}' is marked as a hotfix, allowed."
        exit 0
        ;;
esac

error_message="PRs cannot originate from the '${RESTRICTED_BRANCH}' branch unless marked as a hotfix.

Rule: Default PR source branch is not '${RESTRICTED_BRANCH}'.
- Only create PRs from '${RESTRICTED_BRANCH}' if explicitly requested or marked as 'hotfix/...'.
- Update your branch name or create a new PR from the default development branch."
zz_log e "${error_message}"
exit 1
