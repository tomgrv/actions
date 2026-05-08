#!/usr/bin/sh

set -eu

if [ -z "${GITHUB_TOKEN:-}" ]; then
  echo "::error::GITHUB_TOKEN is required" >&2
  exit 1
fi

BOT_NAME="${BOT_NAME:-github-actions[bot]}"
BOT_EMAIL="${BOT_EMAIL:-341898282+github-actions[bot]@users.noreply.github.com}"

if [ "${BOT_NAME}" = "github-actions[bot]" ]; then
  echo "::notice::BOT_NAME not set, using default: github-actions[bot]" >&2
fi
if [ "${BOT_EMAIL}" = "341898282+github-actions[bot]@users.noreply.github.com" ]; then
  echo "::notice::BOT_EMAIL not set, using default: 341898282+github-actions[bot]@users.noreply.github.com" >&2
fi

BASIC_CREDENTIAL=$(printf 'x-access-token:%s' "${GITHUB_TOKEN}" | base64 | tr -d '\n')
AUTH_HEADER="AUTHORIZATION: basic ${BASIC_CREDENTIAL}"

# saving existing $RUNNER_TEMP/git-credentials-*.config to $RUNNER_TEMP/git-credentials-*.config.bak
echo "Authenticating git with bot credentials" >&2

git config --global --unset-all http.https://github.com/.extraheader || true
git config --global "http.https://github.com/.extraheader" "${AUTH_HEADER}" || true

echo "Setting git user name and email for bot as ${BOT_NAME} <${BOT_EMAIL}>" >&2

git config --global user.email "${BOT_EMAIL}"
git config --global user.name "${BOT_NAME}"

printf 'git_user_name=%s\n' "${BOT_NAME}"
printf 'git_user_email=%s\n' "${BOT_EMAIL}"
