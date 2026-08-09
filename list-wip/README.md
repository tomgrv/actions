<!-- @format -->

# GitHub Action: List WIP Files

Lists files changed on the current pull request — diffed against the merge-base of a base branch — optionally restricted to a set of paths and file extensions. Used by the `wip` input of [**run-phpstan**](../run-phpstan/README.md), [**run-pint**](../run-pint/README.md), [**run-phpinsights**](../run-phpinsights/README.md), [**run-phpmd**](../run-phpmd/README.md) and [**run-filacheck**](../run-filacheck/README.md) to scan only the files touched by the pull request, instead of a whole directory tree.

## Inputs

### path

**Optional.** Comma-separated list of paths to restrict the list to. Defaults to `.` (whole repository).

### extensions

**Optional.** Comma-separated list of file extensions to keep, without the leading dot. Defaults to `php`.

### base-ref

**Optional.** Base branch/ref to diff against. Defaults to `GITHUB_BASE_REF`, which GitHub Actions sets automatically on `pull_request` events. Fails with an error when neither is available.

## Outputs

- `files`: Newline-separated list of matching changed files. Empty when none match.
- `count`: Number of matching files.
- `has-files`: `true` if at least one file matches, `false` otherwise.

## Works well with

- [**list-dirty**](../list-dirty/README.md) — the working-tree equivalent, listing uncommitted changes instead of the full pull-request diff.
- [**run-phpstan**](../run-phpstan/README.md), [**run-pint**](../run-pint/README.md), [**run-phpinsights**](../run-phpinsights/README.md), [**run-phpmd**](../run-phpmd/README.md), [**run-filacheck**](../run-filacheck/README.md) — wrap this action behind their own `wip` input.

## Local Usage

Run this action locally using the root `./dispatch.sh` dispatcher:

```sh
GITHUB_BASE_REF=main ./dispatch.sh list-wip
```

## Example

```yaml
- name: List WIP PHP files
  id: wip
  uses: tomgrv/actions/list-wip@v1
  with:
      path: app,config

- name: Use the list
  if: steps.wip.outputs.has-files == 'true'
  run: echo "${{ steps.wip.outputs.files }}"
```
