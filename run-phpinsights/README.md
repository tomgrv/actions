<!-- @format -->

# GitHub Action: Validate PR PHP Insights

Runs [PHP Insights](https://phpinsights.com/) and reports findings inline via reviewdog. Can also run in **fix mode** to automatically apply fixes.

## Inputs

### github-token

**Required.** GitHub token for reviewdog reporting.

### paths

**Optional.** Comma-separated list of paths to analyze. Defaults to `app`.

### fix

**Optional.** Apply fixes directly instead of reporting via reviewdog. Defaults to `false`.

### level

**Optional.** Report level for reviewdog `[info,warning,error]`. Defaults to `error`.

### reporter

**Optional.** Reporter of reviewdog command `[github-pr-check,github-check,github-pr-review]`. Defaults to `github-pr-check`.

### filter-mode

**Optional.** Filtering mode for the reviewdog command `[added,diff_context,file,nofilter]`. Defaults to `added`.

### fail-level

**Optional.** Exit code for reviewdog if it finds at least the specified level `[none,any,info,warning,error]`. Defaults to `none`.

### reviewdog-flags

**Optional.** Additional reviewdog flags. Defaults to empty.

## Outputs

- `has-changes`: Whether fix mode produced local changes.

## Works well with

- [**setup-php**](../setup-php/README.md) — set up PHP and Composer before running PHP Insights.
- [**create-pr**](../create-pr/README.md) — open a pull request with the auto-fixed files.

## Local Usage

Run this action locally using the root `npx @tomgrv/actions` dispatcher:

```sh
npx @tomgrv/actions run-phpinsights
```

Required environment variables must be set before running. See [Inputs](#inputs) for details.

## Example

```yaml
name: PR PHP Checks

on:
    pull_request:

jobs:
    php-insights:
        runs-on: ubuntu-latest
        steps:
            - uses: actions/checkout@v4

            - name: Setup PHP toolchain
              uses: tomgrv/actions/setup-php@v1

            - name: Run PHP Insights
              uses: tomgrv/actions/run-phpinsights@v1
              with:
                  github-token: ${{ secrets.GITHUB_TOKEN }}
                  paths: app,config,routes
```

### Fix mode

```yaml
name: PHP Insights Fix

on:
    workflow_dispatch:

jobs:
    fix:
        runs-on: ubuntu-latest
        steps:
            - uses: actions/checkout@v4

            - name: Setup PHP toolchain
              uses: tomgrv/actions/setup-php@v1

            - name: Run PHP Insights in fix mode
              id: insights
              uses: tomgrv/actions/run-phpinsights@v1
              with:
                  github-token: ${{ secrets.GITHUB_TOKEN }}
                  paths: app,config,routes
                  fix: 'true'

            - name: Create pull request with fixes
              if: ${{ steps.insights.outputs.has-changes == 'true' }}
              uses: tomgrv/actions/create-pr@v1
              with:
                  github-token: ${{ secrets.GITHUB_TOKEN }}
                  head-branch: chore/phpinsights-fix
                  pr-title: 'chore: apply phpinsights fixes'
```
