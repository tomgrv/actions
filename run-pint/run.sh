#!/usr/bin/sh

set -e

if [ -n "${GITHUB_WORKSPACE:-}" ]; then
  cd "${GITHUB_WORKSPACE}" || exit 1
  git config --global --add safe.directory "${GITHUB_WORKSPACE}" || exit 1
fi

if [ -z "${REVIEWDOG_GITHUB_API_TOKEN:-}" ]; then
  export REVIEWDOG_GITHUB_API_TOKEN="${GITHUB_TOKEN}"
fi

TARGET_PATHS="${1:-app}"

echo "Running Pint analysis on: ${TARGET_PATHS}" >&2

if [ "${FIX:-false}" = "true" ]; then
  CHANGED=$({ vendor/bin/pint --no-interaction -- $(echo "${TARGET_PATHS}" | tr ',' ' ') 2>/dev/null || true; } | \
    tee /dev/stderr | \
    awk -F'  *\\.+ ' '/FIXED/{print $1}' | sed 's/^ *//' | paste -sd "," -)

  if [ -n "$CHANGED" ]; then
    printf 'has-changes=true\n'
    printf 'changed-files=%s\n' "$CHANGED"
  else
    printf 'has-changes=false\n'
  fi
else
  { vendor/bin/pint --test --no-interaction --format=checkstyle -- $(echo "${TARGET_PATHS}" | tr ',' ' ') 2>/dev/null || true; } | \
    reviewdog \
      -f=checkstyle \
      -name="pint" \
      -reporter=${REVIEWDOG_REPORTER:-github-pr-review} \
      -fail-level=none

  printf 'has-changes=false\n'
fi
