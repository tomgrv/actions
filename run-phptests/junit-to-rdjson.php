<?php

/**
 * Convert a PHPUnit/Pest JUnit report to reviewdog diagnostic JSON (rdjson).
 *
 * reviewdog has no JUnit input format, so failing test cases are translated to
 * rdjson diagnostics on stdout and piped to `reviewdog -f=rdjson`. Diagnostics
 * are anchored on the file and line reported by the runner, falling back to the
 * first stack frame outside `vendor/` so the report lands on the code under test.
 *
 * Usage: php junit-to-rdjson.php <junit.xml>
 */
$path = $argv[1] ?? null;

if ($path === null || !is_file($path)) {
    fwrite(STDERR, "::notice::No JUnit report to convert\n");

    exit(0);
}

$previous = libxml_use_internal_errors(true);
$document = simplexml_load_file($path);
libxml_use_internal_errors($previous);

if ($document === false) {
    fwrite(STDERR, "::notice::Could not parse JUnit report: {$path}\n");

    exit(0);
}

$root = rtrim(getcwd() ?: '.', '/');

/**
 * Make a path relative to the working directory, which is where reviewdog runs.
 *
 * `strncmp` rather than `str_starts_with`: the converter runs on whatever PHP
 * the project under test pins, which may predate 8.0.
 */
$relative = static function (string $file) use ($root): string {
    $file = (string) (realpath($file) ?: $file);
    $prefix = $root . '/';

    if ($root !== '' && strncmp($file, $prefix, strlen($prefix)) === 0) {
        return substr($file, strlen($prefix));
    }

    return $file;
};

/**
 * Dig the first stack frame outside vendor/ out of a failure message.
 *
 * @return array{0: string, 1: int}|null
 */
$frameFromMessage = static function (string $message): ?array {
    if (preg_match_all('#(/[^\s:()]+\.php):(\d+)#', $message, $matches, PREG_SET_ORDER) === 0) {
        return null;
    }

    foreach ($matches as $match) {
        if (strpos($match[1], '/vendor/') === false) {
            return [$match[1], (int) $match[2]];
        }
    }

    return null;
};

$diagnostics = [];

// `//testcase` already walks arbitrarily nested <testsuite> elements, so a flat
// report and a deeply nested one are handled the same way.
foreach ($document->xpath('//testcase[failure or error]') ?: [] as $case) {
    foreach (['failure', 'error'] as $kind) {
        foreach ($case->{$kind} as $problem) {
            $message = trim((string) $problem);

            if ($message === '') {
                $message = trim((string) ($problem['message'] ?? '')) ?: 'Test failed';
            }

            $file = (string) ($case['file'] ?? '');
            $line = (int) ($case['line'] ?? 0);
            $frame = $frameFromMessage($message);

            if ($frame !== null) {
                [$file, $line] = $frame;
            }

            if ($file === '') {
                continue;
            }

            $name = (string) ($case['name'] ?? 'test');
            $class = (string) ($case['class'] ?? $case['classname'] ?? '');

            $diagnostics[] = [
                'message' => $message,
                'location' => [
                    'path' => $relative($file),
                    'range' => [
                        'start' => ['line' => max($line, 1)],
                    ],
                ],
                'severity' => 'ERROR',
                'code' => [
                    'value' => $class === '' ? $name : $class . '::' . $name,
                ],
            ];
        }
    }
}

echo json_encode([
    'source' => [
        'name' => getenv('REVIEWDOG_TOOL_NAME') ?: 'phpunit',
        'url' => 'https://phpunit.de',
    ],
    'severity' => 'ERROR',
    'diagnostics' => $diagnostics,
], JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE), "\n";
