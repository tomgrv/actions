#!/usr/bin/sh

set -eu

if [ -z "${GH_TOKEN:-}" ]; then
  echo "::error::github-token is required" >&2
  exit 1
fi

REF="${REF:?ref is required}"
SHA="${SHA:?sha is required}"
REPO="${REPO:-${GITHUB_REPOSITORY:-}}"

if [ -z "${REPO}" ]; then
  echo "::error::could not determine repository from REPO or GITHUB_REPOSITORY." >&2
  exit 1
fi

SHORT_REF="${REF#refs/}"

if gh api "repos/${REPO}/git/ref/${SHORT_REF}" >/dev/null 2>&1; then
  gh api --method PATCH "repos/${REPO}/git/refs/${SHORT_REF}" -f sha="${SHA}" -F force=true >/dev/null
  echo "Updated ref ${REF} -> ${SHA}" >&2
  printf 'action=updated\n'
else
  gh api --method POST "repos/${REPO}/git/refs" -f ref="${REF}" -f sha="${SHA}" >/dev/null
  echo "Created ref ${REF} -> ${SHA}" >&2
  printf 'action=created\n'
fi

printf 'ref=%s\n' "${REF}"
