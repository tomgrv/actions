<!-- @format -->

# GitHub Action: Validate PR PHPStan

This action runs PHPStan and reports findings with reviewdog.

## Inputs

### github-token

Required. GitHub token for reviewdog reporting.

## Usage

```yaml
- name: Run PHPStan
  uses: perspikapps/validate-pr-phpstan
  with:
      github-token: ${{ secrets.GITHUB_TOKEN }}
```
