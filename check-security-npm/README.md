<!-- @format -->

# GitHub Action: Validate PR Security NPM

Runs `npm audit` against the project's npm dependencies and reports findings inline via reviewdog. Node.js and npm are set up automatically via [**setup-node**](../setup-node/README.md), and reviewdog via [**setup-reviewdog**](../setup-reviewdog/README.md); both are skipped if they already ran earlier in the job.

Each vulnerable dependency is reported once per manifest it's directly declared in, combining all of its advisories. For direct dependencies where npm knows a non-breaking fix (`fixAvailable`), the finding is posted as a review on the owning `package.json` (the root manifest, or the relevant npm workspace member's manifest) with a suggested version bump you can apply directly from the GitHub UI.

Findings are sorted most severe first and capped at `max-diagnostics` (default `40`); any remainder is rolled up into a single summary diagnostic so the check stays within GitHub's per-step/per-job annotation limits.

## Inputs

### github-token

**Optional.** GitHub token for reviewdog reporting. Defaults to `github.token`.

### name

**Optional.** Name reported by reviewdog to identify this check. Defaults to `npm-audit`.

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

**Optional.** Maximum number of vulnerability diagnostics to report, most severe first. Defaults to `40`. When `npm audit` finds more vulnerable packages than this, the extra findings are collapsed into a single summary diagnostic instead of one per package, to stay under [GitHub's annotation limits](https://docs.github.com/en/actions/reference/workflow-commands-for-github-actions#about-workflow-commands) (10 error/10 warning annotations per step, 50 per job).

## Outputs

This action has no outputs.

## Works well with

- [**setup-node**](../setup-node/README.md) — included automatically; add it explicitly only to pass custom `cache`/`node-version`/`options`, or once at the top of the job to share the setup across several Node actions.
- [**setup-reviewdog**](../setup-reviewdog/README.md) — included automatically; add it explicitly only to pass a custom `version`.
- [**check-security-composer**](../check-security-composer/README.md) — also audit Composer dependencies.

## Local Usage

Run this action locally using the root `npx @tomgrv/actions` dispatcher:

```sh
npx @tomgrv/actions check-security-npm
```

Required environment variables must be set before running. See [Inputs](#inputs) for details.

## Example

```yaml
name: PR Security Checks

on:
    pull_request:

jobs:
    audit-npm:
        runs-on: ubuntu-latest
        steps:
            - uses: actions/checkout@v4

            - name: Audit npm dependencies
              uses: tomgrv/actions/check-security-npm@v1
              with:
                  github-token: ${{ secrets.GITHUB_TOKEN }}
```
