#!/usr/bin/sh

# Resolve the deploy branch, tag, and environment from the triggering GitHub
# event (push, PR review request, tag, or workflow_dispatch).

set -eu

starts_with() {
    case "$2" in
        "$1"*) return 0 ;;
        *) return 1 ;;
    esac
}

contains() {
    case "$2" in
        *"$1"*) return 0 ;;
        *) return 1 ;;
    esac
}

EVENT_NAME="${EVENT_NAME:-}"
EVENT_ACTION="${EVENT_ACTION:-}"
REF="${REF:-}"
REF_NAME="${REF_NAME:-}"
PR_HEAD_SHA="${PR_HEAD_SHA:-}"
DEP="${DEP:-deploy}"

branch=""
tag=""
env=""

if [ "${EVENT_NAME}" = "pull_request" ] && [ "${EVENT_ACTION}" = "review_requested" ]; then
    # PR review requested → deploy the exact reviewed commit to the unstable environment.
    # NOTE: github.sha is NOT the PR's head commit for pull_request events - GitHub sets
    # it to an ephemeral auto-generated merge commit (refs/pull/<n>/merge) that a normal
    # mirror clone never fetches, so `git archive` on it fails with "not a tree object".
    # pull_request.head.sha is the actual head commit, reachable via the branch's own ref.
    branch="${PR_HEAD_SHA}"
    env="unstable"
elif starts_with "refs/heads/release/" "${REF}"; then
    branch="${REF_NAME}"
    env="staging"
elif [ "${REF}" = "refs/heads/main" ]; then
    branch="${REF_NAME}"
    env="production"
elif starts_with "refs/tags/" "${REF}" && contains "-" "${REF_NAME}"; then
    tag="${REF_NAME}"
    env="staging"
elif starts_with "refs/tags/" "${REF}"; then
    tag="${REF_NAME}"
    env="production"
elif [ "${DEP}" = "deploy" ]; then
    # Fallback for any other branch push, or a workflow_dispatch run against a
    # specific branch (e.g. an MCP-triggered on-demand deploy): deploy whatever
    # ref the workflow itself ran on. No environment guess is made here - the
    # caller must supply one via run-deployer's `environment` input.
    if starts_with "refs/heads/" "${REF}"; then
        branch="${REF_NAME}"
    fi
fi

printf 'branch=%s\n' "${branch}"
printf 'tag=%s\n' "${tag}"
printf 'env=%s\n' "${env}"
