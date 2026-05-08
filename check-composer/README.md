<!-- @format -->

# GitHub Action: Validate PR Composer

Runs `composer validate --strict` on the repository and reports findings inline via reviewdog.

## Inputs

### github-token

**Required.** GitHub token for reviewdog reporting.

## Outputs

This action has no outputs.

## Works well with

- [**setup-php**](../setup-php/README.md) — set up PHP and Composer before running validation.


## Local Usage

Each action script can be run directly as a shell utility or via `npx`:

```sh
npx -yes @tomgrv/action-check-composer
```

Required environment variables must be set before running. See [Inputs](#inputs) for details.

## Example

```yaml
name: PR Checks

on:
    pull_request:

jobs:
    validate-composer:
        runs-on: ubuntu-latest
        steps:
            - uses: actions/checkout@v4

            - name: Setup PHP toolchain
              uses: tomgrv/actions/setup-php@v1

            - name: Validate composer
              uses: tomgrv/actions/check-composer@v1
              with:
                  github-token: ${{ secrets.GITHUB_TOKEN }}
```
