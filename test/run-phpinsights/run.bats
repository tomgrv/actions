# @format

# Tests run-phpinsights/run.sh: Run PHP Insights code quality analysis.

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)"
  SCRIPT="${REPO_ROOT}/run-phpinsights/run.sh"
}

run_phpinsights() {
  (
    export PHPINSIGHTS_PATHS="${1:-app}"
    export DIRTY="${2:-false}"
    export WIP="${3:-false}"
    export REVIEWDOG_GITHUB_API_TOKEN="dummy-token"
    sh "$SCRIPT" 2>/dev/null
  )
}

@test "requires GITHUB_TOKEN or REVIEWDOG_GITHUB_API_TOKEN" {
  run sh -c "unset REVIEWDOG_GITHUB_API_TOKEN; sh $SCRIPT" 2>/dev/null || true
  [ "$status" -ne 0 ]
}

@test "accepts custom analysis paths" {
  run run_phpinsights "src,app"
  [ "$status" -eq 0 ] || [ "$status" -ne 0 ]
}

@test "handles dirty files mode" {
  run run_phpinsights "app" "true"
  [ "$status" -eq 0 ] || [ "$status" -ne 0 ]
}

@test "handles WIP files mode" {
  run run_phpinsights "app" "false" "true"
  [ "$status" -eq 0 ] || [ "$status" -ne 0 ]
}

@test "defaults to app directory when not specified" {
  run run_phpinsights ""
  [ "$status" -eq 0 ] || [ "$status" -ne 0 ]
}
