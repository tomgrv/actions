<!-- @format -->

# GitHub Action: Create PR comment

Post a new comment on a pull request or issue.

## Inputs

### github-token

**Optional.** GitHub token with permission to write issue comments.

### repository

**Optional.** Repository in the format "owner/name". Defaults to the current repository.

### issue-number

**Optional.** Pull request or issue number to comment on. Defaults to the current pull request or issue number.

### body

**Required.** Comment body (Markdown supported).

## Outputs

- `comment-id`: ID of the created comment.
- `comment-url`: HTML URL of the created comment.

## Local Usage

Run this action locally from a clone of this repository with [`zz-use`](https://github.com/tomgrv/scripts/tree/main/zz-use):

```sh
zz-use -x ./create-pr-comment
```

See [Inputs](#inputs) for the environment variables to set.

## Example

```yaml
- uses: tomgrv/actions/create-pr-comment@v5
  with:
      body: <body>
```
