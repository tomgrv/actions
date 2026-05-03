<!-- @format -->

# Validate PR Format

Validates and optionally normalizes pull request title format.

## Inputs

- `github-token` (optional): GitHub token used when updating PR title.

## Usage

```yaml
- name: Validate PR title
  uses: tomgrv/actions/check-pr-format
  with:
      github-token: ${{ secrets.GITHUB_TOKEN }}
```
