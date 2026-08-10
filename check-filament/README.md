<!-- @format -->

# GitHub Action: Validate PR Filament

Runs the Filament-specific check suite — currently [FilaCheck](https://github.com/LaravelDaily/FilaCheck) — and reports findings inline via reviewdog. This is a thin wrapper around [**run-filacheck**](../run-filacheck/README.md), kept as its own action so Filament checks can grow independently of the general Laravel suite in [**check-laravel**](../check-laravel/README.md).

Every input is forwarded as-is to the wrapped `run-filacheck` call, including `github-token` and the reviewdog options (`level`, `reporter`, `fail-level`, `reviewdog-flags`), so the reviewdog context you configure on `check-filament` is exactly what the underlying check uses — never a separately-defaulted one. `filter-mode` is not forwarded: `run-filacheck` fixes it to `file`, since the wrapped check operates on files. PHP, Composer and reviewdog are set up automatically (via `run-filacheck`'s own embedded `setup-php`/`setup-reviewdog`), skipped if they already ran earlier in the job.

## Inputs

### github-token

**Optional.** GitHub token for reviewdog reporting. Defaults to `github.token`.

### path

**Optional.** Path to analyze with FilaCheck. Defaults to `app/Filament`.

### detailed

**Optional.** Show detailed output with rule categories. Defaults to `false`.

### dirty

**Optional.** Only scan files with uncommitted git changes. Defaults to `false`.

### wip

**Optional.** Only scan files changed on the current pull request, relative to its base branch. Defaults to `false`.

### wip-base-ref

**Optional.** Base branch/ref to diff against when `wip` is enabled. Defaults to `GITHUB_BASE_REF`, which GitHub Actions sets automatically on `pull_request` events.

### level

**Optional.** Report level for reviewdog `[info,warning,error]`. Defaults to `error`.

### reporter

**Optional.** Reporter of reviewdog command `[github-pr-check,github-check,github-pr-review]`. Defaults to the reporter resolved by [**setup-reviewdog**](../setup-reviewdog/README.md) for this run's context (`github-pr-check` on pull requests, `github-check` otherwise).

### fail-level

**Optional.** Exit code for reviewdog if it finds at least the specified level `[none,any,info,warning,error]`. Defaults to `none`.

### reviewdog-flags

**Optional.** Additional reviewdog flags. Defaults to empty.

## Outputs

This action has no outputs.

## Works well with

- [**check-laravel**](../check-laravel/README.md) — run the general Laravel PHP suite alongside the Filament-specific one.
- [**list-wip**](../list-wip/README.md) — included automatically behind `wip`.

## Example

```yaml
name: PR Filament Checks

on:
    pull_request:

jobs:
    filament:
        runs-on: ubuntu-latest
        steps:
            - uses: actions/checkout@v4

            - name: Validate Filament
              uses: tomgrv/actions/check-filament@v1
              with:
                  github-token: ${{ secrets.GITHUB_TOKEN }}
```
