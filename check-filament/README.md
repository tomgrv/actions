<!-- @format -->

# GitHub Action: Validate PR Filament

Runs the Filament-specific check suite — currently [FilaCheck](https://github.com/LaravelDaily/FilaCheck) — and reports findings inline via reviewdog. This is a thin wrapper around [**run-filacheck**](../run-filacheck/README.md), kept as its own action so Filament checks can grow independently of the general Laravel suite in [**check-laravel**](../check-laravel/README.md).

Every input is forwarded as-is to the wrapped `run-filacheck` call, including `github-token` and the reviewdog options (`level`, `reporter`, `filter-mode`, `fail-level`, `reviewdog-flags`), so the reviewdog context you configure on `check-filament` is exactly what the underlying check uses — never a separately-defaulted one. PHP, Composer and reviewdog are set up automatically (via `run-filacheck`'s own embedded `setup-php`/`setup-reviewdog`), skipped if they already ran earlier in the job.

## Inputs

### github-token

**Required.** GitHub token for reviewdog reporting.

### path

**Optional.** Path to analyze with FilaCheck. Defaults to `app/Filament`.

### fix

**Optional.** Apply fixes directly instead of reporting via reviewdog. Defaults to `false`.

### detailed

**Optional.** Show detailed output with rule categories. Defaults to `false`.

### dirty

**Optional.** Only scan files with uncommitted git changes. Defaults to `false`.

### dry-run

**Optional.** Preview fix changes without modifying files. Defaults to `false`.

### backup

**Optional.** Create backup files when fixing. Defaults to `false`.

### level

**Optional.** Report level for reviewdog `[info,warning,error]`. Defaults to `error`.

### reporter

**Optional.** Reporter of reviewdog command `[github-pr-check,github-check,github-pr-review]`. Defaults to `github-pr-check`.

### filter-mode

**Optional.** Filtering mode for the reviewdog command `[added,diff_context,file,nofilter]`. Defaults to empty, which keeps `run-filacheck`'s own default (`added`).

### fail-level

**Optional.** Exit code for reviewdog if it finds at least the specified level `[none,any,info,warning,error]`. Defaults to `none`.

### reviewdog-flags

**Optional.** Additional reviewdog flags. Defaults to empty.

## Outputs

- `has-changes`: Whether fix mode produced local changes.

## Works well with

- [**check-laravel**](../check-laravel/README.md) — run the general Laravel PHP suite alongside the Filament-specific one.
- [**create-pr**](../create-pr/README.md) — open a pull request with the auto-fixed files.

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
