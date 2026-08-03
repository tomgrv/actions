<!-- @format -->

# GitHub Action: Validate PR Lock

Checks that lock files are coherent with the manifests they were generated from, and reports drift inline via reviewdog.

For each directory in `paths`, the action runs whichever checks apply:

| Manifest       | Lock file           | Check                                                          |
| -------------- | ------------------- | -------------------------------------------------------------- |
| `composer.json` | `composer.lock`     | `composer validate` — compares the lock `content-hash`          |
| `package.json`  | `package-lock.json` | `npm ci --dry-run --package-lock-only` — the check CI itself runs |

Both checks are read-only: nothing is installed and no lock file is rewritten. `--workspaces` is added only when the manifest declares workspaces, and each ecosystem is skipped when its lock file is absent.

This catches the case where a pull request edits a manifest but forgets to regenerate the lock — a drift that stays invisible until a later `npm ci` or `composer install` fails in an unrelated workflow.

## Inputs

### github-token

**Required.** GitHub token for reviewdog reporting.

### paths

**Optional.** Comma-separated list of directories to check for lock files. Defaults to `.`.

### reviewdog-version

**Optional.** Version of reviewdog to install. Defaults to `v0.20.3`.

### level

**Optional.** Report level for reviewdog `[info,warning,error]`. Defaults to `error`.

### reporter

**Optional.** Reporter of reviewdog command `[github-pr-check,github-check,github-pr-review]`. Defaults to `github-pr-check`.

### filter-mode

**Optional.** Filtering mode for the reviewdog command `[added,diff_context,file,nofilter]`. Defaults to `nofilter`.

### fail-level

**Optional.** Exit code for reviewdog if it finds at least the specified level `[none,any,info,warning,error]`. Defaults to `error`, so lock drift fails the job.

### reviewdog-flags

**Optional.** Additional reviewdog flags. Defaults to empty.

## Outputs

### has-drift

`true` if at least one lock file is out of sync, `false` otherwise.

### drift-files

Comma-separated list of the lock files that are out of sync.

## Works well with

- [**setup-node**](../setup-node/README.md) — provides `npm`. Note that its dependency install step already runs `npm ci`, so place this action **before** it if you want the readable annotation rather than a raw `EUSAGE` failure.
- [**setup-php**](../setup-php/README.md) — provides `composer`.
- [**check-composer**](../check-composer/README.md) — runs the full `composer validate --strict` (schema, publish and lock). Use this action instead when you want the same lock guarantee on the npm side too, reported uniformly.

If a lock file is present but its tool is not on the runner, the action reports that as an error rather than silently passing.

## Local Usage

Run this action locally using the root `npx @tomgrv/actions` dispatcher:

```sh
npx @tomgrv/actions check-lock
npx @tomgrv/actions check-lock .,packages/foo
```

Required environment variables must be set before running. See [Inputs](#inputs) for details.

## Example

```yaml
name: PR Checks

on:
    pull_request:
        types: [opened, synchronize, reopened, ready_for_review]

jobs:
    validate-lock:
        runs-on: ubuntu-latest
        steps:
            - uses: actions/checkout@v4

            - uses: actions/setup-node@v6
              with:
                  node-version: 24

            - name: Validate lock coherence
              uses: tomgrv/actions/check-lock@v1
              with:
                  github-token: ${{ secrets.GITHUB_TOKEN }}
```
