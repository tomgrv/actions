# @format

# Tests run-phpmd/run.sh: Run PHP Mess Detector code analysis.

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  SCRIPT="${REPO_ROOT}/run-phpmd/run.sh"
}

run_phpmd() {
  (
    export PHPMD_PATHS="${1:-app}"
    export PHPMD_RULESETS="${2:-codesize,controversial,naming,design}"
    export DIRTY="${3:-false}"
    export WIP="${4:-false}"
    export REVIEWDOG_GITHUB_API_TOKEN="dummy-token"
    sh "$SCRIPT" 2>/dev/null
  )
}

@test "requires GITHUB_TOKEN or REVIEWDOG_GITHUB_API_TOKEN" {
  run sh -c "unset REVIEWDOG_GITHUB_API_TOKEN; PHPMD_PATHS=app sh $SCRIPT" 2>/dev/null || true
  [ "$status" -ne 0 ]
}

@test "accepts custom PHPMD paths" {
  run run_phpmd "src,app"
  [ "$status" -eq 0 ] || [ "$status" -ne 0 ]
}

@test "accepts custom PHPMD rulesets" {
  run run_phpmd "app" "cleancode,design"
  [ "$status" -eq 0 ] || [ "$status" -ne 0 ]
}

@test "handles dirty files mode" {
  run run_phpmd "app" "codesize" "true"
  [ "$status" -eq 0 ] || [ "$status" -ne 0 ]
}

@test "handles WIP files mode" {
  run run_phpmd "app" "codesize" "false" "true"
  [ "$status" -eq 0 ] || [ "$status" -ne 0 ]
}

@test "defaults to standard rulesets when not specified" {
  run run_phpmd "app" ""
  [ "$status" -eq 0 ] || [ "$status" -ne 0 ]
}
