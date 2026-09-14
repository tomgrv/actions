# @format

# Tests setup-node/action.yml: shared Node setup and dependency-install guards.

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  ACTION_FILE="${REPO_ROOT}/setup-node/action.yml"
  TEST_DIR="$(mktemp -d)"
  STUB_BIN="$(mktemp -d)"
  CALLS_FILE="$(mktemp)"
  export PATH="${STUB_BIN}:${PATH}"
}

teardown() {
  rm -rf "${TEST_DIR}" "${STUB_BIN}"
  rm -f "${CALLS_FILE}"
}

stub_npm() {
  cat > "${STUB_BIN}/npm" << STUB
#!/bin/sh
echo "npm \$*" >> "${CALLS_FILE}"
STUB
  chmod +x "${STUB_BIN}/npm"
}

init_repo() {
  repo_dir="${TEST_DIR}/repo"
  mkdir -p "${repo_dir}"
  git -C "${repo_dir}" init -q
  printf '{}\n' > "${repo_dir}/package-lock.json"
}

run_setup_node_fixture() {
  repo_dir="${1:?}"
  marker="${2:-false}"
  bare_input="${3:-false}"
  (
    cd "${repo_dir}"
    GITHUB_OUTPUT="${repo_dir}/github-output"
    GITHUB_ENV="${repo_dir}/github-env"
    export GITHUB_OUTPUT GITHUB_ENV
    if [ "${marker}" = "true" ]; then
      export TOMGRV_NODE_SETUP=true
    else
      unset TOMGRV_NODE_SETUP
    fi
    bare_repo="$(git rev-parse --is-bare-repository 2> /dev/null || echo false)"
    if [ "${TOMGRV_NODE_SETUP:-}" != 'true' ] && [ "${bare_input}" != 'true' ] && [ "${bare_repo}" != 'true' ] && [ -f package-lock.json ]; then
      npm ci --no-progress --workspaces
    fi
    if [ "${TOMGRV_NODE_SETUP:-}" != 'true' ]; then
      echo "TOMGRV_NODE_SETUP=true" >> "${GITHUB_ENV}"
    fi
  )
}

@test "declares a composite action" {
  run grep -c '^  using: composite$' "$ACTION_FILE"
  [ "$status" -eq 0 ]
  [ "$output" -eq 1 ]
}

@test "installs dependencies and marks the toolchain for a non-bare repo with a lockfile" {
  stub_npm
  init_repo
  run run_setup_node_fixture "${TEST_DIR}/repo"
  [ "$status" -eq 0 ]
  grep -qF "npm ci --no-progress --workspaces" "${CALLS_FILE}"
  grep -qF "TOMGRV_NODE_SETUP=true" "${TEST_DIR}/repo/github-env"
}

@test "skips dependency install when bare=true but still marks the toolchain ready" {
  stub_npm
  init_repo
  run run_setup_node_fixture "${TEST_DIR}/repo" false true
  [ "$status" -eq 0 ]
  [ ! -s "${CALLS_FILE}" ]
  grep -qF "TOMGRV_NODE_SETUP=true" "${TEST_DIR}/repo/github-env"
}

@test "skips repeated setup once TOMGRV_NODE_SETUP is already true" {
  stub_npm
  init_repo
  run run_setup_node_fixture "${TEST_DIR}/repo" true
  [ "$status" -eq 0 ]
  [ ! -s "${CALLS_FILE}" ]
  [ ! -f "${TEST_DIR}/repo/github-env" ]
}
