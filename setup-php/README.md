<!-- @format -->

# GitHub Action: Setup PHP

Shared composite action that prepares PHP, extensions, optional PHP tools, and Composer for workflow jobs. Reads the required PHP version and extensions from `composer.json`, installs the matching PHP runtime, optionally installs global tools through `shivammathur/setup-php`, and runs `composer install`.

## Inputs

### options

**Optional.** Additional options to pass to `composer install`, such as `--no-dev`. Defaults to none.

### tools

**Optional.** Comma-separated tools to install with `shivammathur/setup-php`, such as `reviewdog,phpstan,phpmd`. Defaults to none.

## Outputs

- `php-version`: Detected PHP version from `composer.json`, or the default (`8.3`).
- `php-extensions`: Detected PHP extensions from `composer.json`, or empty.

## Works well with

- [**check-lock**](../check-lock/README.md) — validate `composer.json`/`composer.lock` after setup.
- [**check-security-composer**](../check-security-composer/README.md) — audit Composer dependencies after setup.
- [**run-phpinsights**](../run-phpinsights/README.md) — run PHP Insights after setup.
- [**run-filacheck**](../run-filacheck/README.md) — run FilaCheck after setup.
- [**run-phpmd**](../run-phpmd/README.md) — run PHPMD after setup.
- [**run-phpstan**](../run-phpstan/README.md) — run PHPStan after setup.
- [**run-pint**](../run-pint/README.md) — run Pint after setup.
- [**run-phptests**](../run-phptests/README.md) — run the test suite after setup.
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
