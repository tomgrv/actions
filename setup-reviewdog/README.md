<!-- @format -->

# Setup reviewdog

Shared composite action that installs reviewdog for actions reporting findings as annotations, checks, or PR comments.

## What It Does

- Installs a pinned version of `reviewdog` via `reviewdog/action-setup`.

## Usage

```yaml
- name: Setup reviewdog
  uses: tomgrv/actions/setup-reviewdog
  with:
    version: v0.20.3 # optional
```
