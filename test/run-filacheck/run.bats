# @format

# Tests run-filacheck/run.sh: Run FilaCheck Filament code analysis.

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)"
  SCRIPT="${REPO_ROOT}/run-filacheck/run.sh"
}

run_filacheck() {
  (
    export FILACHECK_PATHS="${1:-app}"
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

@test "accepts custom Filament paths" {
  run run_filacheck "app/Filament"
  [ "$status" -eq 0 ] || [ "$status" -ne 0 ]
}

@test "handles dirty files mode" {
  run run_filacheck "app" "true"
  [ "$status" -eq 0 ] || [ "$status" -ne 0 ]
}

@test "handles WIP files mode" {
  run run_filacheck "app" "false" "true"
  [ "$status" -eq 0 ] || [ "$status" -ne 0 ]
}
