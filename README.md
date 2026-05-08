<!-- @format -->

# tomgrv/actions

![Docs](https://img.shields.io/badge/docs-updated-blue) ![License](https://img.shields.io/badge/license-MIT-green)

Reusable GitHub Actions

## Overview

tomgrv/actions is a suite of modular, reusable GitHub composite actions designed to automate code quality, PR management, and package maintenance for monorepos and composer-based projects. Each action is self-contained, follows strict output/logging conventions, and is documented for easy integration into your workflows.

Each action is also published as an npm package under `@tomgrv/action-<name>` and can be run directly via `npx`:

```sh
npx -yes @tomgrv/action-<name>
```

For example:

```sh
# Run composer validation locally
GITHUB_TOKEN=ghp_xxx npx -yes @tomgrv/action-check-composer

# List monorepo packages
npx -yes @tomgrv/action-list-packages

# Detect uncommitted changes
npx -yes @tomgrv/action-detect-changes
```

## Available Actions

> **Badge legend:**
> ![stable](https://img.shields.io/badge/stable-green) Stable &nbsp;
> ![beta](https://img.shields.io/badge/beta-yellow) Beta &nbsp;
> ![experimental](https://img.shields.io/badge/experimental-orange) Experimental

### 🔧 Utils

- [**config-bot**](config-bot/README.md) ![stable](https://img.shields.io/badge/stable-green): Configure git bot identity and authentication for CI/CD.
- [**setup-php**](setup-php/README.md) ![stable](https://img.shields.io/badge/stable-green): Setup PHP, Composer, and extensions as per composer for CI jobs.
- [**setup-node**](setup-node/README.md) ![stable](https://img.shields.io/badge/stable-green): Setup Node.js and npm for CI jobs.

### 📦 Monorepo

- [**list-packages**](list-packages/README.md) ![stable](https://img.shields.io/badge/stable-green): List all composer/npm packages in a monorepo.
- [**degit-package**](degit-package/README.md) ![stable](https://img.shields.io/badge/stable-green): Import the latest source branch content into a package repository and prune unwanted folders.
- [**split-package**](split-package/README.md) ![stable](https://img.shields.io/badge/stable-green): Split a monorepo package to a separate repository based on path.

### 🐘 PHP Check

- [**run-phpinsights**](run-phpinsights/README.md) ![stable](https://img.shields.io/badge/stable-green): Run PHP Insights via reviewdog for inline code review feedback.
- [**run-phpstan**](run-phpstan/README.md) ![stable](https://img.shields.io/badge/stable-green): Run PHPStan via reviewdog for inline code review feedback.
- [**run-phpmd**](run-phpmd/README.md) ![stable](https://img.shields.io/badge/stable-green): Run PHP Mess Detector and report via reviewdog.
- [**run-pint**](run-pint/README.md) ![stable](https://img.shields.io/badge/stable-green): Run Laravel Pint code style fixer and report via reviewdog.
- [**run-phptests**](run-phptests/README.md) ![stable](https://img.shields.io/badge/stable-green): Run the PHP test suite.
- [**check-composer**](check-composer/README.md) ![stable](https://img.shields.io/badge/stable-green): Validate composer.json and composer.lock consistency.
- [**check-security-composer**](check-security-composer/README.md) ![stable](https://img.shields.io/badge/stable-green): Audit Composer dependencies for known vulnerabilities.

### 🔀 Pull Request

- [**create-pr**](create-pr/README.md) ![stable](https://img.shields.io/badge/stable-green): Open or update a pull request for a branch, with customizable title/body/labels.
- [**rebase-pr**](rebase-pr/README.md) ![stable](https://img.shields.io/badge/stable-green): Rebase the head branch of a pull request onto its base branch.
- [**check-pr-format**](check-pr-format/README.md) ![stable](https://img.shields.io/badge/stable-green): Validate PR title and body format.
- [**check-secret**](check-secret/README.md) ![stable](https://img.shields.io/badge/stable-green): Scan pull request changes for leaked secrets.
- [**check-security-npm**](check-security-npm/README.md) ![stable](https://img.shields.io/badge/stable-green): Audit npm dependencies for known vulnerabilities.

### 🏷️ Repository Management

- [**update-labels**](update-labels/README.md) ![stable](https://img.shields.io/badge/stable-green): Create or update repository labels from a JSON file or comma-separated list.
- [**detect-changes**](detect-changes/README.md) ![stable](https://img.shields.io/badge/stable-green): Detect uncommitted or untracked changes in a given path.

See each action's README for usage, inputs, and outputs.

## License

MIT License. See individual action folders for details.
