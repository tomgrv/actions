<?php

return [
    'enabled' => env('APP_RIBBON', true),

    /*
    |--------------------------------------------------------------------------
    | Environments
    |--------------------------------------------------------------------------
    |
    | Here you can change the ribbon's display behavior
    |
    | For more detailed instructions you can look here:
    | https://github.com/tomgrv/envribbon/#Environments
    |
    */

    'environments' => [
        'production' => [
            'visible' => env('APP_DEBUG', false),
            'color' => 'limeGreen',
        ],

        'staging' => [
            'visible' => true,
            'color' => 'darkorange',
        ],

        '*' => [
            'visible' => true,
            'color' => 'crimson',
        ],
    ],
];
