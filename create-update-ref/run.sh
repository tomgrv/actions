#!/usr/bin/sh

# Provides a `gh` shim on Forgejo (no-op on GitHub).
. "$(dirname "$0")/../_lib/forge.sh"

set -eu

# Export GitHub token for gh CLI
export GH_TOKEN="${GITHUB_TOKEN:-}"

if [ -z "${GH_TOKEN}" ]; then
  zz-log e "github-token is required"
  exit 1
fi

REF="${REF:?ref is required}"
SHA="${SHA:?sha is required}"
REPO="${REPO:-${GITHUB_REPOSITORY:-}}"

if [ -z "${REPO}" ]; then
  zz-log e "could not determine repository from REPO or GITHUB_REPOSITORY."
  exit 1
fi

SHORT_REF="${REF#refs/}"

if [ "${FORGE}" = forgejo ]; then
  # Forgejo cannot create/move a ref to a SHA through its REST API: push it
  # (the SHA must exist in the local clone).
  _auth="AUTHORIZATION: basic $(printf 'x-access-token:%s' "${GH_TOKEN}" | base64 | tr -d '\n')"
  if git ls-remote --exit-code "${GITHUB_SERVER_URL}/${REPO}.git" "${REF}" >/dev/null 2>&1; then _action=updated; else _action=created; fi
  git -c "http.${GITHUB_SERVER_URL}/.extraheader=${_auth}" push --force "${GITHUB_SERVER_URL}/${REPO}.git" "${SHA}:${REF}" >&2
  zz-log i "${_action} ref ${REF} -> ${SHA}"
  printf 'action=%s\n' "${_action}"
elif gh api "repos/${REPO}/git/ref/${SHORT_REF}" >/dev/null 2>&1; then
  gh api --method PATCH "repos/${REPO}/git/refs/${SHORT_REF}" -f sha="${SHA}" -F force=true >/dev/null
  zz-log i "Updated ref ${REF} -> ${SHA}"
  printf 'action=updated\n'
else
  gh api --method POST "repos/${REPO}/git/refs" -f ref="${REF}" -f sha="${SHA}" >/dev/null
  zz-log i "Created ref ${REF} -> ${SHA}"
  printf 'action=created\n'
fi

printf 'ref=%s\n' "${REF}"
