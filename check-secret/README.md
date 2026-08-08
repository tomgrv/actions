<!-- @format -->

# GitHub Action: Validate PR Secrets

Scans pull request changes for leaked secrets using [gitleaks](https://github.com/gitleaks/gitleaks-action).

## Inputs

### github-token

**Optional.** GitHub token for the gitleaks action. Defaults to `github.token`.

### gitleaks-license

**Optional.** Gitleaks license key.

## Outputs

This action has no outputs.

## Works well with

- [**check-pr-format**](../check-pr-format/README.md) — validate PR title format.
- [**check-security-composer**](../check-security-composer/README.md) — audit Composer dependency security.
- [**check-security-npm**](../check-security-npm/README.md) — audit npm dependency security.

## Example

```yaml
name: PR Security Check

on:
    pull_request:

jobs:
    check-secrets:
        runs-on: ubuntu-latest
        steps:
            - uses: actions/checkout@v4
              with:
                  fetch-depth: 0

            - name: Scan for secrets
              uses: tomgrv/actions/check-secret@v1
              with:
                  github-token: ${{ secrets.GITHUB_TOKEN }}
                  gitleaks-license: ${{ secrets.GITLEAKS_LICENSE }}
```
