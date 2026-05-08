<!-- @format -->

# GitHub Action: Validate PR Security NPM

Runs `npm audit` against the project's npm dependencies and reports findings inline via reviewdog.

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

- [**setup-node**](../setup-node/README.md) — set up Node.js and npm before running the audit.
- [**check-security-composer**](../check-security-composer/README.md) — also audit Composer dependencies.

## Local Usage

Each action script can be run directly as a shell utility or via `npx`:

```sh
npx -yes @tomgrv/action-check-security-npm
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

            - name: Setup Node.js toolchain
              uses: tomgrv/actions/setup-node@v1

            - name: Audit npm dependencies
              uses: tomgrv/actions/check-security-npm@v1
              with:
                  github-token: ${{ secrets.GITHUB_TOKEN }}
```
