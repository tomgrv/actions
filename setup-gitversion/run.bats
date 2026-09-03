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

@test "skips the network install when the toolchain is already on PATH" {
  stub_toolchain_present
  stub curl 1 # would fail loudly if actually invoked
  run sh "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "fetches gv/bump-tag/bump-changelog/bump-version and builds the docker wrapper when tools are missing" {
  # curl stub simulates fetching each bin script's content.
  cat >"${STUB_BIN}/curl" <<'STUB'
#!/bin/sh
# args: -fsSL <url> -o <dest>
for arg do
  prev="$arg"
  if [ "$last" = "-o" ]; then
    dest="$arg"
  fi
  last="$arg"
done
echo "#!/bin/sh" > "$dest"
echo "exit 0" >> "$dest"
STUB
  chmod +x "${STUB_BIN}/curl"
  run sh "$SCRIPT"
  [ "$status" -eq 0 ]
  [ -x "${STUB_BIN}/gv" ]
  [ -x "${STUB_BIN}/bump-tag" ]
  [ -x "${STUB_BIN}/bump-changelog" ]
  [ -x "${STUB_BIN}/bump-version" ]
  [ -x "${STUB_BIN}/docker-gitversion" ]
  [ -L "${STUB_BIN}/gitversion" ]
}

@test "errors when curl fails to fetch a script" {
  stub curl 1
  run sh "$SCRIPT"
  [ "$status" -ne 0 ]
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
