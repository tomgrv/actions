<!-- @format -->

# GitHub Action: Validate PR PHPStan

Runs [PHPStan](https://phpstan.org/) and reports findings inline via reviewdog. Can also run in **fix mode** to generate or update a PHPStan baseline file and produce a prepared branch for downstream steps.

## Inputs

### github-token

**Required.** GitHub token for reviewdog reporting.

### paths

**Optional.** Comma-separated list of paths to analyze. Defaults to `app`.

### fix

**Optional.** Enable baseline generation mode instead of reviewdog reporting. Defaults to `false`.

### branch-prefix

**Optional.** Prefix for the generated branch name when fix mode is enabled. Defaults to `chore/phpstan-fix`.

### baseline-file

**Optional.** Baseline file to generate or update when fix mode is enabled. Defaults to `phpstan-baseline.neon`.

## Outputs

- `has-changes`: Whether fix mode produced local changes.
- `head-branch`: Generated branch name when fix mode is enabled.

## Works well with

- [**setup-php**](../setup-php/README.md) — set up PHP and Composer before running PHPStan.
- [**create-pr**](../create-pr/README.md) — open a pull request with the generated baseline update.
- [**run-phpmd**](../run-phpmd/README.md) — complement PHPStan with mess detection.

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

            - name: Setup PHP toolchain
              uses: tomgrv/actions/setup-php@v1

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

            - name: Setup PHP toolchain
              uses: tomgrv/actions/setup-php@v1

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
                  head-branch: ${{ steps.phpstan.outputs.head-branch }}
                  pr-title: 'chore: update phpstan baseline'
```
