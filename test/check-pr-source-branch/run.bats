# @format

# Tests check-pr-source-branch/run.sh: Reject PRs from the restricted branch
# unless the title marks them as a hotfix.

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)"
  SCRIPT="${REPO_ROOT}/check-pr-source-branch/run.sh"
}

run_check() {
  (
    export SOURCE_BRANCH="${1:-}"
    export PR_TITLE="${2:-}"
    export RESTRICTED_BRANCH="${3:-main}"
    sh "$SCRIPT"
  )
}

@test "non-restricted source branch passes" {
  run run_check "feature/foo" "feat: add thing"
  [ "$status" -eq 0 ]
}

@test "restricted branch with hotfix in title passes" {
  run run_check "main" "hotfix: patch prod issue"
  [ "$status" -eq 0 ]
}

@test "restricted branch with hotfix word anywhere in title passes" {
  run run_check "main" "fix hotfix regression"
  [ "$status" -eq 0 ]
}

@test "restricted branch without hotfix in title fails" {
  run run_check "main" "feat: add thing"
  [ "$status" -eq 1 ]
  echo "$output" | grep -q "::error::"
}

@test "restricted branch with empty title fails" {
  run run_check "main" ""
  [ "$status" -eq 1 ]
  echo "$output" | grep -q "::error::"
}

@test "custom restricted branch is honored" {
  run run_check "release" "feat: add thing" "release"
  [ "$status" -eq 1 ]
  echo "$output" | grep -q "::error::"
}

@test "custom restricted branch does not block main" {
  run run_check "main" "feat: add thing" "release"
  [ "$status" -eq 0 ]
}

@test "missing SOURCE_BRANCH fails fast" {
  run sh "$SCRIPT"
  [ "$status" -ne 0 ]
}
