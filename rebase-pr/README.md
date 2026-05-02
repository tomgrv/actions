<!-- @format -->

# GitHub Action: Rebase Pull Request

This action rebases the head branch of a pull request onto its base branch using native `git rebase`. It is safe, fast, and avoids merge commits.

## Inputs

### github-token

**Required.** GitHub token with `pull_requests: write` and `contents: write` permissions.

### repository

**Optional.** Repository in the format `owner/name`. Defaults to the current repository (`github.repository`).

### pr-number

**Optional.** Pull request number to rebase. Defaults to the pull request number from the current event context (`github.event.pull_request.number`).

### autosquash

**Optional.** Whether to autosquash `fixup!` and `squash!` commits during rebase. Defaults to `false`.

## Outputs

- `head-branch`: Head branch of the rebased pull request.
- `base-branch`: Base branch onto which the pull request was rebased.
- `pr-number`: Pull request number that was rebased.
- `pr-url`: Pull request URL.
- `action`: Action taken by the workflow (`rebased`, `up-to-date`, or `skip`).

## Usage

### Rebase on comment trigger

```yaml
name: Rebase PR on comment

on:
  issue_comment:
    types: [created]

jobs:
  rebase:
    if: github.event.issue.pull_request && github.event.comment.body == '/rebase'
    runs-on: ubuntu-latest
    permissions:
      contents: write
      pull-requests: write
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
          token: ${{ secrets.GITHUB_TOKEN }}

      - name: Rebase PR
        uses: tomgrv/actions/rebase-pr@main
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
          pr-number: ${{ github.event.issue.number }}
```

### Rebase on PR update

```yaml
name: Rebase PR on base update

on:
  pull_request:
    types: [synchronize]

jobs:
  rebase:
    runs-on: ubuntu-latest
    permissions:
      contents: write
      pull-requests: write
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
          token: ${{ secrets.GITHUB_TOKEN }}

      - name: Rebase PR
        uses: tomgrv/actions/rebase-pr@main
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
          autosquash: 'true'
```
