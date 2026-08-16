<!-- @format -->

# GitHub Action: Validate PR Laravel

Runs the standard Laravel PHP check suite — [PHPStan](https://phpstan.org/), [Laravel Pint](https://laravel.com/docs/pint), [PHP Insights](https://phpinsights.com/), [PHP Mess Detector](https://phpmd.org/), and the test suite — and reports findings inline via reviewdog. This is a thin wrapper around [**run-phpstan**](../run-phpstan/README.md), [**run-pint**](../run-pint/README.md), [**run-phpinsights**](../run-phpinsights/README.md), [**run-phpmd**](../run-phpmd/README.md) and [**run-phptests**](../run-phptests/README.md); Filament-specific checks live separately in [**check-filament**](../check-filament/README.md).

Each check can be individually skipped via its boolean toggle (`phpstan`, `pint`, `phpinsights`, `phpmd`, `tests`), and every check runs to completion — a failing check does not stop the others, so you get every annotation in one job. The action itself fails at the end if any wrapped check failed, so `fail-level` still gates the job as expected.

## Reviewdog context

`github-token`, `level`, `fail-level` and `reviewdog-flags` are forwarded as-is from this action's inputs to every wrapped check, so the reviewdog context you configure once on `check-laravel` is exactly what each underlying check uses — never a separately-defaulted one. Each wrapped check resolves its own `reporter` via [**setup-reviewdog**](../setup-reviewdog/README.md) for this run's context (`github-pr-check` on pull requests, `github-check` otherwise).

`filter-mode` is not forwarded either: every wrapped check (PHPStan, Pint, PHP Insights, PHPMD, tests) fixes it to `file`, since they all operate on files.

PHP, Composer and reviewdog are set up automatically (each wrapped action embeds its own `setup-php`/`setup-reviewdog`); only the first one in the job actually installs anything; the rest detect the job-scoped marker and skip straight through.

## Inputs

### github-token

**Optional.** GitHub token for reviewdog reporting, shared by every wrapped check. Defaults to `github.token`.

### paths

**Optional.** Comma-separated list of paths to analyze with PHPStan, Pint, PHP Insights and PHPMD. Defaults to `app`.

### dirty

**Optional.** Only analyze files with uncommitted git changes, forwarded to every wrapped check that supports it (PHPStan, Pint, PHP Insights, PHPMD — see each action's own README for how it's emulated). Defaults to `false`.

### wip

**Optional.** Only analyze files changed on the current pull request, relative to its base branch, forwarded the same way as `dirty`. Defaults to `false`.

### wip-base-ref

**Optional.** Base branch/ref to diff against when `wip` is enabled. Defaults to `GITHUB_BASE_REF`, which GitHub Actions sets automatically on `pull_request` events.

### phpstan / pint / phpinsights / phpmd / tests

**Optional.** Whether to run each check. Defaults to `true`.

### pint-blade

**Optional.** Format `.blade.php` files too when Pint runs, via Pint's [`--blade`](https://laravel-news.com/blade-formatting-in-laravel-pint) flag (Pint 1.30+), forwarded to [**run-pint**](../run-pint/README.md)'s `blade` input. Requires `prettier`, `prettier-plugin-blade` and `prettier-plugin-tailwindcss` already available in the repository. Defaults to `false`.

### level

**Optional.** Report level for reviewdog `[info,warning,error]`, shared by every wrapped check. Defaults to `error`.

### fail-level

**Optional.** Exit code for reviewdog if it finds at least the specified level `[none,any,info,warning,error]`, shared by every wrapped check. Defaults to `none`.

### reviewdog-flags

**Optional.** Additional reviewdog flags, shared by every wrapped check. Defaults to empty.

## Outputs

- `tests-passed`: Whether the test suite passed.
- `coverage-file`: Path of the generated coverage report, empty when no report was produced.
- `junit-file`: Path of the generated JUnit report, empty when no report was produced.

## Works well with

- [**check-filament**](../check-filament/README.md) — run the Filament-specific suite alongside the general Laravel one.
- [**check-security-composer**](../check-security-composer/README.md) — complement the suite with a Composer dependency audit.
- [**check-lock**](../check-lock/README.md) — complement the suite with lock coherence validation.
- [**list-dirty**](../list-dirty/README.md) / [**list-wip**](../list-wip/README.md) — included automatically behind `dirty`/`wip`.

## Example

```yaml
name: PR PHP Checks

on:
    pull_request:

jobs:
    laravel:
        runs-on: ubuntu-latest
        steps:
            - uses: actions/checkout@v4

            - name: Validate Laravel
              uses: tomgrv/actions/check-laravel@v1
              with:
                  github-token: ${{ secrets.GITHUB_TOKEN }}
                  paths: app,config,routes
```

### Skipping a check

```yaml
jobs:
    laravel:
        runs-on: ubuntu-latest
        steps:
            - uses: actions/checkout@v4

            - name: Validate Laravel (no PHPMD)
              uses: tomgrv/actions/check-laravel@v1
              with:
                  github-token: ${{ secrets.GITHUB_TOKEN }}
                  phpmd: 'false'
```
