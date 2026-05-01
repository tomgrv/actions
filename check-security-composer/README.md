<!-- @format -->

# GitHub Action: Validate PR Security Composer

Runs `composer audit` against the project's Composer dependencies and reports findings inline via reviewdog.

## Inputs

### github-token

**Required.** GitHub token for reviewdog reporting.

## Outputs

This action has no outputs.

## Works well with

- [**setup-php**](../setup-php/README.md) — set up PHP and Composer before running the audit.
- [**check-security-npm**](../check-security-npm/README.md) — also audit npm dependencies.

## Example

```yaml
name: PR Security Checks

on:
    pull_request:

jobs:
    audit-composer:
        runs-on: ubuntu-latest
        steps:
            - uses: actions/checkout@v4

            - name: Setup PHP toolchain
              uses: tomgrv/actions/setup-php@v1

            - name: Audit Composer dependencies
              uses: tomgrv/actions/check-security-composer@v1
              with:
                  github-token: ${{ secrets.GITHUB_TOKEN }}
```
