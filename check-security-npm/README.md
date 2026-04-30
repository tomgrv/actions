<!-- @format -->

# Validate PR Security NPM

Runs `npm audit` and reports findings through reviewdog.

## Inputs

- `github-token` (required): GitHub token for reviewdog reporting.

## Usage

```yaml
- name: Run npm security audit
  uses: tomgrv/actions/check-security-npm
  with:
      github-token: ${{ secrets.GITHUB_TOKEN }}
```
