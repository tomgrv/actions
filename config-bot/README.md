<!-- @format -->

# GitHub Action: Configure Git Bot

Configures global Git identity and GitHub authentication for bot commits within a workflow job. Resolves the GitHub App bot user ID from its slug and writes the matching `user.name`, `user.email`, and token authentication header into the runner's Git configuration.

## Inputs

### github-token

**Required.** GitHub token used for authenticated Git operations.

### github-app-slug

**Optional.** GitHub App slug used to resolve the bot identity. Defaults to `github-actions`.

## Outputs

- `user-id`: Resolved GitHub App bot user ID.
- `git-user-name`: Configured `git user.name`.
- `git-user-email`: Configured `git user.email`.

## Works well with

- [**create-pr**](../create-pr/README.md) — open or update a pull request after committing changes as the bot.
- [**degit-package**](../degit-package/README.md) — import source content and prepare a branch; pair with `config-bot` for authenticated pushes.
- [**split-package**](../split-package/README.md) — split a monorepo subtree; pair with `config-bot` to sign the split commits.

## Example

```yaml
name: Sync Packages

on:
    push:
        branches: [main]

jobs:
    sync:
        runs-on: ubuntu-latest
        steps:
            - uses: actions/checkout@v4

            - name: Generate app token
              id: app-token
              uses: actions/create-github-app-token@v1
              with:
                  app-id: ${{ secrets.APP_ID }}
                  private-key: ${{ secrets.APP_PRIVATE_KEY }}

            - name: Configure git bot
              uses: tomgrv/actions/config-bot@v1
              with:
                  github-token: ${{ steps.app-token.outputs.token }}
                  github-app-slug: ${{ steps.app-token.outputs.app-slug }}

            - name: Create pull request
              uses: tomgrv/actions/create-pr@v1
              with:
                  github-token: ${{ steps.app-token.outputs.token }}
                  head-branch: chore/automated-update
                  pr-title: 'chore: automated update'
```
