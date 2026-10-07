<!-- @format -->

# Upgrading

How to ship, and consume, a **breaking change** in the scripts that these
composite actions bootstrap, without deadlocking CI or releases. Written from
the v3.0.0 release (`tomgrv/scripts` v1: `zz_*` → `zz-*`,
`<verb>-json|yaml` → `json-<verb>|yaml-<verb>`). The full rename tables and the
renaming-repo checklist live in
[`tomgrv/scripts/UPGRADING.md`](https://github.com/tomgrv/scripts/blob/main/UPGRADING.md).

## Why a major is required

Every action here that installs scripts goes through `setup-scripts`, which
bootstraps `tomgrv/scripts` **`main`**. When script names change, the
previously published actions (`@v2`) call `zz_use`, which no longer exists, and
fail with `setup-scripts/run.sh: zz_use: not found`. Floating tags only move
within a major, so the breaking release must be a new major (`v3`) and every
consumer must move off `@v2`.

| Repo             | Before | After  |
| ---------------- | ------ | ------ |
| `tomgrv/scripts` | v0.34  | v1.0.0 |
| `tomgrv/actions` | v2.46  | v3.0.0 |

## Order of operations

1. **scripts** is merged and released first (its `main` carries the new names).
2. **This repo** — merge the rename PR. Its checks are red by construction (they
   run the old published `@v2`); merging red needs an explicit decision.
3. **Bootstrap the release from the checked-out code.** In
   `.github/workflows/release-prod.yml` use `uses: ./release-promote` (checkout
   is `develop`) instead of `tomgrv/actions/release-promote@v<old>`: the old
   tag's `setup-scripts` cannot run against the new scripts.
4. Dry run (`dry_run: true`), then the real `release-prod`. Confirm the new
   `v<major>` tags.
5. Follow-up PR: move every remaining `@v<old>` and `scripts-ref: v<old>`
   (workflows, action files, docs, stubs) to the new majors; merge when green;
   patch release. `$/<name>` self-references in composite actions need no change.

## Checklist in this repo

1. Rewrite script names in every `run.sh`, `action.yml`, workflow, README and
   `run.bats` — regular files only (never `sed -i` through symlinks), skipping
   `CHANGELOG.md` and `package-lock.json`.
2. `setup-scripts` `scripts:` inputs and defaults use the new names
   (`zz-log zz-npx`).
3. Bats stubs that define a script as a shell **function** must become
   executables: `sh` cannot define `zz-log() { … }`.
4. Merge `develop` right before finishing — actions added meanwhile (e.g.
   `prefix-orphan-branches`) still reference old names.
5. PR title scope must be one of the action folder names (e.g. `setup-scripts`),
   header ≤ 100 chars. Squash-merge with `!` in the title and a
   `BREAKING CHANGE:` footer.
6. Run `bats` with a fresh cache (`ZZ_CACHE_DIR=$(mktemp -d)`) and compare any
   failure with the pre-change commit — `config-bot` and `detect-changes` fail
   in minimal containers regardless of the rename.

## Pitfalls we hit

- A check re-run reuses the original event payload (old PR title): push, or
  mark the PR ready for review.
- Ready-for-review starts checks that never ran on the draft.
- Pinning an old `release-promote` (`@v2.22.0`) does **not** protect a release:
  it still bootstraps `scripts` `main`. Move to the new major.
- After a squash merge the remote branch can survive; before reusing the name
  verify its tree equals `develop`, then `--force-with-lease`.

## Upgrading a consuming workflow

```sh
grep -rn -E 'tomgrv/actions[^ ]*@v2|scripts-ref: v0' .github
```

Change `@v2` → `@v3` and `scripts-ref: v0` → `v1` together, rename any script
you call directly, and run the workflow once with `workflow_dispatch`.
Rollback is the reverse, again **together**.
