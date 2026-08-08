<!-- @format -->

# tomgrv/actions

Reusable GitHub Actions

## Overview

tomgrv/actions is a suite of modular, reusable GitHub composite actions designed to automate code quality, PR management, and package maintenance for monorepos and composer-based projects. Each action is self-contained, follows strict output/logging conventions, and is documented for easy integration into your workflows.

## Available Actions

### Utils

- [**config-bot**](config-bot/README.md): Configure git bot identity and authentication for CI/CD.
- [**setup-php**](setup-php/README.md): Setup PHP, Composer, and extensions as per composer for CI jobs.
- [**setup-reviewdog**](setup-reviewdog/README.md): Install reviewdog for actions that report findings as annotations/comments.
- [**clean-history**](clean-history/README.md): Remove old workflow run history, keeping a minimum number of days and runs per workflow.
- [**create-update-ref**](create-update-ref/README.md): Create a git ref (tag/branch), or force-update it if it already exists.
- [**run-deployer**](run-deployer/README.md): Install PHP Deployer and run a `dep` command, reporting warnings/errors via reviewdog.

### Monorepo

- [**list-packages**](list-packages/README.md): List all composer/npm packages in a monorepo.
- [**degit-package**](degit-package/README.md): Import the latest source branch content into a package repository and prune unwanted folders.
- [**split-package**](split-package/README.md): Split a monorepo package to a separate repository based on path

### PHP Check

- [**run-phpinsights**](run-phpinsights/README.md): Run PHP Insights via reviewdog for inline code review feedback.
- [**run-phpstan**](run-phpstan/README.md): Run PHPStan via reviewdog for inline code review feedback.
- [**run-phpmd**](run-phpmd/README.md): Run PHP Mess Detector and report via reviewdog.
- [**run-pint**](run-pint/README.md): Run Laravel Pint code style fixer and report via reviewdog.
- [**check-composer**](check-composer/README.md): Validate composer.json and composer.lock consistency.

### Pull Request

- [**create-pr**](create-pr/README.md): Open or update a pull request for a branch, with customizable title/body/labels.
- [**check-pr-format**](check-pr-format/README.md): Validate PR title and body format.
- [**create-pr-comment**](create-pr-comment/README.md): Create or update a pull request comment, keyed by a stable marker.

See each action's README for usage, inputs, and outputs.

## License

MIT License. See individual action folders for details.
