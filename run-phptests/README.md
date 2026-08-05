<!-- @format -->

# GitHub Action: Validate PR Test Suite

Runs the PHP test suite for a pull request and reports failing tests with reviewdog.

The action picks the first available runner — `pest`, then `phpunit` (from `vendor/bin` or the global `PATH`), then a `test` script declared in `composer.json`. Test output is streamed to the job log, and the JUnit report is converted to reviewdog diagnostics so each failure lands on the file and line of the first stack frame outside `vendor/`.

Reporting never changes the verdict: the suite's own exit code is what fails the step, so a missing token or a reviewdog problem cannot mask or invent a test result.

## Inputs

| Name                | Description                                                                                                            | Required | Default      |
| ------------------- | ---------------------------------------------------------------------------------------------------------------------- | -------- | ------------ |
| `github-token`      | GitHub token for reviewdog reporting. Reporting is skipped when empty.                                                  | No       | `${{ github.token }}` |
| `working-directory` | Directory to run the test suite in, relative to the workspace.                                                          | No       | `.`          |
| `install`           | Install Composer dependencies when `vendor/autoload.php` is missing `[auto,true,false]`. `auto` installs when a composer.json is present. | No       | `auto`       |
| `runner`            | Test runner to use `[auto,pest,phpunit,composer]`. `auto` picks pest, then phpunit, then the composer `test` script.     | No       | `auto`       |
| `paths`             | Optional paths or filters to pass to the test runner. Defaults to the whole suite.                                      | No       | `''`         |
| `flags`             | Additional flags to pass to the test runner.                                                                            | No       | `''`         |
| `coverage`          | Generate a clover coverage report `[auto,true,false]`. `auto` skips coverage when no xdebug/pcov driver is loaded.       | No       | `auto`       |
| `coverage-file`     | Clover coverage report to write when coverage is enabled.                                                               | No       | `coverage.xml` |
| `junit-file`        | JUnit report to write, used to report failing tests.                                                                    | No       | `junit.xml`  |
| `migrate`           | Run `artisan migrate` before the suite `[auto,true,false]`. `auto` migrates when the project has migrations.             | No       | `auto`       |
| `level`             | Report level for reviewdog `[info,warning,error]`.                                                                      | No       | `error`      |
| `reporter`          | Reporter of reviewdog command `[github-pr-check,github-check,github-pr-review]`.                                         | No       | `github-pr-check` |
| `filter-mode`       | Filtering mode for the reviewdog command `[added,diff_context,file,nofilter]`. Defaults to `nofilter`, as failing tests often sit outside the diff. | No | `nofilter` |
| `fail-level`        | Exit code for reviewdog if it finds at least the specified level of diagnostic `[none,any,info,warning,error]`.          | No       | `none`       |
| `reviewdog-flags`   | Additional reviewdog flags.                                                                                             | No       | `''`         |

## Outputs

| Name            | Description                                                                    |
| --------------- | ------------------------------------------------------------------------------ |
| `tests-passed`  | Whether the test suite passed.                                                  |
| `coverage-file` | Path of the generated coverage report, empty when no report was produced.       |
| `junit-file`    | Path of the generated JUnit report, empty when no report was produced.          |

## Composer dependencies

The suite cannot run without `vendor/autoload.php` — `artisan`, `pest` and `phpunit` all require it and die with a raw PHP fatal when it is absent. PHP and Composer dependencies are set up automatically via [**setup-php**](../setup-php/README.md), which installs dependencies from `composer.json` whether or not a `composer.lock` is committed; the setup is skipped if it already ran earlier in the job. If `vendor/autoload.php` is still missing afterward, the action installs the dependencies itself (`install: auto`) and, failing that, reports what is missing instead of a stack trace.

## Laravel projects

When an `artisan` file is present, the action bootstraps the application before running the suite:

- `.env` is seeded from `.env.example`, `.env.testing` or `.env.ci` — an existing `.env` is never overwritten.
- `php artisan key:generate` and `php artisan config:clear` are run. Config is deliberately **not** cached: a cached config freezes `env()` to build-time values and silently ignores `.env.testing` and `phpunit.xml` overrides during tests.
- `php artisan migrate --force` runs when the project has migrations, unless `migrate` is set to `false`.

## Works well with

- [**setup-php**](../setup-php/README.md) — included automatically; add it explicitly only to pass custom `options`/`tools`, or once at the top of the job to share the setup across several PHP actions.
- [**run-phpstan**](../run-phpstan/README.md) — complement the test suite with static analysis.
- [**run-pint**](../run-pint/README.md) — complement the test suite with code style checks.

## Local Usage

Run this action locally using the root `npx @tomgrv/actions` dispatcher:

```sh
npx @tomgrv/actions run-phptests
```

Inputs are read from the matching environment variables when running locally: `WORKING_DIRECTORY`, `INSTALL`, `TEST_RUNNER`, `TEST_PATHS`, `TEST_FLAGS`, `COVERAGE`, `COVERAGE_FILE`, `JUNIT_FILE`, `MIGRATE`, and the usual `REVIEWDOG_*` variables.

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
