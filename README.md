<!-- @format -->

# tomgrv/actions

![Docs](https://img.shields.io/badge/docs-updated-blue) ![License](https://img.shields.io/badge/license-MIT-green)

Reusable GitHub Actions

## Overview

tomgrv/actions is a suite of modular, reusable GitHub composite actions designed to automate code quality, PR management, and package maintenance for monorepos and composer-based projects. Each action is self-contained, follows strict output/logging conventions, and is documented for easy integration into your workflows.

Actions are consumed directly from a workflow with `uses: tomgrv/actions/<action-name>@<ref>` — this repository is never published to npm (every package here, including the root one, is `private: true`; npm workspaces exist only to manage this monorepo's own code and tooling). For local testing, any action with a `run.sh` can be run from a clone of this repository via the bundled `dispatch.sh`, which sets sensible `GITHUB_*` defaults:

```sh
./dispatch.sh <action> [args...]
```

For example:

```sh
# Run lock coherence validation locally
GITHUB_TOKEN=ghp_xxx ./dispatch.sh check-lock

# List monorepo packages
./dispatch.sh list-packages

# Detect uncommitted changes
./dispatch.sh detect-changes
```

Run without arguments to see all available actions:

```sh
./dispatch.sh
```

## Naming convention

`run-*` actions analyze specific files (a `paths`/`path` input scoped to what changed) and report via reviewdog with `-filter-mode=file`: findings are limited to files that are actually part of the run's scope, but not further restricted to changed lines. `check-*` actions validate repository- or PR-wide state (manifests, lock files, secrets, PR metadata) that isn't tied to a specific set of files, and report with `-filter-mode=nofilter`. Both are fixed by the action itself and are not exposed as a configurable input; only `reporter` remains configurable, and it defaults to the value [**setup-reviewdog**](setup-reviewdog/README.md) resolves for the run's context.

## Available Actions

> **Badge legend:**
> ![stable](https://img.shields.io/badge/stable-green) Stable &nbsp;
> ![beta](https://img.shields.io/badge/beta-yellow) Beta &nbsp;
> ![experimental](https://img.shields.io/badge/experimental-orange) Experimental

### 🔧 Utils

- [**config-bot**](config-bot/README.md) ![stable](https://img.shields.io/badge/stable-green): Configure git bot identity and authentication for CI/CD.
- [**setup-php**](setup-php/README.md) ![stable](https://img.shields.io/badge/stable-green): Setup PHP, Composer, and extensions as per composer for CI jobs.
- [**setup-node**](setup-node/README.md) ![stable](https://img.shields.io/badge/stable-green): Setup Node.js and npm for CI jobs.
- [**setup-reviewdog**](setup-reviewdog/README.md) ![stable](https://img.shields.io/badge/stable-green): Setup reviewdog for CI jobs.
- [**resolve-environment**](resolve-environment/README.md) ![experimental](https://img.shields.io/badge/experimental-orange): Resolve the deploy branch, tag, and environment from the triggering GitHub event.
- [**run-deployer**](run-deployer/README.md) ![experimental](https://img.shields.io/badge/experimental-orange): Install PHP Deployer and run a `dep` command, reporting warnings/errors via reviewdog.

### 📦 Monorepo

- [**list-packages**](list-packages/README.md) ![stable](https://img.shields.io/badge/stable-green): List all composer/npm packages in a monorepo.
- [**degit-package**](degit-package/README.md) ![stable](https://img.shields.io/badge/stable-green): Import the latest source branch content into a package repository and prune unwanted folders.
- [**split-package**](split-package/README.md) ![stable](https://img.shields.io/badge/stable-green): Split a monorepo package to a separate repository based on path.

### 🐘 PHP Check

- [**check-laravel**](check-laravel/README.md) ![beta](https://img.shields.io/badge/beta-yellow): Run the standard Laravel PHP check suite (PHPStan, Pint, PHP Insights, PHPMD, tests) and report via reviewdog.
- [**check-filament**](check-filament/README.md) ![beta](https://img.shields.io/badge/beta-yellow): Run Filament-specific checks (FilaCheck) and report via reviewdog.
- [**run-phpinsights**](run-phpinsights/README.md) ![stable](https://img.shields.io/badge/stable-green): Run PHP Insights via reviewdog for inline code review feedback.
- [**run-filacheck**](run-filacheck/README.md) ![stable](https://img.shields.io/badge/stable-green): Run FilaCheck via reviewdog for inline Filament code review feedback.
- [**run-phpstan**](run-phpstan/README.md) ![stable](https://img.shields.io/badge/stable-green): Run PHPStan via reviewdog for inline code review feedback.
- [**run-phpmd**](run-phpmd/README.md) ![stable](https://img.shields.io/badge/stable-green): Run PHP Mess Detector and report via reviewdog.
- [**run-pint**](run-pint/README.md) ![stable](https://img.shields.io/badge/stable-green): Run Laravel Pint code style checks and report via reviewdog.
- [**run-phptests**](run-phptests/README.md) ![stable](https://img.shields.io/badge/stable-green): Run the PHP test suite.
- [**check-security-composer**](check-security-composer/README.md) ![stable](https://img.shields.io/badge/stable-green): Audit Composer dependencies for known vulnerabilities.
- [**list-dirty**](list-dirty/README.md) ![beta](https://img.shields.io/badge/beta-yellow): List files with uncommitted git changes, used by the PHP checks' `dirty` input.
- [**list-wip**](list-wip/README.md) ![beta](https://img.shields.io/badge/beta-yellow): List files changed on the current pull request, used by the PHP checks' `wip` input.

### 🔀 Pull Request

- [**create-pr**](create-pr/README.md) ![stable](https://img.shields.io/badge/stable-green): Open or update a pull request for a branch, with customizable title/body/labels.
- [**rebase-pr**](rebase-pr/README.md) ![stable](https://img.shields.io/badge/stable-green): Rebase the head branch of a pull request onto its base branch.
- [**check-pr-format**](check-pr-format/README.md) ![stable](https://img.shields.io/badge/stable-green): Validate PR title and body format.
- [**check-secret**](check-secret/README.md) ![stable](https://img.shields.io/badge/stable-green): Scan pull request changes for leaked secrets.
- [**check-security-npm**](check-security-npm/README.md) ![stable](https://img.shields.io/badge/stable-green): Audit npm dependencies for known vulnerabilities.
- [**check-lock**](check-lock/README.md) ![beta](https://img.shields.io/badge/beta-yellow): Validate composer.json/composer.lock and package.json/package-lock.json — schema, publish-readiness, and lock coherence — via reviewdog.

### 🏷️ Repository Management

- [**update-labels**](update-labels/README.md) ![stable](https://img.shields.io/badge/stable-green): Create or update repository labels from a JSON file or comma-separated list.
- [**detect-changes**](detect-changes/README.md) ![stable](https://img.shields.io/badge/stable-green): Detect uncommitted or untracked changes in a given path.

See each action's README for usage, inputs, and outputs.

## License

MIT License. See individual action folders for details.
