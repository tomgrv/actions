<!-- @format -->

# GitHub Action: Validate PR Security NPM

Runs `npm audit` against the project's npm dependencies and reports findings inline via reviewdog.

## Inputs

### github-token

**Required.** GitHub token for reviewdog reporting.

## Outputs

This action has no outputs.

## Works well with

- [**setup-node**](../setup-node/README.md) — set up Node.js and npm before running the audit.
- [**check-security-composer**](../check-security-composer/README.md) — also audit Composer dependencies.

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
