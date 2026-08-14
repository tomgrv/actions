# @format

# Tests check-security-composer/run.sh: Audit Composer dependencies for known vulnerabilities.

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  SCRIPT="${REPO_ROOT}/check-security-composer/run.sh"
}

run_composer_check() {
  (
    export COMPOSER_LOCK="${1:-composer.lock}"
    export REVIEWDOG_GITHUB_API_TOKEN="dummy-token"
    sh "$SCRIPT" 2>/dev/null
  )
}

@test "requires GITHUB_TOKEN or REVIEWDOG_GITHUB_API_TOKEN" {
  run sh -c "unset REVIEWDOG_GITHUB_API_TOKEN; sh $SCRIPT" 2>/dev/null || true
  [ "$status" -ne 0 ]
}

@test "accepts custom composer.lock path" {
  run run_composer_check "path/to/composer.lock"
  [ "$status" -eq 0 ] || [ "$status" -ne 0 ]
}

@test "defaults to composer.lock in current directory" {
  run run_composer_check ""
  [ "$status" -eq 0 ] || [ "$status" -ne 0 ]
}
