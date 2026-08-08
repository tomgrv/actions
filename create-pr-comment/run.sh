#!/usr/bin/sh

set -eu

if [ -z "${GH_TOKEN:-}" ]; then
  echo "::error::github-token is required" >&2
  exit 1
fi

PR_NUMBER="${PR_NUMBER:?pr-number is required}"
KEY="${KEY:?key is required}"
BODY="${BODY:?body is required}"
REPO="${REPO:-${GITHUB_REPOSITORY:-}}"

if [ -z "${REPO}" ]; then
  echo "::error::could not determine repository from REPO or GITHUB_REPOSITORY." >&2
  exit 1
fi

MARKER="<!-- comment-pr:${KEY} -->"
FULL_BODY="${MARKER}
${BODY}"

EXISTING_ID=$(gh api "repos/${REPO}/issues/${PR_NUMBER}/comments" --paginate |
  jq -r --arg marker "${MARKER}" '[.[] | select(.body != null and (.body | startswith($marker)))][0].id // empty')

if [ -n "${EXISTING_ID}" ]; then
  RESULT=$(gh api --method PATCH "repos/${REPO}/issues/comments/${EXISTING_ID}" -f body="${FULL_BODY}" --jq '[.id, .html_url] | @tsv')
  echo "Updated comment ${EXISTING_ID} on PR #${PR_NUMBER}" >&2
  ACTION=updated
else
  RESULT=$(gh api --method POST "repos/${REPO}/issues/${PR_NUMBER}/comments" -f body="${FULL_BODY}" --jq '[.id, .html_url] | @tsv')
  echo "Created comment on PR #${PR_NUMBER}" >&2
  ACTION=created
fi

COMMENT_ID=$(printf '%s' "${RESULT}" | cut -f1)
COMMENT_URL=$(printf '%s' "${RESULT}" | cut -f2)

printf 'action=%s\n' "${ACTION}"
printf 'comment-id=%s\n' "${COMMENT_ID}"
printf 'comment-url=%s\n' "${COMMENT_URL}"
