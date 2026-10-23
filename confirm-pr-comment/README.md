<!-- @format -->

# GitHub Action: Confirm comment

Add a reaction emoji to the current GitHub event comment.

## Inputs

### github-token

**Optional.** GitHub token with permission to add reactions.

### repository

**Optional.** Repository in the format "owner/name". Used when comment-url is not provided.

### comment-url

**Optional.** API URL of the comment to react to. Defaults to github.event.comment.url.

### comment-id

**Optional.** Numeric comment ID. Used with repository when comment-url is not provided.

### reaction

**Optional.** Reaction to add. Supports GitHub values (+1, -1, laugh, confused, heart, hooray, rocket, eyes) and emoji aliases (👍, 👎, 😄, 😕, ❤️, 🎉, 🚀, 👀). Defaults to `+1`.

## Outputs

- `reaction-id`: ID of the created (or existing) reaction.
- `reaction-content`: Normalized GitHub reaction content value.
- `comment-url`: API URL of the comment that was reacted to.

## Local Usage

Run this action locally from a clone of this repository with [`zz-use`](https://github.com/tomgrv/scripts/tree/main/zz-use):

```sh
zz-use -x ./confirm-pr-comment
```

See [Inputs](#inputs) for the environment variables to set.

## Example

```yaml
- uses: tomgrv/actions/confirm-pr-comment@v5
```
