#!/usr/bin/sh

# Configure the git bot identity (user.name/user.email) used by later steps
# in the job to author commits.

set -eu

export GH_TOKEN="${GITHUB_TOKEN:-}"

GITHUB_APP_SLUG="${GITHUB_APP_SLUG:-github-actions}"

# Input defaulting is a setup detail, not a finding: plain log only, no
# GitHub annotation.
if [ "${GITHUB_APP_SLUG}" = "github-actions" ] && [ -z "${BOT_NAME:-}" ]; then
  zz_log i "GITHUB_APP_SLUG not set, using default: github-actions"
fi

# BOT_NAME/BOT_EMAIL can be overridden directly (used by run.bats to test
# git-config behavior without a real gh binary/API call); otherwise both are
# derived from GITHUB_APP_SLUG.
BOT_NAME="${BOT_NAME:-${GITHUB_APP_SLUG}[bot]}"

if [ -z "${BOT_EMAIL:-}" ]; then
  # A failed/unavailable lookup is not fatal: BOT_EMAIL falls back to the
  # well-known github-actions[bot] user ID below.
  USER_ID="$(gh api "/users/${BOT_NAME}" --jq .id 2>/dev/null || true)"
  BOT_EMAIL="${USER_ID:-341898282}+${BOT_NAME}@users.noreply.github.com"
fi
USER_ID="${USER_ID:-}"

zz_log i "Setting git user name and email for bot as ${BOT_NAME} <${BOT_EMAIL}>"

git config --global user.email "${BOT_EMAIL}"
git config --global user.name "${BOT_NAME}"

printf 'user_id=%s\n' "${USER_ID}"
printf 'git_user_name=%s\n' "${BOT_NAME}"
printf 'git_user_email=%s\n' "${BOT_EMAIL}"
