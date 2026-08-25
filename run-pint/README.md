<!-- @format -->

# GitHub Action: Validate PR Pint

Runs [Laravel Pint](https://laravel.com/docs/pint) and reports code style findings inline via reviewdog. PHP and Composer dependencies are set up automatically via [**setup-php**](../setup-php/README.md), and reviewdog via [**setup-reviewdog**](../setup-reviewdog/README.md); both are skipped if they already ran earlier in the job. `pint` itself is installed globally via `setup-php`'s `require` input (`laravel/pint`), unless already required locally in `composer.json` (and thus in `vendor/`) or already installed globally.

## Inputs

### github-token

**Optional.** GitHub token for reviewdog reporting. Defaults to `github.token`.

### paths

**Optional.** Comma-separated list of paths to analyze. Defaults to `app`.

### preset

**Optional.** Pint preset to use (e.g. `laravel`, `default`, `symfony`). Defaults to `laravel`. Ignored when `config` is set.

### config

**Optional.** Path to a custom Pint configuration file. Leave empty to let Pint auto-detect `pint.json` at the repository root, or fall back to `preset` otherwise.

### blade

**Optional.** Format `.blade.php` files too, via Pint's [`--blade`](https://laravel-news.com/blade-formatting-in-laravel-pint) flag (Pint 1.30+). Formats Blade syntax, Alpine attributes, Livewire `wire:` bindings, Flux components, and Tailwind class sorting, through `prettier` + `prettier-plugin-blade` + `prettier-plugin-tailwindcss` — these must already be available in the repository (e.g. as npm `devDependencies`). Defaults to `false`.

### dirty

**Optional.** Only analyze files with uncommitted git changes (staged, unstaged, or untracked). Pint has no native flag for this, so it is emulated: [**list-dirty**](../list-dirty/README.md) resolves the changed files and this action passes that explicit list in place of `paths`. Defaults to `false`.

### wip

**Optional.** Only analyze files changed on the current pull request, relative to its base branch. Emulated the same way as `dirty`, via [**list-wip**](../list-wip/README.md) diffing against the merge-base of `wip-base-ref`. Defaults to `false`.

### wip-base-ref

**Optional.** Base branch/ref to diff against when `wip` is enabled. Defaults to `GITHUB_BASE_REF`, which GitHub Actions sets automatically on `pull_request` events.

### name

**Optional.** Name reported by reviewdog to identify this check. Defaults to `pint`.

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
- [**run-phpstan**](../run-phpstan/README.md) — complement Pint style checks with static analysis.
- [**list-dirty**](../list-dirty/README.md) / [**list-wip**](../list-wip/README.md) — included automatically behind `dirty`/`wip`.

## Local Usage

Run this action locally using the root `./dispatch.sh` dispatcher:

```sh
./dispatch.sh run-pint
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
