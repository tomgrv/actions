<!-- @format -->

# GitHub Action: Validate PR Source Branch

Rejects pull requests whose source branch is the restricted branch (`main` by default) unless the PR title marks them as a hotfix. Enforces that regular development PRs come from the default development branch, reserving direct PRs from `main` for emergency fixes.

## Inputs

### restricted-branch

**Optional.** Branch name that requires a hotfix-marked title when used as a PR source. Defaults to `main`.

## Outputs

This action has no outputs.

## Local Usage

Run this action locally using the root `./dispatch.sh` dispatcher:

```sh
./dispatch.sh check-pr-source-branch
```

Required environment variables must be set before running. See [Inputs](#inputs) for details.

## Example

```yaml
name: Validate PR Source Branch

on:
    pull_request:
        types: [opened, reopened, synchronize]

jobs:
    validate-source:
        runs-on: ubuntu-latest
        steps:
            - name: Validate PR source branch
              uses: tomgrv/actions/check-pr-source-branch@v1
```

## Behavior

- Passes silently when the PR source branch is not the restricted branch.
- Passes when the source branch is the restricted branch and the PR title contains `hotfix`.
- Fails with a `::error::` annotation, explaining the rule, when the source branch is the restricted branch and the title is not marked as a hotfix.
