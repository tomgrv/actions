<!-- @format -->

# GitHub Action: Validate PR Format

Validates and optionally normalizes pull request title format against the Conventional Commits specification. When a GitHub token is provided and the title can be normalized, the PR title is updated automatically.

## Inputs

### github-token

**Optional.** GitHub token used to update the PR title when normalization is needed. Defaults to `github.token`.

## Outputs

This action has no outputs.

## Works well with

- [**check-secret**](../check-secret/README.md) — scan pull request changes for leaked secrets.
- [**check-security-composer**](../check-security-composer/README.md) — audit Composer dependency security.
- [**check-security-npm**](../check-security-npm/README.md) — audit npm dependency security.


## Local Usage

Run this action locally using the root `npx @tomgrv/actions` dispatcher:

```sh
npx @tomgrv/actions check-pr-format
```

Required environment variables must be set before running. See [Inputs](#inputs) for details.

## Example

```yaml
name: PR Format Check

on:
    pull_request:
        types: [opened, edited, synchronize, reopened]

jobs:
    check-pr-format:
        runs-on: ubuntu-latest
        steps:
            - name: Validate PR title format
              uses: tomgrv/actions/check-pr-format@v1
              with:
                  github-token: ${{ secrets.GITHUB_TOKEN }}
```
