# @format

# Tests run-deployer/rdjson.jq: Deployer log lines must be classified into
# reviewdog rdjson diagnostics by content (error/warning keywords), not by
# the "[alias] " host prefix that every per-host line carries regardless of
# whether it's routine progress or an actual problem.

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)"
  JQ_SCRIPT="${REPO_ROOT}/run-deployer/rdjson.jq"
  FIXTURES="${BATS_TEST_DIRNAME}/fixtures"
}

run_rdjson() {
  jq -R -s --arg status "$1" --arg url "${2:-}" -f "${JQ_SCRIPT}" <"$3"
}

severity_count() {
  echo "$1" | jq --arg severity "$2" '[.diagnostics[] | select(.severity == $severity)] | length'
}

@test "successful deploy with one PHP warning reports exactly one warning and one notice" {
  run run_rdjson "0" "https://example.com" "${FIXTURES}/success-with-warning.txt"
  [ "$status" -eq 0 ]

  [ "$(severity_count "$output" WARNING)" -eq 1 ]
  [ "$(severity_count "$output" INFO)" -eq 1 ]
  [ "$(severity_count "$output" ERROR)" -eq 0 ]
}

@test "successful deploy does not flag routine task-progress lines as warnings" {
  run run_rdjson "0" "https://example.com" "${FIXTURES}/success-with-warning.txt"
  [ "$status" -eq 0 ]

  ok_flagged=$(echo "$output" | jq '[.diagnostics[] | select(.message | test("✔ Ok"))] | length')
  [ "$ok_flagged" -eq 0 ]
}

@test "success notice includes the deploy URL" {
  run run_rdjson "0" "https://example.com" "${FIXTURES}/success-with-warning.txt"
  [ "$status" -eq 0 ]

  echo "$output" | jq -e '.diagnostics[] | select(.severity == "INFO") | .message | contains("https://example.com")'
}

@test "failed deploy with a deprecation notice and an exception reports one warning and one aggregated error" {
  run run_rdjson "1" "" "${FIXTURES}/failure-with-exception.txt"
  [ "$status" -eq 0 ]

  [ "$(severity_count "$output" WARNING)" -eq 1 ]
  [ "$(severity_count "$output" ERROR)" -eq 1 ]
  [ "$(severity_count "$output" INFO)" -eq 0 ]
}

@test "aggregated error diagnostic includes the exception line" {
  run run_rdjson "1" "" "${FIXTURES}/failure-with-exception.txt"
  [ "$status" -eq 0 ]

  echo "$output" | jq -e '.diagnostics[] | select(.severity == "ERROR") | .message | test("GracefulShutdownException")'
}
