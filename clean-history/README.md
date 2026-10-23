<!-- @format -->

# GitHub Action: Clean Workflow History

Removes old workflow run history for all or selected workflows in a repository.
Keeps at least the last **N days** of history and the last **N most-recent runs** per workflow — whichever set is larger.

## Inputs

### min-days

Optional. Minimum number of complete days to keep. Defaults to `10`.

### min-runs

Optional. Minimum number of most-recent runs to keep per workflow, regardless of age. Defaults to `10`.

### workflows

Optional. Comma-separated list of workflow file names to clean (e.g. `deploy.yml,clean.yml`). Defaults to all workflows in the repository.

> **Note**: Up to 500 recent runs are inspected per workflow. Repositories with extremely high run counts may retain some older runs beyond this window.

### github-token

**Required.** GitHub token with actions:read and actions:write permissions.

## Usage

```yaml
- name: Clean workflow history
  uses: tomgrv/actions/clean-history@v5
  with:
      min-days: "10"
      min-runs: "10"
```

```yaml
- name: Clean specific workflows
  uses: tomgrv/actions/clean-history@v5
  with:
      workflows: deploy.yml,clean.yml,split.yml
      min-days: "10"
      min-runs: "10"
```

## Local Usage

Run this action locally from a clone of this repository with [`zz-use`](https://github.com/tomgrv/scripts/tree/main/zz-use):

```sh
zz-use -x ./clean-history
```

See [Inputs](#inputs) for the environment variables to set.

## Example

```yaml
- uses: tomgrv/actions/clean-history@v5
  with:
      github-token: <github-token>
```
