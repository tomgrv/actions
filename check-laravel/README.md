<!-- @format -->

# GitHub Action: Validate PR Laravel

Runs the standard Laravel PHP check suite — [PHPStan](https://phpstan.org/), [Laravel Pint](https://laravel.com/docs/pint), [PHP Insights](https://phpinsights.com/), [PHP Mess Detector](https://phpmd.org/), and the test suite — and reports findings inline via reviewdog. This is a thin wrapper around [**run-phpstan**](../run-phpstan/README.md), [**run-pint**](../run-pint/README.md), [**run-phpinsights**](../run-phpinsights/README.md), [**run-phpmd**](../run-phpmd/README.md) and [**run-phptests**](../run-phptests/README.md); Filament-specific checks live separately in [**check-filament**](../check-filament/README.md).

Each check can be individually skipped via its boolean toggle (`phpstan`, `pint`, `phpinsights`, `phpmd`, `tests`), and every check runs to completion — a failing check does not stop the others, so you get every annotation in one job. The action itself fails at the end if any wrapped check failed, so `fail-level` still gates the job as expected.

## Reviewdog context

`github-token`, `level`, `reporter`, `fail-level` and `reviewdog-flags` are forwarded as-is from this action's inputs to every wrapped check, so the reviewdog context you configure once on `check-laravel` is exactly what each underlying check uses — never a separately-defaulted one.

`filter-mode` is the one exception: it defaults to empty here, which lets each wrapped check keep its own tuned default (PHPStan, Pint and PHP Insights default to `added`; PHPMD and the test suite default to `nofilter`, since mess-detection findings and test failures often sit outside the diff). Set `filter-mode` explicitly on `check-laravel` to force the same value across every check instead.

PHP, Composer and reviewdog are set up automatically (each wrapped action embeds its own `setup-php`/`setup-reviewdog`); only the first one in the job actually installs anything; the rest detect the job-scoped marker and skip straight through.

## Inputs

### github-token

**Required.** GitHub token for reviewdog reporting, shared by every wrapped check.

### paths

**Optional.** Comma-separated list of paths to analyze with PHPStan, Pint, PHP Insights and PHPMD. Defaults to `app`.

### fix

**Optional.** Apply fixes directly (PHPStan baseline, Pint, PHP Insights) instead of reporting via reviewdog. Defaults to `false`.

### phpstan / pint / phpinsights / phpmd / tests

**Optional.** Whether to run each check. Defaults to `true`.

### level

**Optional.** Report level for reviewdog `[info,warning,error]`, shared by every wrapped check. Defaults to `error`.

### reporter

**Optional.** Reporter of reviewdog command `[github-pr-check,github-check,github-pr-review]`, shared by every wrapped check. Defaults to `github-pr-check`.

### filter-mode

**Optional.** Filtering mode for the reviewdog command `[added,diff_context,file,nofilter]`, shared by every wrapped check. Defaults to empty — see [Reviewdog context](#reviewdog-context).

### fail-level

**Optional.** Exit code for reviewdog if it finds at least the specified level `[none,any,info,warning,error]`, shared by every wrapped check. Defaults to `none`.

### reviewdog-flags

**Optional.** Additional reviewdog flags, shared by every wrapped check. Defaults to empty.

## Outputs

- `has-changes`: Whether fix mode produced local changes in any of PHPStan, Pint or PHP Insights.
- `phpstan-has-changes`: Whether fix mode produced changes to the PHPStan baseline file.
- `pint-has-changes`: Whether fix mode produced local changes via Pint.
- `phpinsights-has-changes`: Whether fix mode produced local changes via PHP Insights.
- `tests-passed`: Whether the test suite passed.
- `coverage-file`: Path of the generated coverage report, empty when no report was produced.
- `junit-file`: Path of the generated JUnit report, empty when no report was produced.

## Works well with

- [**check-filament**](../check-filament/README.md) — run the Filament-specific suite alongside the general Laravel one.
- [**check-security-composer**](../check-security-composer/README.md) — complement the suite with a Composer dependency audit.
- [**check-lock**](../check-lock/README.md) — complement the suite with lock coherence validation.
- [**create-pr**](../create-pr/README.md) — open a pull request with the auto-fixed files.

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
