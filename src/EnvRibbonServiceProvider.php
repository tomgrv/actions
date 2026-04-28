<?php

namespace Perspikapps\LaravelEnvRibbon;

use Illuminate\Contracts\Http\Kernel;
use Illuminate\Support\ServiceProvider;
use Perspikapps\LaravelEnvRibbon\Middleware\InjectEnvRibbon;

class EnvRibbonServiceProvider extends ServiceProvider
{
    const CONFIG_PATH = __DIR__.'/../config/env-ribbon.php';

    /**
     * Perform post-registration booting of services.
     */
    public function boot(): void
    {
        // $this->loadTranslationsFrom(__DIR__.'/../resources/lang', 'perspikapps');
        // $this->loadViewsFrom(__DIR__.'/../resources/views', 'perspikapps');
        // $this->loadMigrationsFrom(__DIR__.'/../database/migrations');
        // $this->loadRoutesFrom(__DIR__.'/routes.php');

        // Publishing is only necessary when using the CLI.
        if ($this->app->runningInConsole()) {
            $this->bootForConsole();
        }

        $this->registerMiddleware(InjectEnvRibbon::class);
    }

    /**
     * Register any package services.
     */
    public function register(): void
    {
        $this->mergeConfigFrom(self::CONFIG_PATH, 'env-ribbon');

        /*
         * Register the service provider for the dependency.
         */
        $this->app->register(\AvtoDev\AppVersion\ServiceProvider::class);

        /*
         * Register the service the package provides.
         */
        $this->app->singleton(EnvRibbon::class, function ($app) {
            return new EnvRibbon($app, $app->make('AvtoDev\AppVersion\AppVersionManagerInterface'));
        });
    }

    /**
     * Register the Middleware.
     *
     * @param  string  $middleware
     */
    protected function registerMiddleware($middleware)
    {
        $kernel = $this->app[Kernel::class];
        $kernel->pushMiddleware($middleware);
    }

    /**
     * Get the services provided by the provider.
     *
     * @return array
     */
    public function provides()
    {
        return [EnvRibbon::class];
    }

    /**
     * Console-specific booting.
     */
    protected function bootForConsole(): void
    {
        // Publishing the configuration file.
        $this->publishes([
            self::CONFIG_PATH => config_path('env-ribbon.php'),
        ], 'env-ribbon.config');

        // Publishing the views.
        /*$this->publishes([
            __DIR__.'/../resources/views' => base_path('resources/views/vendor/perspikapps'),
        ], 'env-ribbon.views');*/

        // Publishing assets.
        /*$this->publishes([
            __DIR__.'/../resources/assets' => public_path('vendor/perspikapps'),
        ], 'env-ribbon.views');*/

        // Publishing the translation files.
        /*$this->publishes([
            __DIR__.'/../resources/lang' => resource_path('lang/vendor/perspikapps'),
        ], 'env-ribbon.views');*/

        // Registering package commands.
        // $this->commands([]);
    }
}
