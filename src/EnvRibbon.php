<?php

namespace Perspikapps\LaravelEnvRibbon;

use AvtoDev\AppVersion\AppVersionManager;
use Illuminate\Foundation\Application;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;

class EnvRibbon
{
    const RESSOURCES_PATH = __DIR__.DIRECTORY_SEPARATOR.'..'.DIRECTORY_SEPARATOR.'resources'.DIRECTORY_SEPARATOR;

    /**
     * The Laravel application instance.
     *
     * @var Application
     */
    protected $app;

    /**
     * True when enabled, false disabled an null for still unknown.
     *
     * @var bool
     */
    protected $enabled = null;

    protected $appversion = null;

    protected $appenvironment = null;

    protected $color = null;

    protected $visible = null;

    /**
     * @param  Application  $app
     */
    public function __construct($app, AppVersionManager $appversion)
    {
        if (! $app) {
            $app = app();   // Fallback when $app is not given
        }

        $this->app = $app;
        $this->appversion = $appversion;

        $this->loadConfig();
    }

    /**
     * Enable the ribbon and boot, if not already booted.
     */
    public function enable()
    {
        $this->enabled = true;
    }

    /**
     * Modify the response and inject the ribbon (or data in headers).
     *
     * @return Response
     */
    public function modifyResponse(Request $request, Response $response)
    {
        $app = $this->app;
        if (! $this->isEnabled() || ! $this->visible) {
            return $response;
        }

        $content = $response->getContent();

        if (($head = mb_strpos($content, '</head>')) !== false) {
            $content = mb_substr($content, 0, $head).
                '<style>'
                .file_get_contents(self::RESSOURCES_PATH.'env-ribbon.css').
                '</style>'.
                mb_substr($content, $head);
        }

        if (($body = mb_strpos($content, '<body')) !== false) {
            $body = mb_strpos($content, '>', $body) + 1;

            $content = mb_substr($content, 0, $body).
                '<div class="env-ribbon shadow top-left sticky" style="--ribbon-color:'.$this->color.';--ribbon-width:25em; ">
                        '.$this->app->environment().' '.$this->appversion->version().'
                </div>'.
                mb_substr($content, $body);
        }

        if ($content) {
            $response->setContent($content);
        }
    }

    /**
     * Check if the ribbon is enabled.
     *
     * @return bool
     */
    public function isEnabled()
    {
        if ($this->enabled === null) {
            $config = $this->app['config'];
            $configEnabled = value($config->get('env-ribbon.enabled'));

            $this->enabled = $configEnabled && ! $this->app->runningInConsole();
        }

        return $this->enabled;
    }

    /**
     * Check if the ribbon is enabled.
     *
     * @return bool
     */
    public function loadConfig()
    {
        $current = $this->app->environment();

        $config = $this->app['config'];
        $environments = value($config->get('env-ribbon.environments'));

        $index = array_key_exists($current, $environments) ? $current : '*';

        if (array_key_exists($index, $environments)) {
            $this->color = $environments[$index]['color'] ?? 'black';
            $this->visible = $environments[$index]['visible'] ?? true;
        }
    }
}
