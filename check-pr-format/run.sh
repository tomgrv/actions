#!/usr/bin/sh

# Validate PR title format (commitlint + devmoji) and auto-fix it when possible.

# do not exit on error to allow for proper error reporting and annotation
# set -e

# Missing tooling/inputs are setup concerns, not PR title findings: plain
# log only, no GitHub annotation (see .github/instructions/action-creation.md).

# Ensure gh CLI is available for fetching PR title
if ! command -v gh >/dev/null 2>&1; then
  echo "Error: gh CLI could not be found. Please install it to run this action." >&2
  exit 1
fi

# Ensure jq is available for parsing JSON
if ! command -v jq >/dev/null 2>&1; then
  echo "Error: jq could not be found. Please install it to run this action." >&2
  exit 1
fi

# Validate required environment variables
if [ -z "${REPO:-}" ]; then
  echo "Error: REPO (github.repository) is required" >&2
  exit 1
fi

# HEAD_REPO_FULL_NAME is set from github.event.pull_request.head.repo.full_name in action.yml;
# when running locally, it defaults to empty (treated as a fork PR).
HEAD_REPO_FULL_NAME="${HEAD_REPO_FULL_NAME:-}"
if [ -z "${HEAD_REPO_FULL_NAME}" ]; then
  echo "HEAD_REPO_FULL_NAME not set, auto-update of PR title will be skipped" >&2
fi

# Ensure commitlint is available for validating commit messages
commitlint_extends="$(jq -r '.commitlint.extends // [] | if type=="array" then join(" ") else . end' package.json 2>/dev/null || true)"
commitlint_extends_trimmed="$(printf '%s' "${commitlint_extends}" | tr -d '[:space:]')"
if [ -n "${commitlint_extends_trimmed}" ]; then
  npm install -q -D ${commitlint_extends}
fi

# Fetching the PR title from the API (fallback when not passed as input) is
# a setup detail, not a finding: plain log only.
if [ -z "${PR_TITLE:-}" ]; then
  echo "PR_TITLE not set, fetching from GitHub API" >&2
  PR_TITLE="$(gh pr view --repo "${REPO}" --json title --jq .title)"
fi

# From here on, errors are the actual outcome of validating the PR title
# (the analyzed content), so they are kept as GitHub annotations.

# Attempt to autocorrect the title with devmoji first, then validate the
# result with commitlint. Errors are only raised when autocorrection isn't
# enough (still invalid) or can't be applied (fork PR or missing token).
formatted_title="$(npx --yes devmoji --text "${PR_TITLE}")"

commitlint_output=$(echo "${formatted_title}" | npx commitlint 2>&1)
commitlint_status=$?
if [ ${commitlint_status} -ne 0 ]; then
  # Escape newlines for GitHub annotation
  escaped_output=$(printf '%s\n' "${commitlint_output}" | sed 's/%/%25/g;s/$/\\n/g' | tr -d '\n' | sed 's/\\n/%0A/g;s/%25/%/g')
  echo "::error::${escaped_output}" >&2
  exit 1
else
  # Show commitlint output as notice on success
  escaped_output=$(printf '%s\n' "${commitlint_output}" | sed 's/%/%25/g;s/$/\\n/g' | tr -d '\n' | sed 's/\\n/%0A/g;s/%25/%/g')
  echo "::notice::${escaped_output}" >&2
fi

if [ "${PR_TITLE}" != "${formatted_title}" ]; then
  if [ "${FIX:-false}" = "true" ] && [ "${HEAD_REPO_FULL_NAME:-}" = "${REPO}" ] && [ -n "${GH_TOKEN:-}" ]; then
    gh pr edit "${PR_NUMBER}" --repo "${REPO}" --title "${formatted_title}"
    echo "PR title updated: ${formatted_title}" >&2
  else
    error_message="PR title is not formatted with devmoji and could not be auto-updated (fix disabled, fork PR, or missing token).

Current:  ${PR_TITLE}
Expected: ${formatted_title}"
    # Escape newlines for GitHub annotation
    escaped_error=$(printf '%s\n' "${error_message}" | sed 's/%/%25/g;s/$/\\n/g' | tr -d '\n' | sed 's/\\n/%0A/g;s/%25/%/g')
    echo "::error::${escaped_error}" >&2
    exit 1
  fi
fi
