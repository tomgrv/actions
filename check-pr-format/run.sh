#!/usr/bin/sh

# Validate PR title format (commitlint + devmoji) and auto-fix it when possible.

# do not exit on error to allow for proper error reporting and annotation
# set -e

# Missing tooling/inputs are setup concerns, not PR title findings: plain
# log only, no GitHub annotation (see .github/instructions/action-creation.md).

# Export GitHub token for gh CLI
export GH_TOKEN="${GITHUB_TOKEN:-}"

# Ensure gh CLI is available for fetching PR title
if ! command -v gh >/dev/null 2>&1; then
  zz_log e "gh CLI could not be found. Please install it to run this action."
  exit 1
fi

# Ensure jq is available for parsing JSON
if ! command -v jq >/dev/null 2>&1; then
  zz_log e "jq could not be found. Please install it to run this action."
  exit 1
fi

# Validate required environment variables
if [ -z "${REPO:-}" ]; then
  zz_log e "REPO (github.repository) is required"
  exit 1
fi

# HEAD_REPO_FULL_NAME is set from github.event.pull_request.head.repo.full_name in action.yml;
# when running locally, it defaults to empty (treated as a fork PR).
HEAD_REPO_FULL_NAME="${HEAD_REPO_FULL_NAME:-}"
if [ -z "${HEAD_REPO_FULL_NAME}" ]; then
  zz_log i "HEAD_REPO_FULL_NAME not set, auto-update of PR title will be skipped"
fi

# Ensure commitlint is available for validating commit messages
commitlint_extends="$(jq -r '.commitlint.extends // [] | if type=="array" then join(" ") else . end' package.json 2>/dev/null || true)"
commitlint_extends_trimmed="$(printf '%s' "${commitlint_extends}" | tr -d '[:space:]')"
npm install -q -D devmoji ${commitlint_extends}

# Fetching the PR title from the API (fallback when not passed as input) is
# a setup detail, not a finding: plain log only. Trim whitespace to detect
# truly empty titles from YAML expansion of null/missing fields.
PR_TITLE_TRIMMED="$(printf '%s' "${PR_TITLE:-}" | tr -d ' \t')"
if [ -z "${PR_TITLE_TRIMMED}" ]; then
  zz_log i "PR_TITLE not set or empty, fetching from GitHub API"
  PR_TITLE="$(gh pr view --repo "${REPO}" --json title --jq .title)"
  # Validate that we got a title from the API
  if [ -z "${PR_TITLE}" ]; then
    zz_log e "PR title could not be fetched from GitHub API"
    exit 1
  fi
fi

# From here on, errors are the actual outcome of validating the PR title
# (the analyzed content), so they are kept as GitHub annotations.

# Attempt to autocorrect the title with devmoji first, then validate the
# result with commitlint. Errors are only raised when autocorrection isn't
# enough (still invalid) or can't be applied (fork PR or missing token).
formatted_title="$(npx devmoji --text "${PR_TITLE}")"

commitlint_output=$(echo "${formatted_title}" | npx commitlint 2>&1)
commitlint_status=$?
if [ ${commitlint_status} -ne 0 ]; then
  zz_log e "${commitlint_output}"
  exit 1
else
  zz_log i "${commitlint_output}"
fi

if [ "${PR_TITLE}" != "${formatted_title}" ]; then
  if [ "${FIX:-false}" = "true" ] && [ "${HEAD_REPO_FULL_NAME:-}" = "${REPO}" ] && [ -n "${GH_TOKEN:-}" ]; then
    gh pr edit "${PR_NUMBER}" --repo "${REPO}" --title "${formatted_title}"
    zz_log i "PR title updated: ${formatted_title}"
  else
    error_message="PR title is not formatted with devmoji and could not be auto-updated (fix disabled, fork PR, or missing token).

Current:  ${PR_TITLE}
Expected: ${formatted_title}"
    zz_log e "${error_message}"
    exit 1
  fi
fi
