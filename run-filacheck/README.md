<!-- @format -->

# GitHub Action: Validate PR FilaCheck

Runs [FilaCheck](https://github.com/LaravelDaily/FilaCheck) and reports Filament code issues inline via reviewdog. Can also run in **fix mode** to apply fixes directly. PHP and Composer dependencies are set up automatically via [**setup-php**](../setup-php/README.md), and reviewdog via [**setup-reviewdog**](../setup-reviewdog/README.md); both are skipped if they already ran earlier in the job. `filacheck` itself is installed globally via `setup-php`'s `require` input (`laraveldaily/filacheck`), unless already required locally in `composer.json` (and thus in `vendor/`) or already installed globally.

## Inputs

### github-token

**Optional.** GitHub token for reviewdog reporting. Defaults to `github.token`.

### path

**Optional.** Path to analyze. Defaults to `app/Filament`.

### fix

**Optional.** Apply fixes directly instead of reporting via reviewdog. Defaults to `false`.

### detailed

**Optional.** Show detailed output with rule categories. Defaults to `false`.

### dirty

**Optional.** Only scan files with uncommitted git changes. Defaults to `false`.

### wip

**Optional.** Only scan files changed on the current pull request, relative to its base branch. FilaCheck has no native flag for this (unlike `dirty`), so it is emulated by resolving the changed files and passing that explicit list in place of `path`. Defaults to `false`.

### wip-base-ref

**Optional.** Base branch/ref to diff against when `wip` is enabled. Defaults to `GITHUB_BASE_REF`, which GitHub Actions sets automatically on `pull_request` events.

### dry-run

**Optional.** Preview fix changes without modifying files. Defaults to `false`.

### backup

**Optional.** Create backup files when fixing. Defaults to `false`.

### name

**Optional.** Name reported by reviewdog to identify this check. Defaults to `filacheck`.

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

- [**check-filament**](../check-filament/README.md) — wraps this action as the Filament check suite entry point.
- [**setup-php**](../setup-php/README.md) — included automatically; add it explicitly only to pass custom `options`/`tools`, or once at the top of the job to share the setup across several PHP actions.
- [**setup-reviewdog**](../setup-reviewdog/README.md) — included automatically; add it explicitly only to pass a custom `version`.
- [**create-pr**](../create-pr/README.md) — open a pull request with the auto-fixed files.
- [**run-pint**](../run-pint/README.md) — complement Filament checks with Laravel Pint.

## Local Usage

Run this action locally using the root `npx @tomgrv/actions` dispatcher:

```sh
npx @tomgrv/actions run-filacheck
```

Required environment variables must be set before running. See [Inputs](#inputs) for details.

## Example

```yaml
name: PR Filament Checks

on:
    pull_request:

jobs:
    filacheck:
        runs-on: ubuntu-latest
        steps:
            - uses: actions/checkout@v4

            - name: Run FilaCheck
              uses: tomgrv/actions/run-filacheck@v1
              with:
                  github-token: ${{ secrets.GITHUB_TOKEN }}
                  path: app/Filament
```

### Fix mode

```yaml
name: FilaCheck Fix

on:
    workflow_dispatch:

jobs:
    fix:
        runs-on: ubuntu-latest
        steps:
            - uses: actions/checkout@v4

            - name: Run FilaCheck in fix mode
              id: filacheck
              uses: tomgrv/actions/run-filacheck@v1
              with:
                  github-token: ${{ secrets.GITHUB_TOKEN }}
                  path: app/Filament
                  fix: 'true'

            - name: Create pull request with fixes
              if: ${{ steps.filacheck.outputs.has-changes == 'true' }}
              uses: tomgrv/actions/create-pr@v1
              with:
                  github-token: ${{ secrets.GITHUB_TOKEN }}
                  head-branch: chore/filacheck-fix
                  pr-title: 'chore: apply filacheck fixes'
```
