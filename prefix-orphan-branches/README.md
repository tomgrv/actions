<!-- @format -->

# GitHub Action: Prefix Orphan Branches

Renames every remote branch that does not follow the gitflow config and has no pull request (open, merged or closed) to `orphan/<name>`. Wraps [`git-fix-orphans`](https://github.com/tomgrv/scripts/tree/main/git-fix-orphans).

Compliant branches are left untouched: the master/develop branches, the repository's default branch, anything starting with a gitflow prefix (`feature/`, `bugfix/`, `release/`, `hotfix/`, `support/`) or the orphan prefix, and any branch that is or was the head of a pull request. A rename that would collide with an existing branch is skipped.

## Inputs

### github-token

Required. Token with `contents: write` and `pull-requests: read` permissions.

### prefix

Optional. Prefix prepended to orphan branch names. Defaults to `orphan/`.

### master-branch / develop-branch

Optional. Branches git-flow treats as production and develop. Default to `main` and `develop`.

### init-gitflow

Optional. When `true` (default), initializes git-flow with the branch inputs and default prefixes first. When `false`, only a git-flow config already present on the runner is used, and nothing is renamed without one.

### dry-run

Optional. When `true`, only lists the branches that would be renamed. Defaults to `false`.

## Outputs

### renamed-branches

Newline-separated `old -> new` renames (planned ones on a dry run). Empty when none.

### count

Number of branches renamed.

## Usage

```yaml
- name: Checkout
  uses: actions/checkout@v7
  with:
      fetch-depth: 0

- name: Prefix orphan branches
  uses: tomgrv/actions/prefix-orphan-branches@v2
  with:
      github-token: ${{ secrets.GITHUB_TOKEN }}
```
