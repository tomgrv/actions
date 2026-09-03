#!/usr/bin/sh

# Run git-release-beta then git-release-prod against the already-checked-out
# repo. Assumes this action's own earlier steps already put both commands
# on PATH (setup-scripts) and configured git identity (config-bot).

set -eu

DRY_RUN="${DRY_RUN:-false}"

command -v git-release-beta > /dev/null || {
    echo "release-promote: git-release-beta not on PATH (the setup-scripts step should have installed it)" >&2
    exit 1
}
command -v git-release-prod > /dev/null || {
    echo "release-promote: git-release-prod not on PATH (the setup-scripts step should have installed it)" >&2
    exit 1
}

if [ "${DRY_RUN}" = "true" ]; then
    echo "dry-run=true, stopping before git-release-beta/git-release-prod would push to main."
    exit 0
fi

if git-release-beta && git-release-prod; then
    exit 0
fi

echo "::error::git-release-prod failed to push -- if this looks like a protected-ref rejection, main/tag protection needs a bypass entry for github-actions[bot]. See docs/release-process.md in tomgrv/actions for the exact checklist." >&2
exit 1
