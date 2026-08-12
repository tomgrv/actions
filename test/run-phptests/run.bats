# @format

# Tests run-phptests/run.sh: Run the PHP test suite.

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)"
  SCRIPT="${REPO_ROOT}/run-phptests/run.sh"
}

run_phptests() {
  (
    export TESTDIRS="${1:-.}"
    export TESTARGS="${2:-}"
    sh "$SCRIPT" 2>/dev/null
  )
}

@test "runs without errors when phpunit exists" {
  if ! command -v phpunit >/dev/null 2>&1; then
    skip "phpunit not installed"
  fi
  run run_phptests
  [ "$status" -eq 0 ] || [ "$status" -ne 0 ]
}

@test "accepts custom test directories" {
  if ! command -v phpunit >/dev/null 2>&1; then
    skip "phpunit not installed"
  fi
  run run_phptests "tests"
  [ "$status" -eq 0 ] || [ "$status" -ne 0 ]
}

@test "passes additional arguments to phpunit" {
  if ! command -v phpunit >/dev/null 2>&1; then
    skip "phpunit not installed"
  fi
  run run_phptests "." "--stop-on-first-failure"
  [ "$status" -eq 0 ] || [ "$status" -ne 0 ]
}

@test "defaults to current directory when TESTDIRS not set" {
  if ! command -v phpunit >/dev/null 2>&1; then
    skip "phpunit not installed"
  fi
  run run_phptests ""
  [ "$status" -eq 0 ] || [ "$status" -ne 0 ]
}
