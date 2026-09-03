<!-- @format -->

# GitHub Action: Release Promote

Runs `git-release-beta` then `git-release-prod` — the git-flow beta→prod
promotion every `tomgrv`/`perspikapps` repo releases through — against
the already-checked-out repo. Pulls both commands from
[`tomgrv/scripts`](https://github.com/tomgrv/scripts#git-utilities)
(pinned via `scripts-ref`, via [`setup-scripts`](../setup-scripts/README.md))
and installs both the [GitVersion toolchain](../setup-gitversion/README.md)
and [git-flow itself](../setup-gitflow/README.md), which those scripts
depend on to compute the release version, bump the changelog/tag, and drive
the actual `git flow release start`/`finish` calls — instead of installing
a whole devcontainer feature for any of it.

Assumes the caller has already checked out the repo (`fetch-depth: 0`,
`ref: develop`) — this action doesn't do that itself, since checkout
options (e.g. `token`, `persist-credentials`) are workflow-level concerns.

## Inputs

### scripts-ref

**Required.** `tomgrv/scripts` ref (tag/branch/commit) to pull
`git-release-beta`/`git-release-prod` from.

### dry-run

**Optional.** When `true`, installs the release scripts but stops before
running them, so nothing gets pushed to `main`. Defaults to `false`.

### github-token

**Optional.** GitHub token used for the release push and to configure the
git bot identity (via [`config-bot`](../config-bot/README.md)). Defaults
to `github.token`.

## Tag/branch protection

`git-release-prod` merges to `main` and pushes a version tag. If a
protected `main`/tag rejects that push, this action fails with a clear
`::error::` pointing back here — see
[`tomgrv/actions`'s release-process doc](../docs/release-process.md) for
the bypass checklist every repo in this family needs applied once, by
hand.

## Local Usage

```yaml
jobs:
    release-main:
        runs-on: ubuntu-latest
        permissions:
            contents: write
        steps:
            - uses: actions/checkout@v6
              with:
                  fetch-depth: 0
                  ref: develop

            - uses: tomgrv/actions/release-promote@v1
              with:
                  scripts-ref: v1
                  dry-run: ${{ inputs.dry_run == true }}
```
