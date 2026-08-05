<!-- @format -->

# GitHub Action: Validate PR PHPMD

Runs [PHP Mess Detector](https://phpmd.org/) and reports findings inline via reviewdog. PHP and Composer dependencies are set up automatically via [**setup-php**](../setup-php/README.md), and reviewdog via [**setup-reviewdog**](../setup-reviewdog/README.md); both are skipped if they already ran earlier in the job. `phpmd` itself must be available either in `vendor/bin` or the global `PATH`.

## Inputs

### github-token

**Required.** GitHub token for reviewdog reporting.

### paths

**Optional.** Comma-separated list of paths to analyze. Defaults to `app`.

### ruleset

**Optional.** Comma-separated PHPMD ruleset to apply. Defaults to `cleancode,codesize,controversial,design,naming,unusedcode`.

### priority

**Optional.** Minimum issue priority to report (`min`/`max`). Defaults to `max`.

### level

**Optional.** Report level for reviewdog `[info,warning,error]`. Defaults to `error`.

### reporter

**Optional.** Reporter of reviewdog command `[github-pr-check,github-check,github-pr-review]`. Defaults to `github-pr-check`.

### filter-mode

**Optional.** Filtering mode for the reviewdog command `[added,diff_context,file,nofilter]`. Defaults to `nofilter`.

### fail-level

**Optional.** Exit code for reviewdog if it finds at least the specified level `[none,any,info,warning,error]`. Defaults to `none`.

### reviewdog-flags

**Optional.** Additional reviewdog flags. Defaults to empty.

## Outputs

This action has no outputs.

## Works well with

- [**setup-php**](../setup-php/README.md) — included automatically; add it explicitly only to pass custom `options`/`tools`, or once at the top of the job to share the setup across several PHP actions.
- [**setup-reviewdog**](../setup-reviewdog/README.md) — included automatically; add it explicitly only to pass a custom `version`.
- [**run-phpstan**](../run-phpstan/README.md) — complement PHPMD with static analysis.
- [**run-phpinsights**](../run-phpinsights/README.md) — complement PHPMD with code quality insights.

## Local Usage

Run this action locally using the root `npx @tomgrv/actions` dispatcher:

```sh
npx @tomgrv/actions run-phpmd
```

Required environment variables must be set before running. See [Inputs](#inputs) for details.

## Example

```yaml
name: PR PHP Checks

on:
    pull_request:

jobs:
    phpmd:
        runs-on: ubuntu-latest
        steps:
            - uses: actions/checkout@v4

            - name: Run PHPMD
              uses: tomgrv/actions/run-phpmd@v1
              with:
                  github-token: ${{ secrets.GITHUB_TOKEN }}
                  paths: app
                  ruleset: cleancode,codesize,naming
```
