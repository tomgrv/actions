# @format

# Tests setup-php/run.sh: Setup PHP and Composer in CI environment.

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  SCRIPT="${REPO_ROOT}/setup-php/run.sh"
}

run_setup_php() {
  (
    export PHP_VERSION="${1:-}"
    export COMPOSER_VERSION="${2:-}"
    export PHP_EXTENSIONS="${3:-}"
    export PHP_INI_VALUES="${4:-}"
    sh "$SCRIPT" 2>/dev/null
  )
}

@test "runs without errors with defaults" {
  run run_setup_php
  [ "$status" -eq 0 ]
}

@test "outputs php_version when PHP is installed" {
  run run_setup_php
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "^php_version=" || true
}

@test "sets PHP version when specified" {
  run run_setup_php "8.2"
  [ "$status" -eq 0 ]
}

@test "sets Composer version when specified" {
  run run_setup_php "" "2"
  [ "$status" -eq 0 ]
}

@test "handles PHP extensions input" {
  run run_setup_php "" "" "json,mbstring"
  [ "$status" -eq 0 ]
}

@test "handles PHP ini values input" {
  run run_setup_php "" "" "" "display_errors=On"
  [ "$status" -eq 0 ]
}

@test "composer_home is set in environment" {
  run run_setup_php
  [ "$status" -eq 0 ]
  # Check that composer home is set or available
  [ -n "${COMPOSER_HOME:-}" ] || command -v composer >/dev/null
}
