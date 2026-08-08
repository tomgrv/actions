#!/usr/bin/sh

set -e

if [ -n "${GITHUB_WORKSPACE:-}" ]; then
  cd "${GITHUB_WORKSPACE}" || exit 1
  git config --global --add safe.directory "${GITHUB_WORKSPACE}" || exit 1
fi

if [ -z "${REVIEWDOG_GITHUB_API_TOKEN:-}" ]; then
  export REVIEWDOG_GITHUB_API_TOKEN="${GITHUB_TOKEN}"
fi

FIX="${FIX:-false}"
TARGET_PATHS="${1:-app}"

echo "Running PHP Insights analysis on: ${TARGET_PATHS}" >&2

if [ "${FIX:-false}" = "true" ]; then
  CHANGED=$({ vendor/bin/phpinsights analyse --no-interaction --fix --summary --format=github-action -- $(echo "${TARGET_PATHS}" | tr ',' ' ') || true; } | \
    awk -F'file=|,line=' '{print $2}' | sort | uniq | paste -sd "," - | sed 's/^,//' )

  if [ -n "$CHANGED" ]; then
    printf 'has-changes=true\n'
    printf 'changed-files=%s\n' "$CHANGED"
  else
    printf 'has-changes=false\n'
  fi
else
  { vendor/bin/phpinsights analyse --no-interaction --format=checkstyle -- $(echo "${TARGET_PATHS}" | tr ',' ' ') || true; } | \
    reviewdog \
      -f=checkstyle \
      -name="phpinsights" \
      -reporter=${REVIEWDOG_REPORTER:-github-pr-review} \
      -filter-mode=diff_context

  printf 'has-changes=false\n'
fi
