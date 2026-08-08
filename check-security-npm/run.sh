#!/usr/bin/sh

set -e

if [ -n "${GITHUB_WORKSPACE:-}" ]; then
  cd "${GITHUB_WORKSPACE}" || exit 1
  git config --global --add safe.directory "${GITHUB_WORKSPACE}" || exit 1
fi

if [ -z "${REVIEWDOG_GITHUB_API_TOKEN:-}" ]; then
  export REVIEWDOG_GITHUB_API_TOKEN="${GITHUB_TOKEN}"
fi

if ! command -v reviewdog >/dev/null 2>&1; then
  echo "::error::reviewdog could not be found. Please install it to run this action." >&2
  exit 1
fi

if ! command -v npm >/dev/null 2>&1; then
  echo "::error::npm could not be found. Please install it to run this action." >&2
  exit 1
fi

npm audit --workspaces --audit-level moderate --package-lock-only --json 2>/dev/null \
  | jq -f "$(dirname "$0")/rdjson.jq" \
  | reviewdog -f=rdjson -name=npm-audit -reporter=github-check -filter-mode=nofilter -fail-level=none
