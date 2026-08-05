<!-- @format -->

# GitHub Action: Setup PHP

Shared composite action that prepares PHP, extensions, optional PHP tools, and Composer for workflow jobs. Reads the required PHP version and extensions from `composer.json`, installs the matching PHP runtime, optionally installs global tools through `shivammathur/setup-php`, and runs `composer install`.

Every PHP-based action in this repository (`run-phpstan`, `run-pint`, `run-phpinsights`, `run-phpmd`, `run-filacheck`, `run-phptests`, `check-security-composer`) includes this action as its first step, so PHP is always ready without an explicit step in your workflow. The actual PHP/Composer install runs once per job: once it has run — whether triggered by an explicit `setup-php` step or by one of the actions above — later invocations in the same job detect the `TOMGRV_PHP_SETUP` environment marker and skip straight through. Add an explicit `setup-php` step yourself only when you need to pass custom `options` or `tools`.

## Inputs

### options

**Optional.** Additional options to pass to `composer install`, such as `--no-dev`. Defaults to none.

### tools

**Optional.** Comma-separated tools to install with `shivammathur/setup-php`, such as `reviewdog,phpstan,phpmd`. Defaults to none.

## Outputs

- `php-version`: Detected PHP version from `composer.json`, or the default (`8.3`).
- `php-extensions`: Detected PHP extensions from `composer.json`, or empty.

## Works well with

- [**check-lock**](../check-lock/README.md) — validate `composer.json`/`composer.lock`; run this action first if `composer` needs to be on `PATH`.
- [**check-security-composer**](../check-security-composer/README.md) — audit Composer dependencies; already included automatically.
- [**run-phpinsights**](../run-phpinsights/README.md) — run PHP Insights; already included automatically.
- [**run-filacheck**](../run-filacheck/README.md) — run FilaCheck; already included automatically.
- [**run-phpmd**](../run-phpmd/README.md) — run PHPMD; already included automatically.
- [**run-phpstan**](../run-phpstan/README.md) — run PHPStan; already included automatically.
- [**run-pint**](../run-pint/README.md) — run Pint; already included automatically.
- [**run-phptests**](../run-phptests/README.md) — run the test suite; already included automatically.
- [**list-packages**](../list-packages/README.md) — discover Composer packages after setup.

## Local Usage

Run this action locally using the root `npx @tomgrv/actions` dispatcher:

```sh
npx @tomgrv/actions setup-php
```

Required environment variables must be set before running. See [Inputs](#inputs) for details.

## Example

```yaml
name: PR PHP Checks

on:
    pull_request:

jobs:
    php-checks:
        runs-on: ubuntu-latest
        steps:
            - uses: actions/checkout@v4

            - name: Setup PHP toolchain
              uses: tomgrv/actions/setup-php@v1
              with:
                  tools: reviewdog,phpstan,phpmd,phpinsights,pint

            - name: Validate composer
              uses: tomgrv/actions/check-lock@v1
              with:
                  github-token: ${{ secrets.GITHUB_TOKEN }}

            - name: Audit Composer dependencies
              uses: tomgrv/actions/check-security-composer@v1
              with:
                  github-token: ${{ secrets.GITHUB_TOKEN }}

            - name: Run PHPStan
              uses: tomgrv/actions/run-phpstan@v1
              with:
                  github-token: ${{ secrets.GITHUB_TOKEN }}

            - name: Run tests
              uses: tomgrv/actions/run-phptests@v1
```
