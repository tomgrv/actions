<!-- @format -->

# Laravel Env Ribbon

[![Packagist](https://img.shields.io/packagist/v/perspikapps/laravel-envribbon.svg)](https://packagist.org/packages/perspikapps/laravel-envribbon)
[![Packagist](https://poser.pugx.org/perspikapps/laravel-envribbon/d/total.svg)](https://packagist.org/packages/perspikapps/laravel-envribbon)
[![Packagist](https://img.shields.io/packagist/l/perspikapps/laravel-envribbon.svg)](https://packagist.org/packages/perspikapps/laravel-envribbon)

[![Commitizen friendly](https://img.shields.io/badge/commitizen-friendly-brightgreen.svg)](http://commitizen.github.io/cz-cli/) [![semantic-release](https://img.shields.io/badge/%20%20%F0%9F%93%A6%F0%9F%9A%80-semantic--release-e10079.svg)](https://github.com/semantic-release/semantic-release)

[![Buy me a coffee](https://badgen.net/badge/buymeacoffe/tomgrv/yellow?icon=buymeacoffee)](https://buymeacoffee.com/tomgrv)

This package displays automaticaly a top-left corner ribbon with APP_ENV value & version number on all pages, depending on APP_ENV value & associated config:

![capture](./doc/assets/capture.png)

## Installation

Install via composer

```bash
composer require perspikapps/laravel-envribbon
```

### Publish package assets

```bash
php artisan vendor:publish --provider="Perspikapps\LaravelEnvRibbon\EnvRibbonServiceProvider"
```

## Usage

Version is handled by [avto-dev/app-version-laravel](https://github.com/avto-dev/app-version-laravel) package: fill in `VERSION` file at project root.

Fill in configuration according to your needs:

```php
return [

    'enabled' => env('APP_RIBBON', true),

    'environments' => [

        'production' => [
            'visible' =>
            env('APP_DEBUG', false),
            'color' => 'limeGreen',
        ],

        'staging' => [
            'visible' => true,
            'color' => 'darkorange',
        ],

        '*' => [
            'visible' => true,
            'color' => 'crimson',
        ]
    ]

];
```

## Security

If you discover any security related issues, please email
instead of using the issue tracker.

## Credits

-   [tomgrv](https://github.com/tomgrv)
-   [avto-dev](https://github.com/avto-dev)
