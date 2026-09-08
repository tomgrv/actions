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

# run.sh unconditionally calls `zz_use gv bump-tag bump-changelog
# bump-version` -- this stub simulates a successful zz_use by dropping a
# stub script onto PATH for each name it's asked to install, same as the
# real zz_use would after fetching them from tomgrv/scripts.
stub_zz_use() {
  cat >"${STUB_BIN}/zz_use" <<STUB
#!/bin/sh
echo "called: zz_use \$*" >&2
for name do
  case "\$name" in
    -*) continue ;;
  esac
  cat > "${STUB_BIN}/\$name" <<INNER
#!/bin/sh
exit 0
INNER
  chmod +x "${STUB_BIN}/\$name"
done
exit ${1:-0}
STUB
  chmod +x "${STUB_BIN}/zz_use"
}

stub_toolchain_present() {
  for name in gv bump-tag bump-changelog bump-version gitversion; do
    stub "$name" 0
  done
}

@test "skips building the docker wrapper when gitversion is already on PATH" {
  stub_toolchain_present
  stub_zz_use 0
  run sh "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "builds the docker wrapper and zz_uses gv/bump-tag/bump-changelog/bump-version when missing" {
  stub_zz_use 0
  run sh "$SCRIPT"
  [ "$status" -eq 0 ]
  [ -x "${STUB_BIN}/docker-gitversion" ]
  [ -L "${STUB_BIN}/gitversion" ]
  [[ "$output" == *"called: zz_use gv bump-tag bump-changelog bump-version"* ]]
  [ -x "${STUB_BIN}/gv" ]
  [ -x "${STUB_BIN}/bump-tag" ]
  [ -x "${STUB_BIN}/bump-changelog" ]
  [ -x "${STUB_BIN}/bump-version" ]
}

@test "errors when zz_use fails to install the toolchain" {
  stub_zz_use 1
  run sh "$SCRIPT"
  [ "$status" -ne 0 ]
}

@test "appends the install bin dir to GITHUB_PATH when set" {
  stub_toolchain_present
  stub_zz_use 0
  gh_path_file="$(mktemp)"
  export GITHUB_PATH="$gh_path_file"
  run sh "$SCRIPT"
  [ "$status" -eq 0 ]
  grep -qF "$STUB_BIN" "$gh_path_file"
  rm -f "$gh_path_file"
}
