<?php

namespace Perspikapps\LaravelEnvRibbon\Tests;

use Orchestra\Testbench\TestCase;
use Perspikapps\LaravelEnvRibbon\Facades\EnvRibbon;

class EnvRibbonTest extends TestCase
{
    protected function getPackageProviders($app)
    {
        return [ServiceProvider::class];
    }

    protected function getPackageAliases($app)
    {
        return [
            'env-ribbon' => EnvRibbon::class,
        ];
    }

    public function test_example()
    {
        $this->assertEquals(1, 1);
    }
}
