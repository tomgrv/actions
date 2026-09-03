<!-- @format -->

# GitHub Action: Setup GitFlow

Installs the [git-flow](https://github.com/petervanderdoes/gitflow-avh)
extension if it's missing (a no-op if it's already on `PATH`), then runs
`git flow init` against the checked-out repo. `git-release-beta`/
`git-release-prod` (from [`tomgrv/scripts`](https://github.com/tomgrv/scripts))
call `git flow release start`/`git flow <flow> finish` directly — both the
`git-flow` binary and its local git config (`gitflow.branch.*`/
`gitflow.prefix.*`) are otherwise missing on a bare CI checkout; a
developer's own devcontainer normally sets this up once, locally, which a
CI runner never inherits.

`git flow init` here always runs (not just after a fresh install) since
that config lives in the checkout's own `.git/config`, not on the runner
image — every job starts from zero.

## Inputs

### master-branch

**Optional.** Branch git-flow treats as production/master. Defaults to `main`.

### develop-branch

**Optional.** Branch git-flow treats as develop. Defaults to `develop`.

## Works well with

- [**release-promote**](../release-promote/README.md) — installs and
  initializes git-flow before running `git-release-beta`/`git-release-prod`.

## Local Usage

```yaml
steps:
    - uses: tomgrv/actions/setup-gitflow@v1

    - run: git flow release start 1.2.3
```
