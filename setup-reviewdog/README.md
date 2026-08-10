<!-- @format -->

# GitHub Action: Setup reviewdog

Shared composite action that installs [reviewdog](https://github.com/reviewdog/reviewdog) for workflow jobs.

Every reviewdog-based action in this repository (`run-phpstan`, `run-pint`, `run-phpinsights`, `run-phpmd`, `run-filacheck`, `run-phptests`, `check-security-composer`, `check-security-npm`, `check-lock`) includes this action as one of its first steps, so reviewdog is always ready without an explicit step in your workflow. The actual install runs once per job: once it has run — whether triggered by an explicit `setup-reviewdog` step or by one of the actions above — later invocations in the same job detect the `REVIEWDOG_SETUP` environment marker and skip straight through. Add an explicit `setup-reviewdog` step yourself only when you need a `version` other than the default.

This action also resolves the default reviewdog `reporter` for the run's context and exports it as the `REVIEWDOG_REPORTER` environment marker, computed once per job the same way as the install step above. On `pull_request`/`pull_request_target` events it resolves to `github-pr-check`; on every other event (`push`, `workflow_dispatch`, `schedule`, tags, ...) it resolves to `github-check`, since `github-pr-check`/`github-pr-review` need a pull request to attach to and `github-check` is the only reporter that works without one. Every action above passes `REVIEWDOG_REPORTER: ${{ inputs.reporter || env.REVIEWDOG_REPORTER }}` to its own run step, so an explicit `reporter` input wins and an empty one falls back to this marker.

It also resolves the reviewdog GitHub API token the same way: `github-token` (defaulting to `github.token`) falling back to a bare `GITHUB_TOKEN` env var, exported as `REVIEWDOG_GITHUB_API_TOKEN`, computed once per job. When neither source has a token, the marker is left unset rather than failing the job here — each wrapped action decides for itself whether a missing token is fatal (most error out; `run-phptests` skips reporting instead, since reporting failing tests is best-effort). Every action above forwards its own `github-token` input into its embedded `setup-reviewdog` step, so passing `github-token` to the wrapped action is enough; you don't need to configure it separately here.

## Inputs

### version

**Optional.** Version of reviewdog to install. Defaults to `v0.20.3`.

### github-token

**Optional.** GitHub token for reviewdog reporting. Falls back to a bare `GITHUB_TOKEN` env var when empty. Defaults to `github.token`.

## Outputs

This action has no outputs.

## Works well with

- [**run-phpstan**](../run-phpstan/README.md) — run PHPStan; already included automatically.
- [**run-pint**](../run-pint/README.md) — run Pint; already included automatically.
- [**run-phpinsights**](../run-phpinsights/README.md) — run PHP Insights; already included automatically.
- [**run-phpmd**](../run-phpmd/README.md) — run PHPMD; already included automatically.
- [**run-filacheck**](../run-filacheck/README.md) — run FilaCheck; already included automatically.
- [**run-phptests**](../run-phptests/README.md) — run the test suite; already included automatically.
- [**check-security-composer**](../check-security-composer/README.md) — audit Composer dependencies; already included automatically.
- [**check-security-npm**](../check-security-npm/README.md) — audit npm dependencies; already included automatically.
- [**check-lock**](../check-lock/README.md) — validate lock coherence; already included automatically.

## Example

```yaml
name: PR PHP Checks

on:
    pull_request:

jobs:
    phpstan:
        runs-on: ubuntu-latest
        steps:
            - uses: actions/checkout@v4

            - name: Setup Reviewdog toolchain
              uses: tomgrv/actions/setup-reviewdog@v1
              with:
                  version: v0.21.0

            - name: Run PHPStan
              uses: tomgrv/actions/run-phpstan@v1
              with:
                  github-token: ${{ secrets.GITHUB_TOKEN }}
```
