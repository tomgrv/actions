<!-- @format -->

# GitHub Action: Run Workspace Tests

Runs a workspace's `.scripts.test` entry (from each root `*.json` file, typically `package.json`) as its test suite, via [`tomgrv/scripts/run-workspace-tests`](https://github.com/tomgrv/scripts/tree/main/run-workspace-tests).

- No root `*.json` file in the workspace → silently skipped.
- `*.json` present but no `.scripts.test` entry → warns, does not fail.
- `.scripts.test` present → run it; a non-zero exit, or a zero exit with no output at all (a silently-empty test run), both fail the step.

## Inputs

### workspace

**Required.** Workspace directory to test.

## Usage

Pair with [`tomgrv/actions/list-packages`](../list-packages) to test every workspace in a monorepo as a matrix:

```yaml
jobs:
    list-packages:
        runs-on: ubuntu-latest
        outputs:
            packages: ${{ steps.list.outputs.packages }}
        steps:
            - uses: actions/checkout@v4
            - uses: tomgrv/actions/list-packages@v2
              id: list

    test:
        needs: list-packages
        runs-on: ubuntu-latest
        strategy:
            matrix:
                package: ${{ fromJson(needs.list-packages.outputs.packages) }}
        steps:
            - uses: actions/checkout@v4
            - uses: tomgrv/actions/run-workspace-tests@v2
              with:
                  workspace: ${{ matrix.package.path }}
```

## Tests

```sh
./run-tests.sh -f run-workspace-tests
```
