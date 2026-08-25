#!/usr/bin/sh

# Determine the reviewdog reporter for this run context: `type` input takes
# precedence when set, otherwise auto-detect from the triggering event.
# `github-pr-*` reporters need a pull request; `github-check` is the only
# reporter that works outside one, so non-PR events (push, workflow_dispatch,
# schedule...) fall back to it.

set -eu

EVENT_NAME="${EVENT_NAME:-}"
TYPE_INPUT="${TYPE_INPUT:-}"

case "${EVENT_NAME}" in
    pull_request | pull_request_target)
        prefix=github-pr
        ;;
    *)
        prefix=github
        ;;
esac

if [ -n "${TYPE_INPUT}" ]; then
    suffix="${TYPE_INPUT}"
else
    suffix=check
fi

case "${suffix}" in
    check | review | annotations)
        reporter="${prefix}-${suffix}"
        ;;
    *)
        echo "Invalid type: ${suffix}. Must be check, review, or annotations." >&2
        exit 1
        ;;
esac

printf 'REVIEWDOG_REPORTER=%s\n' "${reporter}"
