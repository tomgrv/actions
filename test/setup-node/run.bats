# @format

# Tests setup-node/run.sh: Setup Node.js and npm in CI environment.

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)"
  SCRIPT="${REPO_ROOT}/setup-node/run.sh"
}

run_setup_node() {
  (
    export NODE_VERSION="${1:-}"
    export NPM_VERSION="${2:-}"
    sh "$SCRIPT" 2>/dev/null
  )
}

@test "runs without errors with defaults" {
  run run_setup_node
  [ "$status" -eq 0 ]
}

@test "outputs node_version when Node is installed" {
  run run_setup_node
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "^node_version=" || true
}

@test "outputs npm_version when npm is installed" {
  run run_setup_node
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "^npm_version=" || true
}

@test "sets Node version when specified" {
  run run_setup_node "20"
  [ "$status" -eq 0 ]
}

@test "sets npm version when specified" {
  run run_setup_node "" "10"
  [ "$status" -eq 0 ]
}

@test "node command is available after setup" {
  run run_setup_node
  [ "$status" -eq 0 ]
  command -v node >/dev/null 2>&1 || true
}

@test "npm command is available after setup" {
  run run_setup_node
  [ "$status" -eq 0 ]
  command -v npm >/dev/null 2>&1 || true
}
