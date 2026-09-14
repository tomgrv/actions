# @format

# Tests run-workspace-tests/run.sh: delegates to the run-workspace-tests
# command (from tomgrv/scripts) with WORKSPACE as its argument.

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  SCRIPT="${REPO_ROOT}/run-workspace-tests/run.sh"
  STUB_BIN="$(mktemp -d)"
  PATH="${STUB_BIN}:${PATH}"
}

teardown() {
  rm -rf "$STUB_BIN"
}

stub_zz_log() {
  cat >"${STUB_BIN}/zz_log" <<'EOF'
#!/bin/sh
lvl="$1"
shift
printf '%s %s\n' "$lvl" "$*" >&2
EOF
  chmod +x "${STUB_BIN}/zz_log"
}

stub_run_workspace_tests() {
  cat >"${STUB_BIN}/run-workspace-tests" <<'EOF'
#!/bin/sh
printf 'called with: %s\n' "$*"
EOF
  chmod +x "${STUB_BIN}/run-workspace-tests"
}

@test "errors when WORKSPACE is not set" {
  stub_zz_log
  run sh "$SCRIPT"
  [ "$status" -ne 0 ]
  [[ "$output" == *"WORKSPACE"* ]]
}

@test "delegates to run-workspace-tests with WORKSPACE as its argument" {
  stub_zz_log
  stub_run_workspace_tests
  run env WORKSPACE="src/foo" sh "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"called with: src/foo"* ]]
}
