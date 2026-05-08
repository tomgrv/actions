<!-- @format -->

# GitHub Action: Validate PR Test Suite

Runs the PHP test suite (`composer test` or the vendor test runner) for a pull request.

## Inputs

This action has no inputs.

## Outputs

This action has no outputs.

## Works well with

- [**setup-php**](../setup-php/README.md) — set up PHP and Composer before running tests.
- [**run-phpstan**](../run-phpstan/README.md) — complement the test suite with static analysis.
- [**run-pint**](../run-pint/README.md) — complement the test suite with code style checks.


## Local Usage

Run this action locally using the root `npx @tomgrv/actions` dispatcher:

```sh
npx @tomgrv/actions run-phptests
```

Required environment variables must be set before running. See [Inputs](#inputs) for details.

## Example

```yaml
name: PR PHP Checks

on:
    pull_request:

jobs:
    tests:
        runs-on: ubuntu-latest
        steps:
            - uses: actions/checkout@v4

            - name: Setup PHP toolchain
              uses: tomgrv/actions/setup-php@v1

            - name: Run test suite
              uses: tomgrv/actions/run-phptests@v1
```
