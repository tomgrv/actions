<!-- @format -->

# GitHub Action: List PHP Parts

Lists the PHP test parts affected by the current change — `core`, `modules/*` and `packages/*/*`, discovered from the root `composer.json` merge-plugin globs — as a JSON matrix, so each pull request only runs the test suites it can impact. Selection is done by the [`php-list-changed`](https://github.com/tomgrv/scripts/tree/develop/php-list-changed) script:

- a change inside a part selects it and every part that `require`s it;
- a change to `tests/` selects `core`;
- a change to a shared file (`app/`, `config/`, `bootstrap/`, `database/`, `routes/`, `resources/`, `.github/`, `composer.json|lock`, `phpunit.xml`, `tests/Pest.php`, `tests/TestCase.php`) selects everything;
- parts without a `tests/` directory are never listed.

Requires a checkout with `fetch-depth: 0` (the diff is taken from the merge-base).

## Inputs

### base-ref

**Optional.** Base branch/ref to diff against. Defaults to `GITHUB_BASE_REF`, which GitHub Actions sets automatically on `pull_request` events.

### all

**Optional.** `true` selects every part regardless of the diff. Defaults to `false`.

## Outputs

- `matrix`: JSON array of affected parts, each `{name,suite,path}` (`path` is the test directory to pass to `run-phptests`; `suite` assumes testsuite names match directory names).
- `has-parts`: `true` if at least one part has tests to run, `false` otherwise.

## Works well with

- [**run-phptests**](../run-phptests/README.md) — run one matrix entry with `paths: <path>`.
- [**list-wip**](../list-wip/README.md) — file-level equivalent for linters.

## Local Usage

```sh
GITHUB_BASE_REF=develop zz-use -x ./list-php-parts
```

## Example

```yaml
jobs:
    detect:
        runs-on: ubuntu-latest
        outputs:
            matrix: ${{ steps.parts.outputs.matrix }}
            has-parts: ${{ steps.parts.outputs.has-parts }}
        steps:
            - uses: actions/checkout@v6
              with:
                  fetch-depth: 0
            - id: parts
              uses: tomgrv/actions/list-php-parts@v3

    test:
        needs: detect
        if: needs.detect.outputs.has-parts == 'true'
        strategy:
            fail-fast: false
            matrix:
                part: ${{ fromJson(needs.detect.outputs.matrix) }}
        runs-on: ubuntu-latest
        steps:
            - uses: actions/checkout@v6
            - uses: tomgrv/actions/run-phptests@v3
              with:
                  paths: ${{ matrix.part.path }}
                  name: phpunit (${{ matrix.part.name }})
```
