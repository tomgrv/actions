# @format

# Tests resolve-environment/run.sh: Resolve deploy branch, tag, and environment
# from GitHub events (push, PR review, tag, workflow_dispatch).

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)"
  SCRIPT="${REPO_ROOT}/resolve-environment/run.sh"
}

run_resolve() {
  (
    export EVENT_NAME="$1"
    export EVENT_ACTION="$2"
    export REF="$3"
    export REF_NAME="$4"
    export PR_HEAD_SHA="$5"
    export DEP="${6:-deploy}"
    sh "$SCRIPT"
  )
}

@test "pull_request review_requested → deploy PR head to unstable" {
  run run_resolve "pull_request" "review_requested" "refs/pull/42/merge" "branch" "abc123def456"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "^branch=abc123def456$"
  echo "$output" | grep -q "^env=unstable$"
}

@test "release branch push → deploy to staging" {
  run run_resolve "push" "" "refs/heads/release/1.2.3" "release/1.2.3" ""
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "^branch=release/1.2.3$"
  echo "$output" | grep -q "^env=staging$"
}

@test "main branch push → deploy to production" {
  run run_resolve "push" "" "refs/heads/main" "main" ""
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "^branch=main$"
  echo "$output" | grep -q "^env=production$"
}

@test "tag with dash (prerelease) → deploy to staging" {
  run run_resolve "push" "" "refs/tags/1.2.3-rc.1" "1.2.3-rc.1" ""
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "^tag=1.2.3-rc.1$"
  echo "$output" | grep -q "^env=staging$"
}

@test "tag without dash (release) → deploy to production" {
  run run_resolve "push" "" "refs/tags/1.2.3" "1.2.3" ""
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "^tag=1.2.3$"
  echo "$output" | grep -q "^env=production$"
}

@test "feature branch push with deploy command → use branch, no environment" {
  run run_resolve "push" "" "refs/heads/feature/my-feature" "feature/my-feature" "" "deploy"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "^branch=feature/my-feature$"
  echo "$output" | grep -q "^env=$"
}

@test "feature branch push with non-deploy command → no branch or tag" {
  run run_resolve "push" "" "refs/heads/feature/my-feature" "feature/my-feature" "" "unlock"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "^branch=$"
  echo "$output" | grep -q "^tag=$"
}

@test "outputs include empty values for unmatched rules" {
  run run_resolve "push" "" "refs/heads/feature/test" "feature/test" "" "deploy"
  [ "$status" -eq 0 ]
  # Should have three lines, one for each output variable
  lines_count=$(echo "$output" | grep -c "=")
  [ "$lines_count" -eq 3 ]
}

@test "non-matching event with deploy command → fallback to current branch" {
  run run_resolve "workflow_dispatch" "" "refs/heads/main" "main" "" "deploy"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "^branch=main$"
}

@test "detached HEAD or tag reference → tag takes precedence" {
  run run_resolve "push" "" "refs/tags/release-1" "release-1" ""
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "^tag=release-1$"
  echo "$output" | grep -q "^branch=$"
}
