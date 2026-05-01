<!-- @format -->

# tomgrv/actions

Reusable GitHub Actions

## Overview

tomgrv/actions is a suite of modular, reusable GitHub composite actions designed to automate code quality, PR management, and package maintenance for monorepos and composer-based projects. Each action is self-contained, follows strict output/logging conventions, and is documented for easy integration into your workflows.

## Available Actions

### Utils

- [**config-bot**](config-bot/README.md): Configure git bot identity and authentication for CI/CD.
- [**setup-php**](setup-php/README.md): Setup PHP, Composer, and extensions as per composer for CI jobs.
- [**setup-node**](setup-node/README.md): Setup Node.js and npm for CI jobs.

### Monorepo

- [**list-packages**](list-packages/README.md): List all composer/npm packages in a monorepo.
- [**degit-package**](degit-package/README.md): Import the latest source branch content into a package repository and prune unwanted folders.
- [**split-packages**](split-packages/README.md): Split a monorepo package to a separate repository based on path.

### PHP Check

- [**run-phpinsights**](run-phpinsights/README.md): Run PHP Insights via reviewdog for inline code review feedback.
- [**run-phpstan**](run-phpstan/README.md): Run PHPStan via reviewdog for inline code review feedback.
- [**run-phpmd**](run-phpmd/README.md): Run PHP Mess Detector and report via reviewdog.
- [**run-pint**](run-pint/README.md): Run Laravel Pint code style fixer and report via reviewdog.
- [**run-phptests**](run-phptests/README.md): Run the PHP test suite.
- [**check-composer**](check-composer/README.md): Validate composer.json and composer.lock consistency.
- [**check-security-composer**](check-security-composer/README.md): Audit Composer dependencies for known vulnerabilities.

### Pull Request

- [**create-pr**](create-pr/README.md): Open or update a pull request for a branch, with customizable title/body/labels.
- [**check-pr-format**](check-pr-format/README.md): Validate PR title and body format.
- [**check-secret**](check-secret/README.md): Scan pull request changes for leaked secrets.
- [**check-security-npm**](check-security-npm/README.md): Audit npm dependencies for known vulnerabilities.

See each action's README for usage, inputs, and outputs.

## License

MIT License. See individual action folders for details.
