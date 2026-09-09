#!/usr/bin/sh

set -eu

# Export GitHub token for gh CLI
export GH_TOKEN="${GITHUB_TOKEN:-}"

if [ -z "${GH_TOKEN}" ]; then
  zz_log e "github-token is required"
  exit 1
fi

REF="${REF:?ref is required}"
SHA="${SHA:?sha is required}"
REPO="${REPO:-${GITHUB_REPOSITORY:-}}"

if [ -z "${REPO}" ]; then
  zz_log e "could not determine repository from REPO or GITHUB_REPOSITORY."
  exit 1
fi

SHORT_REF="${REF#refs/}"

if gh api "repos/${REPO}/git/ref/${SHORT_REF}" >/dev/null 2>&1; then
  gh api --method PATCH "repos/${REPO}/git/refs/${SHORT_REF}" -f sha="${SHA}" -F force=true >/dev/null
  zz_log i "Updated ref ${REF} -> ${SHA}"
  printf 'action=updated\n'
else
  gh api --method POST "repos/${REPO}/git/refs" -f ref="${REF}" -f sha="${SHA}" >/dev/null
  zz_log i "Created ref ${REF} -> ${SHA}"
  printf 'action=created\n'
fi

printf 'ref=%s\n' "${REF}"
