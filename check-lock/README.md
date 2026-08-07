<!-- @format -->

# GitHub Action: Validate PR Lock

Checks that a repository's dependency manifests and lock files are coherent, and reports problems inline via reviewdog. reviewdog itself is set up automatically via [**setup-reviewdog**](../setup-reviewdog/README.md); the setup is skipped if it already ran earlier in the job.

For each directory in `paths`, the action runs whichever checks apply:

| Manifest        | Lock file           | Check                                                                                     |
| --------------- | -------------------- | ------------------------------------------------------------------------------------------ |
| `composer.json` | `composer.lock` (optional) | `composer validate --strict` — schema, publish-readiness, and lock content-hash coherence, all in one pass |
| `package.json`  | `package-lock.json`  | `npm ci --dry-run --package-lock-only` — the check CI itself runs                          |

Both are read-only: nothing is installed and no lock file is rewritten. `--workspaces` is added to the npm check only when `package.json` declares workspaces. `composer.lock` is optional — packages and libraries commonly don't commit one, and `composer.json` is still validated in that case; `package-lock.json` is required for the npm check to run at all.

The composer.json findings are split by what `validate --strict` itself calls them: bullets under a "warnings" section (e.g. missing license, unbound version constraints) are reported as `WARNING`; everything else — lock drift, publish errors (missing description), schema errors — is `ERROR`. `fail-level` defaults to `error`, so warnings annotate without failing the job while lock drift and schema/publish errors do fail it.

This catches the case where a pull request edits a manifest but forgets to regenerate the lock — a drift that stays invisible until a later `npm ci` or `composer install` fails in an unrelated workflow — as well as the schema/publish-readiness problems `composer validate --strict` has always caught.

## Inputs

### github-token

**Required.** GitHub token for reviewdog reporting.

### paths

**Optional.** Comma-separated list of directories to check for lock files. Defaults to `.`.

### reviewdog-version

**Optional.** Version of reviewdog to install. Defaults to `v0.20.3`.

### name

**Optional.** Name reported by reviewdog to identify this check. Defaults to `lock-coherence`.

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

`true` if at least one finding was reported (lock drift, a schema/publish problem, or a warning), `false` otherwise. This is broader than literal lock drift: it is also `true` when the check itself couldn't run — the required tool is missing from the runner, or the validator command failed for some other reason (malformed manifest, registry/config error, unsupported lockfile version). In every case the annotation explains which of these happened. It does not by itself mean the job failed — check `fail-level` for that; a warnings-only result sets `has-drift=true` but passes with the default `fail-level: error`.

### drift-files

Comma-separated list of the files that triggered a finding above (`composer.json`, `composer.lock`, or `package-lock.json`).

## Works well with

- [**setup-reviewdog**](../setup-reviewdog/README.md) — included automatically; add it explicitly only to pass a custom `version`.
- [**setup-node**](../setup-node/README.md) — provides `npm`. Note that its dependency install step already runs `npm ci`, so place this action **before** it if you want the readable annotation rather than a raw `EUSAGE` failure.
- [**setup-php**](../setup-php/README.md) — provides `composer`.

If a lock file's tool is not on the runner, the action reports that as an error rather than silently passing.

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
