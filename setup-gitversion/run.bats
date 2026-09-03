# @format

# Tests setup-gitversion/run.sh: idempotently install the gitversion toolchain.

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  SCRIPT="${REPO_ROOT}/setup-gitversion/run.sh"
  STUB_BIN="$(mktemp -d)"
  export PATH="${STUB_BIN}:${PATH}"
  # run.sh always does `export PATH="${INSTALL_BIN_DIR:-/usr/local/bin}:$PATH"`
  # even when the install is skipped -- point it at STUB_BIN too, so a real
  # gv this dev container may already have installed system-wide doesn't
  # shadow the stub once that line re-prepends its default.
  export INSTALL_BIN_DIR="${STUB_BIN}"
  unset GITHUB_PATH
}

teardown() {
  rm -rf "${STUB_BIN}"
}

stub() {
  # stub <name> <exit-code>
  cat >"${STUB_BIN}/$1" <<STUB
#!/bin/sh
echo "called: $1 \$*" >&2
exit ${2:-0}
STUB
  chmod +x "${STUB_BIN}/$1"
}

stub_toolchain_present() {
  for name in gv bump-tag bump-changelog bump-version gitversion; do
    stub "$name" 0
  done
}

@test "skips the feature install when the toolchain is already on PATH" {
  stub_toolchain_present
  stub npm 1 # would fail loudly if actually invoked
  run sh "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "installs the gitversion feature via npm exec when tools are missing" {
  # npm stub simulates the feature installer materializing the toolchain.
  cat >"${STUB_BIN}/npm" <<STUB
#!/bin/sh
echo "npm called: \$*" >&2
for name in gv bump-tag bump-changelog bump-version gitversion; do
  cat >"${STUB_BIN}/\$name" <<INNER
#!/bin/sh
exit 0
INNER
  chmod +x "${STUB_BIN}/\$name"
done
STUB
  chmod +x "${STUB_BIN}/npm"
  run sh "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"npm called:"* ]]
  [[ "$output" == *"exec --yes"*"devcontainer-features"*"gitversion"* ]]
}

@test "errors when a tool is still missing after install" {
  stub npm 0 # a no-op npm that installs nothing
  run sh "$SCRIPT"
  [ "$status" -ne 0 ]
  [[ "$output" == *"not on PATH after install"* ]]
}

@test "appends the install bin dir to GITHUB_PATH when set" {
  stub_toolchain_present
  gh_path_file="$(mktemp)"
  export GITHUB_PATH="$gh_path_file"
  run sh "$SCRIPT"
  [ "$status" -eq 0 ]
  grep -qF "$STUB_BIN" "$gh_path_file"
  rm -f "$gh_path_file"
}
