<!-- @format -->

# GitHub Action: Run Workspace Tests

Runs a workspace's `.scripts.test` entry (from each root `*.json` file, typically `package.json`) as its test suite, via [`tomgrv/scripts/ws-test`](https://github.com/tomgrv/scripts/tree/main/ws-test).

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
            - uses: tomgrv/actions/list-packages@v5
              id: list

    test:
        needs: list-packages
        runs-on: ubuntu-latest
        strategy:
            matrix:
                package: ${{ fromJson(needs.list-packages.outputs.packages) }}
        steps:
            - uses: actions/checkout@v4
            - uses: tomgrv/actions/run-workspace-tests@v5
              with:
                  workspace: ${{ matrix.package.path }}
```

## Tests

```sh
./.repo/tests/run-tests.sh -f run-workspace-tests
```

## Local Usage

Run this action locally from a clone of this repository with [`zz-use`](https://github.com/tomgrv/scripts/tree/main/zz-use):

```sh
zz-use -x ./run-workspace-tests
```

See [Inputs](#inputs) for the environment variables to set.

## Example

```yaml
- uses: tomgrv/actions/run-workspace-tests@v5
  with:
      workspace: <workspace>
```
