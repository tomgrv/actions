<!-- @format -->

# Release process

Every `tomgrv`/`perspikapps` repo in this family (`devcontainer-features`,
`actions`, `scripts`, `vps`) releases the same way: **GitHub → Actions →
`release-main` → "Run workflow"** — a `workflow_dispatch` button in the
GitHub web UI, no `gh`/`git` CLI required. Each repo's own
`.github/workflows/release-main.yml` is a thin wrapper that calls this
repo's [`release-promote.yml`](../.github/workflows/release-promote.yml)
reusable workflow, which pulls `git-release-beta`/`git-release-prod` from
[`tomgrv/scripts`](https://github.com/tomgrv/scripts) (pinned via the
caller's `scripts_ref` input) and runs them non-interactively.

This replaced four independently-drifting copies of the same
`git beta && git prod` logic (different `setup-node` pins, an unpinned
`gitutils` install from a moving default branch) with one implementation,
pinned dependencies, and a `dry_run` input for safe verification.

## Tag/branch protection bypass checklist

`git-release-prod` merges to `main` and pushes a version tag. If a repo's
`main` (or its tags) is protected, that final push fails until the
workflow's identity is allowed past the protection. This has to be applied
by hand in each repo's settings — there's no API surface for it wired into
these workflows on purpose, since changing branch/tag protection is a
security-relevant setting a human should decide on, not something a
workflow silently bypasses.

For each of `devcontainer-features`, `actions`, `scripts`, and `vps`:

1. **Settings → Rules → Rulesets** (or **Settings → Branches** on the
   legacy UI) on the rule targeting `main`. If "Restrict pushes" or
   "Require a pull request" is active, add the `github-actions` app (the
   identity `release-promote.yml` commits and pushes as —
   `github-actions[bot]`) to that rule's **bypass list**.
2. If a **tag protection ruleset** exists (e.g. targeting `v*`), add the
   same bypass actor there too — otherwise the version tag push fails even
   once the branch push succeeds.
3. Expected failure signature before the bypass is applied: the "Run
   release beta then prod" step fails on the final push/tag with a
   protected-ref rejection. `release-promote.yml` prints a pointer back to
   this checklist when that happens.

## Verifying without releasing

Run `release-main` with `dry_run: true` to exercise everything up through
installing `git-release-beta`/`git-release-prod` without pushing to `main`
— useful for confirming a change to the shared workflow or a repo's
wrapper before trusting it with a real release.
