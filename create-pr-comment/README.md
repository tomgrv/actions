<!-- @format -->

# GitHub Action: Create PR Comment

Creates or updates a pull request comment. Comments are keyed by a stable `key` input, embedded in the comment as a hidden marker, so repeated calls with the same key edit the existing comment instead of creating duplicates.

## Inputs

### github-token

Required. GitHub token with pull-requests write permission.

### pr-number

Required. Pull request number to comment on.

### key

Required. Stable key identifying this comment. Reused calls with the same key update the same comment instead of creating a new one.

### body

Required. Markdown body of the comment.

## Outputs

### action

Whether the comment was `created` or `updated`.

### comment-id

ID of the created or updated comment.

### comment-url

HTML URL of the created or updated comment.

## Usage

```yaml
- name: Comment deployment URL on PR
  if: ${{ github.event_name == 'pull_request' && steps.deploy.outputs.deploy-url != '' }}
  uses: tomgrv/actions/create-pr-comment@v0
  with:
    github-token: ${{ secrets.GITHUB_TOKEN }}
    pr-number: ${{ github.event.pull_request.number }}
    key: deploy-${{ matrix.hosts.host }}
    body: "🚀 Deployed **${{ matrix.hosts.host }}** → ${{ steps.deploy.outputs.deploy-url }}"
```
