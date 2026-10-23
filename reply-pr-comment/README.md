<!-- @format -->

# GitHub Action: Reply comment

Post a comment on a pull request or issue, referencing the comment that triggered the workflow.

## Inputs

### github-token

**Optional.** GitHub token with permission to write issue comments.

### repository

**Optional.** Repository in the format "owner/name". Defaults to the current repository.

### issue-number

**Optional.** Pull request or issue number to comment on. Defaults to the current pull request or issue number.

### reply-to-url

**Optional.** HTML URL of the comment being replied to, included as a reference link in the posted comment. Defaults to github.event.comment.html_url. Leave empty to omit the reference.

### body

**Required.** Comment body (Markdown supported).

## Outputs

- `comment-id`: ID of the created comment.
- `comment-url`: HTML URL of the created comment.

## Local Usage

Run this action locally from a clone of this repository with [`zz-use`](https://github.com/tomgrv/scripts/tree/main/zz-use):

```sh
zz-use -x ./reply-pr-comment
```

See [Inputs](#inputs) for the environment variables to set.

## Example

```yaml
- uses: tomgrv/actions/reply-pr-comment@v5
  with:
      body: <body>
```
