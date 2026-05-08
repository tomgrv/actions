<!-- @format -->

# GitHub Action: List Packages

Discovers Composer and npm workspace packages in the repository and emits a JSON matrix array suitable for use as a GitHub Actions matrix value.

## Inputs

### workdir

**Optional.** Working directory to search for packages. Defaults to the repository root (`${{ github.workspace }}`).

## Outputs

### packages

JSON array of package objects, each containing `org`, `name`, `path`, and `repository` fields.

## Works well with

- [**degit-package**](../degit-package/README.md) — use the package matrix to degit each package in parallel.
- [**split-packages**](../split-packages/README.md) — use the package matrix to split each package in parallel.
- [**setup-php**](../setup-php/README.md) — install Composer dependencies before listing packages.
- [**setup-node**](../setup-node/README.md) — install npm dependencies before listing packages.


## Local Usage

Each action script can be run directly as a shell utility or via `npx`:

```sh
npx -yes @tomgrv/action-list-packages
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

    split-packages:
        runs-on: ubuntu-latest
        needs: list-packages
        strategy:
            matrix:
                package: ${{ fromJson(needs.list-packages.outputs.packages) }}
        steps:
            - uses: actions/checkout@v4
              with:
                  fetch-depth: 0

            - name: Split package
              uses: tomgrv/actions/split-packages@v1
              with:
                  package-directory: ${{ matrix.package.path }}
                  repository-organization: ${{ matrix.package.org }}
                  repository-name: ${{ matrix.package.name }}
                  github-token: ${{ secrets.GITHUB_TOKEN }}
```
