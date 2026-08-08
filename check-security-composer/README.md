<!-- @format -->

# GitHub Action: Validate PR Security Composer

Runs `composer audit` against the project's Composer dependencies and reports findings inline via reviewdog. PHP and Composer are set up automatically via [**setup-php**](../setup-php/README.md), and reviewdog via [**setup-reviewdog**](../setup-reviewdog/README.md); both are skipped if they already ran earlier in the job.

Each vulnerable package is reported once, combining all of its advisories. The action works out the lowest version that clears every advisory range affecting the currently locked version and, when the package is required directly in `composer.json`, posts the finding as a review with a suggested version bump you can apply directly from the GitHub UI.

Findings (advisories and abandoned packages) are sorted most severe first and capped at `max-diagnostics` (default `40`); any remainder is rolled up into a single summary diagnostic so the check stays within GitHub's per-step/per-job annotation limits.

## Inputs

### github-token

**Optional.** GitHub token for reviewdog reporting. Defaults to `github.token`.

### name

**Optional.** Name reported by reviewdog to identify this check. Defaults to `composer-audit`.

### level

**Optional.** Report level for reviewdog `[info,warning,error]`. Defaults to `error`.

### reporter

**Optional.** Reporter of reviewdog command `[github-pr-check,github-check,github-pr-review]`. Defaults to `github-pr-review` so recommended version upgrades are posted as applyable suggestions.

### filter-mode

**Optional.** Filtering mode for the reviewdog command `[added,diff_context,file,nofilter]`. Defaults to `nofilter`.

### fail-level

**Optional.** Exit code for reviewdog if it finds at least the specified level `[none,any,info,warning,error]`. Defaults to `none`.

### reviewdog-flags

**Optional.** Additional reviewdog flags. Defaults to empty.

### max-diagnostics

**Optional.** Maximum number of vulnerability diagnostics to report, most severe first. Defaults to `40`. When `composer audit` finds more findings than this, the extra ones are collapsed into a single summary diagnostic instead of one per finding, to stay under [GitHub's annotation limits](https://docs.github.com/en/actions/reference/workflow-commands-for-github-actions#about-workflow-commands) (10 error/10 warning annotations per step, 50 per job).

## Outputs

This action has no outputs.

## Works well with

- [**setup-php**](../setup-php/README.md) — included automatically; add it explicitly only to pass custom `options`/`tools`, or once at the top of the job to share the setup across several PHP actions.
- [**setup-reviewdog**](../setup-reviewdog/README.md) — included automatically; add it explicitly only to pass a custom `version`.
- [**check-security-npm**](../check-security-npm/README.md) — also audit npm dependencies.

## Local Usage

Run this action locally using the root `npx @tomgrv/actions` dispatcher:

```sh
npx @tomgrv/actions check-security-composer
```

Required environment variables must be set before running. See [Inputs](#inputs) for details.

## Example

```yaml
name: PR Security Checks

on:
    pull_request:

jobs:
    audit-composer:
        runs-on: ubuntu-latest
        steps:
            - uses: actions/checkout@v4

            - name: Audit Composer dependencies
              uses: tomgrv/actions/check-security-composer@v1
              with:
                  github-token: ${{ secrets.GITHUB_TOKEN }}
```
