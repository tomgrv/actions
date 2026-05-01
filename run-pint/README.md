<!-- @format -->

# GitHub Action: Validate PR Pint

Runs [Laravel Pint](https://laravel.com/docs/pint) in test mode and reports code style findings inline via reviewdog.

## Inputs

### github-token

**Required.** GitHub token for reviewdog reporting.

### paths

**Optional.** Comma-separated list of paths to analyze. Defaults to `app`.

## Outputs

This action has no outputs.

## Works well with

- [**setup-php**](../setup-php/README.md) — set up PHP and Composer before running Pint.
- [**run-phpstan**](../run-phpstan/README.md) — complement Pint style checks with static analysis.
- [**run-phptests**](../run-phptests/README.md) — run the full test suite alongside style checks.

## Example

```yaml
name: PR PHP Checks

on:
    pull_request:

jobs:
    pint:
        runs-on: ubuntu-latest
        steps:
            - uses: actions/checkout@v4

            - name: Setup PHP toolchain
              uses: tomgrv/actions/setup-php@v1

            - name: Run Pint
              uses: tomgrv/actions/run-pint@v1
              with:
                  github-token: ${{ secrets.GITHUB_TOKEN }}
                  paths: app,config,routes,tests
```
