<!-- @format -->

# GitHub Action: Setup Scripts

Idempotently bootstraps [`tomgrv/scripts`](https://github.com/tomgrv/scripts)'s
`zz_use` activator (a no-op if it's already on `PATH`), then optionally
installs a specific list of its scripts — pinned to one shared ref, if
given — so later steps in the job can call them directly.

## Inputs

### scripts

**Optional.** Space-separated `tomgrv/scripts` tool names to `zz_use`
after bootstrapping (e.g. `git-release-beta git-release-prod`). Leave
empty to only bootstrap `zz_use` itself, without installing anything.

### scripts-ref

**Optional.** `tomgrv/scripts` ref (tag/branch/commit) every name in
`scripts` is pinned to, applied as `<name>@<ref>`. Leave empty to use
each script's own default origin/ref (its repo's default branch).

### scripts-branch

**Optional.** Branch to fetch `tomgrv/scripts` `setup.sh` from when
bootstrapping `zz_use` (default `main`, typically overridden to a
development branch during integration testing).

## Works well with

- [**release-promote**](../release-promote/README.md) — uses this action
  to install `git-release-beta`/`git-release-prod` before running them.

## Local Usage

```yaml
steps:
    - uses: tomgrv/actions/setup-scripts@v1
      with:
          scripts: validate-json merge-json
          scripts-ref: v2

    - run: validate-json --help
```
