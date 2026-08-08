<!-- @format -->

# GitHub Action: Validate PR PHPStan

This action runs PHPStan and reports findings with reviewdog. It can also generate baseline updates in fix mode.

## Inputs

### github-token

Required. GitHub token for reviewdog reporting.

### paths

Optional. Comma-separated paths to analyze. Defaults to `app`.

### fix

Optional. Enable baseline generation mode. Defaults to `false`.

### branch-prefix

Optional. Prefix for generated branch name in fix mode. Defaults to `chore/phpstan-fix`.

### baseline-file

Optional. Baseline file to generate in fix mode. Defaults to `phpstan-baseline.neon`.

## Outputs

- `has-changes`: Whether fix mode produced local changes.
- `head-branch`: Generated branch name in fix mode.

## Usage

```yaml
- name: Run PHPStan
  uses: tomgrv/actions/run-phpstan
  with:
      github-token: ${{ secrets.GITHUB_TOKEN }}
