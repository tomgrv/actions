<!-- @format -->

# GitHub Action: Validate PR Format

Validates pull request title format against the Conventional Commits specification. When `fix: true` and a GitHub token is provided, a title that can be normalized (via devmoji) is autocorrected and pushed back to the PR instead of failing; an error is only raised when the title still fails validation after normalization, or when it can't be pushed back (fork PR or missing token).

## Inputs

### github-token

**Optional.** GitHub token used to update the PR title when normalization is needed. Defaults to `github.token`.

### fix

**Optional.** When `true`, autocorrect the PR title (via devmoji) and push it back to the PR when possible, instead of only reporting the expected format. Defaults to `false`.

## Outputs

This action has no outputs.

## Works well with

- [**check-secret**](../check-secret/README.md) — scan pull request changes for leaked secrets.
- [**check-security-composer**](../check-security-composer/README.md) — audit Composer dependency security.
- [**check-security-npm**](../check-security-npm/README.md) — audit npm dependency security.

## GitLab CI

When `GITLAB_CI=true`, the merge request title is read and updated through the GitLab REST API (`curl`) instead of the `gh` CLI. Run it with `zz-use -x tomgrv/actions/check-pr-format` and set `REPO` (`$CI_PROJECT_PATH`), `PR_TITLE` (`$CI_MERGE_REQUEST_TITLE`), `PR_NUMBER` (`$CI_MERGE_REQUEST_IID`), `HEAD_REPO_FULL_NAME` (`$CI_MERGE_REQUEST_SOURCE_PROJECT_PATH`), `FIX`, and `GITLAB_TOKEN`: a project access token with the `api` scope, as the CI job token cannot edit merge requests. Without a token, the title is only validated.

## Local Usage

Run this action locally from a clone of this repository with [`zz-use`](https://github.com/tomgrv/scripts/tree/main/zz-use):

```sh
zz-use -x ./check-pr-format
```

Required environment variables must be set before running. See [Inputs](#inputs) for details.

## Example

```yaml
name: PR Format Check

on:
    pull_request:
        types: [opened, edited, synchronize, reopened]

jobs:
    check-pr-format:
        runs-on: ubuntu-latest
        steps:
            - name: Validate PR title format
              uses: tomgrv/actions/check-pr-format@v5
              with:
                  github-token: ${{ secrets.GITHUB_TOKEN }}
                  fix: true
```
