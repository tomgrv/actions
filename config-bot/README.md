<!-- @format -->

# GitHub Action: Configure Git Bot

This action configures global Git bot identity and GitHub authentication header for subsequent Git operations.

## Inputs

### github-token

Required. GitHub token used for authenticated Git operations.

### github-app-slug

Optional. GitHub App slug used to resolve the bot identity. Defaults to `github-actions`.

## Outputs

- `user-id`: Resolved GitHub App bot user ID.
- `git-user-name`: Configured git user name.
- `git-user-email`: Configured git user email.

## Usage

```yaml
- name: Configure git bot
  uses: tomgrv/actions/config-bot
  with:
      github-token: ${{ secrets.GITHUB_TOKEN }}
      github-app-slug: your-app-slug
```
