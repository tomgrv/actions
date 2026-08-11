<!-- @format -->

# GitHub Action: Validate PR PHPStan

Runs [PHPStan](https://phpstan.org/) and reports findings inline via reviewdog. PHP and Composer dependencies are set up automatically via [**setup-php**](../setup-php/README.md), and reviewdog via [**setup-reviewdog**](../setup-reviewdog/README.md); both are skipped if they already ran earlier in the job. `phpstan` itself is installed globally via `setup-php`'s `require` input (`phpstan/phpstan`), unless already required locally in `composer.json` (and thus in `vendor/`) or already installed globally.

## Inputs

### github-token

**Optional.** GitHub token for reviewdog reporting. Defaults to `github.token`.

### paths

**Optional.** Comma-separated list of paths to analyze. Defaults to `app`.

### dirty

**Optional.** Only analyze files with uncommitted git changes (staged, unstaged, or untracked). PHPStan has no native flag for this, so it is emulated: [**list-dirty**](../list-dirty/README.md) resolves the changed files and this action passes that explicit list in place of `paths`. Defaults to `false`.

### wip

**Optional.** Only analyze files changed on the current pull request, relative to its base branch. Emulated the same way as `dirty`, via [**list-wip**](../list-wip/README.md) diffing against the merge-base of `wip-base-ref`. Defaults to `false`.

### wip-base-ref

**Optional.** Base branch/ref to diff against when `wip` is enabled. Defaults to `GITHUB_BASE_REF`, which GitHub Actions sets automatically on `pull_request` events.

### config

**Optional.** Path to a custom PHPStan configuration file. Leave empty to let PHPStan auto-detect `phpstan.neon`/`phpstan.neon.dist`/`phpstan.dist.neon` at the repository root, or fall back to its own defaults otherwise.

### name

**Optional.** Name reported by reviewdog to identify this check. Defaults to `phpstan`.

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

- [**check-laravel**](../check-laravel/README.md) — wraps this action as part of the Laravel check suite.
- [**setup-php**](../setup-php/README.md) — included automatically; add it explicitly only to pass custom `options`/`tools`, or once at the top of the job to share the setup across several PHP actions.
- [**setup-reviewdog**](../setup-reviewdog/README.md) — included automatically; add it explicitly only to pass a custom `version`.
- [**run-phpmd**](../run-phpmd/README.md) — complement PHPStan with mess detection.
- [**list-dirty**](../list-dirty/README.md) / [**list-wip**](../list-wip/README.md) — included automatically behind `dirty`/`wip`.

## Local Usage

Run this action locally using the root `./dispatch.sh` dispatcher:

```sh
./dispatch.sh run-phpstan
```

Required environment variables must be set before running. See [Inputs](#inputs) for details.

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

            - name: Run PHPStan
              uses: tomgrv/actions/run-phpstan@v1
              with:
                  github-token: ${{ secrets.GITHUB_TOKEN }}
                  paths: app,modules
```

