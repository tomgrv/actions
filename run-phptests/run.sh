#!/usr/bin/sh

set -e

if [ -n "${GITHUB_WORKSPACE:-}" ]; then
    cd "${GITHUB_WORKSPACE}" || exit 1
    git config --global --add safe.directory "${GITHUB_WORKSPACE}" || exit 1
fi

resolve_test_runner() {
    if [ -x './vendor/bin/pest' ]; then
        printf '%s' './vendor/bin/pest'
        return 0
    fi

    if command -v pest > /dev/null 2>&1; then
        command -v pest
        return 0
    fi

    if [ -x './vendor/bin/phpunit' ]; then
        printf '%s' './vendor/bin/phpunit'
        return 0
    fi

    if command -v phpunit > /dev/null 2>&1; then
        command -v phpunit
        return 0
    fi

    echo "::error::No test runner found in ./vendor/bin or PATH. Please install Pest or PHPUnit locally or make one available globally." >&2
    exit 1
}

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

TEST_RUNNER="$(resolve_test_runner)"
"${TEST_RUNNER}" --coverage-clover coverage.xml
