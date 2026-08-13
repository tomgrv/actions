<!-- @format -->

# GitHub Action: Detect Unpublished Packages

Scans the immediate subdirectories of a given path for `package.json` manifests and emits a JSON matrix of the packages that are public and not yet published at their current version on npm.

## Inputs

### path

**Optional.** Directory containing package subdirectories to scan. Defaults to `src`.

## Outputs

### packages

JSON array of unpublished package objects, each containing `name`, `version`, and `path` fields.

## Local Usage

Run this action locally using the root `./dispatch.sh` dispatcher:

```sh
./dispatch.sh detect-unpublished-packages path=src
```

## Usage in a workflow

```yaml
jobs:
    detect:
        runs-on: ubuntu-latest
        outputs:
            packages: ${{ steps.detect.outputs.packages }}
        steps:
            - uses: actions/checkout@v4

            - name: Detect unpublished feature packages
              id: detect
              uses: tomgrv/actions/detect-unpublished-packages@v1
              with:
                  path: src

    publish:
        runs-on: ubuntu-latest
        needs: detect
        if: ${{ needs.detect.outputs.packages != '[]' }}
        strategy:
            matrix:
                package: ${{ fromJson(needs.detect.outputs.packages) }}
        steps:
            - uses: actions/checkout@v4

            - name: Publish package
              uses: tomgrv/actions/publish-npm@v1
              with:
                  path: ${{ matrix.package.path }}
```
