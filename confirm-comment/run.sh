#!/usr/bin/sh

set -eu

if [ -z "${GITHUB_TOKEN:-}" ]; then
  echo "::error::GITHUB_TOKEN is required" >&2
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "::error::gh CLI could not be found. Please install it." >&2
  exit 1
fi

export GH_TOKEN="${GITHUB_TOKEN}"

REPOSITORY="${REPOSITORY:-${GITHUB_REPOSITORY:-}}"
COMMENT_URL="${COMMENT_URL:-}"
COMMENT_ID="${COMMENT_ID:-}"
REACTION="${REACTION:-+1}"

normalize_reaction() {
  case "$1" in
    +1|thumbs_up|thumbsup|👍)
      echo "+1"
      ;;
    -1|thumbs_down|thumbsdown|👎)
      echo "-1"
      ;;
    laugh|smile|😄)
      echo "laugh"
      ;;
    confused|😕)
      echo "confused"
      ;;
    heart|❤️|♥️|♥)
      echo "heart"
      ;;
    hooray|tada|🎉)
      echo "hooray"
      ;;
    rocket|🚀)
      echo "rocket"
      ;;
    eyes|👀)
      echo "eyes"
      ;;
    *)
      echo "$1"
      ;;
  esac
}

REACTION_CONTENT=$(normalize_reaction "${REACTION}")

case "${REACTION_CONTENT}" in
  +1|-1|laugh|confused|heart|hooray|rocket|eyes)
    ;;
  *)
    echo "::error::Invalid reaction '${REACTION}'. Use one of: +1, -1, laugh, confused, heart, hooray, rocket, eyes." >&2
    exit 1
    ;;
esac

if [ -z "${COMMENT_URL}" ]; then
  if [ -z "${COMMENT_ID}" ] || [ -z "${REPOSITORY}" ]; then
    echo "::error::Provide comment-url, or comment-id with repository." >&2
    exit 1
  fi
  COMMENT_URL="https://api.github.com/repos/${REPOSITORY}/issues/comments/${COMMENT_ID}"
fi

echo "Adding reaction '${REACTION_CONTENT}' to comment ${COMMENT_URL}" >&2

REACTION_RESULT=$(gh api \
  --method POST \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "${COMMENT_URL}/reactions" \
  -f "content=${REACTION_CONTENT}" \
  --jq '[.id, .content] | @tsv')

REACTION_ID=$(printf '%s' "${REACTION_RESULT}" | cut -f1)
REACTION_CREATED=$(printf '%s' "${REACTION_RESULT}" | cut -f2)

echo "Reaction added: id=${REACTION_ID}, content=${REACTION_CREATED}" >&2

printf 'reaction-id=%s\n' "${REACTION_ID}"
printf 'reaction-content=%s\n' "${REACTION_CREATED}"
printf 'comment-url=%s\n' "${COMMENT_URL}"
