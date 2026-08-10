<!-- @format -->

# GitHub Action: Validate PR FilaCheck

Runs [FilaCheck](https://github.com/LaravelDaily/FilaCheck) and reports Filament code issues inline via reviewdog. PHP and Composer dependencies are set up automatically via [**setup-php**](../setup-php/README.md), and reviewdog via [**setup-reviewdog**](../setup-reviewdog/README.md); both are skipped if they already ran earlier in the job. `filacheck` itself is installed globally via `setup-php`'s `require` input (`laraveldaily/filacheck`), unless already required locally in `composer.json` (and thus in `vendor/`) or already installed globally.

## Inputs

### github-token

**Optional.** GitHub token for reviewdog reporting. Defaults to `github.token`.

### path

**Optional.** Path to analyze. Defaults to `app/Filament`.

### detailed

**Optional.** Show detailed output with rule categories. Defaults to `false`.

### dirty

**Optional.** Only scan files with uncommitted git changes. Defaults to `false`.

### wip

**Optional.** Only scan files changed on the current pull request, relative to its base branch. FilaCheck has no native flag for this (unlike `dirty`), so it is emulated: [**list-wip**](../list-wip/README.md) resolves the changed files and this action passes that explicit list in place of `path`. Defaults to `false`.

### wip-base-ref

**Optional.** Base branch/ref to diff against when `wip` is enabled. Defaults to `GITHUB_BASE_REF`, which GitHub Actions sets automatically on `pull_request` events.

### name

**Optional.** Name reported by reviewdog to identify this check. Defaults to `filacheck`.

### level

**Optional.** Report level for reviewdog `[info,warning,error]`. Defaults to `error`.

### reporter

**Optional.** Reporter of reviewdog command `[github-pr-check,github-check,github-pr-review]`. Defaults to the reporter resolved by [**setup-reviewdog**](../setup-reviewdog/README.md) for this run's context (`github-pr-check` on pull requests, `github-check` otherwise).

### filter-mode

Fixed to `file`: this action operates on files, not the whole repository, so reviewdog only needs to know which files are in scope. Not configurable.

### fail-level

**Optional.** Exit code for reviewdog if it finds at least the specified level `[none,any,info,warning,error]`. Defaults to `none`.

### reviewdog-flags

**Optional.** Additional reviewdog flags. Defaults to empty.

## Outputs

This action has no outputs.

## Works well with

- [**check-filament**](../check-filament/README.md) — wraps this action as the Filament check suite entry point.
- [**setup-php**](../setup-php/README.md) — included automatically; add it explicitly only to pass custom `options`/`tools`, or once at the top of the job to share the setup across several PHP actions.
- [**setup-reviewdog**](../setup-reviewdog/README.md) — included automatically; add it explicitly only to pass a custom `version`.
- [**run-pint**](../run-pint/README.md) — complement Filament checks with Laravel Pint.
- [**list-wip**](../list-wip/README.md) — included automatically behind `wip`.

## Local Usage

Run this action locally using the root `./dispatch.sh` dispatcher:

```sh
./dispatch.sh run-filacheck
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

