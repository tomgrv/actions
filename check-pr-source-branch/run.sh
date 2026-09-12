#!/usr/bin/sh

# Reject a PR whose target (base) branch is the restricted branch unless its
# title marks it as a hotfix.

set -eu

TARGET_BRANCH="${TARGET_BRANCH:?TARGET_BRANCH is required}"
PR_TITLE="${PR_TITLE:-}"

if [ -z "${RESTRICTED_BRANCH:-}" ]; then
    zz_log i "RESTRICTED_BRANCH not set, using default: main"
fi
RESTRICTED_BRANCH="${RESTRICTED_BRANCH:-main}"

if [ "${TARGET_BRANCH}" != "${RESTRICTED_BRANCH}" ]; then
    zz_log i "Target branch '${TARGET_BRANCH}' is not restricted, nothing to check."
    exit 0
fi

case "${PR_TITLE}" in
    *hotfix*)
        zz_log i "PR from '${RESTRICTED_BRANCH}' is marked as a hotfix, allowed."
        exit 0
        ;;
esac

error_message="PRs cannot target the '${RESTRICTED_BRANCH}' branch unless marked as a hotfix.

Rule: Default PR target (base) branch is not '${RESTRICTED_BRANCH}'.
- Only open PRs against '${RESTRICTED_BRANCH}' if explicitly requested or marked as 'hotfix/...'.
- Retarget your PR to the default development branch."
zz_log e "${error_message}"
exit 1
