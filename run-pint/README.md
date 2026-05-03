<!-- @format -->

# GitHub Action: Validate PR Pint

This action runs Laravel Pint in test mode and reports findings with reviewdog.

## Inputs

### github-token

Required. GitHub token for reviewdog reporting.

## Usage

```yaml
- name: Run Pint
  uses: tomgrv/actions/run-pint
  with:
      github-token: ${{ secrets.GITHUB_TOKEN }}
```
