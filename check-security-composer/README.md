<!-- @format -->

# Validate PR Security Composer

Runs `composer audit` and reports findings through reviewdog.

## Inputs

- `github-token` (required): GitHub token for reviewdog reporting.

## Usage

```yaml
- name: Run composer security audit
  uses: tomgrv/actions/check-security-composer
  with:
      github-token: ${{ secrets.GITHUB_TOKEN }}
```
