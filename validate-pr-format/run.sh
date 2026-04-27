#!/usr/bin/sh

set -e

# Ensure gh CLI is available for fetching PR title
if ! command -v gh >/dev/null 2>&1; then
  echo "gh CLI could not be found. Please install it to run this action."
  exit 1
fi

# Ensure jq is available for parsing JSON
if [ -f package-lock.json ]; then
  npm ci
else
  npm install
fi

# Ensure commitlint is available for validating commit messages
commitlint_extends="$(jq -r '.commitlint.extends // [] | if type=="array" then join(" ") else . end' package.json 2>/dev/null || true)"
commitlint_extends_trimmed="$(printf '%s' "${commitlint_extends}" | tr -d '[:space:]')"
if [ -n "${commitlint_extends_trimmed}" ]; then
  npm install -D ${commitlint_extends}
fi

# Set up environment variables for reviewdog
if [ -z "${PR_TITLE:-}" ]; then
  PR_TITLE="$(gh pr view --repo "${REPO}" --json title --jq .title)"
fi

# Validate PR title with commitlint
if ! echo "${PR_TITLE}" | npx commitlint; then
  echo "PR title does not meet commitlint rules."
  echo "Current: ${PR_TITLE}"
  exit 1
fi
  
# Format PR title with devmoji and update if necessary
formatted_title="$(npx --yes devmoji --text "${PR_TITLE}")"
if [ "${PR_TITLE}" != "${formatted_title}" ]; then
  echo "PR title is not formatted with devmoji."
  echo "Current:  ${PR_TITLE}"
  echo "Expected: ${formatted_title}"

  if [ "${HEAD_REPO_FULL_NAME}" = "${REPO}" ] && [ -n "${GH_TOKEN:-}" ]; then
    gh pr edit "${PR_NUMBER}" --repo "${REPO}" --title "${formatted_title}"
    echo "PR title updated."
  else
    echo "PR title could not be auto-updated (fork PR or missing token)."
    exit 1
  fi
fi
