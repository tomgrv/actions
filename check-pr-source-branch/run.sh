#!/usr/bin/sh

# Reject a PR whose source branch is the restricted branch unless its title
# marks it as a hotfix.

set -eu

SOURCE_BRANCH="${SOURCE_BRANCH:?SOURCE_BRANCH is required}"
PR_TITLE="${PR_TITLE:-}"

if [ -z "${RESTRICTED_BRANCH:-}" ]; then
    echo "RESTRICTED_BRANCH not set, using default: main" >&2
fi
RESTRICTED_BRANCH="${RESTRICTED_BRANCH:-main}"

if [ "${SOURCE_BRANCH}" != "${RESTRICTED_BRANCH}" ]; then
    echo "::notice::Source branch '${SOURCE_BRANCH}' is not restricted, nothing to check." >&2
    exit 0
fi

case "${PR_TITLE}" in
    *hotfix*)
        echo "::notice::PR from '${RESTRICTED_BRANCH}' is marked as a hotfix, allowed." >&2
        exit 0
        ;;
esac

error_message="PRs cannot originate from the '${RESTRICTED_BRANCH}' branch unless marked as a hotfix.

Rule: Default PR source branch is not '${RESTRICTED_BRANCH}'.
- Only create PRs from '${RESTRICTED_BRANCH}' if explicitly requested or marked as 'hotfix/...'.
- Update your branch name or create a new PR from the default development branch."
escaped_error=$(printf '%s\n' "${error_message}" | sed 's/%/%25/g;s/$/\\n/g' | tr -d '\n' | sed 's/\\n/%0A/g;s/%25/%/g')
echo "::error::${escaped_error}"
exit 1
