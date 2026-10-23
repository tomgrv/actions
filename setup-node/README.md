<!-- @format -->

# GitHub Action: Setup Node.js

Shared composite action that prepares Node.js and npm for workflow jobs. Sets up the requested Node.js version with dependency caching and installs workspace dependencies from the lock file.

[**check-security-npm**](../check-security-npm/README.md) includes this action as its first step, so Node.js is always ready without an explicit step in your workflow. The actual Node.js/npm install runs once per job: once it has run — whether triggered by an explicit `setup-node` step or by an action that embeds it — later invocations in the same job detect the `TOMGRV_NODE_SETUP` environment marker and skip straight through. Add an explicit `setup-node` step yourself only when you need to pass custom `cache`, `node-version`, or `options`.

## Inputs

### cache

**Optional.** Package manager to use for dependency caching. Defaults to `npm`.

### node-version

**Optional.** Node.js version to set up. Defaults to `24`.

### options

**Optional.** Additional arguments to pass to the install command. includes --no-progress and --workspaces by default.

### bare

**Optional.** If true, skips the `npm ci` step. Useful for actions that only need Node.js and npm available, but not the project's dependencies. Defaults to `false`.

## Outputs

This action has no outputs.

## Works well with

- [**check-security-npm**](../check-security-npm/README.md) — audit npm dependencies; already included automatically.
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
              uses: tomgrv/actions/setup-node@v5

            - name: Audit npm dependencies
              uses: tomgrv/actions/check-security-npm@v5
              with:
                  github-token: ${{ secrets.GITHUB_TOKEN }}
```
