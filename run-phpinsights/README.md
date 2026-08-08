<!-- @format -->

# GitHub Action: Validate PR PHP Insights

Runs [PHP Insights](https://phpinsights.com/) and reports findings inline via reviewdog. Can also run in **fix mode** to automatically apply fixes. PHP and Composer dependencies are set up automatically via [**setup-php**](../setup-php/README.md), and reviewdog via [**setup-reviewdog**](../setup-reviewdog/README.md); both are skipped if they already ran earlier in the job. `phpinsights` itself is installed globally via `setup-php`'s `require` input (`nunomaduro/phpinsights`), unless already required locally in `composer.json` (and thus in `vendor/`) or already installed globally.

## Inputs

### github-token

**Required.** GitHub token for reviewdog reporting.

### paths

**Optional.** Comma-separated list of paths to analyze. Defaults to `app`.

### fix

**Optional.** Apply fixes directly instead of reporting via reviewdog. Defaults to `false`.

### config-path

**Optional.** Path to a custom PHP Insights configuration file. Leave empty to let PHP Insights auto-detect `phpinsights.json` (or `config/insights.php` in Laravel apps) at the repository root, or fall back to its own defaults otherwise.

### name

**Optional.** Name reported by reviewdog to identify this check. Defaults to `phpinsights`.

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

- [**check-laravel**](../check-laravel/README.md) — wraps this action as part of the Laravel check suite.
- [**setup-php**](../setup-php/README.md) — included automatically; add it explicitly only to pass custom `options`/`tools`, or once at the top of the job to share the setup across several PHP actions.
- [**setup-reviewdog**](../setup-reviewdog/README.md) — included automatically; add it explicitly only to pass a custom `version`.
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
