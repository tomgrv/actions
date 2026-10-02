# @format

# Tests list-php-parts/run.sh: wraps php-changed and emits matrix/has-parts outputs.

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  SCRIPT="${REPO_ROOT}/list-php-parts/run.sh"
  TEST_DIR="$(mktemp -d)"
  STUB_BIN="$(mktemp -d)"
  ARGS_FILE="${STUB_BIN}/args"

  # zz_log is a no-op; php-changed records its arguments and prints $STUB_MATRIX.
  printf '#!/bin/sh\nexit 0\n' > "${STUB_BIN}/zz_log"
  printf '#!/bin/sh\necho "$@" > "%s"\nprintf "%%s" "$STUB_MATRIX"\n' "${ARGS_FILE}" > "${STUB_BIN}/php-changed"
  chmod +x "${STUB_BIN}/zz_log" "${STUB_BIN}/php-changed"

  cd "$TEST_DIR"
  git init -q -b main
}

teardown() {
  rm -rf "$TEST_DIR" "$STUB_BIN"
}

run_parts() {
  (
    cd "$TEST_DIR"
    export PATH="${STUB_BIN}:${PATH}"
    export STUB_MATRIX="$1"
    export LIST_BASE_REF="${2:-}"
    export LIST_ALL="${3:-false}"
    unset GITHUB_BASE_REF GITHUB_WORKSPACE
    sh "$SCRIPT" 2>/dev/null
  )
}

@test "emits the matrix and has-parts=true when parts are affected" {
  run run_parts '[{"name":"modules/Shop","suite":"Shop","path":"modules/Shop/tests"}]'
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '^matrix=\[{"name":"modules/Shop"'
  echo "$output" | grep -q "^has-parts=true$"
}

@test "emits an empty matrix and has-parts=false when nothing is affected" {
  run run_parts ''
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "^matrix=\[\]$"
  echo "$output" | grep -q "^has-parts=false$"
}

@test "forwards base-ref to php-changed as origin/<ref>" {
  run run_parts '[]' develop
  [ "$status" -eq 0 ]
  grep -q -- "-f json -b origin/develop" "$ARGS_FILE"
}

@test "forwards all=true to php-changed" {
  run run_parts '[]' '' true
  [ "$status" -eq 0 ]
  grep -q -- "-a" "$ARGS_FILE"
}
