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

echo "Running PHPStan analysis on: ${TARGET_PATHS}" >&2

if [ "${FIX:-false}" = "true" ]; then
  CHANGED=$({ vendor/bin/phpstan analyse  --error-format=github --memory-limit=512M --no-progress -- $(echo "${TARGET_PATHS}" | tr ',' ' ') >&2 || true } \
  tee /dev/stderr | \
    awk -F'file=|,line=' '{print $2}' | sort | uniq | paste -sd "," - | sed 's/^,//' )

  if [ -n "$CHANGED" ]; then
    printf 'has-changes=true\n'
    printf 'changed-files=%s\n' "$CHANGED"
  else
    printf 'has-changes=false\n'
  fi

else

  { vendor/bin/phpstan analyse --error-format=checkstyle --memory-limit=512M --no-progress -- $(echo "${TARGET_PATHS}" | tr ',' ' ') 2>/dev/null || true; } | \
    reviewdog \
      -f=checkstyle \
      -name="phpstan" \
      -reporter=${REVIEWDOG_REPORTER:-github-pr-review} \
      -filter-mode=diff_context \

  printf 'has-changes=false\n'
fi
