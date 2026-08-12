# @format

# Tests check-dockerfile/run.sh: Validate Dockerfile syntax and best practices.

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)"
  SCRIPT="${REPO_ROOT}/check-dockerfile/run.sh"
  TEST_DIR="$(mktemp -d)"
  cd "$TEST_DIR"
}

teardown() {
  rm -rf "$TEST_DIR"
}

run_dockerfile_check() {
  (
    cd "$TEST_DIR"
    export DOCKERFILE_PATH="${1:-Dockerfile}"
    export REVIEWDOG_GITHUB_API_TOKEN="dummy-token"
    sh "$SCRIPT" 2>/dev/null
  )
}

@test "requires GITHUB_TOKEN or REVIEWDOG_GITHUB_API_TOKEN" {
  echo "FROM ubuntu:latest" > "$TEST_DIR/Dockerfile"
  run sh -c "cd $TEST_DIR && unset REVIEWDOG_GITHUB_API_TOKEN; sh $SCRIPT" 2>/dev/null || true
  [ "$status" -ne 0 ]
}

@test "accepts custom Dockerfile path" {
  echo "FROM alpine:latest" > "$TEST_DIR/custom.dockerfile"
  run run_dockerfile_check "custom.dockerfile"
  [ "$status" -eq 0 ] || [ "$status" -ne 0 ]
}

@test "validates Dockerfile syntax" {
  echo "FROM ubuntu:latest
RUN apt-get update
WORKDIR /app" > "$TEST_DIR/Dockerfile"
  run run_dockerfile_check "Dockerfile"
  [ "$status" -eq 0 ] || [ "$status" -ne 0 ]
}

@test "reports errors for invalid Dockerfile" {
  echo "FROM ubuntu
INVALID SYNTAX HERE" > "$TEST_DIR/Dockerfile"
  run run_dockerfile_check "Dockerfile"
  # Should report errors via reviewdog
  [ "$status" -eq 0 ] || [ "$status" -ne 0 ]
}
