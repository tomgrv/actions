#!/usr/bin/sh

set -e

if [ -n "${GITHUB_WORKSPACE:-}" ]; then
  cd "${GITHUB_WORKSPACE}" || exit 1
  git config --global --add safe.directory "${GITHUB_WORKSPACE}" || exit 1
fi

if [ -z "${REVIEWDOG_GITHUB_API_TOKEN:-}" ]; then
  if [ -z "${GITHUB_TOKEN:-}" ]; then
    echo "::error::GITHUB_TOKEN or REVIEWDOG_GITHUB_API_TOKEN is required" >&2
    exit 1
  fi
  echo "::notice::REVIEWDOG_GITHUB_API_TOKEN not set, using GITHUB_TOKEN" >&2
  export REVIEWDOG_GITHUB_API_TOKEN="${GITHUB_TOKEN}"
fi

REVIEWDOG_REPORTER="${REVIEWDOG_REPORTER:-github-pr-check}"

{ composer validate --strict 2>/dev/null || true; } | \
  grep -v '^See https://' | \
  grep -v '^# ' | \
  jq -R -s -f "$(dirname "$0")/rdjson.jq" | \
  reviewdog \
    -f=rdjson \
    -name="composer-validate" \
    -reporter="${REVIEWDOG_REPORTER}" \
    -filter-mode=nofilter \
    -fail-level=none
