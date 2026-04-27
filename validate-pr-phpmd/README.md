<!-- @format -->

# GitHub Action: Validate PR PHPMD

This action runs PHPMD and reports findings with reviewdog.

## Inputs

### github-token

Required. GitHub token for reviewdog reporting.

## Usage

```yaml
- name: Run PHPMD
  uses: perspikapps/validate-pr-phpmd
  with:
      github-token: ${{ secrets.GITHUB_TOKEN }}
```
