#!/usr/bin/sh

# Run the PHP test suite (pest/phpunit/composer script), bootstrapping a
# Laravel app when needed, and report failures via reviewdog.

set -e

if [ -n "${GITHUB_WORKSPACE:-}" ]; then
    cd "${GITHUB_WORKSPACE}" || exit 1
    git config --global --add safe.directory "${GITHUB_WORKSPACE}" || exit 1
fi

WORKING_DIRECTORY="${WORKING_DIRECTORY:-.}"

# Setup/input problems below are plain logs, not GitHub annotations (see
# .github/instructions/action-creation.md); only the test suite's own result
# at the end of this script is a finding worth annotating.
if [ "${WORKING_DIRECTORY}" != "." ]; then
    if [ ! -d "${WORKING_DIRECTORY}" ]; then
        echo "Error: Working directory not found: ${WORKING_DIRECTORY}" >&2
        exit 1
    fi
    cd "${WORKING_DIRECTORY}" || exit 1
fi

TEST_RUNNER="${TEST_RUNNER:-auto}"
TEST_PATHS="${TEST_PATHS:-${1:-}}"
TEST_FLAGS="${TEST_FLAGS:-}"
INSTALL="${INSTALL:-auto}"
COVERAGE="${COVERAGE:-auto}"
COVERAGE_FILE="${COVERAGE_FILE:-coverage.xml}"
JUNIT_FILE="${JUNIT_FILE:-junit.xml}"
MIGRATE="${MIGRATE:-auto}"

#
# Report file names end up verbatim in GITHUB_OUTPUT, where a newline would
# corrupt the file and let extra key/value pairs through.
#
_reject_control_chars() {
    case "$2" in
        *[[:cntrl:]]*)
            echo "Error: ${1} must not contain control characters or newlines." >&2
            return 1
            ;;
    esac

    return 0
}

if ! _reject_control_chars 'coverage-file' "${COVERAGE_FILE}" || ! _reject_control_chars 'junit-file' "${JUNIT_FILE}"; then
    printf 'tests-passed=false\n'
    printf 'coverage-file=\n'
    printf 'junit-file=\n'
    exit 1
fi

REVIEWDOG_BIN="reviewdog"
REVIEWDOG_NAME="${REVIEWDOG_NAME:-phpunit}"
REVIEWDOG_REPORTER="${REVIEWDOG_REPORTER:-${TOMGRV_REVIEWDOG_REPORTER:-github-check}}"
REVIEWDOG_LEVEL="${REVIEWDOG_LEVEL:-error}"
REVIEWDOG_FILTER_MODE="file"
REVIEWDOG_FAIL_LEVEL="${REVIEWDOG_FAIL_LEVEL:-none}"
REVIEWDOG_FLAGS="${REVIEWDOG_FLAGS:-}"

if [ -z "${REVIEWDOG_GITHUB_API_TOKEN:-}" ] && [ -n "${GITHUB_TOKEN:-}" ]; then
    echo "REVIEWDOG_GITHUB_API_TOKEN not set, using GITHUB_TOKEN" >&2
    export REVIEWDOG_GITHUB_API_TOKEN="${GITHUB_TOKEN}"
fi

ACTION_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"

#
# Nothing below works without an autoloader: artisan, pest and phpunit all
# require vendor/autoload.php and die with a raw PHP fatal when it is missing.
# Install the dependencies when they are absent rather than failing on a stack
# trace, since a project without a committed composer.lock is easy to miss.
#
if [ ! -f vendor/autoload.php ]; then
    _install='false'

    case "${INSTALL}" in
        true) _install='true' ;;
        auto) [ -f composer.json ] && _install='true' ;;
    esac

    if [ "${_install}" = 'true' ]; then
        echo "vendor/autoload.php is missing, installing Composer dependencies" >&2

        # A failed install must not abort the script under `set -e`: the guard
        # below is what turns this into an actionable message and still writes
        # the step outputs.
        if ! command -v composer > /dev/null 2>&1; then
            echo "Error: composer was not found in PATH, cannot install dependencies." >&2
        else
            composer install --no-interaction --no-progress --prefer-dist --ansi >&2 || echo "Error: composer install failed, see the output above." >&2
        fi
    fi
fi

if [ ! -f vendor/autoload.php ]; then
    if [ -f composer.json ]; then
        echo "Error: Composer dependencies are not installed (vendor/autoload.php is missing). Run setup-php or composer install before this action, or set install to true." >&2
    else
        echo "Error: No composer.json found in $(pwd). Set working-directory to the package that holds the test suite." >&2
    fi

    printf 'tests-passed=false\n'
    printf 'coverage-file=\n'
    printf 'junit-file=\n'
    exit 1
fi

#
# Resolve the test runner: an explicit one when asked for, otherwise the first
# available of pest / phpunit, falling back to a `test` script in composer.json.
#
RUNNER_KIND=''
RUNNER_BIN=''

#
# Probe composer for a `test` script. Composer's own chatter is only surfaced
# when the probe fails, so a broken install shows its root cause instead of
# hiding behind a generic "no test runner" message.
#
_composer_has_test_script() {
    if [ ! -f composer.json ]; then
        return 1
    fi

    if ! command -v composer > /dev/null 2>&1; then
        echo "Error: composer was not found in PATH." >&2
        return 1
    fi

    _probe_err="${TMPDIR:-/tmp}/run-phptests-composer-$$.err"
    _probe_out=''

    if ! _probe_out="$(composer run-script --list 2> "${_probe_err}")"; then
        echo "Error: \`composer run-script --list\` failed:" >&2
        cat "${_probe_err}" >&2
        rm -f "${_probe_err}"
        return 1
    fi

    rm -f "${_probe_err}"

    printf '%s\n' "${_probe_out}" | grep -qE '^[[:space:]]*test[[:space:]]'
}

_resolve_runner() {
    case "${TEST_RUNNER}" in
        auto)
            for _candidate in pest phpunit; do
                if command -v "${_candidate}" > /dev/null 2>&1; then
                    RUNNER_KIND='phpunit'
                    RUNNER_BIN="${_candidate}"
                    return 0
                fi
            done

            if _composer_has_test_script; then
                RUNNER_KIND='composer'
                RUNNER_BIN='composer'
                return 0
            fi

            echo "Error: No test runner found. Install pest or phpunit, or declare a \"test\" script in composer.json." >&2
            return 1
            ;;
        composer)
            if ! _composer_has_test_script; then
                echo "Error: Runner \"composer\" was requested but no \"test\" script is available in composer.json." >&2
                return 1
            fi

            RUNNER_KIND='composer'
            RUNNER_BIN='composer'
            return 0
            ;;
        *)
            if command -v "${TEST_RUNNER}" > /dev/null 2>&1; then
                RUNNER_KIND='phpunit'
                RUNNER_BIN="${TEST_RUNNER}"
                return 0
            fi

            echo "Error: Requested test runner not found in PATH: ${TEST_RUNNER}" >&2
            return 1
            ;;
    esac
}

if ! _resolve_runner; then
    printf 'tests-passed=false\n'
    printf 'coverage-file=\n'
    printf 'junit-file=\n'
    exit 1
fi

#
# Coverage is only requested when a driver can actually produce it: asking for a
# clover report without xdebug or pcov makes PHPUnit fail with an obscure error.
#
_has_coverage_driver() {
    php -r 'exit(extension_loaded("xdebug") || extension_loaded("pcov") ? 0 : 1);' > /dev/null 2>&1
}

case "${COVERAGE}" in
    true)
        if _has_coverage_driver; then
            COVERAGE_ENABLED='true'
        else
            echo "Error: Coverage was requested but neither xdebug nor pcov is loaded." >&2
            printf 'tests-passed=false\n'
            printf 'coverage-file=\n'
            printf 'junit-file=\n'
            exit 1
        fi
        ;;
    auto)
        if _has_coverage_driver; then
            COVERAGE_ENABLED='true'
        else
            echo "No coverage driver (xdebug/pcov) loaded, running tests without coverage." >&2
            COVERAGE_ENABLED='false'
        fi
        ;;
    *)
        COVERAGE_ENABLED='false'
        ;;
esac

if [ "${COVERAGE_ENABLED}" = 'true' ] && php -r 'exit(extension_loaded("xdebug") ? 0 : 1);' > /dev/null 2>&1; then
    export XDEBUG_MODE=coverage
fi

#
# Laravel bootstrap. An existing .env is never overwritten: the checkout may
# carry one on purpose, and clobbering it silently changes what is tested.
#
if [ ! -f .env ]; then
    for _template in .env.example .env.testing .env.ci; do
        if [ -f "${_template}" ]; then
            echo "Seeding .env from ${_template}" >&2
            cp "${_template}" .env
            break
        fi
    done

    if [ ! -f .env ]; then
        echo "No .env template found, creating an empty .env" >&2
        : > .env
    fi
fi

if [ -f artisan ]; then
    php artisan key:generate --ansi --force >&2

    # Never `config:cache` before a test run: cached config freezes env() to the
    # build-time values and silently ignores .env.testing / phpunit.xml overrides.
    php artisan config:clear >&2

    _should_migrate='false'
    case "${MIGRATE}" in
        true) _should_migrate='true' ;;
        auto)
            if [ -d database/migrations ] && [ -n "$(find database/migrations -name '*.php' -print -quit 2> /dev/null)" ]; then
                _should_migrate='true'
            fi
            ;;
    esac

    if [ "${_should_migrate}" = 'true' ]; then
        echo "Running database migrations" >&2
        php artisan migrate --force --no-interaction >&2
    fi
fi

#
# Run the suite. Everything the runner prints is forwarded to stderr so it shows
# up in the job log while stdout stays reserved for GITHUB_OUTPUT key/values.
#
runner_args=''
junit_written='false'

if [ "${RUNNER_KIND}" = 'phpunit' ]; then
    runner_args="${runner_args} --log-junit=${JUNIT_FILE}"
    junit_written='true'

    if [ "${COVERAGE_ENABLED}" = 'true' ]; then
        runner_args="${runner_args} --coverage-clover=${COVERAGE_FILE}"
    fi
fi

rm -f "${JUNIT_FILE}" "${COVERAGE_FILE}"

echo "Running test suite with ${RUNNER_BIN}" >&2

exit_code=0
if [ "${RUNNER_KIND}" = 'composer' ]; then
    # shellcheck disable=SC2086
    composer run-script --no-interaction test -- ${TEST_FLAGS} ${TEST_PATHS} >&2 || exit_code=$?
else
    # shellcheck disable=SC2086
    "${RUNNER_BIN}" ${runner_args} ${TEST_FLAGS} ${TEST_PATHS} >&2 || exit_code=$?
fi

#
# Report failing tests through reviewdog. The suite's own exit code is what
# fails the step, so a reporting problem never masks or invents a test result.
#
if [ "${junit_written}" = 'true' ] && [ -f "${JUNIT_FILE}" ]; then
    if [ -z "${REVIEWDOG_GITHUB_API_TOKEN:-}" ]; then
        echo "No GITHUB_TOKEN or REVIEWDOG_GITHUB_API_TOKEN set, skipping reviewdog reporting." >&2
    elif ! command -v "${REVIEWDOG_BIN}" > /dev/null 2>&1; then
        echo "reviewdog was not found in PATH, skipping reviewdog reporting." >&2
    else
        echo "Reviewdog parameters: -f=rdjson -name=${REVIEWDOG_NAME} -reporter=${REVIEWDOG_REPORTER} -level=${REVIEWDOG_LEVEL} -filter-mode=${REVIEWDOG_FILTER_MODE} -fail-level=${REVIEWDOG_FAIL_LEVEL} -flags=${REVIEWDOG_FLAGS}" >&2
        echo "JUnit tempfile source size: $(wc -c < "${JUNIT_FILE}") bytes" >&2

        # shellcheck disable=SC2086
        php "${ACTION_DIR}/junit-to-rdjson.php" "${JUNIT_FILE}" \
            | "${REVIEWDOG_BIN}" \
                -f=rdjson \
                -name="${REVIEWDOG_NAME}" \
                -reporter="${REVIEWDOG_REPORTER}" \
                -level="${REVIEWDOG_LEVEL}" \
                -filter-mode="${REVIEWDOG_FILTER_MODE}" \
                -fail-level="${REVIEWDOG_FAIL_LEVEL}" \
                ${REVIEWDOG_FLAGS} >&2 || true
    fi
fi

if [ "${exit_code}" -eq 0 ]; then
    printf 'tests-passed=true\n'
else
    echo "::error::Test suite failed with exit code ${exit_code}." >&2
    printf 'tests-passed=false\n'
fi

if [ -f "${COVERAGE_FILE}" ]; then
    printf 'coverage-file=%s\n' "${COVERAGE_FILE}"
else
    printf 'coverage-file=\n'
fi

if [ -f "${JUNIT_FILE}" ]; then
    printf 'junit-file=%s\n' "${JUNIT_FILE}"
else
    printf 'junit-file=\n'
fi

exit "${exit_code}"
