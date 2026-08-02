<?php

/**
 * Turn a PHPUnit/Pest JUnit report into GitHub Actions annotations.
 *
 * Reads the JUnit XML produced by the test run and emits one `::error` workflow
 * command per failing test case, plus a markdown recap in the job summary when
 * GITHUB_STEP_SUMMARY is available. Annotations are anchored to the file and
 * line reported by the runner, falling back to the first stack frame inside the
 * workspace so the failure lands on the code under test.
 *
 * Usage: php annotate.php <junit.xml>
 */
$path = $argv[1] ?? null;

if ($path === null || !is_file($path)) {
    fwrite(STDERR, "::notice::No JUnit report to annotate\n");

    exit(0);
}

$previous = libxml_use_internal_errors(true);
$document = simplexml_load_file($path);
libxml_use_internal_errors($previous);

if ($document === false) {
    fwrite(STDERR, "::notice::Could not parse JUnit report: {$path}\n");

    exit(0);
}

$workspace = rtrim(getenv('GITHUB_WORKSPACE') ?: getcwd(), '/');

/**
 * Make a path relative to the workspace so GitHub can map it to the diff.
 */
$relative = static function (string $file) use ($workspace): string {
    $file = (string) (realpath($file) ?: $file);

    if ($workspace !== '' && str_starts_with($file, $workspace . '/')) {
        return substr($file, strlen($workspace) + 1);
    }

    return $file;
};

/**
 * Dig the first workspace stack frame out of a failure message.
 *
 * @return array{0: string, 1: int}|null
 */
$frameFromMessage = static function (string $message) use ($workspace): ?array {
    if (preg_match_all('#(/[^\s:()]+\.php):(\d+)#', $message, $matches, PREG_SET_ORDER) === 0) {
        return null;
    }

    foreach ($matches as $match) {
        if (str_contains($match[1], '/vendor/')) {
            continue;
        }

        if ($workspace === '' || str_starts_with($match[1], $workspace . '/')) {
            return [$match[1], (int) $match[2]];
        }
    }

    return null;
};

/**
 * Escape a workflow command message. The runner only unescapes %25/%0D/%0A here,
 * so escaping anything else would show up literally in the annotation.
 */
$escapeData = static function (string $value): string {
    return str_replace(['%', "\r", "\n"], ['%25', '%0D', '%0A'], $value);
};

/**
 * Escape a workflow command property, where `:` and `,` are delimiters too.
 */
$escapeProperty = static function (string $value): string {
    return str_replace(['%', "\r", "\n", ':', ','], ['%25', '%0D', '%0A', '%3A', '%2C'], $value);
};

$failures = [];

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

            $failures[] = [
                'kind' => $kind,
                'name' => (string) ($case['name'] ?? 'test'),
                'class' => (string) ($case['class'] ?? $case['classname'] ?? ''),
                'file' => $file === '' ? '' : $relative($file),
                'line' => max($line, 1),
                'message' => $message,
            ];
        }
    }
}

foreach ($failures as $failure) {
    $title = $failure['class'] === ''
        ? $failure['name']
        : $failure['class'] . '::' . $failure['name'];

    $location = $failure['file'] === ''
        ? ''
        : sprintf('file=%s,line=%d,', $escapeProperty($failure['file']), $failure['line']);

    printf(
        "::error %stitle=%s::%s\n",
        $location,
        $escapeProperty($title),
        $escapeData($failure['message'])
    );
}

$summaryFile = getenv('GITHUB_STEP_SUMMARY');

if ($summaryFile === false || $summaryFile === '') {
    exit(0);
}

$root = $document->getName() === 'testsuites' ? ($document->testsuite[0] ?? $document) : $document;
$total = (int) ($root['tests'] ?? 0);
$errors = (int) ($root['errors'] ?? 0);
$failed = (int) ($root['failures'] ?? 0);
$skipped = (int) ($root['skipped'] ?? 0);
$time = (float) ($root['time'] ?? 0);

$summary = sprintf(
    "### PHP test suite\n\n| Tests | Failures | Errors | Skipped | Time |\n| --- | --- | --- | --- | --- |\n| %d | %d | %d | %d | %.2fs |\n",
    $total,
    $failed,
    $errors,
    $skipped,
    $time
);

if ($failures !== []) {
    $summary .= "\n<details><summary>Failing tests</summary>\n\n";

    foreach ($failures as $failure) {
        $title = $failure['class'] === ''
            ? $failure['name']
            : $failure['class'] . '::' . $failure['name'];

        $summary .= sprintf(
            "- **%s**%s\n",
            $title,
            $failure['file'] === '' ? '' : sprintf(' — `%s:%d`', $failure['file'], $failure['line'])
        );
    }

    $summary .= "\n</details>\n";
}

file_put_contents($summaryFile, $summary, FILE_APPEND);
