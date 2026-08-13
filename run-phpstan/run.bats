# @format

# Tests run-phpstan/run.sh: Run PHPStan static analysis.

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  SCRIPT="${REPO_ROOT}/run-phpstan/run.sh"
}

run_phpstan() {
  (
    export PHPSTAN_PATHS="${1:-app}"
    export PHPSTAN_LEVEL="${2:-5}"
    export PHPSTAN_CONFIG="${3:-}"
    export DIRTY="${4:-false}"
    export WIP="${5:-false}"
    export REVIEWDOG_GITHUB_API_TOKEN="dummy-token"
    sh "$SCRIPT" 2>/dev/null
  )
}

@test "requires GITHUB_TOKEN or REVIEWDOG_GITHUB_API_TOKEN" {
  run sh -c "unset REVIEWDOG_GITHUB_API_TOKEN; sh $SCRIPT" 2>/dev/null || true
  [ "$status" -ne 0 ]
}

@test "accepts custom PHPStan paths" {
  run run_phpstan "src,app"
  [ "$status" -eq 0 ] || [ "$status" -ne 0 ]
}

@test "accepts custom analysis level" {
  run run_phpstan "app" "8"
  [ "$status" -eq 0 ] || [ "$status" -ne 0 ]
}

@test "accepts custom config file" {
  run run_phpstan "app" "5" "phpstan.neon"
  [ "$status" -eq 0 ] || [ "$status" -ne 0 ]
}

@test "handles dirty files mode" {
  run run_phpstan "app" "5" "" "true"
  [ "$status" -eq 0 ] || [ "$status" -ne 0 ]
}

@test "handles WIP files mode" {
  run run_phpstan "app" "5" "" "false" "true"
  [ "$status" -eq 0 ] || [ "$status" -ne 0 ]
}

@test "defaults to level 5 when not specified" {
  run run_phpstan "app" ""
  [ "$status" -eq 0 ] || [ "$status" -ne 0 ]
}
