<!-- @format -->

# GitHub Action: Detect Changes

Detects uncommitted or untracked changes in a given path using `git status --porcelain`.
Outputs a `has-changes` flag that downstream steps can act on.

## Inputs

### path

**Optional.** Base path to check for changes, relative to the repository root. Defaults to `.` (entire repo).

### subpath

**Optional.** Sub-path appended to `path` to narrow the check (e.g. a specific module or package directory).

### status-options

**Optional.** Additional flags forwarded to `git status` (e.g. `--ignored`, `-u`, `--untracked-files=all`).

## Outputs

### has-changes

`true` if changes are detected in the target path, `false` otherwise.
Includes both tracked modifications and untracked files.

## Works well with

- [**create-pr**](../create-pr/README.md) — open a pull request only when changes are present.
- [**run-pint**](../run-pint/README.md) — run code style checks on changed paths.
- [**run-phpstan**](../run-phpstan/README.md) — run static analysis only when relevant files changed.

## Example

```yaml
name: Conditional PR on Changes

on:
    push:
        branches:
            - develop

jobs:
    detect-and-pr:
        runs-on: ubuntu-latest
        steps:
            - uses: actions/checkout@v4

            - name: Detect changes
              id: changes
              uses: tomgrv/actions/detect-changes@v1
              with:
                  path: src
                  subpath: components
                  status-options: '--untracked-files=all'

            - name: Create PR if changes found
              if: steps.changes.outputs.has-changes == 'true'
              uses: tomgrv/actions/create-pr@v1
              with:
                  github-token: ${{ secrets.GITHUB_TOKEN }}
```
