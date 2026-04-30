<!-- @format -->

# Validate PR Test Suite

Runs the pull request test suite for a given PHP version.

## Inputs

- `php-version` (required): PHP version used to run tests.

## Usage

```yaml
- name: Run tests
  uses: tomgrv/actions/validate-pr-test
  with:
      php-version: '8.3'
```
