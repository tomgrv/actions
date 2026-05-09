#!/usr/bin/sh

set -e

if [ -n "${GITHUB_WORKSPACE:-}" ]; then
    cd "${GITHUB_WORKSPACE}" || exit 1
    git config --global --add safe.directory "${GITHUB_WORKSPACE}" || exit 1
fi

PATH="${GITHUB_WORKSPACE:-.}/vendor/bin:$(composer config -g home)/vendor/bin:${PATH}"
REVIEWDOG_BIN="reviewdog"

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

for TEST_RUNNER in pest phpunit; do
    if command -v "${TEST_RUNNER}" > /dev/null 2>&1; then
        
        ${TEST_RUNNER} --coverage-clover coverage.xml 2> /dev/null 
        exit $?
    fi
done

echo "::error::Neither Pest nor PHPUnit was found. Please ensure one of them is installed and available in PATH." >&2
exit 1
