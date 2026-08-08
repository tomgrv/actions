<!-- @format -->

# Setup node

Shared composite action that prepares Node.js and npm for validation jobs.

## What It Does

- Extracts Node.js version from `package.json`
- Sets up Node.js with required version
- Caches Composer packages
- Installs Composer dependencies

## Usage

```yaml
- name: Setup Node.js toolchain
  uses: tomgrv/actions/setup-node
```
