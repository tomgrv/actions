#!/usr/bin/sh

set -e

if [ -n "${GITHUB_WORKSPACE:-}" ]; then
  cd "${GITHUB_WORKSPACE}" || exit 1
  git config --global --add safe.directory "${GITHUB_WORKSPACE}" || exit 1
fi

if [ -z "${REVIEWDOG_GITHUB_API_TOKEN:-}" ]; then
  if [ -n "${GITHUB_TOKEN:-}" ]; then
    export REVIEWDOG_GITHUB_API_TOKEN="${GITHUB_TOKEN}"
  fi
fi

cp .env.example .env || cp .env.testing .env || touch .env

if [ -f "artisan" ]; then
  php artisan key:generate --ansi
  php artisan config:clear
  php artisan config:cache
  php artisan migrate --force
fi

if [ -f "./vendor/bin/pest" ]; then
  ./vendor/bin/pest --coverage-clover coverage.xml
elif [ -f "./vendor/bin/phpunit" ]; then
  ./vendor/bin/phpunit --coverage-clover coverage.xml
else
  echo "::error::No test runner found" >&2
  exit 1
fi
