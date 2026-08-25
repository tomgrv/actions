#!/usr/bin/sh

# Post a comment on a pull request or issue, referencing the comment that
# triggered the workflow.

set -eu

# Missing tooling/tokens are setup concerns: plain log only.
if [ -z "${GITHUB_TOKEN:-}" ]; then
  echo "Error: GITHUB_TOKEN is required" >&2
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "Error: gh CLI could not be found. Please install it." >&2
  exit 1
fi

export GH_TOKEN="${GITHUB_TOKEN}"

REPOSITORY="${REPOSITORY:-${GITHUB_REPOSITORY:-}}"
ISSUE_NUMBER="${ISSUE_NUMBER:-}"
REPLY_TO_URL="${REPLY_TO_URL:-}"
BODY="${BODY:-}"

if [ -z "${REPOSITORY}" ]; then
  echo "Error: Provide repository or set GITHUB_REPOSITORY." >&2
  exit 1
fi

if [ -z "${ISSUE_NUMBER}" ]; then
  echo "Error: issue-number is required." >&2
  exit 1
fi

if [ -z "${BODY}" ]; then
  echo "Error: body is required." >&2
  exit 1
fi

if [ -n "${REPLY_TO_URL}" ]; then
  FULL_BODY=$(printf 'Replying to [this comment](%s):\n\n%s' "${REPLY_TO_URL}" "${BODY}")
else
  FULL_BODY="${BODY}"
fi

echo "Posting comment on ${REPOSITORY}#${ISSUE_NUMBER}" >&2

COMMENT_RESULT=$(gh api \
  --method POST \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "repos/${REPOSITORY}/issues/${ISSUE_NUMBER}/comments" \
  -f "body=${FULL_BODY}" \
  --jq '[.id, .html_url] | @tsv')

COMMENT_ID=$(printf '%s' "${COMMENT_RESULT}" | cut -f1)
COMMENT_URL=$(printf '%s' "${COMMENT_RESULT}" | cut -f2)

echo "Comment posted: id=${COMMENT_ID}, url=${COMMENT_URL}" >&2

printf 'comment-id=%s\n' "${COMMENT_ID}"
printf 'comment-url=%s\n' "${COMMENT_URL}"
