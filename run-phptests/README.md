<!-- @format -->

# GitHub Action: Validate PR Test Suite

Runs the PHP test suite for a pull request and reports failing tests as pull request annotations.

The action picks the first available runner — `pest`, then `phpunit` (from `vendor/bin` or the global `PATH`), then a `test` script declared in `composer.json`. Test output is streamed to the job log, failures are annotated on the offending file and line from the JUnit report, and a recap table is added to the job summary.

## Inputs

| Name                | Description                                                                                                            | Required | Default      |
| ------------------- | ---------------------------------------------------------------------------------------------------------------------- | -------- | ------------ |
| `working-directory` | Directory to run the test suite in, relative to the workspace.                                                          | No       | `.`          |
| `runner`            | Test runner to use `[auto,pest,phpunit,composer]`. `auto` picks pest, then phpunit, then the composer `test` script.     | No       | `auto`       |
| `paths`             | Optional paths or filters to pass to the test runner. Defaults to the whole suite.                                      | No       | `''`         |
| `flags`             | Additional flags to pass to the test runner.                                                                            | No       | `''`         |
| `coverage`          | Generate a clover coverage report `[auto,true,false]`. `auto` skips coverage when no xdebug/pcov driver is loaded.       | No       | `auto`       |
| `coverage-file`     | Clover coverage report to write when coverage is enabled.                                                               | No       | `coverage.xml` |
| `junit-file`        | JUnit report to write, used to annotate failing tests.                                                                  | No       | `junit.xml`  |
| `migrate`           | Run `artisan migrate` before the suite `[auto,true,false]`. `auto` migrates when the project has migrations.             | No       | `auto`       |
| `annotate`          | Annotate failing tests on the pull request from the JUnit report.                                                       | No       | `true`       |

## Outputs

| Name            | Description                                                                    |
| --------------- | ------------------------------------------------------------------------------ |
| `tests-passed`  | Whether the test suite passed.                                                  |
| `coverage-file` | Path of the generated coverage report, empty when no report was produced.       |
| `junit-file`    | Path of the generated JUnit report, empty when no report was produced.          |

## Laravel projects

When an `artisan` file is present, the action bootstraps the application before running the suite:

- `.env` is seeded from `.env.example`, `.env.testing` or `.env.ci` — an existing `.env` is never overwritten.
- `php artisan key:generate` and `php artisan config:clear` are run. Config is deliberately **not** cached: a cached config freezes `env()` to build-time values and silently ignores `.env.testing` and `phpunit.xml` overrides during tests.
- `php artisan migrate --force` runs when the project has migrations, unless `migrate` is set to `false`.

## Works well with

- [**setup-php**](../setup-php/README.md) — set up PHP and Composer before running tests.
- [**run-phpstan**](../run-phpstan/README.md) — complement the test suite with static analysis.
- [**run-pint**](../run-pint/README.md) — complement the test suite with code style checks.

## Local Usage

Run this action locally using the root `npx @tomgrv/actions` dispatcher:

```sh
npx @tomgrv/actions run-phptests
```

Inputs are read from the matching environment variables when running locally: `WORKING_DIRECTORY`, `TEST_RUNNER`, `TEST_PATHS`, `TEST_FLAGS`, `COVERAGE`, `COVERAGE_FILE`, `JUNIT_FILE`, `MIGRATE` and `ANNOTATE`.

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
              id: tests
              uses: tomgrv/actions/run-phptests@v1

            - name: Upload coverage
              if: ${{ steps.tests.outputs.coverage-file != '' }}
              uses: actions/upload-artifact@v4
              with:
                  name: coverage
                  path: ${{ steps.tests.outputs.coverage-file }}
```
