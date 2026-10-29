<!-- @format -->

# GitHub Action: Clean Branches

Deletes branches whose linked pull request is closed, keeping protected branches untouched.

## Inputs

### protected-branches

Optional. Comma-separated list of branch names that must never be deleted, even if linked to a closed PR. Defaults to `main,master,develop`.

### merged-only

Optional. When `true`, only delete branches whose PR was merged. When `false` (default), also delete branches whose PR was closed without merging.

### github-token

**Required.** GitHub token with contents:write and pull-requests:read permissions.

## Outputs

### deleted-branches

Newline-separated list of deleted branch names. Empty when none were deleted.

### count

Number of branches deleted.

> **Note**: Up to 500 recent pull requests are inspected. Branches from forked repositories and branches still referenced by an open PR are never deleted.

## Usage

```yaml
- name: Clean branches
  uses: tomgrv/actions/clean-branches@v5
  with:
      github-token: ${{ secrets.GITHUB_TOKEN }}
```

```yaml
- name: Clean merged branches only
  uses: tomgrv/actions/clean-branches@v5
  with:
      github-token: ${{ secrets.GITHUB_TOKEN }}
      protected-branches: main,develop,staging
      merged-only: "true"
```

## GitLab CI

Inside GitLab CI (`GITLAB_CI=true`) the merge requests and branches go through the GitLab REST API (`curl`, `jq`) instead of `gh`: merged and closed merge requests whose source branch lives in the project are cleaned the same way. Set `GITLAB_TOKEN` to a project access token with the `api` scope; `REPO` defaults to `$CI_PROJECT_PATH`.

## Local Usage

Run this action locally from a clone of this repository with [`zz-use`](https://github.com/tomgrv/scripts/tree/main/zz-use):

```sh
zz-use -x ./clean-branches
```

See [Inputs](#inputs) for the environment variables to set.

## Example

```yaml
- uses: tomgrv/actions/clean-branches@v5
  with:
      github-token: <github-token>
```
