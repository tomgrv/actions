# @format

# Tests setup-reviewdog/run.sh: Determine the reviewdog reporter for this run
# context from the `type` input and triggering event.

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  SCRIPT="${REPO_ROOT}/setup-reviewdog/run.sh"
}

run_resolve() {
  (
    export EVENT_NAME="$1"
    export TYPE_INPUT="$2"
    sh "$SCRIPT"
  )
}

@test "pull_request event with no type → github-pr-check" {
  run run_resolve "pull_request" ""
  [ "$status" -eq 0 ]
  [ "$output" = "REVIEWDOG_REPORTER=github-pr-check" ]
}

@test "pull_request_target event with no type → github-pr-check" {
  run run_resolve "pull_request_target" ""
  [ "$status" -eq 0 ]
  [ "$output" = "REVIEWDOG_REPORTER=github-pr-check" ]
}

@test "non-PR event with no type → github-check" {
  run run_resolve "push" ""
  [ "$status" -eq 0 ]
  [ "$output" = "REVIEWDOG_REPORTER=github-check" ]
}

@test "workflow_dispatch event with no type → github-check" {
  run run_resolve "workflow_dispatch" ""
  [ "$status" -eq 0 ]
  [ "$output" = "REVIEWDOG_REPORTER=github-check" ]
}

@test "pull_request event with type=review → github-pr-review" {
  run run_resolve "pull_request" "review"
  [ "$status" -eq 0 ]
  [ "$output" = "REVIEWDOG_REPORTER=github-pr-review" ]
}

@test "pull_request event with type=annotations → github-pr-annotations" {
  run run_resolve "pull_request" "annotations"
  [ "$status" -eq 0 ]
  [ "$output" = "REVIEWDOG_REPORTER=github-pr-annotations" ]
}

@test "push event with type=check → github-check" {
  run run_resolve "push" "check"
  [ "$status" -eq 0 ]
  [ "$output" = "REVIEWDOG_REPORTER=github-check" ]
}

@test "push event with type=review → github-review" {
  run run_resolve "push" "review"
  [ "$status" -eq 0 ]
  [ "$output" = "REVIEWDOG_REPORTER=github-review" ]
}

@test "invalid type → errors" {
  run run_resolve "pull_request" "bogus"
  [ "$status" -ne 0 ]
  echo "$output" | grep -q "Invalid type"
}
