<!-- @format -->

# GitHub Action: Clean Branches

Deletes branches whose linked pull request is closed, keeping protected branches untouched.

## Inputs

### protected-branches

Optional. Comma-separated list of branch names that must never be deleted, even if linked to a closed PR. Defaults to `main,master,develop`.

### merged-only

Optional. When `true`, only delete branches whose PR was merged. When `false` (default), also delete branches whose PR was closed without merging.

## Outputs

### deleted-branches

Newline-separated list of deleted branch names. Empty when none were deleted.

### count

Number of branches deleted.

> **Note**: Up to 500 recent pull requests are inspected. Branches from forked repositories and branches still referenced by an open PR are never deleted.

## Usage

```yaml
- name: Clean branches
  uses: tomgrv/actions/clean-branches@v2
  with:
      github-token: ${{ secrets.GITHUB_TOKEN }}
```

```yaml
- name: Clean merged branches only
  uses: tomgrv/actions/clean-branches@v2
  with:
      github-token: ${{ secrets.GITHUB_TOKEN }}
      protected-branches: main,develop,staging
      merged-only: 'true'
```
