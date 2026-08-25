<!-- @format -->

# GitHub Action: Create or Update Ref

Creates a git ref (tag or branch). If the ref already exists, it is force-updated to point at the given SHA instead of failing.

## Inputs

### github-token

Required. GitHub token with contents write permission.

### ref

Required. Full ref name (e.g. `refs/tags/deploy/myhost`).

### sha

Required. The SHA to point the ref at.

## Outputs

### action

Whether the ref was `created` or `updated`.

### ref

The ref that was created or updated.

## Usage

```yaml
- name: Tag deployed version
  uses: tomgrv/actions/create-update-ref@v2
  with:
      github-token: ${{ secrets.GITHUB_TOKEN }}
      ref: refs/tags/deploy/myhost
      sha: ${{ github.sha }}
```
