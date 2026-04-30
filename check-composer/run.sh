#!/usr/bin/sh

set -e

if [ -n "${GITHUB_WORKSPACE:-}" ]; then
  cd "${GITHUB_WORKSPACE}" || exit 1
  git config --global --add safe.directory "${GITHUB_WORKSPACE}" || exit 1
fi

if [ -z "${REVIEWDOG_GITHUB_API_TOKEN:-}" ]; then
  export REVIEWDOG_GITHUB_API_TOKEN="${GITHUB_TOKEN}"
fi

{ composer validate --strict 2>/dev/null || true; } | \
  grep -v '^See https://' | \
  grep -v '^# ' | \
  jq -R -s -f "$(dirname "$0")/rdjson.jq" | \
  reviewdog \
    -f=rdjson \
    -name="composer-validate" \
    -reporter=${REVIEWDOG_REPORTER:-github-pr-check} \
    -filter-mode=nofilter \
    -fail-level=none
