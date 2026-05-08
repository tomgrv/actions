<!-- @format -->

# GitHub Action: Validate PR Security Composer

Runs `composer audit` against the project's Composer dependencies and reports findings inline via reviewdog.

## Inputs

### github-token

**Required.** GitHub token for reviewdog reporting.

### level

**Optional.** Report level for reviewdog `[info,warning,error]`. Defaults to `error`.

### reporter

**Optional.** Reporter of reviewdog command `[github-pr-check,github-check,github-pr-review]`. Defaults to `github-pr-check`.

### filter-mode

**Optional.** Filtering mode for the reviewdog command `[added,diff_context,file,nofilter]`. Defaults to `nofilter`.

### fail-level

**Optional.** Exit code for reviewdog if it finds at least the specified level `[none,any,info,warning,error]`. Defaults to `none`.

### reviewdog-flags

**Optional.** Additional reviewdog flags. Defaults to empty.

## Outputs

This action has no outputs.

## Works well with

- [**setup-php**](../setup-php/README.md) — set up PHP and Composer before running the audit.
- [**check-security-npm**](../check-security-npm/README.md) — also audit npm dependencies.

## Local Usage

Run this action locally using the root `npx @tomgrv/actions` dispatcher:

```sh
npx @tomgrv/actions check-security-composer
```

Required environment variables must be set before running. See [Inputs](#inputs) for details.

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
