<!-- @format -->

# GitHub Action: Validate PR Composer

This action runs `composer validate --strict` and reports findings with reviewdog.

## Inputs

### github-token

Required. GitHub token for reviewdog reporting.

## Usage

```yaml
- name: Validate composer
  uses: tomgrv/actions/check-composer
  with:
      github-token: ${{ secrets.GITHUB_TOKEN }}
```
