<!-- @format -->

# GitHub Action: Validate PR Security NPM

Runs `npm audit` against the project's npm dependencies and reports findings inline via reviewdog. Node.js and npm are set up automatically via [**setup-node**](../setup-node/README.md), and reviewdog via [**setup-reviewdog**](../setup-reviewdog/README.md); both are skipped if they already ran earlier in the job.

## Inputs

### github-token

**Required.** GitHub token for reviewdog reporting.

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
