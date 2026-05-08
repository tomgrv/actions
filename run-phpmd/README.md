<!-- @format -->

# GitHub Action: Validate PR PHPMD

Runs [PHP Mess Detector](https://phpmd.org/) and reports findings inline via reviewdog.

## Inputs

### github-token

**Required.** GitHub token for reviewdog reporting.

### paths

**Optional.** Comma-separated list of paths to analyze. Defaults to `app`.

### ruleset

**Optional.** Comma-separated PHPMD ruleset to apply. Defaults to `cleancode,codesize,controversial,design,naming,unusedcode`.

### priority

**Optional.** Minimum issue priority to report (1 = highest, 5 = lowest). Defaults to `max`.

## Outputs

This action has no outputs.

## Works well with

- [**setup-php**](../setup-php/README.md) — set up PHP and Composer before running PHPMD.
- [**run-phpstan**](../run-phpstan/README.md) — complement PHPMD with static analysis.
- [**run-phpinsights**](../run-phpinsights/README.md) — complement PHPMD with code quality insights.


## Local Usage

Each action script can be run directly as a shell utility or via `npx`:

```sh
npx -yes @tomgrv/action-run-phpmd
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

            - name: Setup PHP toolchain
              uses: tomgrv/actions/setup-php@v1

            - name: Run PHPMD
              uses: tomgrv/actions/run-phpmd@v1
              with:
                  github-token: ${{ secrets.GITHUB_TOKEN }}
                  paths: app,modules
                  ruleset: cleancode,codesize,naming
```
