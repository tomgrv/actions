# @format

# Tests setup-scripts/run.sh: bootstrap zz_use, optionally install scripts.

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  SCRIPT="${REPO_ROOT}/setup-scripts/run.sh"
  STUB_BIN="$(mktemp -d)"
  export PATH="${STUB_BIN}:${PATH}"
  # run.sh always does `export PATH="${INSTALL_BIN_DIR:-/usr/local/bin}:$PATH"`
  # even when the bootstrap is skipped -- point it at STUB_BIN too, so a
  # real zz_use this dev container may already have installed system-wide
  # doesn't shadow the stub once that line re-prepends its default.
  export INSTALL_BIN_DIR="${STUB_BIN}"
  unset GITHUB_PATH
  unset SCRIPTS
  unset SCRIPTS_REF
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

stub_zz_use_recording() {
  # zz_use stub that records its argv for assertions
  cat >"${STUB_BIN}/zz_use" <<STUB
#!/bin/sh
echo "zz_use called with: \$*" >&2
exit 0
STUB
  chmod +x "${STUB_BIN}/zz_use"
}

@test "skips the network bootstrap when zz_use is already on PATH" {
  stub_zz_use_recording
  stub curl 1 # would fail loudly if actually invoked
  run sh "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "does nothing further when scripts is empty" {
  stub_zz_use_recording
  run sh "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" != *"zz_use called with:"* ]]
}

@test "zz_use's every requested script, unpinned, when scripts-ref is empty" {
  stub_zz_use_recording
  stub git-release-beta 0
  stub git-release-prod 0
  export SCRIPTS="git-release-beta git-release-prod"
  run sh "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"zz_use called with: git-release-beta git-release-prod"* ]]
}

@test "pins every requested script to scripts-ref when set" {
  stub_zz_use_recording
  stub git-release-beta 0
  stub git-release-prod 0
  export SCRIPTS="git-release-beta git-release-prod"
  export SCRIPTS_REF="v2"
  run sh "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"zz_use called with: git-release-beta@v2 git-release-prod@v2"* ]]
}

@test "errors when a requested script isn't on PATH after zz_use" {
  stub_zz_use_recording
  # git-release-beta deliberately not stubbed -- not on PATH after zz_use
  export SCRIPTS="git-release-beta"
  run sh "$SCRIPT"
  [ "$status" -ne 0 ]
  [[ "$output" == *"not on PATH after zz_use"* ]]
}

@test "appends the install bin dir to GITHUB_PATH when set" {
  stub_zz_use_recording
  gh_path_file="$(mktemp)"
  export GITHUB_PATH="$gh_path_file"
  run sh "$SCRIPT"
  [ "$status" -eq 0 ]
  grep -qF "$STUB_BIN" "$gh_path_file"
  rm -f "$gh_path_file"
}
