<!-- @format -->

# Validate PR Secrets

Scans pull request changes for leaked secrets using gitleaks.

## Inputs

- `github-token` (required): GitHub token for gitleaks action.
- `gitleaks-license` (optional): Optional gitleaks license.

## Usage

```yaml
- name: Validate PR secrets
  uses: tomgrv/actions/check-secret
  with:
      github-token: ${{ secrets.GITHUB_TOKEN }}
      gitleaks-license: ${{ secrets.GITLEAKS_LICENSE }}
```
