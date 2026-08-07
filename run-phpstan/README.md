<!-- @format -->

# GitHub Action: Validate PR PHPStan

Runs [PHPStan](https://phpstan.org/) and reports findings inline via reviewdog. Can also run in **fix mode** to generate or update a PHPStan baseline file. PHP and Composer dependencies are set up automatically via [**setup-php**](../setup-php/README.md), and reviewdog via [**setup-reviewdog**](../setup-reviewdog/README.md); both are skipped if they already ran earlier in the job. `phpstan` itself must be available either in `vendor/bin` or the global `PATH`.

## Inputs

### github-token

**Required.** GitHub token for reviewdog reporting.

### paths

**Optional.** Comma-separated list of paths to analyze. Defaults to `app`.

### fix

**Optional.** Generate a PHPStan baseline file instead of reporting via reviewdog. Defaults to `false`.

### baseline-file

**Optional.** Baseline file to generate when fix mode is enabled. Defaults to `phpstan-baseline.neon`.

### config

**Optional.** Path to a custom PHPStan configuration file. Leave empty to let PHPStan auto-detect `phpstan.neon`/`phpstan.neon.dist`/`phpstan.dist.neon` at the repository root, or fall back to its own defaults otherwise.

### name

**Optional.** Name reported by reviewdog to identify this check. Defaults to `phpstan`.

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

- `has-changes`: Whether fix mode produced changes to the baseline file.

## Works well with

- [**check-laravel**](../check-laravel/README.md) — wraps this action as part of the Laravel check suite.
- [**setup-php**](../setup-php/README.md) — included automatically; add it explicitly only to pass custom `options`/`tools`, or once at the top of the job to share the setup across several PHP actions.
- [**setup-reviewdog**](../setup-reviewdog/README.md) — included automatically; add it explicitly only to pass a custom `version`.
- [**create-pr**](../create-pr/README.md) — open a pull request with the generated baseline update.
- [**run-phpmd**](../run-phpmd/README.md) — complement PHPStan with mess detection.

## Local Usage

Run this action locally using the root `npx @tomgrv/actions` dispatcher:

```sh
npx @tomgrv/actions run-phpstan
```

Required environment variables must be set before running. See [Inputs](#inputs) for details.

## Example

```yaml
name: PR PHP Checks

on:
    pull_request:

jobs:
    phpstan:
        runs-on: ubuntu-latest
        steps:
            - uses: actions/checkout@v4

            - name: Run PHPStan
              uses: tomgrv/actions/run-phpstan@v1
              with:
                  github-token: ${{ secrets.GITHUB_TOKEN }}
                  paths: app,modules
```

### Baseline update mode

```yaml
name: PHPStan Baseline Update

on:
    workflow_dispatch:

jobs:
    update-baseline:
        runs-on: ubuntu-latest
        steps:
            - uses: actions/checkout@v4

            - name: Update PHPStan baseline
              id: phpstan
              uses: tomgrv/actions/run-phpstan@v1
              with:
                  github-token: ${{ secrets.GITHUB_TOKEN }}
                  paths: app,modules
                  fix: 'true'
                  baseline-file: phpstan-baseline.neon

            - name: Create pull request with updated baseline
              if: ${{ steps.phpstan.outputs.has-changes == 'true' }}
              uses: tomgrv/actions/create-pr@v1
              with:
                  github-token: ${{ secrets.GITHUB_TOKEN }}
                  head-branch: chore/phpstan-baseline
                  pr-title: 'chore: update phpstan baseline'
```
