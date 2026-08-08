<!-- @format -->

# GitHub Action: Validate PR Pint

Runs [Laravel Pint](https://laravel.com/docs/pint) and reports code style findings inline via reviewdog. Can also run in **fix mode** to apply fixes directly. PHP and Composer dependencies are set up automatically via [**setup-php**](../setup-php/README.md), and reviewdog via [**setup-reviewdog**](../setup-reviewdog/README.md); both are skipped if they already ran earlier in the job. `pint` itself is installed globally via `setup-php`'s `require` input (`laravel/pint`), unless already required locally in `composer.json` (and thus in `vendor/`) or already installed globally.

## Inputs

### github-token

**Optional.** GitHub token for reviewdog reporting. Defaults to `github.token`.

### paths

**Optional.** Comma-separated list of paths to analyze. Defaults to `app`.

### fix

**Optional.** Apply fixes directly instead of reporting via reviewdog. Defaults to `false`.

### preset

**Optional.** Pint preset to use (e.g. `laravel`, `default`, `symfony`). Defaults to `laravel`. Ignored when `config` is set.

### config

**Optional.** Path to a custom Pint configuration file. Leave empty to let Pint auto-detect `pint.json` at the repository root, or fall back to `preset` otherwise.

### dirty

**Optional.** Only analyze files with uncommitted git changes (staged, unstaged, or untracked). Pint has no native flag for this, so it is emulated by resolving the changed files and passing that explicit list in place of `paths`. Defaults to `false`.

### wip

**Optional.** Only analyze files changed on the current pull request, relative to its base branch. Emulated the same way as `dirty`, diffing against the merge-base of `wip-base-ref`. Defaults to `false`.

### wip-base-ref

**Optional.** Base branch/ref to diff against when `wip` is enabled. Defaults to `GITHUB_BASE_REF`, which GitHub Actions sets automatically on `pull_request` events.

### name

**Optional.** Name reported by reviewdog to identify this check. Defaults to `pint`.

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
