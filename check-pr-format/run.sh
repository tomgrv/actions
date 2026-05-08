#!/usr/bin/sh

set -e

# Ensure gh CLI is available for fetching PR title
if ! command -v gh >/dev/null 2>&1; then
  echo "::error::gh CLI could not be found. Please install it to run this action." >&2
  exit 1
fi

# Ensure jq is available for parsing JSON
if ! command -v jq >/dev/null 2>&1; then
  echo "::error::jq could not be found. Please install it to run this action." >&2
  exit 1
fi

# Validate required environment variables
if [ -z "${REPO:-}" ]; then
  echo "::error::REPO (github.repository) is required" >&2
  exit 1
fi

# HEAD_REPO_FULL_NAME is set from github.event.pull_request.head.repo.full_name in action.yml;
# when running locally, it defaults to empty (treated as a fork PR).
HEAD_REPO_FULL_NAME="${HEAD_REPO_FULL_NAME:-}"
if [ -z "${HEAD_REPO_FULL_NAME}" ]; then
  echo "::notice::HEAD_REPO_FULL_NAME not set, auto-update of PR title will be skipped" >&2
fi

# Ensure commitlint is available for validating commit messages
commitlint_extends="$(jq -r '.commitlint.extends // [] | if type=="array" then join(" ") else . end' package.json 2>/dev/null || true)"
commitlint_extends_trimmed="$(printf '%s' "${commitlint_extends}" | tr -d '[:space:]')"
if [ -n "${commitlint_extends_trimmed}" ]; then
  npm install -D ${commitlint_extends}
fi

# Set up environment variables for reviewdog
if [ -z "${PR_TITLE:-}" ]; then
  echo "::notice::PR_TITLE not set, fetching from GitHub API" >&2
  PR_TITLE="$(gh pr view --repo "${REPO}" --json title --jq .title)"
fi

# Validate PR title with commitlint
if ! echo "${PR_TITLE}" | npx commitlint; then
  echo "::error::PR title does not meet commitlint rules." >&2
  echo "::error::Current: ${PR_TITLE}" >&2
  exit 1
fi
  
# Format PR title with devmoji and update if necessary
formatted_title="$(npx --yes devmoji --text "${PR_TITLE}")"
if [ "${PR_TITLE}" != "${formatted_title}" ]; then
  echo "::error::PR title is not formatted with devmoji." >&2
  echo "::error::Current:  ${PR_TITLE}" >&2
  echo "::error::Expected: ${formatted_title}" >&2

  if [ "${HEAD_REPO_FULL_NAME:-}" = "${REPO}" ] && [ -n "${GH_TOKEN:-}" ]; then
    gh pr edit "${PR_NUMBER}" --repo "${REPO}" --title "${formatted_title}"
    echo "PR title updated." >&2
  else
    echo "::error::PR title could not be auto-updated (fork PR or missing token)." >&2
    exit 1
  fi
fi
