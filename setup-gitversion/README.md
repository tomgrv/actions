<!-- @format -->

# GitHub Action: Setup GitVersion

Idempotently installs the toolchain behind the
[`gitversion`](https://github.com/tomgrv/devcontainer-features/tree/main/src/gitversion)
devcontainer feature (a no-op if it's already on `PATH`): a docker-wrapped
[GitVersion](https://gitversion.net/) CLI, plus the
`gv`/`bump-tag`/`bump-changelog`/`bump-version` scripts, fetched directly from
that feature's source rather than run through its own installer — that
installer is built for onboarding a dev environment and deploys stub files
(`.gitattributes`, `package.json` merges, VS Code tasks, skills) into the
checked-out repo, unwanted noise for a CI release job that only needs the CLI
tools on `PATH`.
`git-release-beta`/`git-release-prod` (from
[`tomgrv/scripts`](https://github.com/tomgrv/scripts)) call these directly to
compute the release version and bump the changelog/tag — they're a separate
dependency from the scripts themselves, so `release-promote` installs this
alongside [`setup-scripts`](../setup-scripts/README.md), not instead of it.

The target repo must have a `.gitversion` config file at its root (see
`tomgrv/actions/.gitversion` for the family's shared bump-message rules) —
`gv` hardcodes `-config ".gitversion"`.

## Inputs

None.

## Works well with

- [**release-promote**](../release-promote/README.md) — installs this
  alongside `setup-scripts` before running `git-release-beta`/`git-release-prod`.

## Local Usage

```yaml
steps:
    - uses: tomgrv/actions/setup-gitversion@v1

    - run: gv -showvariable MajorMinorPatch
```
