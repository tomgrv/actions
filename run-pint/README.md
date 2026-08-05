<!-- @format -->

# GitHub Action: Validate PR Pint

Runs [Laravel Pint](https://laravel.com/docs/pint) and reports code style findings inline via reviewdog. Can also run in **fix mode** to apply fixes directly. PHP and Composer dependencies are set up automatically via [**setup-php**](../setup-php/README.md), and reviewdog via [**setup-reviewdog**](../setup-reviewdog/README.md); both are skipped if they already ran earlier in the job. `pint` itself must be available either in `vendor/bin` or the global `PATH`.

## Inputs

### github-token

**Required.** GitHub token for reviewdog reporting.

### paths

**Optional.** Comma-separated list of paths to analyze. Defaults to `app`.

### fix

**Optional.** Apply fixes directly instead of reporting via reviewdog. Defaults to `false`.

### preset

**Optional.** Pint preset to use (e.g. `laravel`, `default`, `symfony`). Defaults to `laravel`.

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

- [**setup-php**](../setup-php/README.md) — included automatically; add it explicitly only to pass custom `options`/`tools`, or once at the top of the job to share the setup across several PHP actions.
- [**setup-reviewdog**](../setup-reviewdog/README.md) — included automatically; add it explicitly only to pass a custom `version`.
- [**run-phpstan**](../run-phpstan/README.md) — complement Pint style checks with static analysis.
- [**create-pr**](../create-pr/README.md) — open a pull request with the auto-fixed files.

## Local Usage

Run this action locally using the root `npx @tomgrv/actions` dispatcher:

```sh
npx @tomgrv/actions run-pint
```

Required environment variables must be set before running. See [Inputs](#inputs) for details.

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

            - name: Run Pint
              uses: tomgrv/actions/run-pint@v1
              with:
                  github-token: ${{ secrets.GITHUB_TOKEN }}
                  paths: app,config,routes,tests
```

### Fix mode

```yaml
name: Pint Fix

on:
    workflow_dispatch:

jobs:
    fix:
        runs-on: ubuntu-latest
        steps:
            - uses: actions/checkout@v4

            - name: Run Pint in fix mode
              id: pint
              uses: tomgrv/actions/run-pint@v1
              with:
                  github-token: ${{ secrets.GITHUB_TOKEN }}
                  paths: app,config,routes
                  fix: 'true'

            - name: Create pull request with fixes
              if: ${{ steps.pint.outputs.has-changes == 'true' }}
              uses: tomgrv/actions/create-pr@v1
              with:
                  github-token: ${{ secrets.GITHUB_TOKEN }}
                  head-branch: chore/pint-fix
                  pr-title: 'chore: apply pint fixes'
```
