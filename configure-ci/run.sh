#!/usr/bin/sh

# Detect the forge, export it to the next steps (FORGE, FORGE_FLAVOR) and, off
# GitHub, put a `gh` on PATH that talks to the forge's REST API (see _lib/forge.sh).

set -eu

DIR="$(cd "$(dirname "$0")" && pwd)"
. "${DIR}/../_lib/forge.sh"

SERVER_URL="${GITHUB_SERVER_URL:-https://github.com}"
API_URL="${GITHUB_API_URL:-https://api.github.com}"

if [ "${FORGE}" = github ]; then
  FLAVOR=github
elif curl -fsS --max-time 5 "${SERVER_URL}/api/forgejo/v1/version" >/dev/null 2>&1; then
  FLAVOR=forgejo
else
  FLAVOR=gitea
fi

[ -z "${GITHUB_ENV:-}" ] || printf 'FORGE=%s\nFORGE_FLAVOR=%s\n' "${FORGE}" "${FLAVOR}" >>"${GITHUB_ENV}"

if [ "${FORGE}" != github ] && [ -n "${GITHUB_PATH:-}" ]; then
  BIN="${RUNNER_TEMP:-${TMPDIR:-/tmp}}/forge-bin"
  mkdir -p "${BIN}"
  printf '#!/bin/sh\n. "%s/../_lib/forge.sh"\ngh "$@"\n' "${DIR}" >"${BIN}/gh"
  chmod +x "${BIN}/gh"
  printf '%s\n' "${BIN}" >>"${GITHUB_PATH}"
fi

zz-log i "Forge: ${FLAVOR} (${SERVER_URL})" 2>/dev/null || echo "Forge: ${FLAVOR} (${SERVER_URL})" >&2

printf 'forge=%s\n' "${FLAVOR}"
printf 'server-url=%s\n' "${SERVER_URL}"
printf 'api-url=%s\n' "${API_URL}"
