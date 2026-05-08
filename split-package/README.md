<!-- @format -->

# GitHub Action: Split Package

Splits a package from a monorepo a separate repository using [splitsh-lite](https://github.com/splitsh/lite). The action extracts the commit history of the given package directory, pushes a split branch to the origin repository, and exposes a working directory ready for use with `create-pr`.

## Inputs

### package-directory

**Required.** Relative path to the package directory from the repository root.

### repository-organization

**Required.** GitHub organization or user that owns the origin repository.

### repository-name

**Required.** Name of the origin repository.

### sync-branch

**Optional.** Target branch in the origin repository. Defaults to `main`.

### github-token

**Optional.** GitHub token with push permissions to the origin repository.

### splitsh-version

**Optional.** Version of splitsh-lite to use. Defaults to `v1.0.1`.

## Outputs

- `split-branch`: Generated split branch name.
- `split-sha`: Commit SHA of the generated split.
- `split-workdir`: Temporary working directory of the split workspace, ready for committing and pushing.

## Works well with

- [**list-packages**](../list-packages/README.md) — discover packages to use as a matrix for `split-package`.
- [**config-bot**](../config-bot/README.md) — configure git bot identity before splitting.
- [**create-pr**](../create-pr/README.md) — open a pull request in the origin repository using `split-branch` and `split-workdir` outputs.


## Local Usage

Run this action locally using the root `npx @tomgrv/actions` dispatcher:

```sh
npx @tomgrv/actions split-package
```

Required environment variables must be set before running. See [Inputs](#inputs) for details.

## Example

```yaml
name: Split Packages

on:
    push:
        branches: [main]

jobs:
    list-packages:
        runs-on: ubuntu-latest
        outputs:
            packages: ${{ steps.list.outputs.packages }}
        steps:
            - uses: actions/checkout@v4

            - name: Setup PHP toolchain
              uses: tomgrv/actions/setup-php@v1
              with:
                  options: '--no-dev'

            - name: Setup Node.js toolchain
              uses: tomgrv/actions/setup-node@v1

            - name: List packages
              id: list
              uses: tomgrv/actions/list-packages@v1

    split-package:
        runs-on: ubuntu-latest
        needs: list-packages
        strategy:
            matrix:
                package: ${{ fromJson(needs.list-packages.outputs.packages) }}
        steps:
            - uses: actions/checkout@v4
              with:
                  fetch-depth: 0

            - name: Generate app token
              id: app-token
              uses: actions/create-github-app-token@v1
              with:
                  app-id: ${{ secrets.APP_ID }}
                  private-key: ${{ secrets.APP_PRIVATE_KEY }}
                  owner: ${{ matrix.package.org }}
                  repositories: ${{ matrix.package.name }}

            - name: Configure git bot
              uses: tomgrv/actions/config-bot@v1
              with:
                  github-token: ${{ steps.app-token.outputs.token }}
                  github-app-slug: ${{ steps.app-token.outputs.app-slug }}

            - name: Split package
              id: split
              uses: tomgrv/actions/split-package@v1
              with:
                  package-directory: ${{ matrix.package.path }}
                  repository-organization: ${{ matrix.package.org }}
                  repository-name: ${{ matrix.package.name }}
                  github-token: ${{ steps.app-token.outputs.token }}

            - name: Create pull request
              if: ${{ steps.split.outputs.split-branch != '' }}
              uses: tomgrv/actions/create-pr@v1
              with:
                  github-token: ${{ steps.app-token.outputs.token }}
                  repository: ${{ matrix.package.org }}/${{ matrix.package.name }}
                  head-branch: ${{ steps.split.outputs.split-branch }}
                  workdir: ${{ steps.split.outputs.split-workdir }}
                  pr-title: 'sync: import from monorepo'
```
