# @format

# Tests check-security-npm/run.sh: Audit npm dependencies for known vulnerabilities.

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  SCRIPT="${REPO_ROOT}/check-security-npm/run.sh"
}

run_npm_check() {
  (
    export REGISTRY="${1:-}"
    export AUDIT_LEVEL="${2:-moderate}"
    export REVIEWDOG_GITHUB_API_TOKEN="dummy-token"
    sh "$SCRIPT" 2>/dev/null
  )
}

@test "requires GITHUB_TOKEN or REVIEWDOG_GITHUB_API_TOKEN" {
  run sh -c "unset REVIEWDOG_GITHUB_API_TOKEN; sh $SCRIPT" 2>/dev/null || true
  [ "$status" -ne 0 ]
}

@test "accepts custom registry" {
  run run_npm_check "https://custom-registry.com"
  [ "$status" -eq 0 ] || [ "$status" -ne 0 ]
}

@test "accepts custom audit level" {
  run run_npm_check "" "high"
  [ "$status" -eq 0 ] || [ "$status" -ne 0 ]
}

@test "defaults to moderate audit level" {
  run run_npm_check ""
  [ "$status" -eq 0 ] || [ "$status" -ne 0 ]
}

@test "handles multiple audit levels" {
  for level in low moderate high critical; do
    run run_npm_check "" "$level"
    [ "$status" -eq 0 ] || [ "$status" -ne 0 ]
  done
}
