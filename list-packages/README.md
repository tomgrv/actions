<!-- @format -->

# GitHub Action: List Packages

This action discovers Composer and npm workspace packages and emits a JSON matrix array suitable for use as a GitHub Actions matrix value.

## Outputs

### packages

JSON array of package objects with `org`, `name`, `path`, and `repository` fields.

## Usage

```yaml
- name: List packages
  id: list-packages
  uses: tomgrv/actions/list-packages
```
