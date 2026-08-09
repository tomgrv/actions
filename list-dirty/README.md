<!-- @format -->

# GitHub Action: List Dirty Files

Lists files with uncommitted git changes — staged, unstaged, or untracked — optionally restricted to a set of paths and file extensions. Used by the `dirty` input of [**run-phpstan**](../run-phpstan/README.md), [**run-pint**](../run-pint/README.md), [**run-phpinsights**](../run-phpinsights/README.md) and [**run-phpmd**](../run-phpmd/README.md) to scan only the files someone is actively working on, instead of a whole directory tree.

## Inputs

### path

**Optional.** Comma-separated list of paths to restrict the list to. Defaults to `.` (whole repository).

### extensions

**Optional.** Comma-separated list of file extensions to keep, without the leading dot. Defaults to `php`.

## Outputs

- `files`: Newline-separated list of matching dirty files. Empty when none match.
- `count`: Number of matching files.
- `has-files`: `true` if at least one file matches, `false` otherwise.

## Works well with

- [**list-wip**](../list-wip/README.md) — the pull-request equivalent, listing files changed relative to a base branch instead of the working tree.
- [**run-phpstan**](../run-phpstan/README.md), [**run-pint**](../run-pint/README.md), [**run-phpinsights**](../run-phpinsights/README.md), [**run-phpmd**](../run-phpmd/README.md) — wrap this action behind their own `dirty` input.

## Local Usage

Run this action locally using the root `./dispatch.sh` dispatcher:

```sh
./dispatch.sh list-dirty
```

## Example

```yaml
- name: List dirty PHP files
  id: dirty
  uses: tomgrv/actions/list-dirty@v1
  with:
      path: app,config
      extensions: php

- name: Use the list
  if: steps.dirty.outputs.has-files == 'true'
  run: echo "${{ steps.dirty.outputs.files }}"
```
