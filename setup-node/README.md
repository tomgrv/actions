<!-- @format -->

# GitHub Action: Setup Node.js

Shared composite action that prepares Node.js and npm for workflow jobs. Sets up the requested Node.js version with dependency caching and installs workspace dependencies from the lock file.

## Inputs

### cache

**Optional.** Package manager to use for dependency caching. Defaults to `npm`.

### node-version

**Optional.** Node.js version to set up. Defaults to `24`.

## Outputs

This action has no outputs.

## Works well with

- [**check-security-npm**](../check-security-npm/README.md) — audit npm dependencies after setup.
- [**list-packages**](../list-packages/README.md) — discover npm workspace packages after setup.

## Example

```yaml
name: PR Node.js Checks

on:
    pull_request:

jobs:
    audit:
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
