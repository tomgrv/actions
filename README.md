<!-- @format -->

# tomgrv/actions

Reusable GitHub Actions for CI: PR checks, PHP and Laravel quality tools,
monorepo packaging, releases and repository housekeeping. Each action is a
composite action you call straight from a workflow.

## Quick start

```yaml
name: PR checks

on:
    pull_request:
        types: [opened, reopened, ready_for_review, synchronize]

jobs:
    checks:
        runs-on: ubuntu-latest
        steps:
            - uses: actions/checkout@v7
            - uses: tomgrv/actions/check-pr-format@v5
              with:
                  fix: true
            - uses: tomgrv/actions/check-pr-source-branch@v5
            - uses: tomgrv/actions/check-secret@v5
```

Use `@v5` for the latest 5.x, or pin an exact tag or commit. Every action's
README lists its inputs, outputs and a ready-to-copy example.

## Run an action on your machine

With [`zz-use`](https://github.com/tomgrv/scripts/tree/main/zz-use), no clone needed:

```sh
zz-use -x tomgrv/actions/list-packages@v5
```

From a clone of this repository:

```sh
GITHUB_TOKEN=ghp_xxx zz-use -x ./check-lock
zz-use -x ./detect-changes
```

Set the `GITHUB_*` variables or inputs the action reads before running it.

## Actions

### 🚀 Release

- [**release-promote**](release-promote/README.md) _(beta)_: Run git-release-beta then git-release-prod (git-flow beta→prod promotion).

### 🔧 Utils

- [**config-bot**](config-bot/README.md): Configure git bot identity and authentication for CI/CD.
- [**setup-scripts**](setup-scripts/README.md) _(beta)_: Idempotently bootstrap `zz-use` from `tomgrv/scripts`, optionally installing specific scripts.
- [**setup-gitversion**](setup-gitversion/README.md) _(beta)_: Idempotently install the `gitversion` devcontainer feature's toolchain (GitVersion CLI plus `gv`/`bump-tag`/`bump-changelog`/`bump-version`).
- [**setup-gitflow**](setup-gitflow/README.md) _(beta)_: Install the git-flow extension if missing, then initialize it against the checked-out repo.
- [**setup-php**](setup-php/README.md): Setup PHP, Composer, and extensions as per composer for CI jobs.
- [**setup-node**](setup-node/README.md): Setup Node.js and npm for CI jobs.
- [**setup-reviewdog**](setup-reviewdog/README.md): Setup reviewdog for CI jobs.
- [**resolve-environment**](resolve-environment/README.md) _(experimental)_: Resolve the deploy branch, tag, and environment from the triggering GitHub event.
- [**run-deployer**](run-deployer/README.md) _(experimental)_: Install PHP Deployer and run a `dep` command, reporting warnings/errors via reviewdog.

### 📦 Monorepo

- [**list-packages**](list-packages/README.md): List all composer/npm packages in a monorepo.
- [**degit-package**](degit-package/README.md): Import the latest source branch content into a package repository and prune unwanted folders.
- [**split-package**](split-package/README.md): Split a monorepo package to a separate repository based on path.
- [**publish-npm**](publish-npm/README.md): Publish a package to npm registry using GitHub's OIDC trusted publishers.
- [**run-workspace-tests**](run-workspace-tests/README.md): Run a workspace's .scripts.test entry (from each root \*.json file) as its test suite.

### 🐘 PHP Check

- [**check-laravel**](check-laravel/README.md) _(beta)_: Run the standard Laravel PHP check suite (PHPStan, Pint, PHP Insights, PHPMD, tests) and report via reviewdog.
- [**check-filament**](check-filament/README.md) _(beta)_: Run Filament-specific checks (FilaCheck) and report via reviewdog.
- [**run-phpinsights**](run-phpinsights/README.md): Run PHP Insights via reviewdog for inline code review feedback.
- [**run-filacheck**](run-filacheck/README.md): Run FilaCheck via reviewdog for inline Filament code review feedback.
- [**run-phpstan**](run-phpstan/README.md): Run PHPStan via reviewdog for inline code review feedback.
- [**run-phpmd**](run-phpmd/README.md): Run PHP Mess Detector and report via reviewdog.
- [**run-pint**](run-pint/README.md): Run Laravel Pint code style checks and report via reviewdog.
- [**run-phptests**](run-phptests/README.md): Run the PHP test suite.
- [**check-security-composer**](check-security-composer/README.md): Audit Composer dependencies for known vulnerabilities.
- [**list-dirty**](list-dirty/README.md) _(beta)_: List files with uncommitted git changes, used by the PHP checks' `dirty` input.
- [**list-wip**](list-wip/README.md) _(beta)_: List files changed on the current pull request, used by the PHP checks' `wip` input.
- [**list-php-parts**](list-php-parts/README.md) _(beta)_: List the PHP test parts (core, modules, packages) affected by a change, as a matrix for per-part test jobs.

### 🔀 Pull Request

- [**create-pr**](create-pr/README.md): Open or update a pull request for a branch, with customizable title/body/labels.
- [**rebase-pr**](rebase-pr/README.md): Rebase the head branch of a pull request onto its base branch.
- [**check-pr-format**](check-pr-format/README.md): Validate PR title and body format.
- [**check-pr-source-branch**](check-pr-source-branch/README.md) _(beta)_: Reject PRs from the main branch unless marked as a hotfix.
- [**check-secret**](check-secret/README.md): Scan pull request changes for leaked secrets.
- [**check-security-npm**](check-security-npm/README.md): Audit npm dependencies for known vulnerabilities.
- [**check-lock**](check-lock/README.md) _(beta)_: Validate composer.json/composer.lock and package.json/package-lock.json — schema, publish-readiness, and lock coherence — via reviewdog.
- [**check-dockerfile**](check-dockerfile/README.md): Validate Dockerfile against 6 production best practices
- [**confirm-pr-comment**](confirm-pr-comment/README.md): Add a reaction emoji to the current GitHub event comment.
- [**create-pr-comment**](create-pr-comment/README.md): Post a new comment on a pull request or issue.
- [**reply-pr-comment**](reply-pr-comment/README.md): Post a comment on a pull request or issue, referencing the comment that triggered the workflow.

### 🏷️ Repository Management

- [**update-labels**](update-labels/README.md): Create or update repository labels from a JSON file or comma-separated list.
- [**detect-changes**](detect-changes/README.md): Detect uncommitted or untracked changes in a given path.
- [**clean-branches**](clean-branches/README.md): Delete branches whose linked pull request is closed (merged or not).
- [**clean-history**](clean-history/README.md): Remove old workflow run history, keeping at least a minimum number of days and runs per workflow.
- [**create-update-ref**](create-update-ref/README.md): Create a git ref (tag/branch). If it already exists, updates it to point at the given SHA.
- [**prefix-orphan-branches**](prefix-orphan-branches/README.md): Rename remote branches that do not follow the gitflow config and have no pull request to orphan/<name>.

`run-*` actions analyse the files they are given and report through reviewdog on
those files. `check-*` actions validate repository or pull-request state.

## Release a repository

Run **Actions → release-prod → Run workflow** in the repository: it calls
[**release-promote**](release-promote/README.md), which cuts the beta and promotes it to production.

## Contributing

Each action is a folder with `action.yml`, `run.sh`, `README.md` and a
`run.bats` test. Run all tests with `./.repo/tests/run-tests.sh`, or one with
`./.repo/tests/run-tests.sh -f <action>`. Pull requests target `develop`.
Breaking changes and major bumps: [`UPGRADING.md`](UPGRADING.md).

## License

MIT.
