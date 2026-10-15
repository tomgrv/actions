# @format

# Tests run-workspace-tests/run.sh: delegates to the ws-test
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
  cat >"${STUB_BIN}/zz-log" <<'EOF'
#!/bin/sh
lvl="$1"
shift
printf '%s %s\n' "$lvl" "$*" >&2
EOF
  chmod +x "${STUB_BIN}/zz-log"
}

stub_ws_test() {
  cat >"${STUB_BIN}/ws-test" <<'EOF'
#!/bin/sh
printf 'called with: %s\n' "$*"
EOF
  chmod +x "${STUB_BIN}/ws-test"
}

@test "errors when WORKSPACE is not set" {
  stub_zz_log
  # Unset explicitly: when this suite runs via the composite action itself
  # (testing run-workspace-tests with itself), WORKSPACE is
  # already exported in the surrounding CI step's environment and would
  # otherwise leak into this subshell, making the check a no-op.
  run env -u WORKSPACE sh "$SCRIPT"
  [ "$status" -ne 0 ]
  [[ "$output" == *"WORKSPACE"* ]]
}

@test "delegates to ws-test with WORKSPACE as its argument" {
  stub_zz_log
  stub_ws_test
  run env WORKSPACE="src/foo" sh "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"called with: src/foo"* ]]
}
