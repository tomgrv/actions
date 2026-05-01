<!-- @format -->

# GitHub Action: Degit Package

Imports the tip of a source repository branch into a target repository workspace (or a subdirectory). After copying, configured paths are excluded, and a branch is prepared for use with `create-pr`.

## Inputs

### github-token

**Required.** GitHub token with read access to the source and write access to the target repository.

### source-organization

**Required.** GitHub organization or user that owns the source repository.

### source-repository

**Required.** Source repository name to import from.

### source-branch

**Optional.** Source branch to import. Defaults to the source repository's default branch.

### target-subdir

**Optional.** Relative subdirectory inside the target repository where content is imported. Defaults to `.` (repository root).

### exclude-paths

**Optional.** Comma-separated paths to exclude during import. Defaults to `.github,.devcontainer,.vscode`.

### head-branch

**Optional.** Branch name to prepare in the target repository. Auto-generated when empty.

## Outputs

- `has-changes`: Whether the import produced any changes in the target workspace.
- `degit-branch`: Branch prepared in the target repository workspace.
- `degit-workdir`: Working directory of the target repository clone.
- `source-sha`: Source branch tip SHA used for the import.

## Works well with

- [**list-packages**](../list-packages/README.md) — discover packages to use as a matrix for `degit-package`.
- [**config-bot**](../config-bot/README.md) — configure git bot identity before pushing the prepared branch.
- [**create-pr**](../create-pr/README.md) — open or update a pull request using `degit-branch` and `degit-workdir` outputs.

## Example

```yaml
name: Degit Packages

on:
    workflow_dispatch:

jobs:
    list-packages:
        runs-on: ubuntu-latest
        outputs:
            packages: ${{ steps.list.outputs.packages }}
        steps:
            - uses: actions/checkout@v4

            - name: List packages
              id: list
              uses: tomgrv/actions/list-packages@v1

    degit-packages:
        runs-on: ubuntu-latest
        needs: list-packages
        strategy:
            matrix:
                package: ${{ fromJson(needs.list-packages.outputs.packages) }}
        steps:
            - uses: actions/checkout@v4

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

            - name: Import package content
              id: degit
              uses: tomgrv/actions/degit-package@v1
              with:
                  github-token: ${{ steps.app-token.outputs.token }}
                  source-organization: ${{ matrix.package.org }}
                  source-repository: ${{ matrix.package.name }}
                  target-subdir: ${{ matrix.package.path }}

            - name: Create or update pull request
              if: ${{ steps.degit.outputs.has-changes == 'true' }}
              uses: tomgrv/actions/create-pr@v1
              with:
                  github-token: ${{ steps.app-token.outputs.token }}
                  repository: ${{ matrix.package.org }}/${{ matrix.package.name }}
                  head-branch: ${{ steps.degit.outputs.degit-branch }}
                  workdir: ${{ steps.degit.outputs.degit-workdir }}
                  pr-title: 'sync: import from upstream'
```
