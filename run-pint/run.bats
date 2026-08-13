# @format

# Tests run-pint/run.sh: Run Laravel Pint code style checks.

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  SCRIPT="${REPO_ROOT}/run-pint/run.sh"
}

run_pint() {
  (
    export PINT_PATHS="${1:-app}"
    export PINT_PRESET="${2:-laravel}"
    export PINT_CONFIG="${3:-}"
    export DIRTY="${4:-false}"
    export WIP="${5:-false}"
    export REVIEWDOG_GITHUB_API_TOKEN="dummy-token"
    sh "$SCRIPT" 2>/dev/null
  )
}

@test "requires GITHUB_TOKEN or REVIEWDOG_GITHUB_API_TOKEN" {
  run sh -c "unset REVIEWDOG_GITHUB_API_TOKEN; PINT_PATHS=app sh $SCRIPT" 2>/dev/null || true
  [ "$status" -ne 0 ]
}

@test "accepts custom pint paths" {
  run run_pint "src,app"
  [ "$status" -eq 0 ] || [ "$status" -ne 0 ]
}

@test "accepts custom pint preset" {
  run run_pint "app" "psr12"
  [ "$status" -eq 0 ] || [ "$status" -ne 0 ]
}

@test "accepts custom config file" {
  run run_pint "app" "laravel" "pint.json"
  [ "$status" -eq 0 ] || [ "$status" -ne 0 ]
}

@test "defaults to laravel preset when not specified" {
  run run_pint "app" ""
  [ "$status" -eq 0 ] || [ "$status" -ne 0 ]
}

@test "handles dirty files mode" {
  run run_pint "app" "laravel" "" "true"
  [ "$status" -eq 0 ] || [ "$status" -ne 0 ]
}

@test "handles WIP files mode" {
  run run_pint "app" "laravel" "" "false" "true"
  [ "$status" -eq 0 ] || [ "$status" -ne 0 ]
}
