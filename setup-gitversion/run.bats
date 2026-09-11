# @format

# Tests setup-gitversion/run.sh: idempotently install the gitversion toolchain.
# gv/bump-tag/bump-changelog/bump-version are installed by this action's own
# earlier "Setup scripts toolchain" step (setup-scripts@v2, scripts: zz_log
# gv bump-tag bump-changelog bump-version) -- run.sh itself only builds the
# docker-gitversion wrapper/gitversion symlink and then verifies everything
# actually landed on PATH.

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
  # zz_log itself needs to resolve here -- in real CI it's put on PATH by
  # the setup-scripts composite step; stub a minimal stand-in.
  cat > "${STUB_BIN}/zz_log" <<'EOF'
#!/bin/sh
shift
echo "$*" >&2
EOF
  chmod +x "${STUB_BIN}/zz_log"
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

stub_scripts_toolchain() {
  for name in gv bump-tag bump-changelog bump-version; do
    stub "$name" 0
  done
}

stub_toolchain_present() {
  stub_scripts_toolchain
  stub gitversion 0
}

@test "skips building the docker wrapper when gitversion is already on PATH" {
  stub_toolchain_present
  run sh "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "builds the docker wrapper when gitversion is missing, given gv/bump-tag/bump-changelog/bump-version already installed" {
  stub_scripts_toolchain
  run sh "$SCRIPT"
  [ "$status" -eq 0 ]
  [ -x "${STUB_BIN}/docker-gitversion" ]
  [ -L "${STUB_BIN}/gitversion" ]
}

@test "errors clearly when gv/bump-tag/bump-changelog/bump-version weren't installed by the earlier setup-scripts step" {
  # None of the four stubbed -- simulates the "Setup scripts toolchain" step
  # never having run or having failed to actually land them on PATH.
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
