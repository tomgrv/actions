<!-- @format -->

# Setup php

Shared composite action that prepares PHP and Composer for validation jobs.

## What It Does

- Extracts PHP version from `composer.json`
- Sets up PHP with required extensions
- Caches Composer packages
- Installs Composer dependencies

## Usage

```yaml
- name: Setup PHP toolchain
  uses: perspikapps/setup-php
```
