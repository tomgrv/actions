<!-- @format -->

# GitHub Action: Validate PR PHP Insights

This action runs PHP Insights and reports findings with reviewdog. It can also run in fix mode.

## Inputs

### github-token

Required. GitHub token for reviewdog reporting.

### paths

Optional. Comma-separated paths to analyze. Defaults to `app`.

### fix

Optional. Enable auto-fix mode. Defaults to `false`.

### branch-prefix

Optional. Prefix for generated branch name in fix mode. Defaults to `chore/phpinsights-fix`.

## Outputs

- `has-changes`: Whether fix mode produced local changes.
- `head-branch`: Generated branch name in fix mode.

## Usage

```yaml
- name: Run PHP Insights
  uses: tomgrv/actions/run-phpinsights
  with:
      github-token: ${{ secrets.GITHUB_TOKEN }}
```

```yaml
- name: Run PHP Insights in fix mode
  id: phpinsights-fix
  uses: tomgrv/actions/run-phpinsights
  with:
      github-token: ${{ secrets.GITHUB_TOKEN }}
      paths: app,config,database,resources,routes,tests,modules,packages
      fix: 'true'
```
