<!-- @format -->

# GitHub Action: Validate PR PHP Insights

Runs [PHP Insights](https://phpinsights.com/) and reports findings inline via reviewdog. Can also run in **fix mode** to automatically apply fixes and produce a list of changed files for downstream steps.

## Inputs

### github-token

**Required.** GitHub token for reviewdog reporting.

### paths

**Optional.** Comma-separated list of paths to analyze. Defaults to `app`.

### fix

**Optional.** Enable auto-fix mode instead of reviewdog reporting. Defaults to `false`.

### branch-prefix

**Optional.** Prefix for the generated branch name when fix mode is enabled. Defaults to `chore/phpinsights-fix`.

## Outputs

- `has-changes`: Whether fix mode produced local changes.
- `changed-files`: Comma-separated list of changed files when fix mode is enabled.

## Works well with

- [**setup-php**](../setup-php/README.md) — set up PHP and Composer before running PHP Insights.
- [**create-pr**](../create-pr/README.md) — open a pull request with the auto-fixed files.


## Local Usage

Each action script can be run directly as a shell utility or via `npx`:

```sh
npx -yes @tomgrv/action-run-phpinsights
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
                  commit-files: ${{ steps.insights.outputs.changed-files }}
                  pr-title: 'chore: apply phpinsights fixes'
```
