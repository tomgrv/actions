#!/usr/bin/sh

set -eu

BOT_NAME="${BOT_NAME:-github-actions[bot]}"
BOT_EMAIL="${BOT_EMAIL:-341898282+github-actions[bot]@users.noreply.github.com}"

if [ "${BOT_NAME}" = "github-actions[bot]" ]; then
  echo "::notice::BOT_NAME not set, using default: github-actions[bot]" >&2
fi
if [ "${BOT_EMAIL}" = "341898282+github-actions[bot]@users.noreply.github.com" ]; then
  echo "::notice::BOT_EMAIL not set, using default: 341898282+github-actions[bot]@users.noreply.github.com" >&2
fi

echo "Setting git user name and email for bot as ${BOT_NAME} <${BOT_EMAIL}>" >&2

git config --global user.email "${BOT_EMAIL}"
git config --global user.name "${BOT_NAME}"

printf 'git_user_name=%s\n' "${BOT_NAME}"
printf 'git_user_email=%s\n' "${BOT_EMAIL}"
